// Copyright © 2026 Easydict contributors. GPL-3.0.

import AppKit
import Carbon.HIToolbox

/// Captures external Copy actions, forwards every key unchanged, and never polls an idle clipboard.
@MainActor
final class CopyActionMonitor {
    var onCopy: ((LookupInput) -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var activationObserver: NSObjectProtocol?
    private var localKeyboardMonitor: Any?
    private var readTask: Task<Void, Never>?
    private var generation = UUID()

    func start() {
        if localKeyboardMonitor == nil {
            // A nonactivating panel can receive keys while another app remains frontmost.
            // Cancel only events actually delivered here, not all events while we retain a key-window reference.
            localKeyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                MainActor.assumeIsolated {
                    self?.cancelPendingRead()
                }
                return event
            }
        }
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
        if let localKeyboardMonitor { NSEvent.removeMonitor(localKeyboardMonitor) }
        localKeyboardMonitor = nil
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
        // Capture the baseline before forwarding the key. Passive taps may arrive after the app has copied.
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
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
