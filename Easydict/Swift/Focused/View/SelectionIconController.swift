// Copyright © 2026 Easydict contributors. GPL-3.0.

import AppKit
import SFSafeSymbols

private final class SelectionIconPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

/// The icon carries the captured selection; clicking it never rereads the focused app or clipboard.
@MainActor
final class SelectionIconController: NSObject {
    var onLookup: ((LookupInput) -> Void)?
    private var input: LookupInput?
    private let panel = SelectionIconPanel(
        contentRect: NSRect(x: 0, y: 0, width: 34, height: 34),
        styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false
    )

    override init() {
        super.init()
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        let button = NSButton(image: NSImage(systemSymbol: .textMagnifyingglass, accessibilityDescription: AppStrings.text("focused.action.lookup")), target: self, action: #selector(lookupSelection))
        button.bezelStyle = .regularSquare
        button.isBordered = false
        button.contentTintColor = .labelColor
        button.toolTip = AppStrings.text("focused.action.lookup")
        button.setAccessibilityLabel(AppStrings.text("focused.action.lookup"))
        let glass = NSGlassEffectView()
        glass.cornerRadius = 10
        glass.contentView = button
        panel.contentView = glass
    }

    func show(_ input: LookupInput) {
        self.input = input
        let visible = (NSScreen.screens.first { $0.frame.contains(input.anchor) } ?? NSScreen.main)?.visibleFrame ?? .zero
        let origin = CGPoint(
            x: min(max(input.anchor.x + 8, visible.minX), visible.maxX - 34),
            y: min(max(input.anchor.y - 42, visible.minY), visible.maxY - 34)
        )
        panel.setFrameOrigin(origin)
        panel.orderFrontRegardless()
    }

    func hide() { input = nil; panel.orderOut(nil) }

    @objc private func lookupSelection() {
        guard let input else { return }
        hide()
        onLookup?(input)
    }
}
