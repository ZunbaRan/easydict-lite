// Copyright © 2026 Easydict contributors. GPL-3.0.

import AppKit
import Combine
import Defaults
import SFSafeSymbols

@main
enum FocusedApplication {
    @MainActor
    static func main() {
        let application = NSApplication.shared
        let delegate = FocusedAppDelegate()
        application.setActivationPolicy(.accessory)
        application.delegate = delegate
        withExtendedLifetime(delegate) { application.run() }
    }
}

@MainActor
final class FocusedAppDelegate: NSObject, NSApplicationDelegate {
    private let lookup = LookupController()
    private let selection = MouseSelectionMonitor()
    private let icon = SelectionIconController()
    private lazy var results = ResultPanelController(lookup: lookup)
    private lazy var settings = FocusedSettingsController()
    private var statusItem: NSStatusItem?
    private var preferences: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildEditingMenu()
        buildMenu()
        lookup.onShow = { [weak self] anchor, clipboard in
            self?.icon.hide()
            self?.results.show(near: anchor, clipboard: clipboard)
        }
        selection.onSelection = { [weak self] input in self?.icon.show(input) }
        selection.onDismiss = { [weak self] in
            self?.icon.hide()
            self?.results.dismissOnExternalClick()
        }
        icon.onLookup = { [weak self] input in
            let mode = Defaults[.focusedSelectionMode]
            // Long selections default to translation rather than receiving a word-lookup prompt.
            let effectiveMode: LookupMode = mode == .dictionary && (input.text.count > 80 || input.text.split(whereSeparator: \.isWhitespace).count > 8) ? .translation : mode
            self?.lookup.start(input, mode: effectiveMode)
        }
        preferences = Defaults.publisher(.focusedSelectionEnabled).receive(on: DispatchQueue.main).sink { [weak self] change in
            if change.newValue { self?.selection.start() } else { self?.selection.stop() }
        }
        if Defaults[.focusedSelectionEnabled] { selection.start() }
        if Defaults[.focusedChannel] == .compatible && Defaults[.focusedModel].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            settings.show()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        selection.stop()
        lookup.stop()
        preferences?.cancel()
        icon.hide()
        if let statusItem { NSStatusBar.system.removeStatusItem(statusItem) }
    }

    private func buildMenu() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbol: .characterBookClosed, accessibilityDescription: AppStrings.text("focused.app.name"))
        item.button?.toolTip = AppStrings.text("focused.app.name")
        let menu = NSMenu()
        let title = NSMenuItem(title: AppStrings.text("focused.app.name"), action: nil, keyEquivalent: "")
        menu.addItem(title)
        menu.addItem(.separator())
        addItem("focused.menu.clipboard", action: #selector(translateClipboard), to: menu)
        addItem("focused.menu.settings", action: #selector(showSettings), to: menu)
        menu.addItem(.separator())
        addItem("focused.menu.quit", action: #selector(quit), to: menu)
        item.menu = menu
        statusItem = item
    }

    private func buildEditingMenu() {
        // Native text-field editing remains available without global hotkeys or shortcut settings.
        let menu = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu(title: AppStrings.text("focused.app.name"))
        appMenu.addItem(NSMenuItem(title: AppStrings.text("focused.menu.quit"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: ""))
        appItem.submenu = appMenu
        menu.addItem(appItem)
        let edit = NSMenu(title: AppStrings.text("focused.menu.edit"))
        let item = NSMenuItem(title: edit.title, action: nil, keyEquivalent: "")
        item.submenu = edit
        menu.addItem(item)
        for (key, action, equivalent) in [
            ("focused.edit.cut", #selector(NSText.cut(_:)), "x"),
            ("focused.edit.copy", #selector(NSText.copy(_:)), "c"),
            ("focused.edit.paste", #selector(NSText.paste(_:)), "v"),
            ("focused.edit.select_all", #selector(NSText.selectAll(_:)), "a"),
        ] {
            edit.addItem(NSMenuItem(title: AppStrings.text(key), action: action, keyEquivalent: equivalent))
        }
        NSApplication.shared.mainMenu = menu
    }

    private func addItem(_ key: String, action: Selector, to menu: NSMenu) {
        let item = NSMenuItem(title: AppStrings.text(key), action: action, keyEquivalent: "")
        item.target = self
        menu.addItem(item)
    }

    @objc private func translateClipboard() { lookup.translateClipboard() }
    @objc private func showSettings() { icon.hide(); settings.show() }
    @objc private func quit() { NSApplication.shared.terminate(nil) }
}
