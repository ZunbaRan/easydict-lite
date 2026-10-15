// Copyright © 2026 Easydict contributors. GPL-3.0.

import AppKit
import Carbon.HIToolbox

/// Observes external Copy keystrokes without intercepting them or polling an idle clipboard.
@MainActor
final class CopyActionMonitor {
    var onCopy: ((LookupInput) -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var activationObserver: NSObjectProtocol?
    private var readTask: Task<Void, Never>?
    private var generation = UUID()

    func start() {
        if activationObserver == nil {
            activationObserver = NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.cancelPendingRead()
                    self?.installEventTap()
                }
            }
        }
        installEventTap()
    }

    func stop() {
        cancelPendingRead()
        if let eventTap { CFMachPortInvalidate(eventTap) }
        if let runLoopSource { CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes) }
        eventTap = nil
        runLoopSource = nil
        if let activationObserver { NSWorkspace.shared.notificationCenter.removeObserver(activationObserver) }
        activationObserver = nil
    }

    /// Explicit queries and later user actions take precedence over a delayed Copy read.
    func cancelPendingRead() {
        generation = UUID()
        readTask?.cancel()
        readTask = nil
    }

    private func installEventTap() {
        guard eventTap == nil, AXIsProcessTrusted() else { return }
        let mask = [CGEventType.keyDown, .leftMouseDown, .rightMouseDown].reduce(CGEventMask(0)) {
            $0 | CGEventMask(1 << $1.rawValue)
        }
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap, place: .headInsertEventTap, options: .listenOnly,
            eventsOfInterest: mask,
            callback: { _, type, event, context in
                guard let context else { return Unmanaged.passUnretained(event) }
                MainActor.assumeIsolated {
                    let monitor = Unmanaged<CopyActionMonitor>.fromOpaque(context).takeUnretainedValue()
                    monitor.handle(type, event: event)
                }
                return Unmanaged.passUnretained(event)
            }, userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return }
        eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    private func handle(_ type: CGEventType, event: CGEvent) {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            cancelPendingRead()
            if let eventTap { CGEvent.tapEnable(tap: eventTap, enable: true) }
            return
        }
        let modifiers = event.flags.intersection([.maskCommand, .maskControl, .maskAlternate, .maskShift])
        guard type == .keyDown,
              event.getIntegerValueField(.keyboardEventKeycode) == Int64(kVK_ANSI_C),
              event.getIntegerValueField(.keyboardEventAutorepeat) == 0,
              modifiers == .maskCommand,
              // A nonactivating result panel can own the keyboard while another app stays frontmost.
              NSApp.keyWindow == nil,
              let app = NSWorkspace.shared.frontmostApplication,
              app.processIdentifier != ProcessInfo.processInfo.processIdentifier
        else {
            cancelPendingRead()
            return
        }
        captureCopy(from: app.processIdentifier)
    }

    private func captureCopy(from processID: pid_t) {
        cancelPendingRead()
        // Capture the counter in the session event tap, before the source app handles the key.
        let initialCount = NSPasteboard.general.changeCount
        let identifier = generation
        let anchor = NSEvent.mouseLocation
        readTask = Task { [weak self] in
            // Source applications may write asynchronously; wait at most one second per Copy.
            for _ in 0 ..< 10 {
                do { try await Task.sleep(for: .milliseconds(100)) } catch { return }
                guard let self, !Task.isCancelled, self.generation == identifier,
                      NSWorkspace.shared.frontmostApplication?.processIdentifier == processID else { return }
                let pasteboard = NSPasteboard.general
                guard pasteboard.changeCount != initialCount else { continue }
                self.readTask = nil
                guard let text = pasteboard.string(forType: .string),
                      !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                self.onCopy?(.init(text: text, anchor: anchor, isClipboard: true))
                return
            }
            if self?.generation == identifier { self?.readTask = nil }
        }
    }
}
