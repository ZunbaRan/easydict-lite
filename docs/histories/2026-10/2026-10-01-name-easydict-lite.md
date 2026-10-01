## 2026-10-01 | 任务：统一 easydict-lite 名称并独立打包

**Links:** [执行计划](../../exec-plans/completed/2026-10/2026-10-01-name-easydict-lite.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 26.6.2 / Xcode Unknown (Command Line Tools / Swift 6.4; build SDK 26.5)`

### 用户请求

用户已有 Easydict，希望精简应用独立使用 `easydict-lite` 名称，并提供可用包，不替换原安装应用。

### 变更

- 同步 SwiftPM 产品、Xcode 产品/可执行文件/TEST_HOST、Info.plist、主 String Catalog 与两种语言
  镜像，公开名称与可执行文件为 `easydict-lite`。
- 打包脚本生成 `dist/easydict-lite.app` 及 `dist/easydict-lite.zip`；ZIP 保留应用顶层目录和签名资源。
- 保留内部 Swift module `Easydict`、独立 bundle ID `org.easydict.focused` 及既有精简偏好/Keychain 身份。
- 同步当前公开说明和架构名称。移除此前由 Agent 生成的 `dist/Easydict Lite.app`，避免本地开发输出
  重名身份造成应用选择歧义；未改动原安装应用。

### 设计意图

用户通过文件名、菜单和进程名即可识别精简应用。保留与原安装应用不同的身份，让两者并存，
同时使精简应用的已有权限、偏好和密钥不因产品重命名而迁移。不自动安装到 Applications。

### 验证

- 初始 HEAD：`c34e762a0a96800ae83a582f1bb94ad1edd83b18`；索引和工作树干净。
- `scripts/focused/package-app.sh release`：通过，生成 app / ZIP。
- `codesign --verify --deep --strict`：原包与 ZIP 解压后的 app 均通过；ZIP CRC 校验通过。
- 包内名称、可执行文件、Info.plist 与生成工程一致；`otool -l`：minos 26.0 / sdk 26.5。
- `scripts/focused/run-tests.sh`：8 tests / 2 suites 全部通过；测试源码未修改。
- `plutil -lint`、`jq -e .`、`bash -n`、`git diff --check`：通过；主本地化与两种镜像一致。
- 原安装 Easydict 的 Info.plist 与可执行文件 SHA-256 交付前后一致。原 bundle ID 为
  `com.izual.Easydict`，精简应用为 `org.easydict.focused`。
- 手动 UI：退出旧精简开发实例后，按新包路径启动，显示 `easydict-lite`，打开 API 设置成功。
  未读取剪贴板、保存密钥或执行真实翻译请求。
- review：冻结基线、候选路径内容摘要和完整 raw diff；检查产品/可执行文件/资源/TEST_HOST/
  ZIP/独立身份的契约，无遗留有效 finding。最终只增加本记录并归档计划，增量已核对。
- `xcodebuild -version`：环境阻塞，只有 CLT；不能宣称生成工程的完整 Xcode 构建/测试通过。

### 受影响文件

- `Package.swift`、`scripts/focused/`、`Easydict.xcodeproj/`
- `Easydict/App/Info.plist`、`Easydict/App/Localizable.xcstrings`、`Easydict/Swift/Focused/Resources/`
- `README.md`、`README_ZH.md`、`AGENTS.md`、当前使用指南/通道说明和应用架构
- `docs/exec-plans/completed/2026-10/2026-10-01-name-easydict-lite.md`、本 history

### 后续事项

- 用户配置 API 通道、模型与密钥并执行连接验证；鼠标划词需用户授予辅助功能权限。
- 再验证短文本/长文本剪贴板翻译和实际鼠标选择。此前 API、AX、悬浮面板焦点/视觉、睡眠唤醒
  及长期使用验证缺口不因重命名或打包而消失。
