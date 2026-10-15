## 2026-10-15 | 任务：增加复制动作翻译开关与语言过滤

**Links:** [执行计划](../../exec-plans/completed/2026-10/2026-10-15-copy-action-translation.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode Unknown (CLT-only)`

### 用户请求

在 feat/streamlined-llm-fork 增加复制动作自动翻译开关，并查看现有中英文识别和排除语言机制。

### 变更

- 新增默认关闭的外部 ⌘C 自动翻译及独立排除语言，使用现有 Language.detect 的系统本地识别。
- 只为每次复制最多等待一秒的新文本写入，形成不可变 LookupInput；复用翻译模式和单结果面板，保留原剪贴板。
- 后续按键、鼠标、应用切换、显式查询和关闭开关取消等待读取；未获取文本时保留当前翻译流。
- 外部前台进程与本应用 key window 双重检查，避免非激活结果面板中的复制触发新翻译。
- 同步设置、英中资源、Xcode 工程、架构和使用说明，没有新增测试。

### 设计意图

复制监听独立于 AX 划词读取，只观察用户的复制按键，不模拟复制或持续轮询剪贴板。
自动语言排除不改变手动菜单行为。权限授权后在应用切换时重试安装观察，停止时清理监听与任务。

### 验证

- 基线及最终 `scripts/focused/run-tests.sh`：8 项测试通过。
- `scripts/focused/package-app.sh release`：成功。
- `codesign --verify --deep --strict dist/easydict-lite.app`：通过；`LC_BUILD_VERSION` sdk 为 26.5。
- 主 String Catalog 与两个 SwiftPM 语言镜像逐项一致，`git diff --check` 通过。
- 使用 review 技能审查并修复非激活窗口复制归属问题，最终增量审查没有其他 finding。
- 手动检查：已重启 dist 应用并确认进程；CUA 读取无可见窗口的菜单栏应用时返回 timeoutReached，未完成真实跨应用复制和语言过滤验证。
- 完整 Xcode build/test 未执行：当前只有 Command Line Tools；SwiftPM 不能替代该验证。

### 受影响文件

- `Easydict/Swift/Focused/Selection/CopyActionMonitor.swift`
- `Easydict/Swift/Focused/App/FocusedApplication.swift`
- `Easydict/Swift/Focused/Model/FocusedPreferences.swift`
- `Easydict/Swift/Focused/View/FocusedSettingsView.swift`
- `Easydict/Swift/Focused/Service/LookupController.swift`
- `Easydict/App/Localizable.xcstrings` 与两个 SwiftPM 字符串镜像
- `Easydict.xcodeproj/project.pbxproj`
- `README.md`、`README_ZH.md`、两份 GUIDE 和应用架构文档
- 本 history 与归档执行计划

### 后续事项

- 实测开关、排除语言、复制结果不回环、重复复制、延迟写入、菜单手动翻译、多屏和权限变化；菜单/右键复制自动触发不在本次范围。
