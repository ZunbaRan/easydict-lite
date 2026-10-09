## 2026-10-09 | 任务：Publish easydict-lite 0.1.8

**Links:** [Plan](../../exec-plans/completed/2026-10/2026-10-09-publish-easydict-lite-0.1.8.md), [Release](https://github.com/ZunbaRan/easydict-lite/releases/tag/v0.1.8), [Notes](../../../changelog/0.1.8.md), [Source commit](https://github.com/ZunbaRan/easydict-lite/commit/a569fdfb5a79385279a3f7aa87811ff54d00b8d7)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 26.6.2 / Xcode Unknown (Command Line Tools only)`

### 用户请求

The user clarified that the missing current release is in ZunbaRan/easydict-lite; publish the already accepted compact/resizable panel version.

### 变更

- Added canonical English 0.1.8 notes and completed this publication plan.
- Created annotated v0.1.8 at `a569fdfb5a79385279a3f7aa87811ff54d00b8d7` and published GitHub prerelease `0.1.8`, ID `408073653`, at `2026-10-09T15:54:51Z`.
- Delivered arm64/macOS 26 ZIP and SHA256SUMS.txt. After anonymous public verification, fast-forwarded fork main to the accepted code and release notes.
- Retained the existing feature checkout and independent app identity. No runtime changes or upstream writes.

### 设计意图

Use the same focused-fork exception adopted for 0.1.7: the retained upstream automation requires removed Sparkle/appcast and original signing setup. Use explicit fork-targeted Draft/Publish stages, canonical notes and ZIP/checksum verification; retain the prerelease default and disclose signing/platform limits. No ASC run, appcast, DMG or unrelated Issue/PR notifications apply.

### 验证

- Focused Release build passed; version 0.1.8/build 9, arm64, org.easydict.focused, SDK 26.5/minos 26.0 verified.
- Eight existing tests in two suites passed. App/extracted-ZIP signatures and file identity passed; no new tests were added.
- Previously accepted UI feedback covers compact controls, resized dimensions and restart persistence, stable streaming geometry, copy confirmation and 13-point text. CUA stays stopped.
- Preparation commit message pre/post checks passed. Draft title/channel, canonical body and uploaded asset names/types/sizes/digests matched before publishing.
- Both anonymous downloads returned 200 and matched local bytes and SHA-256. Checksum metadata is text/plain; CDN transport is application/octet-stream, accepted after exact content verification.
- ZIP: 2931997 bytes, SHA-256 `c3d0ee0ecc9ab2cadc4c64ddf849a20c73db6317f67d428087e3936952641d0d`.
- Checksum: 102 bytes, SHA-256 `8a12554d4f134b687295f806979a070e719141f33f67bbe6a5583e18a1830477`.
- Fork Issues are disabled with zero open items, and there are no merged fork PRs requiring follow-up. Tag identity and main fast-forward checked.
- Full Xcode, exhaustive provider/app UI, sleep/wake and extended-use coverage remain incomplete. The release notes disclose ad-hoc signing, lack of notarization and private-glass compatibility limits.
- Final delivery records are ready for commit/push and clean-state checks; only this task's ignored preparation directory will be removed after successful delivery. Local app and ZIP/checksum are retained.

### 受影响文件

- `changelog/0.1.8.md`
- Archived publication plan and this history.
- Fork Git refs and GitHub Release metadata/assets.

### 后续事项

- No unfinished publication stage. This is a prerelease, not a Developer ID notarized stable distribution.
