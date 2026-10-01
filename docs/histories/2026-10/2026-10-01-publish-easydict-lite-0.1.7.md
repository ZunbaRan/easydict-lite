## 2026-10-01 | 任务：Fork and publish easydict-lite 0.1.7

**Links:** [Plan](../../exec-plans/completed/2026-10/2026-10-01-publish-easydict-lite-0.1.7.md),
[Fork](https://github.com/ZunbaRan/easydict-lite),
[Release](https://github.com/ZunbaRan/easydict-lite/releases/tag/v0.1.7),
[Source commit](https://github.com/ZunbaRan/easydict-lite/commit/0071edb0f748dc8d4f78815843741c408e8a5adc)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 26.6.2 / Xcode Unknown (Command Line Tools only)`

### 用户请求

Fork the project, commit and push the current easydict-lite code, and publish a new release.

### 变更

- Created public fork `ZunbaRan/easydict-lite`, parent `tisfeng/Easydict`.
- Prepared canonical English 0.1.7 notes and corrected English/Chinese landing pages for public
  downloads, tested behavior and undocumented active-glass queries.
- Archived the accepted implementation plan without claiming unreported UI subchecks passed.
- Committed source as `0071edb0f748dc8d4f78815843741c408e8a5adc`, pushed fork `main` and
  `feat/streamlined-llm-fork`, set `main` as default, and pushed annotated `v0.1.7`.
- Published verified GitHub prerelease `0.1.7` with the arm64 ZIP and `SHA256SUMS.txt`; archived
  the release plan. Publication records are delivered separately without moving the source tag.

### 设计意图

Publish the independent app with its existing identity and version, preserving the installed Easydict.
The retained upstream release automation depends on removed Sparkle/appcast and original signing
configuration; this fork instead uses explicit GitHub draft/publish stages and ZIP/checksum evidence.
Default to a prerelease, disclose arm64/macOS 26 requirements, ad-hoc signing and private API limits.
No upstream Issue/PR follow-up or updater changes are part of this request.

### 验证

- GitHub account and new fork parent verified. Current binary is arm64, version 0.1.7 / build 8.
- Existing Release/signature/resource/SDK checks and eight retained tests passed for the exact
  source candidate; all 12 production/resource hashes matched the accepted Review and package.
- Candidate Review froze 22 files and raw diff/SHA-256; the 12 production/resource files match the
  previous Review. Notes, landing pages, archive links, ownership and fork targeting were checked,
  with no evidenced new finding. HEAD/index and source/resource hashes remained unchanged.
- Source message pre/post validators passed; one staging operation exactly matched the frozen
  22-file paths/raw diff. Worktree was clean after source commit; fork branches and peeled tag were
  checked against that commit before draft creation.
- Draft body, title, prerelease flag and asset type/length/digests matched before publishing.
  The draft-by-tag endpoint returned 404; authenticated list lookup verified the existing draft.
- Public release ID `401003284`, title `0.1.7`, prerelease channel, published `2026-10-01T13:39:06Z`.
  Exact canonical notes SHA-256:
  `1043915cfa06f1bf2b112c897344aa950f355e0e6ba4a89833a22e4c991fcaf7`.
- Public metadata API passed with authentication; anonymous API was rate-limited. Anonymous asset
  GETs returned 200 with exact lengths/types and SHA-256. Downloaded ZIP CRC, app metadata,
  deep/strict signature and executable identity passed. Anonymous downloads used no token.
- ZIP `easydict-lite-0.1.7-macos-arm64.zip`: 2,928,621 bytes, SHA-256
  `3a25969996b7a9d923c8d1e1763e29c9bc59293ed7dc08a451637798e8c9a9a5`.
  `SHA256SUMS.txt`: 102 bytes, SHA-256
  `19c06a1ca2c090d27e70c3e09129f396f883d7cb3f6202a40f179add21c354ff`.
- Fork default branch is `main`; no associated Issues/PRs require follow-up (zero open Issues).
  No ASC run, appcast, DMG or release worktree exists for this publication. Clean up only this
  task's ignored preparation files after the final push, retaining the local app and ZIP.
- Full Xcode, exhaustive provider/UI and extended-use coverage remain incomplete; CUA stays stopped.

### 受影响文件

- Accepted panel/API candidate and implementation plan/history.
- `README.md`, `README_ZH.md`, `changelog/0.1.7.md`.
- This plan/history; local and fork Git refs/remotes, GitHub Release assets/metadata.

### 后续事项

- Ad-hoc signing/notarization, private-glass compatibility and validation limitations are disclosed
  in `changelog/0.1.7.md`; future releases should revalidate them. No unfinished publication stage.
