# easydict-lite

基于 [Easydict](https://github.com/tisfeng/Easydict) 的精简本地分支，仅保留 **鼠标划词、显式剪贴板翻译、OpenAI 兼容 API 和 DeepSeek**。

[English](README.md) · [使用与构建指南](docs/user-docs/zh/GUIDE.md)

## 功能

- 在其他应用选中纯文本，点击查询图标查词或翻译。
- 从菜单栏执行剪贴板长文本翻译。每次仅读取一次，翻译不改变剪贴板，点击「复制结果」可显式复制回答。
- macOS 26+ 原生 Liquid Glass 单一悬浮面板，支持文本选择、滚动、复制、停止、重试和固定。
- 根据本地背景亮度自动切换深浅文字，支持可选屏幕录制权限及手动文字颜色。
- 两类 API 通道，分别通过钥匙串保存密钥。
- 保留翻译、查单词、句子分析和自定义提示词。
- 请求取消、过期响应隔离、UTF-8 流式缓冲和不完整结果提示。

已移除 OCR、截图翻译、音频、离线词典、其他服务集成、全局快捷键、模拟复制、文本替换、浏览器脚本、遥测和原项目更新器。仅保留 Alamofire、Defaults、SFSafeSymbols 三个运行时 Swift 包依赖。

## 构建与运行

需要 macOS 26+、Swift 6.2+ 和 macOS 26 或以上 SDK。SwiftPM 本地构建无需完整 Xcode。

```bash
scripts/focused/package-app.sh release
open "dist/easydict-lite.app"
scripts/focused/run-tests.sh
```

脚本还会生成 `dist/easydict-lite.zip`。可将 `easydict-lite.app` 移入 Applications，与原 Easydict 并存。

脚本会在 Command Line Tools 环境优先使用已安装的 macOS 26 SDK，绕过 macOS 27 CLT SDK 缺少 SwiftUI 宏插件的问题。打包时记录真实 SDK 版本并使用稳定的本地 ad-hoc 签名，不覆盖已安装 Easydict。分支使用独立 bundle ID `org.easydict.focused`、偏好和钥匙串条目。

设置中选择通道、填写模型并保存密钥；测试连接仅发送固定简短示例。鼠标划词需要辅助功能权限，剪贴板翻译无需该权限。自动背景文字对比度使用可选屏幕录制权限，在「设置 → 窗口」显式启用；翻译本身不依赖该权限。无权限时可手动选择深色或浅色文字，自动模式暂时跟随系统外观。背景图片仅在本地内存处理，不保存或发送给 API。

## 限制与验证

仅通过辅助功能读取所选文字，部分应用、PDF 阅读器和网页不提供所选文字，可使用显式剪贴板翻译。查词结果由 LLM 生成，不是经过验证的词典数据库结果。

原文完整发送，超过 2 MiB 时明确报错，不静默截断。模型上下文限制由服务端决定。响应上限为 8 MiB，输出截断或流式中断会保留已接收的结果并提示。停止会取消本地请求，但不保证供应商停止生成或计费。

保留的八个请求取消与节流测试通过。新选择、剪贴板、网络和 UI 路径尚缺专属回归测试。完整 Xcode、真实 API、辅助功能取词、悬浮面板焦点和视觉、睡眠唤醒及长时间使用检查仍需在目标环境验证；实际证据见[任务 history](docs/histories/2026-10/2026-09-30-streamlined-llm-fork.md)。

## 开发

在 Xcode 26+ 中打开 `Easydict.xcworkspace`，使用 `Easydict` scheme。增加或删除 Swift 源码后执行：

```bash
python3 scripts/focused/generate-project.py
```

请阅读 [AGENTS.md](AGENTS.md) 和 [CONTRIBUTING.md](CONTRIBUTING.md)。既有历史与专题文档保留原项目背景，不代表精简分支当前功能。

## 许可证与致谢

采用 GPL-3.0，保留 [LICENSE](LICENSE)。基于 tisfeng 及贡献者开发的 Easydict，原项目受 Bob 和 Saladict 启发。保留 Prompt 示例、取消控制和节流实现的原始署名。悬浮面板与背景对比度行为参考 EchoType，使用公开 AppKit 和 ScreenCaptureKit API，不包含私有外观覆盖。
