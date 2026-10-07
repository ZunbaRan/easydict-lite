## 2026-10-07 | 任务：压缩悬浮面板并保存手动宽高

**Links:** [执行计划](../../exec-plans/completed/2026-10/2026-10-07-compact-resizable-panel.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 26.6.2 / Xcode Unknown (Unknown)`（仅 Command Line Tools）

### 用户请求

缩小顶部应用名称和操作栏，把底部复制、重试移到顶部并只显示图标；支持拖拽窗口任意宽高并默认记住尺寸。
用户认可已打包新版后，继续要求复制图标显示 1 秒蓝底勾号反馈，并缩小结果正文。
确认追加优化「完美了」后，明确要求 commit & push，交付到当前 `feat/streamlined-llm-fork` 分支。

### 变更

- 标题使用 12 点字体，顶部按钮统一 24×24 点；复制、重试 / 停止、固定、关闭集中在右侧，
  保留本地化 tooltip、accessibility label 和即时固定反馈。移除底部栏及分割线，减少外层留白。
- 面板保留原生 `.resizable`，关闭 SwiftUI 宿主隐式尺寸约束；宽高默认通过 Defaults 保存，
  用户 live resize 结束才写入，新查询与应用重启恢复。初始 440×320、最小 320×200 点。
- 移除结果订阅触发的自动增高、鼠标释放等待任务和最大高度滑块；长结果滚动，原文展开区域按高度限制。
  小屏约束只影响显示 frame，不覆盖保存的较大尺寸。固定与位置偏好保持独立。
- 同步中英本地化、使用指南和应用架构。生成本地 0.1.8 / build 9 app 与 ZIP。
- 复制成功才显示蓝底白色勾号，使用原生 symbol replace 动画，1 秒后恢复；连续点击取消旧复位任务并
  重新计时，清空结果或视图消失时取消。LookupController 返回实际 NSPasteboard 写入结果，避免虚假成功。
  正文从 15 点改为 13 点，新增中英「已复制」accessibility value；复制失败也会清除旧确认。

### 设计意图

让用户选择的窗口尺寸成为唯一几何来源，避免新查询与流式结果覆盖手动布局。
沿用 AppKit 原生缩放及 delegate 生命周期，比自行处理鼠标拖拽减少事件与焦点风险。
玻璃与对比度、取词监视器、API / Prompt 和剪贴板写入边界均未改动。

Apple 的 [NSHostingView sizingOptions](https://developer.apple.com/documentation/swiftui/nshostingview/sizingoptions)
说明空选项不会创建尺寸约束；[windowDidEndLiveResize](https://developer.apple.com/documentation/appkit/nswindowdelegate/windowdidendliveresize(_:))
对应用户缩放结束，用于只保存手动尺寸。编译通过不代表原生边缘命中或真实窗口场景已经通过。
复制根据 Apple 的 [NSPasteboard.setString](https://developer.apple.com/documentation/appkit/nspasteboard/setstring(_:fortype:))
返回值确认写入成功；图标切换使用公开的 [symbol content transition](https://developer.apple.com/documentation/swiftui/contenttransition/symboleffect)。

### 验证

- `scripts/focused/package-app.sh release`：通过，生成独立 `org.easydict.focused` 应用。
- `codesign --verify --deep --strict`、ZIP 完整性、应用元数据：通过，0.1.8 / build 9。
- 最终 ZIP 解包后的 deep / strict 签名检查通过，二进制与本地 app 一致；
  ZIP SHA-256：`6ebed0c69b7db79fd4dfaf007fa65deb1b8161e59e128f65614ed228fdde1ffb`。
- `otool -l`：最低系统 26.0、SDK 26.5。
- `jq -e .`、`plutil -lint`：通过；98 个中英 catalog 值分别与 SwiftPM 镜像一致。
- `git diff --check`：通过。
- `scripts/focused/run-tests.sh`：既有 2 个 suite、8 个测试全部通过；未新增或扩写测试。
- Review：基线 `960b45457f2d546c04ab56e96034937998557134`，初版 13 路径及追加后的 14 路径内容摘要。
  复核尺寸所有权、保存生命周期、固定、按钮、滚动与复制计时；P2 COPY-FAIL-STALE（写入失败仍保留旧勾号）
  已修复，重新 Release 打包及 8 个既有测试通过，增量复审无剩余有效 finding。
- 手动检查：用户对顶部按钮、边缘缩放、流式尺寸稳定和重启恢复的检查请求反馈「非常棒了」，
  认可当前版本并追加复制动画和正文优化；未单独逐项报告多屏等场景。
  对追加复制动画、约 1 秒复位、重复复制与 13 点正文的检查请求反馈「完美了」。
  最后仅补充失败分支清理，正常成功路径保持一致；未实际触发 pasteboard ownership 竞争。

### 受影响文件

- `Easydict/Swift/Focused/View/{ResultContentView,ResultPanel,FocusedSettingsView}.swift`
- `Easydict/Swift/Focused/Model/FocusedPreferences.swift`
- `Easydict/Swift/Focused/Service/LookupController.swift`
- `Easydict/App/{Info.plist,Localizable.xcstrings}` 与 `Easydict/Swift/Focused/Resources/*/Localizable.strings`
- `docs/design-docs/application-architecture.md`、`docs/user-docs/{en,zh}/GUIDE.md`
- 本 history 及对应执行计划。

### 后续事项

- 完整 Xcode 构建 / 测试不可运行；保留测试不覆盖新 UI 几何。多屏与长期使用需目标环境检查。
- 按用户授权经 git-commit 校验创建提交，并推送至 `origin/feat/streamlined-llm-fork`。
  本轮 GitHub Release 未在请求范围内，本地 0.1.8 产物可直接使用。
