// Copyright © 2026 Easydict contributors. GPL-3.0.

import AppKit
import Defaults

/// Owns one passive mouse monitor; no keyboard tap, clipboard observer, or polling timer.
@MainActor
final class MouseSelectionMonitor {
    var onSelection: ((LookupInput) -> Void)?
    var onDismiss: (() -> Void)?

    private var monitor: Any?
    private var activationObserver: NSObjectProtocol?
    private var readTask: Task<Void, Never>?
    private var generation = UUID()

    func start() {
        guard monitor == nil else { return }
        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .leftMouseUp, .rightMouseDown]) { [weak self] event in
            MainActor.assumeIsolated {
                if event.type == .leftMouseUp { self?.readSelection() }
                else { self?.invalidateSelection() }
            }
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
        if let activationObserver { NSWorkspace.shared.notificationCenter.removeObserver(activationObserver) }
        activationObserver = nil
    }

    private func invalidateSelection() {
        generation = UUID()
        readTask?.cancel()
        readTask = nil
        onDismiss?()
    }

    private func readSelection() {
        invalidateSelection()
        guard Defaults[.focusedSelectionEnabled], AXIsProcessTrusted(),
              let app = NSWorkspace.shared.frontmostApplication,
              app.processIdentifier != ProcessInfo.processInfo.processIdentifier
        else { return }
        let processID = app.processIdentifier
        let anchor = NSEvent.mouseLocation
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
