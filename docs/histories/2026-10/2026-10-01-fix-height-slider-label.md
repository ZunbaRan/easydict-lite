## 2026-10-01 | 任务：修复窗口反馈、保持活跃玻璃并控制句子思考

**Links:** [执行计划](../../exec-plans/completed/2026-10/2026-10-01-fix-height-slider-label.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 26.6.2 / Xcode Unknown (Command Line Tools only)`

### 用户请求

解释最大高度滑块的作用，并修复拖动后仍显示 67% 的问题。
后续继续修复固定按钮无明显视觉反馈，并要求翻译句子时关闭 LLM 思考，单词查词可以保留。
0.1.4 现场反馈继续报告取消固定与未固定拖动结束会消失，翻译中按钮无法点击；句子 API 无报错。
0.1.5 复验确认翻译中操作和拖动已修复，玻璃材质稳定后取消固定却仍显示选中颜色，实际状态已变化。
0.1.6 反馈目前基本没有问题，后续要求鼠标移开也保持 EchoType 的液态玻璃外观。

### 变更

- 将百分比从 Slider 的 label closure 移到同一行的独立 Text，直接读取 Defaults 绑定。
- 使用 1% 步长，并四舍五入显示整数，避免浮点值被截断为低一档百分比。
- 保留 35%–90% 范围和原偏好 key；Slider 使用本地化的动态 accessibility label。
- 固定按钮增加强调色背景与白色填充图标，未固定恢复普通图标；help 和 accessibility label
  切换为固定 / 取消固定动作，选中状态添加 accessibility selected trait。
- 0.1.6 固定按钮点击立即更新局部 `@State` 并写回原偏好；设置页修改通过偏好通知同步，读取
  当前值避免过期通知覆盖连续点击。取消固定显示灰色，短过渡只作用于按钮，不重建面板。
- `LookupController` 从模式与原文识别计算 `allowThinking`，只有字典模式的标准英文单词或
  既有短中文词识别允许保留；翻译、句子分析及字典模式的其他文本关闭。
- `LLMClient` 接收必填请求策略：DeepSeek 使用 `thinking.type`；DashScope 翻译请求发送
  顶层 `enable_thinking: false`，单词请求保留服务默认值。原配置的 DeepSeek 开关仅作用于
  合格单词请求；关闭思考后温度参数不再被错误省略。
- 重试、剪贴板、自定义 Prompt 使用同一策略；测试连接也关闭思考。未知服务不注入非标准字段。
- 旧取词失效只清除图标，独立的外部 mouse-down 回调才关闭未固定划词面板，mouse-up 和
  应用切换不再触发结果面板关闭。
- 本地 mouse-down 原样传递并保护随后可能全局收到的 mouse-up；全局事件转换屏幕坐标，
  使用 AppKit 最前命中窗口识别本应用，取消过期 AX 读取并保留查询图标输入快照。
- 鼠标按下期间合并推迟流式自动缩放，只保留一个异步等待任务，释放后使用最新内容；
  close / windowWillClose 取消等待，固定面板仍不自动缩放。
- 同步中英文 API 提示、指南与架构。先提供 0.1.3 / build 4 滑块包及 0.1.4 / build 5 扩展包，
  0.1.4 交互复验后继续提供 0.1.5 / build 6 修复包。
  0.1.5 的显示复验失败后继续提供 0.1.6 / build 7。
- 0.1.7 / build 8 在结果面板子类局部覆盖两个 AppKit 活跃外观查询，匹配 EchoType 的
  非激活玻璃行为；未更改真实 key / main 状态、焦点入口、Pin、拖动或对比度采样。
  同步架构和中英文指南，记录未公开接口的维护边界。

### 设计意图

最大高度限制非固定结果面板的自动扩展；以可用屏幕高度为基准，最低为 260 点，溢出结果
在面板内滚动。固定面板保持现有尺寸和位置，不随设置或新结果自动缩放。
独立 Text 使动态数值直接参与 SwiftUI body 更新；不使用随数值变化的 view identity，
避免为刷新文字而重建正在拖动的 Slider。底层 SwiftUI label 缓存原因未直接观测。
按钮使用背景、图标及可访问性状态同时反馈，保留原偏好与固定 frame 逻辑。
原按钮写回偏好后仍依赖异步观察刷新；改为点击直接更新显示状态，同时保持设置页同步。
玻璃材质变化与停滞有关的底层原因未直接观测，保留已验证的自动对比度和原生材质实现。

EchoType 的 `Sources/EchoType/SnapPanel.swift` 为保持活跃玻璃，覆盖 `_hasActiveAppearance`
和 `_hasActiveAppearanceIgnoringKeyFocus`。SDK 26.5 与
[Apple NSGlassEffectView 文档](https://developer.apple.com/documentation/appkit/nsglasseffectview)
没有可直接设置的活跃状态；NSVisualEffectView 的 state 属于另一种材质类。按用户要求复用
这两个局部外观提示，不采用真实激活窗口或持续夺取 key 的方案，保持原键盘焦点和选字资格。
不做系统类 swizzle，也不通过 unsafe IMP 调用扩展兼容层。未公开契约需在系统升级后复验，
若系统不再查询这些 selector，常驻效果可能失效；不声称已保证所有后续系统版本。

当前配置为 DashScope 的 qwen3.8-flash。原实现只过滤输出中的思考文字，未发送 DashScope
开关；[Alibaba 官方文档](https://www.alibabacloud.com/help/en/model-studio/deep-thinking)
确认该模型默认启用思考，REST 字段位于请求顶层。
[DeepSeek 官方文档](https://api-docs.deepseek.com/guides/thinking_mode/)
定义 `thinking.type` 开关。将请求意图独立于 Prompt 和显示过滤传入传输层，避免 few-shot、
自定义提示词及切换模式重试绕过策略。任意兼容协议及仅支持思考的模型没有统一可关闭契约，
不宣称已覆盖；API 提示和指南要求这类接口使用非思考模型翻译句子。

此前 `invalidateSelection()` 同时触发关闭结果，导致 mouse-up / 应用激活等选择失效路径被误作
外部点击；解绑这两个动作，保持内部按钮与拖动的事件边界。
[Apple 事件监视契约](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/EventOverview/MonitoringEvents/MonitoringEvents.html)
区分全局与本地事件。本地监视器原样返回鼠标事件，不发送或拦截键盘。
[AppKit 命中窗口查询](https://developer.apple.com/documentation/appkit/nswindow/windownumber(at:belowwindowwithwindownumber:))
用于排除真正的本应用表面，避免按被遮挡设置窗口矩形误排外部事件。
`pressedMouseButtons` 只用于当前几何更新的暂停条件，不作为历史事件 tracking；
翻译期间不能点击的具体原生事件顺序未观测，除事件分离外同步防止按下期间的 frame 变化。

### 验证

- `scripts/focused/package-app.sh release`：0.1.3–0.1.7 均通过；最新为 0.1.7 / build 8 app 与 ZIP。
- app / 解包 ZIP 的 `codesign --verify --deep --strict`：通过；Info.plist、executable
  一致，独立 bundle ID 保留。
- `scripts/focused/run-tests.sh`：0.1.3–0.1.7 的 8 个既有测试均通过，仅覆盖取消与节流，
  不覆盖本次 UI 或思考策略。
- `plutil -lint Easydict/App/Info.plist`、`git diff --check`：通过。
- 中英文 catalog、SwiftPM 镜像与最新包内字符串逐条一致；`jq -e .` 通过。
- Review：初始工作树与索引干净，基线 HEAD `f12816befc65ab98510cf9312d7d6a79d13b8ab3`；
  冻结 4 个文件及完整 raw diff / SHA-256，检查偏好读写、显示舍入、步长、locale、
  accessibility、范围与版本。无有证据的新增 finding，复验快照不变；现有局部方案足够。
  交付记录后续增量另行检查。
- 扩展后的 Review：冻结 14 个任务文件的完整 raw diff / SHA-256，核对两处 translate 入口、
  mode / 原文策略、自定义 Prompt 与重试路径、官方 REST 开关、host 边界、温度参数和
  状态样式 / 可访问性 / 本地化，无有证据的新增 finding，复验快照不变。
  显式请求策略与局部样式变化的范围和复杂度足够；仅过滤输出不能满足关闭思考目标。
- 用户 0.1.4 手动检查：固定按钮可以变为选中颜色，句子 API 正常返回，确认接口接受新请求；
  取消固定、拖动结束和翻译中点击仍失败。之前没有 finding 的 Review 不代表该场景已验证。
  滑块变化 / 保存仍未明确反馈。CUA 保持停止。
- 0.1.5 构建及 app / 解包 ZIP 签名通过；metadata 与 executable 一致，版本 0.1.5 / build 6
  和独立 bundle ID 正确。
- 0.1.5 Review：冻结 17 个任务文件的完整 raw diff / SHA-256，此前 8 个生产 / 资源文件
  摘要不变；检查三个新增改动模块的完整 diff、调用链与文档增量，核对本地事件原样传递、
  mouse-up 保护、命中窗口 / 坐标、AX generation、查询图标快照、外部关闭条件、几何等待
  合并和取消。无有证据的新增 finding；复验冻结文件与 HEAD / 空索引不变。
  局部事件分离比关闭全部自动消失或增加键盘 / 事件注入更适合请求范围。
- 用户 0.1.5 现场复验：翻译期间固定可操作、拖动后不再消失；玻璃稳定后按钮颜色仍停留在
  选中状态，但实际取消固定生效。滑块变化 / 保存和外部点击仍未明确确认，CUA 保持停止。
- 0.1.6 Release 构建、app / 解包 ZIP 的 deep / strict 签名通过；版本 0.1.6 / build 7、
  独立 ID、metadata / executable 一致性通过。包内中英文镜像一致、SDK 26.5；8 个既有测试、
  plist lint / diff whitespace 通过。包资源检查首次因检查路径错误失败，修正路径后通过。
- 0.1.6 Review：冻结 17 个文件的完整 raw diff / SHA-256，12 个文件与上一快照相同；
  复核按钮和版本的完整差异及文档增量，检查同步显示 / 写回、通知顺序、快速切换、设置页
  同步、appearance 变化、样式 / 可访问性与局部动画，无有证据的新增 finding。
  复验冻结文件、HEAD 与空索引不变。当前局部方案比重建面板或添加重绘干预更适合范围；
  玻璃稳定后的现场反馈待用户复验，Review 不作为 UI 实际通过证据。
- 不新增或扩写测试；完整 Xcode build/test 当前不可用。
- 用户 0.1.6 概括确认目前基本没有问题，但未逐项列出滑块保存 / 外部点击；0.1.7 常驻玻璃
  实现已落地。
- 0.1.7 Release、app / 解包 ZIP 签名、版本 / 独立 ID、metadata / executable、中英文资源
  一致性通过；SDK 26.5，8 个既有测试、plist lint / diff whitespace 通过。本机只读查询
  NSWindow 两个方法的运行时签名均为 `B16@0:8`，符合无参数 Bool 方法；未创建窗口或操作
  桌面，CUA 未重新启用。
- 0.1.7 Review：冻结 17 个任务文件、完整 raw diff / SHA-256，10 个文件与上一快照不变。
  核对面板与版本的完整差异、EchoType 源码、SDK / 运行时签名与文档增量；检查局部覆盖、
  真实焦点 / show 入口、Pin / 文字选择身份和升级边界，无有证据的新增 finding，复验快照、
  HEAD 和空索引不变。局部提示满足本机实现目标且不增加真实激活调用，实际外观与焦点
  仍需现场确认，编译 / 方法签名不能代替。
- 用户对 0.1.7 表示认可，并明确要求 fork、提交、push 和发布当前代码；本实现任务按当前
  版本验收归档，远程交付由独立 0.1.7 发布计划记录。整体认可不作为新增分项场景证据。

### 受影响文件

- `Easydict/Swift/Focused/View/FocusedSettingsView.swift`
- `Easydict/Swift/Focused/View/{ResultContentView,APISettingsView}.swift`
- `Easydict/Swift/Focused/Service/{LookupController,LLMClient}.swift`
- `Easydict/Swift/Focused/App/FocusedApplication.swift`、`Selection/MouseSelectionMonitor.swift`、`View/ResultPanel.swift`
- `Easydict/App/{Info.plist,Localizable.xcstrings}`
- `Easydict/Swift/Focused/Resources/{en,zh-Hans}.lproj/Localizable.strings`
- `docs/user-docs/{en,zh}/GUIDE.md`、`docs/design-docs/application-architecture.md`
- 本任务 plan / history

### 后续事项

- 用户已认可当前版本并要求发布；滑块保存、外部点击、0.1.7 焦点 / 选字未逐项明确反馈，
  后续验证仍应覆盖这些场景，不把整体认可当作独立通过。
- 常驻玻璃使用与 EchoType 一致的未公开 AppKit 查询，系统升级后需复验。
- 思考字段检查依据代码与官方契约；目前未观测实际服务返回的 reasoning token 计数。
- 极短中文词识别是既有长度 / 字符规则，不能语义区分极短句子；翻译和句子分析模式总是关闭。
