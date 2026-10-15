// Copyright © 2026 Easydict contributors. GPL-3.0.

import AppKit
import Combine
import Defaults
import SwiftUI

/// Becomes key only after an intentional click; merely appearing never steals focus.
final class ResultPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    // AppKit has no public always-active setting for NSGlassEffectView on macOS 26.
    // Match EchoType's appearance hints only on this panel; do not change real key/main status.
    // These undocumented selectors need revalidation after macOS updates.
    @objc(_hasActiveAppearance)
    private func focusedHasActiveAppearance() -> Bool { true }

    @objc(_hasActiveAppearanceIgnoringKeyFocus)
    private func focusedHasActiveAppearanceIgnoringKeyFocus() -> Bool { true }
}

@MainActor
final class ResultPanelController: NSObject, NSWindowDelegate {
    let panel: ResultPanel
    private let lookup: LookupController
    private let backdrop: BackdropAppearanceController
    private var lastPosition: CGPoint?
    private var hasShown = false
    private var observations = Set<AnyCancellable>()
    private var idleHideTimer: Timer?
    private var hideDeadline = Date.distantFuture
    private static let idleHideInterval: TimeInterval = 10

    init(lookup: LookupController) {
        self.lookup = lookup
        let resultPanel = ResultPanel(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 320),
            styleMask: [.borderless, .nonactivatingPanel, .resizable], backing: .buffered, defer: false
        )
        panel = resultPanel
        backdrop = BackdropAppearanceController(panel: resultPanel)
        super.init()
        panel.delegate = self
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.minSize = NSSize(width: 320, height: 200)
        panel.isReleasedWhenClosed = false
        let glass = NSGlassEffectView()
        glass.cornerRadius = 18
        glass.style = .clear
        // Tint only the material, keeping the text opaque over a gently darkened backdrop.
        glass.tintColor = NSColor.black.withAlphaComponent(0.12)
        let content = NSHostingView(rootView: ResultContentView(lookup: lookup, backdrop: backdrop, onClose: { [weak self] in self?.close() }))
        // AppKit owns the frame. SwiftUI content must not constrain or resize the user's window.
        content.sizingOptions = []
        glass.contentView = content
        panel.contentView = glass
        lookup.$isRunning.receive(on: DispatchQueue.main).sink { [weak self] _ in
            // Read current state after @Published commits, including rapid stop/retry transitions.
            self?.refreshAutoHide()
        }.store(in: &observations)
        Defaults.publisher(.focusedPinned).receive(on: DispatchQueue.main).sink { [weak self] _ in
            self?.refreshAutoHide()
        }.store(in: &observations)
    }

    func show(near anchor: CGPoint, clipboard: Bool) {
        if Defaults[.focusedPinned], hasShown {
            // Reuse the frame, including user drags/resizes, across selections, retries, and reopenings.
            if let visible = panel.screen?.visibleFrame { updateSizeLimits(for: visible) }
            updateCollectionBehavior()
            panel.orderFrontRegardless()
            backdrop.start()
            refreshAutoHide()
            return
        }
        let screen = NSScreen.screens.first { $0.frame.contains(anchor) } ?? NSScreen.main
        guard let visible = screen?.visibleFrame else { return }
        updateCollectionBehavior()
        updateSizeLimits(for: visible)
        let size = restoredSize(in: visible)
        let origin: CGPoint
        if Defaults[.focusedRememberPosition], let lastPosition { origin = lastPosition }
        else if clipboard { origin = CGPoint(x: visible.midX - size.width / 2, y: visible.midY - size.height / 2) }
        else { origin = CGPoint(x: anchor.x + 14, y: anchor.y - size.height - 14) }
        let frame = NSRect(
            x: min(max(origin.x, visible.minX), visible.maxX - size.width),
            y: min(max(origin.y, visible.minY), visible.maxY - size.height),
            width: size.width, height: size.height
        )
        panel.setFrame(frame, display: true)
        hasShown = true
        // Unlike makeKeyAndOrderFront, this does not transfer keyboard input to the lookup app.
        panel.orderFrontRegardless()
        backdrop.start()
        refreshAutoHide()
    }

    func close() {
        cancelAutoHide()
        backdrop.stop()
        lookup.stop()
        panel.orderOut(nil)
    }

    func windowDidMove(_ notification: Notification) {
        lastPosition = panel.frame.origin
        backdrop.frameDidChange()
    }
    func windowDidResize(_ notification: Notification) {
        backdrop.frameDidChange()
    }

    func windowWillStartLiveResize(_ notification: Notification) {
        if let visible = panel.screen?.visibleFrame { updateSizeLimits(for: visible) }
    }

    func windowDidEndLiveResize(_ notification: Notification) {
        // Persist only intentional user resizing, never programmatic positioning or a small-screen clamp.
        let size = panel.frame.size
        guard size.width.isFinite, size.height.isFinite, size.width > 0, size.height > 0 else { return }
        Defaults[.focusedPanelWidth] = Double(size.width)
        Defaults[.focusedPanelHeight] = Double(size.height)
    }

    func windowDidChangeScreen(_ notification: Notification) {
        if let visible = panel.screen?.visibleFrame { updateSizeLimits(for: visible) }
        backdrop.frameDidChange()
    }

    func windowWillClose(_ notification: Notification) {
        cancelAutoHide()
        backdrop.stop()
        lookup.stop()
    }

    /// Only completed, unpinned results expire; interacting with the panel renews the idle interval.
    private func refreshAutoHide() {
        cancelAutoHide()
        guard panel.isVisible, !Defaults[.focusedPinned], !lookup.isRunning else { return }
        hideDeadline = Date().addingTimeInterval(Self.idleHideInterval)
        let timer = Timer(timeInterval: 0.25, repeats: true) { [weak self] timer in
            MainActor.assumeIsolated {
                guard let self else { timer.invalidate(); return }
                guard self.panel.isVisible, !Defaults[.focusedPinned], !self.lookup.isRunning else {
                    self.cancelAutoHide()
                    return
                }
                let isSelecting = self.panel.isKeyWindow && NSEvent.pressedMouseButtons != 0
                if self.panel.inLiveResize || isSelecting || NSMouseInRect(NSEvent.mouseLocation, self.panel.frame, false) {
                    self.hideDeadline = Date().addingTimeInterval(Self.idleHideInterval)
                } else if Date() >= self.hideDeadline {
                    self.close()
                }
            }
        }
        idleHideTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func cancelAutoHide() {
        idleHideTimer?.invalidate()
        idleHideTimer = nil
    }

    private func updateCollectionBehavior() {
        panel.collectionBehavior = Defaults[.focusedAllSpaces] ? [.canJoinAllSpaces, .fullScreenAuxiliary] : [.fullScreenAuxiliary]
    }

    private func updateSizeLimits(for visible: NSRect) {
        panel.minSize = NSSize(width: min(320, visible.width), height: min(200, visible.height))
        panel.maxSize = visible.size
    }

    private func restoredSize(in visible: NSRect) -> NSSize {
        let width = Defaults[.focusedPanelWidth]
        let height = Defaults[.focusedPanelHeight]
        // Keep the saved size intact when moving to a smaller screen; only constrain the displayed frame.
        return NSSize(
            width: min(visible.width, max(320, width.isFinite ? CGFloat(width) : 440)),
            height: min(visible.height, max(200, height.isFinite ? CGFloat(height) : 320))
        )
    }
}
