# Easydict Lite

A focused local fork of [Easydict](https://github.com/tisfeng/Easydict) for **mouse selection and explicit clipboard translation** using an OpenAI-compatible LLM API or DeepSeek.

[中文](README_ZH.md) · [Usage and build guide](docs/user-docs/en/GUIDE.md)

## Features

- Select plain text in another application, then click the lookup icon.
- Translate long clipboard passages from the menu bar. The clipboard is read once and preserved during translation. **Copy result** is an explicit action.
- One selectable, scrollable Liquid Glass result panel on macOS 26+. Clipboard results stay open until closed.
- OpenAI-compatible Chat Completions and a DeepSeek preset, with separate Keychain credentials.
- Retained translation, word explanation, sentence analysis, and custom prompts.
- Cancellation, stale-response isolation, streaming UTF-8 buffering, and explicit incomplete-output errors.

OCR, screenshots, speech, local dictionaries, other service integrations, global shortcut settings, simulated Copy, text replacement, browser scripts, telemetry, and the upstream updater have been removed. Only three runtime Swift package dependencies remain: Alamofire, Defaults, and SFSafeSymbols.

## Build and run

Requires macOS 26+ and Swift 6.2+ with a macOS 26 or newer SDK. Xcode is optional for local SwiftPM builds.

```bash
scripts/focused/package-app.sh release
open "dist/Easydict Lite.app"
scripts/focused/run-tests.sh
```

The packaging script selects an installed macOS 26 SDK on Command Line Tools to avoid missing SwiftUI macro plugins in the macOS 27 CLT SDK. It records the actual SDK version for Liquid Glass and applies a stable local ad-hoc signature. It does not install over Easydict. The fork uses bundle ID `org.easydict.focused` and separate preferences and Keychain entries.

In Settings, choose a channel, enter a model, and save its API key. **Test connection** sends a short fixed sample. Mouse selection requires Accessibility permission; Clipboard Translation does not. No screen-recording permission is required.

## Limits and verification

Selection uses only text exposed by Accessibility. Some applications, PDF viewers, and browser pages do not expose their selection; use explicit Clipboard Translation for those cases. Word explanations come from the LLM, not a verified dictionary database.

Input is sent in full up to an explicit 2 MiB limit. Model context limits vary; API errors are displayed rather than silently truncating input. Responses are bounded at 8 MiB. Output-limit and interrupted-stream errors preserve partial answers. Stop cancels the local request; provider-side billing or generation may continue.

The retained eight task-control and throttling tests pass. New selection, clipboard, transport, and UI workflows do not yet have dedicated regression suites. Full Xcode builds, real provider calls, Accessibility selection, floating-panel focus/visual checks, sleep/wake, and extended-use checks remain to be verified in the target environment; see the [task history](docs/histories/2026-09/2026-09-30-streamlined-llm-fork.md) for actual evidence.

## Development

Open `Easydict.xcworkspace` and select the `Easydict` scheme in Xcode 26+. The Xcode project and SwiftPM package use the same compact Swift source set. After changing the source-file inventory, regenerate the Xcode references:

```bash
python3 scripts/focused/generate-project.py
```

Read [AGENTS.md](AGENTS.md) and [CONTRIBUTING.md](CONTRIBUTING.md). Earlier histories and specialist documentation describe the upstream application and are not current fork features unless explicitly adopted.

## License and attribution

GPL-3.0; retain [LICENSE](LICENSE). Based on Easydict by tisfeng and contributors, originally inspired by Bob and Saladict. Translation prompt examples and the request task-control/throttling implementations retain their original attribution. The floating panel takes visual inspiration from EchoType and uses public AppKit APIs; EchoType's private appearance overrides and screen sampling are not included.
