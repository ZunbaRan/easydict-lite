## 2026-10-01 | 任务：修复 API 基础地址和固定浮窗

**Links:** [执行计划](../../exec-plans/completed/2026-10/2026-10-01-fix-api-and-pinned-panel.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 26.6.2 / Xcode Unknown (Command Line Tools only)`

### 用户请求

修复自定义模型配置产生的 HTTP 404，使浮窗更透明并参考图 3，固定后保留位置。
保留独立 easydict-lite 包，不替换原 Easydict。

### 变更

- 按 URL 最后路径段识别 `v1`，支持 `/compatible-mode/v1` 及尾部斜线，补全
  `/chat/completions`；完整 endpoint、模型快照和凭据逻辑保持既有语义。
- 固定后沿用当前 frame，涵盖新选区、剪贴板、重试及关闭后的重新显示；停止自动尺寸调整。
  用户主动拖动或缩放后的 frame 成为后续固定位置，长输出继续滚动。
- 采用公开 clear Liquid Glass 材质及轻微黑色 tint，不改变文本或整个窗口的 alpha。
- 版本为 0.1.1 / build 2，重新生成独立 app 和 ZIP。
- 完成本任务计划与历史记录；无测试文件变更。

### 设计意图

404 来自基础地址直接接收 POST，而非模型字段没有进入请求。
[Alibaba 文档](https://www.alibabacloud.com/help/en/model-studio/model-calling-in-sub-workspace)
区分 SDK 基础地址与完整 HTTP 路径，因此采用通用路径补全，不增加专有翻译集成。
固定需要约束 frame 的两条修改路径（显示定位和流式内容尺寸），避免仅阻止关闭。
现有单面板和滚动视图足以承载固定尺寸，无需新增布局状态机。

### 验证

- `scripts/focused/package-app.sh release`：通过，生成 `dist/easydict-lite.app` 与 ZIP。
- `scripts/focused/run-tests.sh`：2 个 suite / 8 个保留测试通过。
- `codesign --verify --deep --strict`：app 与解包 ZIP 通过，解包的 metadata / executable
  与构建产物一致；`otool -l` 的 minimum / SDK 为 26.0 / 26.5。
- `plutil -lint Easydict/App/Info.plist`、`git diff --check`：通过。
- 无密钥固定样本 HTTP 请求：基础地址返回 404，正确请求地址返回缺少密钥的 401，确认路由差异；
  未读取或输出用户密钥，未证明模型权限或带凭据请求成功。
- 手动检查：新包进程已启动，辅助功能权限仍有效。用户自行批准 macOS Keychain 提示后，
  DashScope 基础地址与 `qwen3.8-flash` 的 UI Test connection 显示 Connection succeeded；
  未读取或输出密钥。原生工具的模拟选择未可靠触发全局选择图标，已请求用户打开结果面板，
  固定位置与材质效果未验证，明确作为交付后检查；未推断用户选择跳过，也未将代码审查或
  现有测试作为实际 UI 场景通过的证据。
- Review 技能：冻结首次写入前 HEAD `73d44240deeab270d68d2261de2e9279c5bf789d`，检查完整
  raw diff、未跟踪 plan 和文件 SHA-256，核对真实配置快照、选择 / 剪贴板 / 重试入口及尺寸订阅。
  没有有证据的新增 finding；现有实现范围和复杂度适合此修复。生产文件摘要复验不变，最终文档
  增量单独检查。实际 UI 限制不作为通过证据。
- 完整 Xcode build/test、本次多屏切换和长时间运行未执行。

### 受影响文件

- `Easydict/Swift/Focused/Service/LLMClient.swift`
- `Easydict/Swift/Focused/View/ResultPanel.swift`
- `Easydict/App/Info.plist`
- `docs/exec-plans/completed/2026-10/2026-10-01-fix-api-and-pinned-panel.md`
- `docs/histories/2026-10/2026-10-01-fix-api-and-pinned-panel.md`

### 后续事项

- 用户打开结果面板后，实际对比固定位置与透明玻璃效果；该项由于原生工具限制尚未验证。
- 固定 frame 仅在本次运行中保留；跨重启保存完整位置 / 尺寸不属于本次请求。
- 在有完整 Xcode 和实际多屏环境时补充对应场景验证。
