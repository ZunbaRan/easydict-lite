# 根据浮窗背景自适应文字对比度

- 状态：completed
- 创建日期：2026-10-01
- 负责人：Codex
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 26.6.2 / Xcode Unknown (Command Line Tools only)`

## 背景

clear Liquid Glass 已达到用户期望的透明度，但文字仍跟随系统外观，浅色背景上白字难以阅读。
用户要求参考 EchoType 的背景明暗适配，并明确继续实现。用户已要求停止 CUA，不再使用它验证。

## 目标与范围

- 目标结果：亮背景使用深色文字、暗背景使用浅色文字；固定位置、滚动及透明度保持现有语义。
- 允许修改路径：Focused 的 View / Model / Resources，App 的权限描述与版本，SwiftPM / 生成的
  Xcode 构建图、打包脚本、当前架构与使用说明、本任务 plan / history。
- 同任务 history：`docs/histories/2026-10/2026-10-01-adaptive-panel-contrast.md`
- 用户限制：不调用 CUA，不替换原 Easydict，不读取 API 密钥，不自动授予屏幕录制权限。
- 非目标：OCR、截图翻译、网络传输背景像素、私有外观 selector、自动安装或发布。
- 验收标准：异步且有界的本地背景采样排除本应用；仅显示时采样，关闭后停止；旧采样不得
  应用到移动后的面板；亮暗阈值有滞后避免抖动；无权限时可手动选择文字颜色；完整本地打包。

## 工作计划

1. 建立独立浮窗对比度控制器，使用公开 ScreenCaptureKit 与语义文字色。
2. 接入显示、移动、关闭与偏好变更，增加简短设置和权限说明，同步本地化与构建图。
3. 运行 Release 打包、保留测试及签名 / SDK / 本地化检查。
4. 使用 review 技能审查冻结差异，处理有效 finding；记录实际验证边界，完成并归档后本地提交。

## 风险与决策

- 初始 HEAD：`0478483f76fdf77302ebc404e0f6414fed7d50e4`，初始 staged / unstaged / untracked 均为空。
- EchoType 的实现仅供行为参考；重新用当前公开 API 实现，不复制私有 selector 或旧截图 API。
- Screen Recording 是背景适配的额外可选权限；只在用户点击设置按钮时请求，取词和翻译不依赖它。
- 仅在内存处理面板区域的低分辨率像素，返回亮度而非图片；不保存，不传给 LLM。
- 不新增或扩写测试；当前规则要求明确授权才可添加。新类型属于 View 控制器，不新增翻译服务。
- CUA 保持停止；实际背景切换、权限提示、多屏及长时间运行需用户手动检查，不声称编译代替 UI。

## 进度

- [x] 完成执行前规则与 EchoType / SDK 调查。
- [x] 实现控制器、生命周期及本地化设置。
- [x] 构建、测试、打包及 Review 完成。
- [x] 用户确认真实亮暗背景切换；记录结果，归档并按自动本地提交规则交付。

## 验证

- 环境：macOS 26.6.2，`xcodebuild -version` 确认只有 Command Line Tools。
- `scripts/focused/package-app.sh release`：通过，生成 0.1.2 / build 3 的 app 和 ZIP。
- `scripts/focused/run-tests.sh`：2 个 suite / 8 个既有测试通过，无测试文件修改。
- app 和解包 ZIP 的 `codesign --verify --deep --strict` 通过；解包 executable、metadata 和
  permission strings 与构建产物一致。`LC_BUILD_VERSION` minimum / SDK 为 26.0 / 26.5。
- 英文 / 简体中文主目录、SwiftPM 镜像、包内 UI 文字和主 bundle 的 InfoPlist.strings 一致。
- 生成 Xcode 工程的 25 个 Swift 来源与 SwiftPM 一致，InfoPlist.xcstrings 已进入资源 phase；
  `plutil -lint`、`jq -e .`、`bash -n`、Python 编译及 `git diff --check` 通过。
- Review：冻结初始 HEAD、完整 raw diff、21 个候选文件及 SHA-256；审查权限入口、采样排除、
  单任务限制、移动 / 关闭失效、坐标转换、语义文字色与已有固定路径。无有证据的新增 finding。
  原冻结内容复验不变，最后 plan / history 文档增量另行检查。
- 用户手动检查：提供新包与显式权限启用步骤后，用户明确回复 “The text switches correctly”，
  确认基本亮暗背景切换正确；该结果属于用户现场反馈，Agent 未调用 CUA 或读取桌面图片。
- Agent 未请求或授予 Screen Recording 权限、未观测系统权限提示。多屏、睡眠唤醒、长时间
  运行和完整 Xcode build/test 未验证。现有测试不覆盖这条新 UI 路径。

## 完成条件

- 实现、打包与必要检查完成，Review 没有未处理的有效 finding。
- 用户确认基本亮暗切换，或明确说明暂不执行该验证；不能仅凭编译将实际 UI 标为通过。
- history 记录新权限及未验证的真实 UI 场景；plan 归档并创建本地提交。
