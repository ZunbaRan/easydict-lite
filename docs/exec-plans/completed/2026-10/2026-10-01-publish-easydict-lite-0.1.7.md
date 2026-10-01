# Fork and publish easydict-lite 0.1.7

- 状态：completed
- 创建日期：2026-10-01
- 负责人：Codex
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 26.6.2 / Xcode Unknown (Command Line Tools only)`

## 背景

The user accepts the current easydict-lite result and explicitly requests a GitHub fork, commit,
push, and a new public release. The implementation and signed 0.1.7 / build 8 package already exist;
the latest panel/API changes are uncommitted on `feat/streamlined-llm-fork`.

## 目标与范围

- 目标结果：publish the current code and verified 0.1.7 ZIP in `ZunbaRan/easydict-lite`.
- 允许修改路径：the owned panel/API candidate, its existing plan/history, `README.md`,
  `README_ZH.md`, `changelog/0.1.7.md`, this plan/history, and local Git refs/remotes.
- 同任务 history：`docs/histories/2026-10/2026-10-01-publish-easydict-lite-0.1.7.md`
- 用户限制：keep the installed Easydict untouched; do not restart CUA.
- 非目标：upstream writes, Issue comments/closures, updater/appcast restoration, notarization,
  new provider integrations, new tests, or history rewriting.
- 验收标准：fork identity and parent verified; source commit and tag pushed; canonical English
  release notes and ZIP/checksum verified in a draft; public release and anonymous downloads
  verified; final records committed/pushed and worktree clean.

## 工作计划

1. Check identity, repo/branch state, existing candidate and package; create the named fork.
2. Archive the accepted implementation plan, correct publication docs, freeze/review and commit.
3. Push the current branch and `main` to the fork, make `main` its default, and push `v0.1.7`.
4. Create and verify a prerelease draft with ZIP/checksum; publish and verify public assets.
5. Record the result, archive this plan, commit/push delivery records, and report URLs and hashes.

## 风险与决策

- Baseline HEAD `f12816befc65ab98510cf9312d7d6a79d13b8ab3`, empty index; all 17 initial dirty
  paths belong to the accepted implementation task and match its reviewed snapshot except
  recorded documentation increments.
- GitHub account `ZunbaRan`; upstream `tisfeng/Easydict` is public. The new public fork is named
  `easydict-lite`, initially copying only upstream's default `dev`. No existing fork/tag was found.
- The retained release skill targets upstream's Sparkle/appcast, original app name and Developer ID
  workflow. It is inapplicable to this stripped fork. Use explicit `gh -R ZunbaRan/easydict-lite`
  draft/publish stages; retain canonical notes, prerelease default, checksum and public verification.
- Only an arm64 ZIP is shipped. The ad-hoc signature is verified but is not notarization;
  installation notes and undocumented active-glass compatibility limits are explicit.
- Preserve upstream as a separate remote; never force-push or change upstream refs. Keep the local
  feature branch, publish the same source commit on fork `main` and the feature branch.
- There are no fork Issues/PRs associated with this first release; no upstream follow-up is authorized
  or needed. No ASC run, DMG, appcast or disposable release worktree is created.

## 进度

- [x] Identity, baseline, release tooling, architecture and package checked.
- [x] Fork created and parent verified.
- [x] Candidate review, commit and fork push.
- [x] Draft and public asset verification.
- [x] Final records archived for the delivery commit; branch push and clean-state checks are the
  final delivery actions. The tag stays on the source commit.

## 验证

- `gh auth status`: active `ZunbaRan`; `gh repo view`: confirmed fork parent `tisfeng/Easydict`.
- `file` confirms current binary is arm64. Existing Release, signature, SDK 26.5, localization and
  eight-test evidence from the implementation task applies while source/resource hashes stay unchanged.
- Full Xcode is unavailable. No additional UI checks or tests are inferred from publication approval.
- Fork CLI initially rejected an unsupported flag combination before any write; corrected command
  created the fork. No release or upstream mutation occurred during that rejected call.
- Final candidate Review froze 22 files and complete raw diff/SHA-256. All 12 production/resource
  files match the prior accepted Review; checked notes, README corrections, archived-plan links,
  ownership, signing/architecture disclosures and explicit fork targets. No evidenced new finding;
  HEAD and empty index stayed unchanged. Source build/test evidence remains applicable.
- Source commit `0071edb0f748dc8d4f78815843741c408e8a5adc`: message pre/post validation passed;
  one staging operation exactly matched frozen paths/raw patch. Initial post-commit worktree clean.
- Fork `main` and `feat/streamlined-llm-fork` received that source commit. Default branch is `main`;
  annotated `v0.1.7` peels to the source commit; tag object `15b149686f9f6e9ba3253c8c7156174b9352760a`.
- Draft title `0.1.7`, prerelease flag, notes SHA-256, two asset names/types/sizes/digests matched
  frozen evidence before publishing. Draft lookup by tag returned 404; authenticated release-list
  lookup verified the unique draft without recreating it.
- Public release [0.1.7](https://github.com/ZunbaRan/easydict-lite/releases/tag/v0.1.7), GitHub ID
  `401003284`, published `2026-10-01T13:39:06Z`. Canonical notes SHA-256
  `1043915cfa06f1bf2b112c897344aa950f355e0e6ba4a89833a22e4c991fcaf7` matches the public body.
- Authenticated public metadata verified `draft=false`, `prerelease=true` and both asset digests.
  Anonymous API lookup was rate-limited (403), while anonymous ZIP and checksum downloads returned
  200 with exact length/type/SHA-256. ZIP CRC, version/build/ID, extracted signature and executable
  identity all passed; no authentication was used for the asset downloads.
- ZIP: 2,928,621 bytes; SHA-256
  `3a25969996b7a9d923c8d1e1763e29c9bc59293ed7dc08a451637798e8c9a9a5`.
  Checksum file: 102 bytes; SHA-256
  `19c06a1ca2c090d27e70c3e09129f396f883d7cb3f6202a40f179add21c354ff`.
- Fork has zero open Issues and Issues disabled by default; no associated PR/Issue follow-up applies.
  No ASC run/appcast/DMG workflow was used. Only this task's ignored preparation directory is eligible
  for cleanup after final delivery; `dist/easydict-lite.app` and ZIP are retained.

## 完成条件

- Source refs, public release body and downloadable ZIP/checksum match frozen local evidence.
- Record limitations, archive plan, push delivery records and verify clean local/remote state.
