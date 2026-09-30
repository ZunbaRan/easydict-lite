# 设计文档

本目录统一保存 Easydict 的产品与技术设计，以及需要长期维护的设计决策。当前 Agent 执行规则
仍以根 `AGENTS.md` 和 `docs/agents/` 为权威；任务进度和完成结果分别位于
`docs/exec-plans/` 与 `docs/histories/`。

## 产品与技术设计

- [`application-architecture.md`](application-architecture.md)：当前源码布局、运行时边界和
  验证入口。
- [`app-path-management.md`](app-path-management.md)：原项目本地文件布局的历史设计，当前精简运行时不使用。
- [`select-text-flow.md`](select-text-flow.md)：原项目文本选择回退流程的历史设计，当前分支不使用复制回退。

产品与技术设计随实现更新；长期设计决策保留状态、日期、背景、取舍和重新评估条件。本目录
不保存任务日志或公共使用说明，也不作为第二套 Agent 任务路由。

- [`upstream-swift-migration.md`](upstream-swift-migration.md)：上游迁移历史，旧功能的剩余迁移事项不属于精简分支。
