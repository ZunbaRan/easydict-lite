# 压缩结果面板布局并记住手动尺寸

- 状态：completed
- 创建日期：2026-10-07
- 负责人：Codex
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 26.6.2 / Xcode Unknown (Unknown)`（仅 Command Line Tools）

## 背景

用户希望标题栏缩小，底部的复制与重试改为顶部图标，结果区域获得更多空间。
原面板已有 resizable style，但新查询重置为 440×260，并依据流式内容自动增高，
无法持续保留用户选择的尺寸；最大高度偏好也限制手动增高。

## 目标与范围

- 目标结果：紧凑顶部操作栏、无底部栏、原生自由缩放并跨重启保存宽高。
- 允许修改路径：`Easydict/Swift/Focused/View/{ResultContentView,ResultPanel,FocusedSettingsView}.swift`、
  `Easydict/Swift/Focused/Model/FocusedPreferences.swift`、`Easydict/App/{Info.plist,Localizable.xcstrings}`、
  `Easydict/Swift/Focused/Service/LookupController.swift`、
  `Easydict/Swift/Focused/Resources/*/Localizable.strings`、`docs/design-docs/application-architecture.md`、
  `docs/user-docs/{en,zh}/GUIDE.md`、本计划及对应 history。
- 同任务 history：`docs/histories/2026-10/2026-10-07-compact-resizable-panel.md`
- 用户限制：保留独立 easydict-lite 身份与原 Easydict 安装；不再启用 CUA；不新增或扩写测试。
- 非目标：网络、提示词、取词、玻璃材质、对比度算法和位置偏好重构；GitHub Release。
  用户确认追加优化后明确授权 commit & push，目标为当前任务分支。
- 验收标准：顶部按钮有 tooltip/可访问 label，固定反馈与请求中停止均可用；底部无操作栏；
  手动缩放不受响应、固定或旧最大高度偏好影响；新查询、关闭重开及应用重启恢复大小；
  小屏只临时约束显示尺寸，不覆盖用户保存的较大尺寸；复制成功后显示蓝底勾号，1 秒后恢复，
  重复复制重新计时；正文缩小至 13 点。

## 工作计划

1. 核对尺寸、固定、焦点和 SwiftUI 宿主约束，确认 AppKit 缩放生命周期契约。
2. 压缩顶部并迁移图标，取消内容自动缩放，保存用户缩放结果并按目标屏幕恢复。
3. 同步窗口设置文案、指南和架构说明，打包本地 0.1.8 / build 9。
   用户认可新版后追加复制确认动画与较小正文，一并验证交付。
4. 运行现有测试、资源/签名/SDK 检查；通过用户手动反馈检查真实 UI，不使用 CUA。
5. 用 review 技能冻结并审查本任务差异，修复有效 finding 后复验；更新 history、归档计划并本地提交。

## 风险与决策

- 使用原生 `.resizable` 和 `windowDidEndLiveResize`，不实现鼠标事件循环或改动取词监视器。
- 禁用 NSHostingView 的隐式尺寸约束，保持 AppKit 设置的最小尺寸与用户 frame 的所有权。
- 初始 440×320，最小 320×200，手动宽高上限为当前屏幕可用区域；长输出滚动显示。
- 移除最大高度滑块及自动增高逻辑，避免已保存尺寸被旧行为覆盖；默认始终记住尺寸。
- 尺寸偏好通过 Defaults 保存，只有用户 live resize 结束时写入；程序化定位和小屏约束不污染偏好。
- 保留固定位置语义、显示不夺焦点、常驻玻璃与自动文字对比度；实际外观与边缘拖动须目标环境检查。

## 进度

- [x] 读取规则、记录初始 HEAD `960b45457f2d546c04ab56e96034937998557134` 与干净工作区，完成现状调查。
- [x] 实现紧凑布局与尺寸保存，同步本地化、指南和架构说明。
- [x] 本地构建、现有测试、真实 UI 用户反馈及 Review，含追加复制动画与字体优化。
- [x] history 与计划归档，提交交付进入 git-commit 的候选冻结、校验流程。

## 验证

- 环境：macOS 26.6.2；`xcodebuild -version` 确认只有 CLT，完整 Xcode 构建不可运行。
- AppKit SDK 26.5 提供 `windowDidEndLiveResize`；Apple 文档确认宿主 `sizingOptions = []` 不生成隐式尺寸约束。
- `scripts/focused/package-app.sh release`：通过，产物为本地 0.1.8 / build 9。
- 签名 deep / strict 验证、ZIP 完整性和元数据检查：通过；`LC_BUILD_VERSION` 最低 26.0、SDK 26.5。
- 最终 ZIP 解包签名通过且二进制与本地 app 一致，SHA-256 见同任务 history。
- String Catalog JSON 与 plist / 两种语言 strings 语法检查：通过；各 98 个本地化值与 SwiftPM 镜像完全一致。
- `git diff --check`：通过；现有 2 个 suite、8 个测试全部通过，未新增测试。
- Review 冻结基线与 13 个路径 SHA-256，完整差异及关联调用链审查未发现有证据的缺陷，复验内容未漂移。
- 追加优化 Review 冻结 14 路径，发现 COPY-FAIL-STALE 并在失败分支清理旧反馈；重新打包与测试通过，
  增量复审无剩余有效 finding。最终 ZIP 摘要及验证边界见 history。
- 用户对已打包新版反馈「非常棒了」，随后追加复制确认动画与缩小正文；保留整体认可，
  不将未逐项反馈的多屏等场景记为通过。不启用 CUA。
- 用户对复制确认与 13 点正文反馈「完美了」。最后的失败清理为增量代码复核，未实际触发 ownership 竞争。

## 完成条件

- 本次允许路径中的实现与文档一致，必要验证和 Review 完成并明确实际验证边界。
- 用户真实场景核对紧凑按钮、边缘缩放、重新查询及重启恢复尺寸。
- 更新 history，归档本计划，按 git-commit 流程创建本地提交。
