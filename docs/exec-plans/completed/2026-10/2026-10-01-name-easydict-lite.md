# easydict-lite 独立命名与打包

- 状态：completed
- 创建日期：2026-10-01
- 负责人：Codex
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 26.6.2 / Xcode Unknown (Command Line Tools / Swift 6.4; build SDK 26.5)`

## 背景

用户已有本地 Easydict，要求精简应用使用 `easydict-lite` 名称并独立打包。

## 目标与范围

- 目标结果：`dist/easydict-lite.app` 和本地 ZIP，名称、可执行文件和 UI 一致。
- 允许修改路径：包/工程元数据、打包脚本、主本地化及镜像、当前公开说明、plan/history。
- 同任务 history：`docs/histories/2026-10/2026-10-01-name-easydict-lite.md`
- 用户限制：不覆盖已安装 Easydict；不执行 push、发布或安装。
- 非目标：翻译逻辑、密钥与偏好迁移、重新命名内部 Swift module。
- 验收标准：独立 bundle ID 与原应用不同，打包/签名通过，安装中原应用文件摘要不变。

## 工作计划

1. 统一产品、可执行文件、输出和 UI 命名。
2. Release 打包、ZIP、静态资源检查及保留测试。
3. 审查命名契约，记录结果，归档计划并本地提交。

## 风险与决策

- 保留 `org.easydict.focused`，与原应用 `com.izual.Easydict` 隔离，并保留精简应用已有偏好/权限身份。
- Swift module 仍为 `Easydict`，使现有测试和资源 bundle 不需要迁移。
- 本机无完整 Xcode；使用 SwiftPM 构建并记录生成工程未运行 Xcode 验证。

## 进度

- [x] 命名同步。
- [x] 打包与验证。
- [x] review、history、归档、提交。

## 验证

- 初始 HEAD `c34e762a0a96800ae83a582f1bb94ad1edd83b18`；索引和工作树干净。
- 已记录原安装应用 Info.plist 和可执行文件的 SHA-256，交付前核对均保持一致。
- Release 打包、原包及解压 ZIP 的严格签名校验、ZIP CRC 校验通过；二进制 minos 26.0 / sdk 26.5。
- 保留的 8 tests / 2 suites 通过；未新增或扩写测试。
- 工程、Shell、JSON、`.strings` 静态校验通过；本地化镜像一致，命名契约一致。
- UI 启动显示 `easydict-lite`，已打开 API 设置。只退出此前的精简开发实例，未退出或替换原 Easydict。
- review：冻结基线和 18 个候选路径，完整 raw diff 与构建/元数据/资源调用契约审查完成；无有效 finding，
  后续增量仅本计划归档与 history。保持内部 module 和既有独立身份足够，不需要迁移凭据或偏好。
- 完整 Xcode 验证因仅安装 CLT 未执行；真实 API、AX 和长文本场景仍属于前次记录的验证缺口。

## 完成条件

- 输出命名、元数据与 UI 一致，签名和保留测试通过。
- 原安装应用未被写入或替换，review、history 和本地提交完成。
