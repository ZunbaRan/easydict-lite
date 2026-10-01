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
  全局 mouse-down 的外部点击与旧选择失效分离；mouse-up / 应用切换只清理选择图标。
  本地 mouse-down 原样返回并保护对应 mouse-up，全局事件用 AppKit 最前命中窗口区分本应用，
  防止读到非激活面板后方旧选择；不是用所有可见窗口矩形排除被其他应用遮挡的设置窗口。
- 剪贴板入口显式读取一次，形成不可变原文快照；重试使用该快照。唯一的剪贴板写入入口是 Copy result。
- `LookupController` 在 MainActor 上拥有当前请求 ID 和 UI 状态，取消旧请求并丢弃过期响应；保留
  `OpenAIStreamTaskControl` 的线程安全任务取消机制。
- `LLMClient` 使用 Alamofire async 数据流统一读取 JSON / SSE，按字节缓冲完整行后解码 UTF-8，
  对输入、响应与 SSE 单事件设置明确资源限制。不静默截断原文或自动分块。
  `LookupController` 依据原文及模式计算 `allowThinking`，只有字典模式的既有英文单词 /
  短中文词识别可保留思考；翻译、句子分析和其他字典文本关闭。重试、自定义 Prompt 不绕过策略。
  DeepSeek 使用 `thinking.type`，DashScope 非单词请求使用顶层 `enable_thinking: false`，
  单词请求保留 DashScope 服务默认值。未知兼容接口不注入这些非标准字段；仅支持思考的模型
  不能保证关闭。隐藏 reasoning 内容只是显示过滤，与请求开关分离。
- `PromptBuilder` 保留翻译、查词、句子分析和 few-shot 示例，剥离旧服务/UI 全局状态。自定义
  Prompt 变量只替换模板中的 token，插入原文不参与递归替换。
- `ResultPanelController` 只有一个窗口，显示不夺焦点，用户点击后允许文本选择；使用公开
  `NSGlassEffectView`。为匹配用户要求的 EchoType 常驻活跃玻璃效果，`ResultPanel` 局部覆盖
  `_hasActiveAppearance` / `_hasActiveAppearanceIgnoringKeyFocus` 两个未公开外观查询。
  不 swizzle 系统类，不伪造 `isKeyWindow` / `isMainWindow`，不调用激活或抢焦点 API；
  保留点击后可选字的 key eligibility，查询图标 / 设置窗口不受覆盖影响。macOS 26 公开玻璃 API
  无常驻活跃开关；该局部兼容处理需在系统升级后复验，若系统不再查询这些 selector 则可能
  回到系统默认的非活跃玻璃。无 WebKit 或 OCR 资源。
  固定按钮使用强调色选中背景、填充图标、动态取消固定 label 及 selected accessibility trait；
  点击同步更新局部显示状态并写回原 Defaults key，取消固定恢复灰色；偏好通知同步设置页变更，
  读取当前值避免快速连续点击被队列中的旧值覆盖。不重建面板或改变玻璃 / 自动对比度生命周期。
  最大高度值独立于 Slider label 显示，以 1% 步长保存，固定 frame 不受其自动缩放影响。
  真正外部 mouse-down 才关闭未固定划词面板；解除固定、窗口拖动 / 松开、应用激活不直接关闭。
  鼠标按下期间推迟流式内容的自动缩放，只保留一个等待任务，释放后读取最新内容更新，
  关闭窗口取消等待。此检查只用于几何暂停，不以 pressedMouseButtons 还原事件顺序。
- `BackdropAppearanceController` 属于 View 边界，使用公开 ScreenCaptureKit 在面板可见时
  低频读取裁剪背景亮度，排除本应用；一张采样完成前不开始下一张，隐藏时取消，移动或偏好
  变更使旧结果失效。图片只存在于局部内存，不进入 LookupController、Prompt 或网络层。
  自动模式需要用户显式授予额外 Screen Recording 权限；无权限跟随系统外观，手动深浅文字
  不采样。亮暗阈值有滞后，AppKit 外观及 SwiftUI colorScheme 一起更新，frame 和 tint 不变。
- 偏好通过 Defaults 保存，密钥通过独立 Keychain service 保存；bundle ID `org.easydict.focused`
  与原应用隔离，无遥测、原项目更新 feed 或自动外部通知。

## 构建与验证边界

SwiftPM 与生成的 Xcode 工程包含相同的精简 Swift 源码。构建、打包与验证命令见
[`build-and-test.md`](../agents/build-and-test.md)。Xcode 入口仍为 `Easydict.xcworkspace` /
`Easydict` scheme，已移除 CocoaPods 和旧源码引用。

保留的两个测试 suite 覆盖节流和任务取消，不能替代新网络/选择/UI 路径的场景验证。辅助功能
权限、真实 API、焦点、多屏、长时间运行和睡眠唤醒必须在目标环境实际检查。
