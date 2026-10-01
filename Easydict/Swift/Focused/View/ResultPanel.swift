// Copyright © 2026 Easydict contributors. GPL-3.0.

import AppKit
import Combine
import Defaults
import SwiftUI

/// Becomes key only after an intentional click; merely appearing never steals focus.
final class ResultPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class ResultPanelController: NSObject, NSWindowDelegate {
    let panel: ResultPanel
    private let lookup: LookupController
    private var lastPosition: CGPoint?
    private var hasShown = false
    private var isClipboardPanel = false
    private var contentSubscription: AnyCancellable?

    init(lookup: LookupController) {
        self.lookup = lookup
        panel = ResultPanel(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 440),
            styleMask: [.borderless, .nonactivatingPanel, .resizable], backing: .buffered, defer: false
        )
        super.init()
        panel.delegate = self
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.minSize = NSSize(width: 360, height: 260)
        panel.isReleasedWhenClosed = false
        let glass = NSGlassEffectView()
        glass.cornerRadius = 18
        glass.style = .clear
        // Tint only the material, keeping the text opaque over a gently darkened backdrop.
        glass.tintColor = NSColor.black.withAlphaComponent(0.12)
        glass.contentView = NSHostingView(rootView: ResultContentView(lookup: lookup, onClose: { [weak self] in self?.close() }))
        panel.contentView = glass
        contentSubscription = lookup.$result.combineLatest(lookup.$errorMessage)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _ in self?.resizeForContent() }
    }

    func show(near anchor: CGPoint, clipboard: Bool) {
        isClipboardPanel = clipboard
        if Defaults[.focusedPinned], hasShown {
            // Reuse the frame, including user drags/resizes, across selections, retries, and reopenings.
            updateCollectionBehavior()
            panel.orderFrontRegardless()
            return
        }
        let screen = NSScreen.screens.first { $0.frame.contains(anchor) } ?? NSScreen.main
        guard let visible = screen?.visibleFrame else { return }
        updateCollectionBehavior()
        let height: CGFloat = 260
        panel.maxSize = NSSize(width: visible.width, height: max(260, visible.height * Defaults[.focusedMaximumHeight]))
        let size = NSSize(width: min(440, visible.width), height: height)
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
    }

    func close() {
        lookup.stop()
        panel.orderOut(nil)
    }

    func dismissOnExternalClick() {
        if !isClipboardPanel && !Defaults[.focusedPinned] && panel.isVisible { close() }
    }

    func windowDidMove(_ notification: Notification) { lastPosition = panel.frame.origin }
    func windowWillClose(_ notification: Notification) { lookup.stop() }

    private func updateCollectionBehavior() {
        panel.collectionBehavior = Defaults[.focusedAllSpaces] ? [.canJoinAllSpaces, .fullScreenAuxiliary] : [.fullScreenAuxiliary]
    }

    private func resizeForContent() {
        // A pinned frame stays fixed while streamed content changes; overflow remains scrollable.
        guard !Defaults[.focusedPinned], panel.isVisible, let screen = panel.screen else { return }
        let text = lookup.result + "\n" + (lookup.errorMessage ?? "")
        // Only sizing is capped; the full answer remains selectable in the scroll view.
        let measured = (String(text.prefix(6000)) as NSString).boundingRect(
            with: NSSize(width: max(300, panel.frame.width - 36), height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: NSFont.systemFont(ofSize: 15)]
        ).height
        let visible = screen.visibleFrame
        let maximum = max(260, visible.height * Defaults[.focusedMaximumHeight])
        let height = min(maximum, max(260, ceil(measured) + 200))
        var frame = panel.frame
        frame.origin.y = max(visible.minY, frame.maxY - height)
        frame.size.height = height
        panel.setFrame(frame, display: true)
    }
}
