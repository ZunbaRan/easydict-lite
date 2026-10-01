# easydict-lite

A focused fork of [Easydict](https://github.com/tisfeng/Easydict) for **mouse selection and explicit clipboard translation** using an OpenAI-compatible LLM API or DeepSeek.

[中文](README_ZH.md) · [Usage and build guide](docs/user-docs/en/GUIDE.md)

Download the macOS 26+ Apple Silicon build from [Releases](https://github.com/ZunbaRan/easydict-lite/releases). Extract `easydict-lite.app` and place it in Applications alongside Easydict. The prerelease is ad-hoc signed, not notarized; see [Apple's app-opening guidance](https://support.apple.com/en-us/102445) if macOS blocks the first launch.

## Features

- Select plain text in another application, then click the lookup icon.
- Translate long clipboard passages from the menu bar. The clipboard is read once and preserved during translation. **Copy result** is an explicit action.
- One selectable, scrollable Liquid Glass result panel on macOS 26+. Clipboard results stay open until closed.
- Automatic light/dark text contrast from local backdrop brightness, with optional Screen Recording access and manual text-color choices.
- OpenAI-compatible Chat Completions and a DeepSeek preset, with separate Keychain credentials.
- Retained translation, word explanation, sentence analysis, and custom prompts.
- Cancellation, stale-response isolation, streaming UTF-8 buffering, and explicit incomplete-output errors.

OCR, screenshot translation, speech, local dictionaries, other service integrations, global shortcut settings, simulated Copy, text replacement, browser scripts, telemetry, and the upstream updater have been removed. Only three runtime Swift package dependencies remain: Alamofire, Defaults, and SFSafeSymbols.

## Build and run

Requires macOS 26+ and Swift 6.2+ with a macOS 26 or newer SDK. Xcode is optional for local SwiftPM builds.

```bash
scripts/focused/package-app.sh release
open "dist/easydict-lite.app"
scripts/focused/run-tests.sh
```

The script also creates `dist/easydict-lite.zip`. Move `easydict-lite.app` to Applications to keep it alongside the original Easydict.

The packaging script selects an installed macOS 26 SDK on Command Line Tools to avoid missing SwiftUI macro plugins in the macOS 27 CLT SDK. It records the actual SDK version for Liquid Glass and applies a stable local ad-hoc signature. It does not install over Easydict. The fork uses bundle ID `org.easydict.focused` and separate preferences and Keychain entries.

In Settings, choose a channel, enter a model, and save its API key. **Test connection** sends a short fixed sample. Mouse selection requires Accessibility permission; Clipboard Translation does not. Automatic background text contrast uses optional Screen Recording access, enabled explicitly in Settings → Window. Translation itself does not require this permission. Without access, choose Dark text or Light text; automatic mode follows system appearance until access is granted. Backdrop images are processed locally and never saved or sent to the API.

## Limits and verification

Selection uses only text exposed by Accessibility. Some applications, PDF viewers, and browser pages do not expose their selection; use explicit Clipboard Translation for those cases. Word explanations come from the LLM, not a verified dictionary database.

Input is sent in full up to an explicit 2 MiB limit. Model context limits vary; API errors are displayed rather than silently truncating input. Responses are bounded at 8 MiB. Output-limit and interrupted-stream errors preserve partial answers. Stop cancels the local request; provider-side billing or generation may continue.

The retained eight task-control and throttling tests pass. New selection, clipboard, transport, and UI workflows do not yet have dedicated regression suites. User feedback confirms configured API requests, pinned positioning, adaptive text contrast, and recent panel fixes; this is not exhaustive provider or UI coverage. Full Xcode builds, additional providers, multi-display behavior, sleep/wake, and extended-use checks remain unverified; see the [panel task history](docs/histories/2026-10/2026-10-01-fix-height-slider-label.md) for the evidence and limits.

## Development

Open `Easydict.xcworkspace` and select the `Easydict` scheme in Xcode 26+. The Xcode project and SwiftPM package use the same compact Swift source set. After changing the source-file inventory, regenerate the Xcode references:

```bash
python3 scripts/focused/generate-project.py
```

Read [AGENTS.md](AGENTS.md) and [CONTRIBUTING.md](CONTRIBUTING.md). Earlier histories and specialist documentation describe the upstream application and are not current fork features unless explicitly adopted.

## License and attribution

GPL-3.0; retain [LICENSE](LICENSE). Based on Easydict by tisfeng and contributors, originally inspired by Bob and Saladict. Translation prompt examples and the request task-control/throttling implementations retain their original attribution. The floating panel and background contrast take behavioral inspiration from EchoType. Persistent active glass uses two undocumented AppKit appearance queries isolated to the result panel, following EchoType's approach; revalidate them after macOS updates. Backdrop sampling uses public ScreenCaptureKit APIs.
