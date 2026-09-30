// Copyright © 2026 Easydict contributors. GPL-3.0.

import AppKit
import SwiftUI

@MainActor
final class FocusedSettingsController {
    private var window: NSWindow?

    func show() {
        if window == nil {
            let created = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 640, height: 690),
                styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false
            )
            created.title = AppStrings.text("focused.menu.settings")
            created.contentView = NSHostingView(rootView: FocusedSettingsView())
            created.isReleasedWhenClosed = false
            created.center()
            window = created
        }
        NSApplication.shared.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
