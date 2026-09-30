# 执行计划

本目录保存执行模式下的多步骤、跨模块或高风险任务计划：

- `active/`：进行中的计划。
- `completed/YYYY-MM/`：按计划文件名月份归档的已完成计划。
- `templates.md`：新计划模板。

## 创建与归档

- 多步骤、跨模块或高风险的执行任务在 `active/` 使用 [`templates.md`](templates.md)；
  完成后按文件名月份移动到 `completed/YYYY-MM/`。
- 新计划从当前模板创建，保留模板中的必填字段、章节和顺序。

## 内容

- plan 记录目标、范围、步骤、风险和验证。
- 文件命名与 slug 规则（含同一任务与 history 共享 slug）见
  [`../histories/README.md`](../histories/README.md#命名与-slug)。

上游 Objective-C-to-Swift 长期迁移路线图已作为
[历史参考](../design-docs/upstream-swift-migration.md) 保存；精简分支使用纯 Swift 运行时，
旧功能的剩余迁移事项不构成当前任务。
