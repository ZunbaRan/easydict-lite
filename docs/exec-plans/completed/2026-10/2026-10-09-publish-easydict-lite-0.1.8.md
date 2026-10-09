# Publish easydict-lite 0.1.8

- 状态：completed
- 创建日期：2026-10-09
- 负责人：Codex
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 26.6.2 / Xcode Unknown (Command Line Tools only)`

## 背景

The user clarified that the missing latest release concerns ZunbaRan/easydict-lite.
Accepted version 0.1.8 is pushed on feat/streamlined-llm-fork, while the public prerelease and default branch remain at the previous delivery.

## 目标与范围

- 目标结果：Publish verified prerelease 0.1.8 and fast-forward the fork main to the accepted code.
- 允许修改路径：`changelog/0.1.8.md`, this plan and its archived path, the same-task history; ignored publication files and fork refs/assets.
- 同任务 history：`docs/histories/2026-10/2026-10-09-publish-easydict-lite-0.1.8.md`
- 用户限制：Preserve installed Easydict, independent identity and existing accepted behavior. Keep CUA stopped.
- 非目标：No runtime changes, upstream writes, updater/appcast restoration, unrelated Issue/PR messages, or new tests.
- 验收标准：Immutable tag, canonical notes, ZIP/checksum, public download verification, synchronized fork refs and clean worktree.

## 工作计划

1. Verify accepted source, fork refs and the existing release; build and validate the focused app and existing tests.
2. Commit canonical English notes and this plan, push the feature branch and immutable version tag, and create a prerelease Draft.
3. Verify Draft metadata/body/assets, publish, verify anonymous downloads, then fast-forward fork main.
4. Record results, archive this plan, commit/push delivery records and clean task-owned preparation files.

## 风险与决策

- Baseline source is `7c1d91a7f5e60b85c14590c54e5931f6989ee2d4`, initially clean index/worktree. Fork main is an ancestor; only fast-forward pushes are allowed.
- Adopt the already-used focused fork release path from the 0.1.7 publication: upstream release automation needs removed Sparkle/appcast and original signing configuration. Explicit GitHub Draft/Publish stages use only `ZunbaRan/easydict-lite`, ZIP/checksum and canonical notes. No ASC run, DMG or appcast is applicable.
- Retain the default prerelease channel, arm64/macOS 26 requirements, ad-hoc signing and private-glass compatibility disclosures.
- Full Xcode is unavailable. Never equate SwiftPM verification with Xcode testing.

## 进度

- [x] Confirmed latest accepted source and fork targeting; main fast-forward precondition passed.
- [x] Build, test and package checks.
- [x] Canonical notes, preparation commit and validated Draft.
- [x] Published assets verified; fork main synchronized.
- [x] Delivery history, archived plan, final pushes and cleanup.

## 验证

- Explicit fork API queries verified main and feature heads, version 0.1.7 prerelease and release assets.
- `git merge-base --is-ancestor origin/main HEAD`: passed after fetching only origin.
- `sw_vers -productVersion`: 26.6.2; `xcodebuild -version`: unavailable in the CLT-only environment.
- Release build, version 0.1.8/build 9, arm64 architecture, independent ID, app/extracted-ZIP signatures and file equality passed; SDK 26.5/minos 26.0 verified.
- Eight existing tests in two suites passed. Runtime/source files remain at the accepted 7c1d91a7 implementation.
- Fork Issues are disabled with zero open items; there are no merged fork PRs requiring follow-up.
- Published prerelease `0.1.8`, release ID `408073653`, with canonical title/body and ZIP/checksum assets verified before and after publication.
- Annotated `v0.1.8` peels to `a569fdfb5a79385279a3f7aa87811ff54d00b8d7`; production files remain unchanged from accepted source `7c1d91a7`.
- Both anonymous downloads returned 200 with exact size and SHA-256; checksum bytes match exactly. Its GitHub API type is text/plain, while the CDN serves it as application/octet-stream attachment; this transport type was accepted only after byte/hash verification.
- Fork main safely fast-forwarded to the release source after public asset checks. Delivery records are prepared for the final commit/push and clean-state verification.
- No ASC run, appcast, DMG or upstream actions apply to this focused fork publication. Only task-owned ignored preparation files are eligible for cleanup; dist app/ZIP/checksum are retained.

## 完成条件

- Public v0.1.8 body and downloadable assets match frozen evidence; tag identity and fork branches are verified.
- Record validation limitations, archive this plan, push the delivery records and verify a clean worktree.
