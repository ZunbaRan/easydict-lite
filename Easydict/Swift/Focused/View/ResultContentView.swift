// Copyright © 2026 Easydict contributors. GPL-3.0.

import Combine
import Defaults
import SFSafeSymbols
import SwiftUI

struct ResultContentView: View {
    @ObservedObject var lookup: LookupController
    @ObservedObject var backdrop: BackdropAppearanceController
    let onClose: () -> Void
    @State private var pinned = Defaults[.focusedPinned]
    @State private var showSource = false
    @State private var copied = false
    @State private var copyFeedbackReset: Task<Void, Never>?

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 8) {
                header
                HStack {
                    Menu {
                        ForEach(LookupMode.allCases, id: \.self) { mode in
                            Button(mode.title) { lookup.retry(mode: mode) }
                        }
                    } label: { Label(lookup.mode.title, systemSymbol: .chevronDown) }
                    Spacer()
                    if lookup.isRunning { ProgressView().controlSize(.mini) }
                    Text(lookup.status).font(.caption).foregroundStyle(.secondary)
                }
                .font(.callout)
                DisclosureGroup(isExpanded: $showSource) {
                    ScrollView {
                        Text(lookup.source).font(.callout).textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    // Leave room for the result even in a short, manually resized panel.
                    .frame(maxHeight: min(110, geometry.size.height * 0.25))
                } label: { Text(AppStrings.text("focused.result.source")).font(.caption).foregroundStyle(.secondary) }
                Divider()
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        if !lookup.result.isEmpty {
                            // Native selectable text avoids WebKit, dictionary CSS, and HTML resource lifecycles.
                            Text(lookup.result).textSelection(.enabled)
                                .font(.system(size: 13)).fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        if let error = lookup.errorMessage {
                            Text(error).font(.callout).foregroundStyle(.red).textSelection(.enabled)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.primary)
        .environment(\.colorScheme, backdrop.isDark ? .dark : .light)
        .onAppear { pinned = Defaults[.focusedPinned] }
        .onReceive(Defaults.publisher(.focusedPinned).receive(on: DispatchQueue.main)) { _ in
            // Settings can change the same preference; queued notifications must not restore an older value.
            pinned = Defaults[.focusedPinned]
        }
        .onChange(of: lookup.source) { _, _ in showSource = false }
        .onChange(of: lookup.result) { _, result in
            if result.isEmpty { resetCopyFeedback() }
        }
        .onDisappear { resetCopyFeedback() }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemSymbol: .characterBookClosed).font(.system(size: 12))
            Text(AppStrings.text("focused.app.name")).font(.system(size: 12, weight: .semibold)).lineLimit(1)
            Spacer(minLength: 8)
            HStack(spacing: 4) {
                copyButton
                if lookup.isRunning {
                    toolbarButton(AppStrings.text("focused.action.stop"), symbol: .stopCircle) { lookup.stop() }
                } else {
                    toolbarButton(AppStrings.text("focused.action.retry"), symbol: .arrowClockwise, disabled: lookup.source.isEmpty) {
                        lookup.retry()
                    }
                }
                Button {
                    // Render the click immediately instead of waiting for asynchronous preference observation.
                    let nextPinned = !Defaults[.focusedPinned]
                    pinned = nextPinned
                    Defaults[.focusedPinned] = nextPinned
                } label: {
                    Image(systemSymbol: pinned ? .pinFill : .pin)
                        .frame(width: 24, height: 24).contentShape(Rectangle())
                }
                .foregroundStyle(pinned ? Color.white : Color.secondary)
                .background {
                    RoundedRectangle(cornerRadius: 6).fill(pinned ? Color.accentColor : Color.clear)
                }
                .animation(.easeInOut(duration: 0.12), value: pinned)
                .help(AppStrings.text(pinned ? "focused.window.unpin_action" : "focused.window.pin_action"))
                .accessibilityLabel(AppStrings.text(pinned ? "focused.window.unpin_action" : "focused.window.pin_action"))
                .accessibilityAddTraits(pinned ? .isSelected : [])
                toolbarButton(AppStrings.text("focused.action.close"), symbol: .xmark, action: onClose)
            }.font(.system(size: 13))
        }
        .frame(height: 24)
    }

    private var copyButton: some View {
        Button(action: copyResult) {
            Image(systemSymbol: copied ? .checkmark : .docOnDoc)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 24, height: 24).contentShape(Rectangle())
        }
        .foregroundStyle(copied ? Color.white : Color.primary)
        .background {
            RoundedRectangle(cornerRadius: 6).fill(copied ? Color.blue : Color.clear)
        }
        .animation(.easeInOut(duration: 0.15), value: copied)
        .disabled(lookup.result.isEmpty)
        .help(AppStrings.text("focused.action.copy"))
        .accessibilityLabel(AppStrings.text("focused.action.copy"))
        .accessibilityValue(copied ? AppStrings.text("focused.action.copied") : "")
    }

    private func copyResult() {
        guard lookup.copyResult() else {
            resetCopyFeedback()
            return
        }
        copyFeedbackReset?.cancel()
        copied = true
        // Restart the one-second confirmation on each successful copy; an older task cannot clear it.
        copyFeedbackReset = Task { @MainActor in
            do { try await Task.sleep(for: .seconds(1)) } catch { return }
            guard !Task.isCancelled else { return }
            copied = false
            copyFeedbackReset = nil
        }
    }

    private func resetCopyFeedback() {
        copyFeedbackReset?.cancel()
        copyFeedbackReset = nil
        copied = false
    }

    private func toolbarButton(_ title: String, symbol: SFSymbol, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemSymbol: symbol).frame(width: 24, height: 24).contentShape(Rectangle())
        }
        .disabled(disabled)
        .help(title)
        .accessibilityLabel(title)
    }
}
