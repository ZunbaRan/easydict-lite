## 2026-10-01 | 任务：根据背景自动调整浮窗文字对比度

**Links:** [执行计划](../../exec-plans/completed/2026-10/2026-10-01-adaptive-panel-contrast.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 26.6.2 / Xcode Unknown (Command Line Tools only)`

### 用户请求

参考 EchoType，让 easydict-lite 在亮背景上显示深色文字、暗背景上显示浅色文字。
用户要求继续实现；保留透明度及固定位置，停止并不重新调用 CUA。

### 变更

- 新增 View 边界的 BackdropAppearanceController，使用公开 ScreenCaptureKit 裁剪面板区域，
  排除本应用、光标与音频，输出最长边 64 像素的背景图，在局部内存缩减为亮度后丢弃。
- 可见面板每 1.5 秒刷新，同一时刻只有一个未完成的采样；显示立即刷新，隐藏取消，移动、
  缩放和偏好变更使旧结果失效。元数据缓存最多 5 秒；采样失败保留上次成功的外观。
- 初次亮度阈值为 0.5，之后用 0.4 / 0.6 滞后区间避免轻微背景变化造成频繁翻转。
  AppKit appearance 与 SwiftUI colorScheme / primary、secondary 语义颜色同步。
- Window 设置提供自动、深色文字、浅色文字三种模式。自动模式检查额外 Screen Recording
  权限，只在用户点击启用按钮时请求；无权限跟随系统外观，手动模式不截图。
- 新增中英文权限描述与设置文本，同步 SwiftPM 镜像及主 bundle 的 InfoPlist.strings。
  更新公开文档和架构，生成 Xcode 引用；版本为 0.1.2 / build 3。
- 独立 bundle ID、Keychain、透明材质 / tint、固定 frame、剪贴板及请求行为保持原语义；
  无新外部 Swift 包，无新增或扩写测试。

### 设计意图

系统外观不能代表浮窗下面网页或文稿的亮度。EchoType 的显式明暗采样行为提供参考，
本次独立使用当前公开 [ScreenCaptureKit](https://developer.apple.com/documentation/screencapturekit)
实现，不采用其私有外观 selector 或旧截图 API。
Apple 要求屏幕录制权限，因此将该能力与取词 / 翻译权限分离，不在启动或选择时弹出授权。
截取数据不进入翻译模型或网络层，低分辨率和单任务限制约束资源占用；单一控制器足够承载此逻辑。

### 验证

- `scripts/focused/package-app.sh release`：通过，独立 app 与 ZIP 已生成。
- `scripts/focused/run-tests.sh`：2 个 suite / 8 个既有测试通过；仅覆盖请求控制和节流。
- app / 解包 ZIP 的 `codesign --verify --deep --strict`：通过；metadata、executable、
  中英文权限描述一致。`otool` 显示 SDK 26.5、minimum 26.0，并链接 ScreenCaptureKit。
- 本地化与构建图检查：英文 / 简体中文的主目录、SwiftPM 镜像、包内 UI 字符串及主 bundle
  permission strings 一致，Info.plist 基础权限描述与英文一致。Xcode / SwiftPM 的 25 个
  app Swift 来源一致，新增 InfoPlist.xcstrings 进入资源 phase。
- `plutil -lint`、`jq -e .`、`bash -n`、Python 编译、`git diff --check`：通过。
- Review 技能：基线 HEAD `0478483f76fdf77302ebc404e0f6414fed7d50e4`，初始工作树干净；
  冻结完整 raw diff、候选清单与 SHA-256，检查请求生命周期、可见性、权限预检与显式授权入口、
  自身排除、主屏坐标转换及交叉屏裁剪、RGBA 亮度、滞后、固定 frame 和 SwiftUI 颜色传播。
  未发现有证据的新增 finding；系统外观或仅调整 tint 不能满足背景适配目标，当前公开 API
  控制器的范围与复杂度适合该需求。冻结文件复验不变，交付文档增量另行审查。
- 用户手动检查：提供 0.1.2 新包和权限启用步骤后，用户明确回复 “The text switches correctly”，
  确认亮背景 / 暗背景上的基本文字切换正确。该证据来自用户现场反馈；Agent 按要求未调用
  CUA、未读取桌面图片、未请求 / 授予权限，也未观测系统权限提示。
- 多屏、睡眠唤醒、长时间运行和完整 Xcode build/test 未验证；保留测试不覆盖新 UI 路径。

### 受影响文件

- `Easydict/Swift/Focused/View/{BackdropAppearanceController,PanelContrastSettingsView,ResultPanel,ResultContentView,FocusedSettingsView}.swift`
- `Easydict/Swift/Focused/Model/FocusedPreferences.swift`
- `Easydict/App/{Info.plist,InfoPlist.xcstrings,Localizable.xcstrings}`
- `Easydict/Swift/Focused/Resources/{en,zh-Hans}.lproj/Localizable.strings`
- `Package.swift`、`Easydict.xcodeproj/project.pbxproj`、`scripts/focused/{generate-project.py,package-app.sh}`
- `README.md`、`README_ZH.md`、`docs/user-docs/{en,zh}/GUIDE.md`
- `docs/design-docs/application-architecture.md`、本任务 plan / history

### 后续事项

- 基本亮暗背景切换已获用户确认；拖动后刷新、固定时背景变化及长输出滚动组合场景尚未
  在本任务中单独验证。
- 无屏幕录制权限时，手动深色或浅色文字可用于保持可读性；自动模式只能跟随系统外观。
- 跨屏面板按交集最大的显示器采样；混合背景使用整体平均亮度，不逐字逐像素反转。
- 完整 Xcode 及目标环境的 UI / 多屏 / 长时间检查待执行，不能将既有测试当作新行为的场景验证。
