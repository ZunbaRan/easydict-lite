# 修复 API 基础地址与固定浮窗

- 状态：completed
- 创建日期：2026-10-01
- 负责人：Codex
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 26.6.2 / Xcode Unknown (Command Line Tools only)`

## 背景

用户配置 DashScope 的 OpenAI 兼容基础地址后收到 HTTP 404；现有实现只补全根地址和
`/v1`，遗漏带前缀的 `/compatible-mode/v1`。浮窗固定状态只阻止关闭，仍会随新查询重新
定位和随输出调整大小。用户还要求调整玻璃材质，已确认需要更透明并参考图 3。

## 目标与范围

- 目标结果：基础地址正确补全 Chat Completions 路径；固定浮窗保留位置和尺寸；调整材质并生成修复包。
- 允许修改路径：`Easydict/Swift/Focused/Service/LLMClient.swift`、
  `Easydict/Swift/Focused/View/ResultPanel.swift`、`Easydict/App/Info.plist`、本任务 plan/history。
- 同任务 history：`docs/histories/2026-10/2026-10-01-fix-api-and-pinned-panel.md`
- 用户限制：保留剪贴板翻译；独立 easydict-lite，不覆盖原 Easydict；不新增或扩写测试。
- 非目标：扩充翻译通道、恢复快捷键、改动用户密钥或模型、发布或 push。
- 验收标准：Release 包构建和签名检查通过；现有测试通过；实际连接与固定窗口场景检查，记录环境限制。

## 工作计划

1. 检查配置快照、URL 合约、窗口调用链及 macOS 26 公开玻璃 API。
2. 修复带路径前缀的基础地址和固定窗口 frame；依据用户答复或明确说明的截图假设调整材质。
3. 生成 0.1.1 修复包，运行现有测试、签名和 SDK 检查；实际 UI 验证。
4. 使用 review 技能检查冻结的任务差异，修复有效 finding 并复验。
5. 更新 history、归档计划，按仓库规则创建本地提交。

## 风险与决策

- 首次写入前 HEAD：`73d44240deeab270d68d2261de2e9279c5bf789d`；索引、工作树和未跟踪文件均为空。
- 仅识别最后路径段为 `v1` 的基础地址，不改写用户提供的完整或自定义请求 endpoint。
- 固定后停止自动定位和自动尺寸调整，长内容仍可滚动；用户可主动拖动或缩放。
- 材质使用公开 `NSGlassEffectView.Style.clear` 和 0.12 alpha 黑色 tint，只改变背景而不淡化文本。
- 不读取或输出密钥；UI Test connection 只发送内置固定样本。
- 外部合约依据：[Alibaba API 文档](https://www.alibabacloud.com/help/en/model-studio/model-calling-in-sub-workspace)。

## 进度

- [x] 查明基础地址漏补全与固定状态未参与布局的原因。
- [x] 实现三项修复，修复包版本更新为 0.1.1 / build 2。
- [x] 完成构建、HTTP 路由诊断及生产代码 Review。
- [x] 用户批准 Keychain 提示后，实际 API Test connection 成功。
- [x] 核对固定 frame 的全部修改入口；尝试 UI 场景并记录自动化限制，实际视觉检查作为交付后事项。
- [x] 完成最终 history 与计划归档；本地提交结果见交付回执。

## 验证

- `scripts/focused/package-app.sh release`：通过，生成独立 app 和 ZIP。
- `scripts/focused/run-tests.sh`：保留的 2 个 suite / 8 个测试通过；未新增或扩写测试。
- app 和解包 ZIP 的 `codesign --verify --deep --strict` 通过；Info.plist 与可执行文件内容一致。
- `otool -l`：最低 macOS 26.0，SDK 26.5；`plutil -lint` 和 `git diff --check` 通过。
- 无密钥、固定样本的 HTTP 诊断：旧基础地址返回 404，完整请求路径返回预期的缺少密钥 401；
  只证明路由有效，不代表用户密钥或模型权限已验证。
- 用户已打开 Settings，辅助功能权限仍有效，并自行批准 Keychain 提示（computer-use 工具
  禁止操作 `com.apple.SecurityAgent`）。当前配置为 DashScope 基础地址与 `qwen3.8-flash`，
  UI Test connection 显示 Connection succeeded，原 HTTP 404 的实际请求路径已验证。
- 原生工具能编辑独立的临时 TextEdit 样本，但模拟鼠标选择未可靠触发全局选择图标；已请求用户
  打开结果面板。工具尚未取得可操作的结果窗口，固定 frame 与材质的实际检查未验证；不以代码
  审查或现有测试替代实际场景，也不推断用户已选择跳过。
- Review：冻结基线 `73d44240deeab270d68d2261de2e9279c5bf789d` 和任务差异，保存 raw diff、
  内容摘要与未跟踪 plan；核对配置快照、所有窗口入口和流式尺寸回调，无有证据的新增 finding。
- 本机没有完整 Xcode，不将 SwiftPM 构建称为 Xcode build/test；多屏切换、长时间运行未执行。

浮窗实际检查移交后续验证，原因是原生工具无法可靠触发全局选择图标；代码、Release 包与真实
API 检查已完成。本任务交付明确保留该验证限制，而非额外等待用户批准代码修改或本地提交。

## 完成条件

- 三项请求已处理，必要验证完成并如实记录限制。
- Review 无未处理的有效 finding；完成 history、归档和本地提交。
