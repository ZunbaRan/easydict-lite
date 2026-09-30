# 构建与测试

精简分支使用 SwiftPM 和一个生成的 Xcode 工程，最低 macOS 26，Swift 6.2+。
本机 Command Line Tools 路径通过打包脚本构建原生应用；完整 Xcode 环境仍可使用 workspace。

## 测试与验证原则

- 只有用户在当前任务中明确要求添加测试，才允许新增或扩写测试，包括测试文件、suite、用例、断言、
  fixture、mock、helper 和仅为测试引入的生产代码 hook；修复 bug、新增功能、修改复杂逻辑和回归
  风险都不构成授权。
- 未获授权时可以运行和分析现有测试，认为需要补充时只在结果中提建议；获授权后优先更新现有用例，
  遵循最小范围，不为测试简单实现增加生产抽象、mock 或 hook。
- 新增服务时，必须新增该服务专属的验证测试文件。服务验证可以依赖实现者本机的 CLI、登录态、密钥或
  其他配置；实现者必须在自己的开发环境中运行并通过该验证。此类环境依赖测试不要求每位开发者或 CI
  持续运行，应通过非默认 test plan 或 Xcode 的精确测试选择运行，且不得将其误认为默认离线回归测试。
- 优先运行直接覆盖变更风险的检查，影响范围不明确时再扩大；只修改已授权的测试与 fixture，不把
  未运行、失败或环境阻塞的检查写成通过。

## 工程与资源

- 源码位于 `Easydict/Swift/Focused`，保留测试位于 `EasydictTests`。
- 增删 Swift 文件时执行 `python3 scripts/focused/generate-project.py`，同步 Xcode group、Sources、
  Resources 与测试 target 引用。工程源清单必须与 SwiftPM 精简 target 一致，不保留悬空引用。
- 主 String Catalog 在 `Easydict/App/Localizable.xcstrings`；SwiftPM `.strings` 镜像必须同步。
- plan、history 和公共 Markdown 不进入运行时资源。

## 选择验证

- 生产源码、资源或依赖实质变化：运行对应 SwiftPM 构建与打包；行为变化运行相关保留测试。
- 修改 Xcode 构建图时，在完整 Xcode 环境运行 `xcodebuild build/test`；环境无 Xcode 时明确记录阻塞，
  SwiftPM 构建不能被汇报为 Xcode 验证通过。
- 包装与玻璃材质变化：运行 Release 打包，`codesign --verify --deep --strict`，检查 `otool -l`
  的 `LC_BUILD_VERSION`，sdk 字段应 ≥ 26。
- UI / AX / 剪贴板行为需要实际场景检查，不以编译或取消控制单测替代。
- 每次修改运行 `git diff --check`；JSON / xcstrings 用 `jq -e .`；Shell 用 `bash -n`。
- SwiftPM 的同一个 `.build` 路径不并发构建；Xcode 构建始终使用 checkout 派生的 agent
  DerivedData，避免与 IDE 同路径构建。

## 常用命令

```bash
scripts/focused/package-app.sh release
scripts/focused/run-tests.sh
python3 scripts/focused/generate-project.py
```

完整 Xcode 环境：

```bash
set -o pipefail
checkout_id="$(git rev-parse --show-toplevel | sed -e "s|$HOME/||" -e 's|/|_|g')"
agent_dd="$HOME/Library/Developer/Xcode/DerivedData/Easydict-Agent/$checkout_id"
xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict -derivedDataPath "$agent_dd"
xcodebuild test -workspace Easydict.xcworkspace -scheme Easydict -derivedDataPath "$agent_dd"
```

CLT 环境下打包脚本优先选已安装的 macOS 26 SDK，避免 macOS 27 SDK 依赖的 SwiftUI 宏插件缺失。
测试脚本按 developer 目录解析 Swift Testing 宏插件。不改变用户全局工具链设置。
