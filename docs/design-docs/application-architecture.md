# easydict-lite 应用架构

精简分支只支持鼠标划词与显式剪贴板翻译，使用一个活动的 OpenAI 兼容 / DeepSeek 通道。
最低系统版本为 macOS 26；旧设计文档记录原项目历史，不代表当前构建图。

## 源码布局

```text
Easydict/Swift/Focused/
├── App/          # 入口、菜单栏、生命周期
├── Model/        # 查询快照、语言、偏好、通道配置
├── Selection/    # AX-only 取词与被动鼠标事件
├── Service/      # Prompt、共享 API 传输、SSE、Keychain、请求协调
├── Utility/      # 本地化、保留的节流与任务取消控制
├── View/         # 查询图标、单结果面板、紧凑设置
└── Resources/    # SwiftPM 英文与简体中文字符串
```

## 运行时边界

- `MouseSelectionMonitor` 仅监听鼠标事件，在后台读取目标进程暴露的选中文本；不发送键盘事件、不
  执行 AppleScript、不触发菜单复制，也不监视剪贴板。捕获后只显示图标，点击才发请求。
- 剪贴板入口显式读取一次，形成不可变原文快照；重试使用该快照。唯一的剪贴板写入入口是 Copy result。
- `LookupController` 在 MainActor 上拥有当前请求 ID 和 UI 状态，取消旧请求并丢弃过期响应；保留
  `OpenAIStreamTaskControl` 的线程安全任务取消机制。
- `LLMClient` 使用 Alamofire async 数据流统一读取 JSON / SSE，按字节缓冲完整行后解码 UTF-8，
  对输入、响应与 SSE 单事件设置明确资源限制。不静默截断原文或自动分块。
- `PromptBuilder` 保留翻译、查词、句子分析和 few-shot 示例，剥离旧服务/UI 全局状态。自定义
  Prompt 变量只替换模板中的 token，插入原文不参与递归替换。
- `ResultPanelController` 只有一个窗口，显示不夺焦点，用户点击后允许文本选择；使用公开
  `NSGlassEffectView`。无私有 selector、屏幕采样、WebKit 或 OCR 资源。
- 偏好通过 Defaults 保存，密钥通过独立 Keychain service 保存；bundle ID `org.easydict.focused`
  与原应用隔离，无遥测、原项目更新 feed 或自动外部通知。

## 构建与验证边界

SwiftPM 与生成的 Xcode 工程包含相同的精简 Swift 源码。构建、打包与验证命令见
[`build-and-test.md`](../agents/build-and-test.md)。Xcode 入口仍为 `Easydict.xcworkspace` /
`Easydict` scheme，已移除 CocoaPods 和旧源码引用。

保留的两个测试 suite 覆盖节流和任务取消，不能替代新网络/选择/UI 路径的场景验证。辅助功能
权限、真实 API、焦点、多屏、长时间运行和睡眠唤醒必须在目标环境实际检查。
