# API 通道

easydict-lite 只提供两个通道，每次查询使用一个活动通道：

| 通道 | 配置 |
| --- | --- |
| OpenAI 兼容接口 | Chat Completions 地址或 Base URL、模型、可选 API Key |
| DeepSeek | 官方请求地址、可编辑模型、API Key、可选思考模式 |

两种通道共享请求取消、流式解码和 Prompt。温度参数可选。不包含其他供应商适配、本地词典、语音或 CLI 运行时。本机兼容模型服务可使用 loopback HTTP 地址。

设置与限制见[指南](GUIDE.md)。DeepSeek 的[思考模式文档](https://api-docs.deepseek.com/guides/thinking_mode/)定义通道专有的请求参数，模型名称可编辑。
