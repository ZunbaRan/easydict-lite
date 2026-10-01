// Copyright © 2026 Easydict contributors. GPL-3.0.

import AppKit
import Defaults
import SFSafeSymbols
import SwiftUI

struct PanelContrastSettingsView: View {
    @Default(.focusedTextContrast) private var contrast
    @State private var screenCaptureAllowed = CGPreflightScreenCaptureAccess()

    var body: some View {
        Section(AppStrings.text("focused.window.contrast.title")) {
            Picker(AppStrings.text("focused.window.contrast.mode"), selection: $contrast) {
                ForEach(PanelTextContrast.allCases, id: \.self) { Text($0.title).tag($0) }
            }
            if contrast == .automatic {
                Label(AppStrings.text(screenCaptureAllowed ? "focused.window.contrast.granted" : "focused.window.contrast.required"),
                      systemSymbol: screenCaptureAllowed ? .checkmarkCircle : .exclamationmarkTriangle)
                HStack {
                    if !screenCaptureAllowed {
                        Button(AppStrings.text("focused.window.contrast.enable")) {
                            screenCaptureAllowed = CGRequestScreenCaptureAccess()
                            if !screenCaptureAllowed,
                               let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    }
                    Button(AppStrings.text("focused.permissions.recheck")) {
                        screenCaptureAllowed = CGPreflightScreenCaptureAccess()
                    }
                }
                Text(AppStrings.text("focused.window.contrast.note")).font(.caption).foregroundStyle(.secondary)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            screenCaptureAllowed = CGPreflightScreenCaptureAccess()
        }
    }
}
