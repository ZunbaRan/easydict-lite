## 2026-09-30 | 任务：建立精简 LLM 划词与剪贴板翻译分支

**Links:** [执行计划](../../exec-plans/completed/2026-09/2026-09-30-streamlined-llm-fork.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 26.6.2 / Xcode Unknown (Command Line Tools / Swift 6.4; build SDK 26.5)`

### 用户请求

完成本地 Easydict 精简分支，保留鼠标纯文本划词、显式剪贴板长文本翻译、OpenAI 兼容 API、
DeepSeek 及核心 Prompt。移除快捷键和不需要的功能，悬浮窗口参考 EchoType，使用 macOS 26
Liquid Glass。用户从分析转为执行并明确要求完成目标；不进行外部 fork、push、PR 或发布。

### 变更

- 在 `feat/streamlined-llm-fork` 建立独立 `org.easydict.focused` 身份的 Easydict Lite。
- 使用 23 个 Swift 文件组成精简运行时，SwiftPM 和生成的 Xcode 工程使用相同源码；运行时只依赖
  Alamofire、Defaults、SFSafeSymbols。移除 CocoaPods、旧构建引用、供应商/CLI 运行时与上游更新 feed。
- AX-only 捕获来源应用的选中文字，后台读取与 generation / 进程 ID 校验隔离快速连续选择；只显示
  查询图标，点击才发送请求。删除复制模拟、浏览器脚本、键盘事件及轮询。
- 剪贴板翻译显式仅读取一次，重试复用不可变原文；自动翻译不写剪贴板。显式 Copy result 与原生
  用户文本编辑操作保持正常复制行为。剪贴板结果在用户关闭前保留。
- 一个非激活浮动面板使用公开 `NSGlassEffectView`，支持原生文本选择、滚动、固定、复制、停止、
  重试与三种查询模式；不移植 EchoType 私有 selector 或屏幕采样。
- 统一 OpenAI 兼容 / DeepSeek Chat Completions 传输、配置快照、独立 Keychain 密钥及连接验证。
  保留翻译、词语解释、句子分析、few-shot 和自定义模板变量；变量只替换模板中的 token。
- 请求 ID 隔离取消与过期回调；SSE 按字节缓冲完整 UTF-8 行；JSON / SSE 都在进入异步缓冲前
  检查总字节上限。输入上限 2 MiB、响应上限 8 MiB、SSE 事件上限 1 MiB，不静默截断原文。
  不完整输出保留部分结果并报错，拒绝 API 重定向。
- 删除 OCR、截图、音频、本地词典、其他服务、文本替换、快捷键设置、遥测和上游外部通知流程。
  精简中英文设置与公开说明，将旧 Swift 迁移路线图移至上游历史参考，避免其剩余事项被误作精简分支待办。
- 保留两个现有测试 suite，共 8 个测试；其文件内容未修改，移除旧功能的无效测试与资源引用。

### 设计意图

把选择捕获、查询快照、请求生命周期、Prompt 和面板职责分开，使用一个活动通道和一个结果面板，
减少旧服务与窗口组合产生的状态。AX-only 明确限制覆盖范围，以显式剪贴板入口承接长文本和不支持
辅助功能取词的来源。减少功能能移除相关故障路径，但没有证据支持“已修复大多数 issue”的比例结论。

### 验证

- 初始 HEAD：`e4882f168fec6b19a7f682f8ed05ecbdc98b970c`；首次写入前工作树和索引均干净。
- `scripts/focused/package-app.sh debug`：通过。
- `scripts/focused/package-app.sh release`：最终源码构建、资源打包、签名和严格校验通过。
- `scripts/focused/run-tests.sh`：8 tests / 2 suites 全部通过，覆盖节流、安装前取消、替换请求取消和
  过期请求完成不影响新请求。未新增或扩写测试；这些断言不覆盖新的 AX / 剪贴板 / 网络 / UI 路径。
- `codesign --verify --deep --strict`：通过；`otool -l`：Release `minos 26.0 / sdk 26.5`。
- `plutil -lint`、`jq -e .`、`bash -n`、`git diff --check`：通过。
- 工程与资源静态核对：SwiftPM / Xcode 的 23 个 Swift 源文件一致，无悬空文件引用；两种语言的
  `.strings` 与主 String Catalog 一致，无缺失的静态 UI key；依赖锁定 3 个运行时 Swift 包。
- 手动启动检查：最终 Release 进程启动成功。旧 smoke 进程退出后第一次 LaunchServices 调用返回
  `-600`，使用新实例启动成功；没有覆盖安装中的原 Easydict。
- `review`：读取完整 raw diff、删除清单、未跟踪文件与核心源码/调用者/现有测试。最终生产快照
  含 1309 个候选路径，manifest SHA-256 为
  `4fe4a75ab892e5766627306cfb1b4cdd44df3b95a66ce55cf99584815c4f3a02`。
  之后只有公开说明和本记录/计划更新，增量已核对。
- Review finding 修复与复验：完整回答尾部 `<` 丢失、缺少标准原生 Copy/Paste 菜单、重定向目的地
  越过初始 URL 约束、响应生产者缓冲先于消费上限。修改后重新构建、运行现有测试与审查，无遗留
  可证实 finding。当前职责分离足以支撑所选范围，不需恢复广泛的旧窗口/服务基础设施。
- `xcodebuild -version`：环境阻塞，仅安装 Command Line Tools；不能汇报 Xcode 构建/测试通过。
  默认 SDK 27 缺少 SwiftUI macro plugin，脚本选择已安装 SDK 26.5；未改变全局工具链。
- UI automation 最初连接超时/环境失败，最终 Release 新实例启动后恢复。实际检查了四个设置 tab、
  两项 API 通道菜单、Prompt 变量说明和单面板选项；General / API 截图未见裁切或布局异常。
  聚焦模型输入框后，原生 Edit 菜单的 Paste / Select All 可用。没有修改设置或粘贴用户内容。
- 未完成真实剪贴板保留、快速连续选择、悬浮面板的焦点/玻璃视觉检查。辅助功能尚未授权、API
  尚未配置；未读取用户剪贴板、使用其 API key、自动授予权限或调用真实供应商。

### 受影响文件

- `Easydict/Swift/Focused/`、`Easydict/App/Info.plist`、`Easydict/App/AppIcon.icns`、`Easydict/App/Localizable.xcstrings`
- `Package.swift`、`Package.resolved`、`.swift-version`、`Easydict.xcodeproj/`、`Easydict.xcworkspace/`
- `scripts/focused/`、移除的旧源码/测试资源/Pods/CLI/更新 feed/通知 workflow
- `README.md`、`README_ZH.md`、`CONTRIBUTING.md`、`AGENTS.md`、当前架构/构建/本地化规则和使用指南
- `docs/exec-plans/completed/2026-09/2026-09-30-streamlined-llm-fork.md`、本 history

### 后续事项

- 在完整 Xcode 环境验证生成工程的 build / test；SwiftPM 通过不代替这一步。
- 配置真实兼容 API / DeepSeek 并验证流式、非流式、上下文超限、部分输出、取消及连接错误。
- 在可用的 UI 环境验证剪贴板保留、快速连续选择、点击结果的焦点、常用应用 AX 覆盖、多屏与玻璃材质。
- 验证长文本、睡眠唤醒和长时间运行。新的网络、选择、剪贴板及面板行为尚缺专属回归覆盖；新增测试
  需遵循仓库的明确用户授权规则。
- Stop 仅取消本地请求，不保证服务端停止生成或计费；LLM 词语解释不是已验证词典结果。
