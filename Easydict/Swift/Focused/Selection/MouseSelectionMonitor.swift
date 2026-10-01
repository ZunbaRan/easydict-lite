// Copyright © 2026 Easydict contributors. GPL-3.0.

import AppKit
import Defaults

/// Owns passive mouse monitors; no keyboard tap, clipboard observer, or polling timer.
@MainActor
final class MouseSelectionMonitor {
    var onSelection: ((LookupInput) -> Void)?
    var onDismiss: (() -> Void)?
    var onExternalClick: ((CGPoint) -> Void)?

    private var monitor: Any?
    private var localMonitor: Any?
    private var ignoreMouseUp = false
    private var activationObserver: NSObjectProtocol?
    private var readTask: Task<Void, Never>?
    private var generation = UUID()

    func start() {
        guard monitor == nil, localMonitor == nil else { return }
        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .leftMouseUp, .rightMouseDown]) { [weak self] event in
            MainActor.assumeIsolated {
                guard let self else { return }
                if event.type == .leftMouseUp && self.ignoreMouseUp {
                    self.ignoreMouseUp = false
                    self.cancelPendingRead()
                    return
                }
                if event.type != .leftMouseUp { self.ignoreMouseUp = false }
                let location = self.screenLocation(of: event)
                // Nonactivating panels can leave another app frontmost. Never read behind our UI.
                let windowNumber = NSWindow.windowNumber(at: location, belowWindowWithWindowNumber: 0)
                if NSApp.windows.contains(where: { $0.isVisible && $0.windowNumber == windowNumber }) {
                    self.ignoreMouseUp = event.type != .leftMouseUp
                    self.cancelPendingRead()
                    return
                }
                if event.type == .leftMouseUp { self.readSelection(anchor: location) }
                else {
                    self.invalidateSelection()
                    self.onExternalClick?(location)
                }
            }
        }
        // Pair our mouse-down with any later global mouse-up, including a native window drag.
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            MainActor.assumeIsolated {
                self?.ignoreMouseUp = true
                self?.cancelPendingRead()
            }
            return event
        }
        activationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                // Clicking selectable result text may activate our own app; keep that panel alive.
                guard NSWorkspace.shared.frontmostApplication?.processIdentifier != ProcessInfo.processInfo.processIdentifier else { return }
                self?.invalidateSelection()
            }
        }
    }

    func stop() {
        invalidateSelection()
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        localMonitor = nil
        ignoreMouseUp = false
        if let activationObserver { NSWorkspace.shared.notificationCenter.removeObserver(activationObserver) }
        activationObserver = nil
    }

    private func invalidateSelection() {
        cancelPendingRead()
        onDismiss?()
    }

    private func cancelPendingRead() {
        generation = UUID()
        readTask?.cancel()
        readTask = nil
    }

    private func screenLocation(of event: NSEvent) -> CGPoint {
        guard let location = event.cgEvent?.location else { return NSEvent.mouseLocation }
        // Quartz starts at the primary display's top-left; AppKit uses its bottom-left.
        return CGPoint(x: location.x, y: CGDisplayBounds(CGMainDisplayID()).height - location.y)
    }

    private func readSelection(anchor: CGPoint) {
        invalidateSelection()
        guard Defaults[.focusedSelectionEnabled], AXIsProcessTrusted(),
              let app = NSWorkspace.shared.frontmostApplication,
              app.processIdentifier != ProcessInfo.processInfo.processIdentifier
        else { return }
        let processID = app.processIdentifier
        let identifier = generation
        readTask = Task { [weak self] in
            do { try await Task.sleep(for: .milliseconds(140)) } catch { return }
            let text = await Task.detached(priority: .userInitiated) { AXTextReader.selectedText(processID: processID) }.value
            guard let self, !Task.isCancelled, self.generation == identifier,
                  NSWorkspace.shared.frontmostApplication?.processIdentifier == processID,
                  Defaults[.focusedSelectionEnabled], let text,
                  !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  text.count >= max(1, Defaults[.focusedMinimumLength])
            else { return }
            let excluded = Language(rawValue: Defaults[.focusedExcludedLanguage]) ?? .auto
            if excluded != .auto && Language.detect(text) == excluded { return }
            self.onSelection?(.init(text: text, anchor: anchor, isClipboard: false))
            self.readTask = nil
        }
    }
}
