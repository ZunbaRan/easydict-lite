# API channels

Easydict Lite has two channels, with one active channel per lookup:

| Channel | Configuration |
| --- | --- |
| OpenAI-compatible | Chat Completions URL or base URL, model, optional API key |
| DeepSeek | Official endpoint preset, editable model, API key, optional thinking mode |

Both share request cancellation, streaming decoding, and the same prompt builder. Temperature is optional. No other provider adapters, local dictionaries, speech, or CLI runtimes are included. Compatible local model servers may be configured using a loopback HTTP URL.

See the [guide](GUIDE.md) for setup and limits. DeepSeek's [thinking-mode documentation](https://api-docs.deepseek.com/guides/thinking_mode/) defines the provider-specific request switch; model names remain editable.
