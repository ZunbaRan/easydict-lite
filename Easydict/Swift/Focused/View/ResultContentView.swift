// Copyright © 2026 Easydict contributors. GPL-3.0.

import Defaults
import SFSafeSymbols
import SwiftUI

struct ResultContentView: View {
    @ObservedObject var lookup: LookupController
    @ObservedObject var backdrop: BackdropAppearanceController
    let onClose: () -> Void
    @Default(.focusedPinned) private var pinned
    @State private var showSource = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemSymbol: .characterBookClosed)
                Text(AppStrings.text("focused.app.name")).font(.headline)
                Spacer()
                if lookup.isRunning { ProgressView().controlSize(.small) }
                Button { pinned.toggle() } label: { Image(systemSymbol: pinned ? .pinFill : .pin) }
                    .help(AppStrings.text("focused.window.pin"))
                    .accessibilityLabel(AppStrings.text("focused.window.pin"))
                Button(action: onClose) { Image(systemSymbol: .xmark) }
                    .help(AppStrings.text("focused.action.close"))
                    .accessibilityLabel(AppStrings.text("focused.action.close"))
            }
            HStack {
                Menu {
                    ForEach(LookupMode.allCases, id: \.self) { mode in
                        Button(mode.title) { lookup.retry(mode: mode) }
                    }
                } label: { Label(lookup.mode.title, systemSymbol: .chevronDown) }
                Spacer()
                Text(lookup.status).font(.caption).foregroundStyle(.secondary)
            }
            DisclosureGroup(isExpanded: $showSource) {
                ScrollView {
                    Text(lookup.source).font(.callout).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                }.frame(maxHeight: 110)
            } label: { Text(AppStrings.text("focused.result.source")).font(.caption).foregroundStyle(.secondary) }
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if !lookup.result.isEmpty {
                        // Native selectable text avoids WebKit, dictionary CSS, and HTML resource lifecycles.
                        Text(lookup.result).textSelection(.enabled)
                            .font(.system(size: 15)).fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if let error = lookup.errorMessage {
                        Text(error).font(.callout).foregroundStyle(.red).textSelection(.enabled)
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider()
            HStack {
                Button { lookup.copyResult() } label: {
                    Label(AppStrings.text("focused.action.copy"), systemSymbol: .docOnDoc)
                }.disabled(lookup.result.isEmpty)
                Spacer()
                if lookup.isRunning {
                    Button { lookup.stop() } label: { Label(AppStrings.text("focused.action.stop"), systemSymbol: .stopCircle) }
                } else {
                    Button { lookup.retry() } label: { Label(AppStrings.text("focused.action.retry"), systemSymbol: .arrowClockwise) }
                        .disabled(lookup.source.isEmpty)
                }
            }
        }
        .padding(18)
        .buttonStyle(.borderless)
        .foregroundStyle(.primary)
        .environment(\.colorScheme, backdrop.isDark ? .dark : .light)
        .onChange(of: lookup.source) { _, _ in showSource = false }
    }
}
