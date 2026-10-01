# easydict-lite guide

## Configure the API

Open Settings from the menu-bar icon. In API, choose OpenAI-compatible API or DeepSeek. Enter a model name; for compatible services, enter the complete Chat Completions URL or its base URL. HTTPS is required except for loopback HTTP local services. Responses API and non-OpenAI protocols are outside this fork's scope.

Enter an API key and click Save key. Keys are stored separately for each channel in Keychain. Local services may accept an empty key. Test connection sends only a fixed short sample. Streaming is enabled by default; JSON responses are also accepted. Leave temperature disabled if the model rejects that parameter. Reasoning content is hidden.

Translation and sentence analysis explicitly disable thinking on DashScope and DeepSeek, including retries and custom prompts. Word Lookup may retain thinking for recognized single English words or short Chinese words: DashScope keeps the model default, and DeepSeek uses its word-lookup thinking toggle. Other text in Word Lookup also disables thinking on these services. Other compatible APIs retain their model settings; choose a non-thinking model for sentence translation. A model that only supports thinking cannot be switched off by this app.

## Mouse selection

Enable the lookup icon in General and grant Accessibility permission in System Settings. Select text, then click the icon. Language exclusion and minimum selection length control when it appears. No request is sent just by selecting text. Long selections default to translation.

Only Accessibility text is read; the app does not simulate Copy or execute browser scripts. Unsupported applications can still be used through Clipboard Translation.

## Clipboard Translation

Copy your passage using the source application's normal Copy action, then click Clipboard Translation in the menu bar. The app snapshots the current plain text, sends it in full, and leaves the clipboard untouched. Clipboard results remain open until closed.

The input limit is 2 MiB, with an explicit error before sending larger input. Model-specific context errors are displayed. There is no automatic chunking or silent truncation. An incomplete answer is marked and the partial result stays available.

## Result panel and prompts

The panel appears without taking keyboard focus. Click the result to select text. Copy result writes only the displayed answer; Stop cancels the local request; Retry repeats the captured input, not the latest clipboard. Changing modes explicitly requests translation, word lookup, or sentence analysis. Pin keeps selection results open and preserves the frame during new lookups; its accent-colored background indicates that it is on. Unpinned panels grow with results up to their height limit; pinned panels keep their size and scroll longer output. The maximum-height slider shows the limit as a percentage of the available screen height, in 1% steps.

In Settings → Window → Text contrast, Automatic from background selects dark text on light backgrounds and light text on dark backgrounds. Click Enable automatic contrast to grant the optional Screen Recording permission; macOS may require an app restart. Without permission, automatic mode follows system appearance; Dark text and Light text work without capture access. Sampling runs only while the result panel is visible, at most one image request at a time with a 1.5-second refresh interval. It excludes this app, crops to the panel area, and reduces pixels to brightness in local memory. Images are never saved or sent to the translation API. The glass transparency and pinned frame are independent of text contrast.

Pin remains available while a request is running. Unpinning or finishing a window drag leaves the panel open; a mouse-down in another application's window dismisses an unpinned selection result. Clipboard results stay open. Automatic growth waits while a mouse button is held and resumes after the release, so streaming updates do not resize the panel during a click or drag.

The result panel keeps its active Liquid Glass appearance when the pointer leaves. Pin controls whether the panel stays open, independently of the glass appearance. System accessibility settings can still alter the material.

Built-in prompt examples are retained. A custom prompt replaces the built-ins and supports `${{queryText}}`, `${{queryFromLanguage}}`, `${{queryTargetLanguage}}`, and `${{firstLanguage}}`. Word explanations are LLM output; no dictionary database is queried.

## Developer build

```bash
scripts/focused/package-app.sh release
scripts/focused/run-tests.sh
open "dist/easydict-lite.app"
```

Requirements: macOS 26+, Swift 6.2+, macOS 26+ SDK. For Xcode use `Easydict.xcworkspace` / `Easydict`. Regenerate file references with `python3 scripts/focused/generate-project.py` after source inventory changes.

The app has a separate local identity and no upstream updater. Eight retained tests cover request task control and throttling. Provider, visual/focus, Accessibility, sleep/wake, and extended-use checks need the target environment and are not implied by a successful build.

The persistent active glass appearance uses two undocumented AppKit appearance queries, isolated to the result panel. This matches EchoType's implementation without making the window key when it appears. Revalidate this compatibility behavior after macOS updates; if the system stops querying those methods, the glass may return to the system's inactive appearance.
