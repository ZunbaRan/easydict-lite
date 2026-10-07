// Copyright © 2026 Easydict contributors. GPL-3.0.

import AppKit
import Defaults
import SFSafeSymbols
import SwiftUI

struct FocusedSettingsView: View {
    @Default(.focusedFirstLanguage) private var firstLanguage
    @Default(.focusedSecondLanguage) private var secondLanguage
    @Default(.focusedSelectionEnabled) private var selectionEnabled
    @Default(.focusedExcludedLanguage) private var excludedLanguage
    @Default(.focusedMinimumLength) private var minimumLength
    @Default(.focusedSelectionMode) private var selectionMode
    @Default(.focusedPinned) private var pinned
    @Default(.focusedAllSpaces) private var allSpaces
    @Default(.focusedRememberPosition) private var rememberPosition
    @Default(.focusedCustomPromptEnabled) private var customPromptEnabled
    @Default(.focusedCustomPrompt) private var customPrompt
    @State private var trusted = AXIsProcessTrusted()

    var body: some View {
        TabView {
            Form {
                Section(AppStrings.text("focused.settings.languages")) {
                    languagePicker("focused.language.first", selection: $firstLanguage)
                    languagePicker("focused.language.second", selection: $secondLanguage)
                    Text(AppStrings.text("focused.language.detection_note")).font(.caption).foregroundStyle(.secondary)
                }
                Section(AppStrings.text("focused.settings.selection")) {
                    Toggle(AppStrings.text("focused.selection.enabled"), isOn: $selectionEnabled)
                    languagePicker("focused.selection.excluded", selection: $excludedLanguage, allowAuto: true)
                    Stepper(value: $minimumLength, in: 1 ... 100) {
                        Text(String(format: AppStrings.text("focused.selection.minimum_length"), minimumLength))
                    }
                    Picker(AppStrings.text("focused.selection.mode"), selection: $selectionMode) {
                        ForEach(LookupMode.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    Text(AppStrings.text("focused.selection.click_note")).font(.caption).foregroundStyle(.secondary)
                }
                Section(AppStrings.text("focused.settings.permissions")) {
                    Label(AppStrings.text(trusted ? "focused.permissions.granted" : "focused.permissions.required"), systemSymbol: trusted ? .checkmarkCircle : .exclamationmarkTriangle)
                    HStack {
                        Button(AppStrings.text("focused.permissions.open")) {
                            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
                            trusted = AXIsProcessTrustedWithOptions(options)
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        Button(AppStrings.text("focused.permissions.recheck")) { trusted = AXIsProcessTrusted() }
                    }
                    Text(AppStrings.text("focused.permissions.note")).font(.caption).foregroundStyle(.secondary)
                }
            }.formStyle(.grouped)
                .tabItem { Label(AppStrings.text("focused.settings.general"), systemSymbol: .gearshape) }

            APISettingsView()
                .tabItem { Label(AppStrings.text("focused.settings.api"), systemSymbol: .network) }

            Form {
                Section(AppStrings.text("focused.settings.prompts")) {
                    Text(AppStrings.text("focused.prompts.retained_note")).font(.callout)
                    Toggle(AppStrings.text("focused.prompts.custom"), isOn: $customPromptEnabled)
                    TextEditor(text: $customPrompt).font(.system(.body, design: .monospaced)).frame(minHeight: 230)
                        .disabled(!customPromptEnabled)
                    Text(AppStrings.text("focused.prompts.variables")).font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
                    Text(AppStrings.text("focused.prompts.lookup_note")).font(.caption).foregroundStyle(.secondary)
                }
            }.formStyle(.grouped)
                .tabItem { Label(AppStrings.text("focused.settings.prompts"), systemSymbol: .textBubble) }

            Form {
                Section(AppStrings.text("focused.settings.window")) {
                    Toggle(AppStrings.text("focused.window.pin"), isOn: $pinned)
                    Toggle(AppStrings.text("focused.window.all_spaces"), isOn: $allSpaces)
                    Toggle(AppStrings.text("focused.window.remember_position"), isOn: $rememberPosition)
                    Text(AppStrings.text("focused.window.resize_note")).font(.caption).foregroundStyle(.secondary)
                    Text(AppStrings.text("focused.window.note")).font(.caption).foregroundStyle(.secondary)
                }
                PanelContrastSettingsView()
                Section(AppStrings.text("focused.settings.about")) {
                    Text(AppStrings.text("focused.app.name")).font(.headline)
                    Text(AppStrings.text("focused.about.description"))
                    Text(AppStrings.text("focused.about.license")).font(.caption).foregroundStyle(.secondary)
                }
            }.formStyle(.grouped)
                .tabItem { Label(AppStrings.text("focused.settings.window"), systemSymbol: .macwindow) }
        }.padding(12).frame(width: 640, height: 690)
    }

    private func languagePicker(_ key: String, selection: Binding<String>, allowAuto: Bool = false) -> some View {
        Picker(AppStrings.text(key), selection: selection) {
            ForEach(Language.allCases.filter { allowAuto || $0 != .auto }, id: \.rawValue) { language in
                Text(language.localizedName).tag(language.rawValue)
            }
        }
    }
}
