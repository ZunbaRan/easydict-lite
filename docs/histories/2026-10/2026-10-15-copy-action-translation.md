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

### 用户复测后的修正

- 用户报告新语言选项选择中文后仍显示不过滤语言，复制英文未触发。
- 已在真实设置界面复现：旧点号 key 保存成功，但 Defaults 的 KVO key-path 观察不支持点号，UI 和开关初始通知回退默认值。
- 新增的两个复制偏好改为合法 camelCase key，以旧值作为兼容默认值；新键的显式保存值优先。其他既有设置不迁移。
- 语言从英语切换回简体中文、开关关闭再开启的页面更新均已通过 CUA 确认；重启后保留用户原中文过滤和开启状态。
- 移除 NSApp.keyWindow 引用过滤，改由本地 keyDown 观察取消应用自身按键的复制等待，避免后台设置窗口阻止外部复制。
- session tap 在回调记录基线后原样放行事件，不删除、改写或模拟输入；Apple API 允许 active filter 原样放行，见 [CGEventTapOptions](https://developer.apple.com/documentation/coregraphics/cgeventtapoptions)。
- 增加原生应用菜单的设置入口与 ⌘,，便于再次打开设置进行核验。
- 临时诊断确认开关实际值、初始通知和 AX 权限均为 true，事件 tap 创建成功；CUA 后台输入没有进入系统全局事件链路，不能替代真实按键验证。

- 新增逻辑再次经过 review，未发现其他有效 finding；保留 8 项测试通过，未新增或扩写测试。
- 临时诊断在最终构建前全部删除。真实全局按键已请求用户确认，未收到结果；不能把后台 UI 输入或编译成功汇报为全局触发实测通过。

### 统一窗口驻留规则

- 用户确认真实 ⌘C 唤出翻译已经正常，并要求 Easydict 与 EchoType 采用相同的 Pin / 未 Pin 驻留规则。
- 划词与剪贴板结果统一：Pin 常驻；未 Pin 在请求结束、失败或停止后闲置 10 秒自动隐藏；流式期间不计时。
- 悬停、选字拖动和 live resize 续期计时；外部点击不再立即关闭结果窗口；明确关闭仍取消请求，复制或查询可再次唤出。
- 控制器观察请求状态与 Pin 变化，定时回调再次检查当前状态；关闭或固定时清理计时器。异步通知读取当前值，避免快速重试或固定被过期值覆盖。
- Pin 改用合法 Defaults key，并以旧键值作为兼容默认值；英中设置文案、主 String Catalog、镜像、README、指南和架构同步。
- 基线与最终 `scripts/focused/run-tests.sh`：8 项通过；没有新增或扩写测试。Release 打包与严格签名校验通过，sdk 26.5。
- 两项只读审查无有效 finding；计时、悬停和选字拖动未实际计时验证，完整 Xcode 不可用，未将编译或保留测试写成 UI 验证通过。
