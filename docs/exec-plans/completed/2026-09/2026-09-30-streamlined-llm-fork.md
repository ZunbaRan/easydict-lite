# 精简 LLM 划词与剪贴板翻译分支

- 状态：completed
- 创建日期：2026-09-30
- 负责人：Codex
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 26.6.2 / Xcode Unknown (Command Line Tools / Swift 6.4; build SDK 26.5)`

## 背景

用户需要本地精简分支，仅保留鼠标划词、显式剪贴板长文本翻译、OpenAI 兼容 API、DeepSeek
和核心 Prompt。当前应用的多服务、多窗口、OCR、音频、替换、快捷键及 CLI 运行时超出需求。

## 目标与范围

- 目标结果：可构建和打包的原生 macOS 精简应用，使用单一 Liquid Glass 结果面板。
- 允许修改路径：应用源码及资源、测试构建引用、工程和依赖、构建脚本、公开说明、规则中的架构与构建事实、plan/history。
- 同任务 history：`docs/histories/2026-10/2026-09-30-streamlined-llm-fork.md`
- 用户限制：不保留全局快捷键；剪贴板翻译是必需功能；不 push、不创建远程 fork/PR、不发布。
- 非目标：OCR、音频、本地词典、第三方非兼容 API、文本替换、浏览器脚本、键盘模拟、遥测。
- 验收标准：仅两种入口和两类 API 通道；用户显式 Copy 之外不修改剪贴板；取消和过期响应隔离；长文本不静默截断；单面板与必要设置；移除旧构建图和依赖。

## 工作计划

1. 保留可复用 Prompt、节流与请求取消逻辑，建立精简应用构建图和独立身份。
2. 实现 AX-only 鼠标划词、显式剪贴板入口、请求协调和两类 API 通道。
3. 实现公开 API Liquid Glass 面板与紧凑设置。
4. 验证替代路径，删除不再使用的源码、资源、依赖和测试引用。
5. 更新公开文档，完成 review、history、计划归档和本地提交。

## 风险与决策

- AX-only 不保证所有应用支持；不通过复制模拟补足覆盖率。
- 单独 bundle ID、数据目录和凭据服务，避免覆盖原 Easydict 偏好与授权。
- 使用公开玻璃 API，不移植 EchoType 私有方法与屏幕采样。
- 环境无 Xcode；使用 SwiftPM 与实际 SDK 验证构建及现有 Swift Testing 测试，保留 Xcode 工程供完整 Xcode 环境使用。
- 未获明确新增测试授权，不新增或扩写测试；运行保留的现有测试及手工检查，记录覆盖缺口。
- 不承诺缺陷比例或供应商端取消效果。

## 进度

- [x] 精简构建图和核心模型。
- [x] 选择与剪贴板路径。
- [x] API、Prompt 和请求生命周期。
- [x] 面板与设置。
- [x] 清理与验证。
- [x] review、history、归档、提交。

## 验证

- `scripts/focused/package-app.sh release`：最终源码构建、打包、ad-hoc 签名和严格验证通过；Debug 构建也通过。
- `scripts/focused/run-tests.sh`：保留的 8 个测试、2 个 suite 全部通过；未新增或扩写测试。
- `plutil`、`jq -e .`、`bash -n`、`git diff --check`：通过。
- 工程静态检查：23 个 Swift 源文件与 SwiftPM 一致，无悬空引用；英文与简体中文资源镜像一致。
- `otool -l`：Release 二进制 `minos 26.0 / sdk 26.5`；Release 应用进程启动成功。
- `review`：基线至工作树的完整 raw diff、删除/未跟踪清单和内容摘要已采集；检查核心调用链及增量后无遗留有效 finding。
- 已修复审查发现：完整回答的尾部 `<` 不再被流式标签缓冲吞掉；补齐原生文本编辑菜单；拒绝 API 重定向；响应字节上限在生产者进入 async 缓冲前生效。
- UI automation 初始连接超时，最终 Release 新实例启动后恢复；四个设置 tab、两项通道菜单、
  原生 Edit 菜单和 General / API 布局检查通过。悬浮面板视觉/焦点、辅助功能和剪贴板场景仍未验证。
- 未执行真实供应商调用、完整 Xcode、睡眠唤醒、多屏及长时间使用验证；未读取用户剪贴板、导入密钥或自动授予权限。
- 初始工作树干净；基线 `e4882f168fec6b19a7f682f8ed05ecbdc98b970c`。
- `xcodebuild -version`：环境阻塞，只有 Command Line Tools。

## 完成条件

- 两种入口、长文本和 API 配置完整；旧功能不进入运行时或构建图。
- 可用环境的构建、保留测试、静态校验通过；环境与人工验证限制如实记录。
- 适用 review 完成，有效 finding 修复并复验；history 与计划归档完成，本地提交核验。

完成记录见 [history](../../../histories/2026-10/2026-09-30-streamlined-llm-fork.md)。
