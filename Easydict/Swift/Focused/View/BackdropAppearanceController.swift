// Copyright © 2026 Easydict contributors. GPL-3.0.

import AppKit
import Combine
import Defaults
import ScreenCaptureKit

/// Chooses a panel appearance from local backdrop brightness, without retaining or exporting images.
@MainActor
final class BackdropAppearanceController: ObservableObject {
    @Published private(set) var isDark: Bool

    private weak var panel: NSPanel?
    private var timer: Timer?
    private var captureTask: Task<Void, Never>?
    private var preferences: AnyCancellable?
    private var generation = 0
    private var adaptiveDark: Bool?
    private var shareableContent: SCShareableContent?
    private var contentRefreshTime = ContinuousClock.now

    init(panel: NSPanel) {
        self.panel = panel
        isDark = panel.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        preferences = Defaults.publisher(.focusedTextContrast).receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                generation += 1
                adaptiveDark = nil
                captureTask?.cancel()
                refresh()
            }
    }

    func start() {
        if timer == nil {
            let timer = Timer(timeInterval: 1.5, repeats: true) { [weak self] _ in
                Task { @MainActor in self?.refresh() }
            }
            self.timer = timer
            RunLoop.main.add(timer, forMode: .common)
        }
        refresh()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        generation += 1
        captureTask?.cancel()
        // Keep the task slot until the underlying screenshot finishes; rapid reopening cannot overlap captures.
        shareableContent = nil
    }

    func frameDidChange() { generation += 1 }

    private func refresh() {
        guard timer != nil, let panel, panel.isVisible else { return }
        switch Defaults[.focusedTextContrast] {
        case .darkText: apply(dark: false)
        case .lightText: apply(dark: true)
        case .automatic:
            // Preflight never prompts. Only the explicit Settings button requests this optional permission.
            guard CGPreflightScreenCaptureAccess() else {
                adaptiveDark = nil
                apply(dark: systemIsDark)
                return
            }
            guard captureTask == nil else { return }
            let frame = panel.frame
            let requestedGeneration = generation
            captureTask = Task { [weak self] in
                guard let self else { return }
                defer { captureTask = nil }
                do {
                    guard let luminance = try await captureLuminance(under: frame) else { return }
                    try Task.checkCancellation()
                    guard timer != nil, generation == requestedGeneration,
                          panel.isVisible, panel.frame == frame,
                          Defaults[.focusedTextContrast] == .automatic,
                          CGPreflightScreenCaptureAccess() else { return }
                    // Hysteresis prevents repeated light/dark flips on a mixed or slightly changing background.
                    let dark = adaptiveDark.map { $0 ? luminance < 0.6 : luminance < 0.4 } ?? (luminance < 0.5)
                    adaptiveDark = dark
                    apply(dark: dark)
                } catch {
                    // A failed capture leaves the last successful appearance in place.
                    if !Task.isCancelled, generation == requestedGeneration, adaptiveDark == nil {
                        apply(dark: systemIsDark)
                    }
                }
            }
        }
    }

    private var systemIsDark: Bool {
        NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
    }

    private func apply(dark: Bool) {
        let name: NSAppearance.Name = dark ? .darkAqua : .aqua
        if panel?.appearance?.name != name { panel?.appearance = NSAppearance(named: name) }
        if isDark != dark { isDark = dark }
    }

    private func captureLuminance(under frame: NSRect) async throws -> CGFloat? {
        let now = ContinuousClock.now
        let content: SCShareableContent
        if let cached = shareableContent, contentRefreshTime.duration(to: now) < .seconds(5) {
            content = cached
        } else {
            content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            try Task.checkCancellation()
            shareableContent = content
            contentRefreshTime = now
        }
        // Cocoa uses a bottom-left origin; ScreenCaptureKit uses the primary display's top-left origin.
        let primaryHeight = CGDisplayBounds(CGMainDisplayID()).height
        let interior = frame.insetBy(dx: 18, dy: 18)
        let screenRect = CGRect(x: interior.minX, y: primaryHeight - interior.maxY,
                                width: interior.width, height: interior.height)
        guard let display = content.displays.max(by: {
            intersectionArea($0.frame, screenRect) < intersectionArea($1.frame, screenRect)
        }) else { return nil }
        let crop = screenRect.intersection(display.frame)
        guard !crop.isNull, crop.width > 0, crop.height > 0 else { return nil }
        let ownApps = content.applications.filter { $0.processID == ProcessInfo.processInfo.processIdentifier }
        // Fail closed if our process is absent: sampling our own glass would create a feedback loop.
        guard !ownApps.isEmpty else { return nil }
        let filter = SCContentFilter(display: display, excludingApplications: ownApps, exceptingWindows: [])
        let configuration = SCStreamConfiguration()
        configuration.sourceRect = crop.offsetBy(dx: -display.frame.minX, dy: -display.frame.minY)
        let scale = 64 / max(crop.width, crop.height)
        configuration.width = max(1, Int((crop.width * scale).rounded()))
        configuration.height = max(1, Int((crop.height * scale).rounded()))
        configuration.showsCursor = false
        configuration.capturesAudio = false
        configuration.colorSpaceName = CGColorSpace.sRGB
        let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration)
        try Task.checkCancellation()
        return averageLuminance(of: image)
    }

    private func intersectionArea(_ display: CGRect, _ panel: CGRect) -> CGFloat {
        let intersection = display.intersection(panel)
        return intersection.isNull ? 0 : intersection.width * intersection.height
    }

    private func averageLuminance(of image: CGImage) -> CGFloat? {
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(data: nil, width: 16, height: 16, bitsPerComponent: 8,
                                      bytesPerRow: 64, space: space,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
        else { return nil }
        context.draw(image, in: CGRect(x: 0, y: 0, width: 16, height: 16))
        guard let bytes = context.data?.assumingMemoryBound(to: UInt8.self) else { return nil }
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        for offset in stride(from: 0, to: 1024, by: 4) {
            brightness += 0.299 * CGFloat(bytes[offset]) + 0.587 * CGFloat(bytes[offset + 1]) + 0.114 * CGFloat(bytes[offset + 2])
            alpha += CGFloat(bytes[offset + 3])
        }
        return alpha > 0 ? brightness / alpha : nil
    }
}
