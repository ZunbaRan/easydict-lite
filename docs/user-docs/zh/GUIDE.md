# Easydict Lite 使用指南

## API 配置

点击菜单栏图标打开设置，在 API 中选择 OpenAI 兼容接口或 DeepSeek。填写模型名称；兼容接口支持完整 Chat Completions 地址或 Base URL。要求 HTTPS，本机 loopback HTTP 服务除外。本分支不支持 Responses API 或非 OpenAI 协议。

填写 API Key 后点击保存密钥，两种通道分别使用钥匙串保存。本地服务可以不填写密钥。测试连接仅发送固定简短示例。默认使用流式输出，也支持返回普通 JSON 的接口。不支持温度参数的模型请关闭温度选项。DeepSeek 可以切换思考模式，思考内容不显示。

## 鼠标划词

在通用中启用查询图标，并在系统设置授予辅助功能权限。选中文本后点击图标才发送请求。语言过滤与最短长度控制图标显示，长文本默认走翻译。

仅通过辅助功能读取文字，不模拟复制、不执行浏览器脚本。不支持取词的应用可使用剪贴板翻译。

## 剪贴板翻译

使用来源应用正常的复制功能，然后点击菜单栏「剪贴板翻译」。应用仅在此时读取一次纯文本，完整发送，保留剪贴板原内容。剪贴板结果保持打开直到关闭。

输入上限 2 MiB，超出时在发送前明确报错。模型上下文错误正常显示，不自动分块或静默截断。答案不完整时保留部分结果并提示。

## 结果面板与提示词

面板显示时不抢占键盘焦点，点击结果可选择文字。复制结果仅写入当前回答；停止取消本地请求；重试使用捕获的原文而非最新剪贴板。切换模式会请求翻译、查单词或句子分析。固定让划词结果在点击其他应用后继续保留。面板随结果增高，到达设置上限后滚动。

保留内置 Prompt 示例。自定义提示词替代内置提示词，支持 `${{queryText}}`、`${{queryFromLanguage}}`、`${{queryTargetLanguage}}` 和 `${{firstLanguage}}`。查词由 LLM 生成，不访问词典数据库。

## 开发者构建

```bash
scripts/focused/package-app.sh release
scripts/focused/run-tests.sh
open "dist/Easydict Lite.app"
```

要求 macOS 26+、Swift 6.2+、macOS 26+ SDK。Xcode 使用 `Easydict.xcworkspace` / `Easydict`。修改源码清单后执行 `python3 scripts/focused/generate-project.py` 更新工程引用。

应用使用独立本地身份，不连接原项目更新器。八个现有测试覆盖请求取消控制和节流。真实服务、视觉/焦点、辅助功能、睡眠唤醒及长时间使用需要目标环境，构建成功不代表这些检查通过。
