<!-- design-interview-policy: design-tree-v1 -->
# 设计访谈

本文件持久保存需求和计划阶段的设计树访谈。事实由 Agent 使用只读源码、文档或 MCP 查询；用户只决定方案。历史尝试不得删除，输入摘要变化后把旧尝试标记为 `superseded` 并追加新尝试。

复杂度字段只使用 `yes`、`no` 或 `unknown`。任一字段为 `yes` 或 `unknown` 时按 `non-trivial`。`lite` 只有全部为 `no` 才能跳过两阶段访谈；`standard` 的非简单需求必须访谈，计划阶段可用计划评审代替第二次访谈；`strict` 的非简单需求和计划都必须访谈。

## requirements/R-001

- status: completed
- provider: grill-me
- provider_version: local-skill
- question_protocol: inline-confirmation-v1
- input_digest: 537c77fd6435fffe237b6a6621390fbcb3ac74d6de12b7933a8ca348bc8fbd38
- started_at: 2026-10-27T16:18:43+08:00
- completed_at: 2026-10-27T16:29:23+08:00
- classification: non-trivial
- classification_reason: 修改浏览器 CORS 安全边界和代理共享响应写出路径，虽然不新增接口字段或数据，但需按安全相关变更使用 strict 档位。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: no
- complexity.database_or_migration: no
- complexity.permission_or_security: yes
- complexity.concurrency: no
- complexity.performance: no
- complexity.multiple_repositories: no
- complexity.external_service: no
- complexity.deployment: no
- complexity.destructive_operation: no
- complexity.uncertain: no

### 问答

| 问题 | 推荐答案 | 用户选择 | 状态 | 确认依据 |
|---|---|---|---|---|
| Q1 原生代理响应头优先级：上游响应头与 BFF 针对当前浏览器生成的 CORS 头同名时，应采用哪一方？ | BFF CORS 头优先；上游其他端到端响应头照常保留，普通代理仍保持流式。 | 按推荐做 | resolved | 用户原话：`自动存审批直到处理完所有任务`，批准当前已完成需求并要求连续处理。 |

设计树已收敛：现有全局 CORS 配置确定 Origin 与凭据策略，用户批准当前需求并要求按计划连续完成；没有开放分支。

### 假设与风险

- Fastify 生成的响应头在直接调用 `reply.raw.writeHead()` 前仍保存在 `reply.getHeaders()` 中；实现测试必须以预置 reply headers 验证这一边界。
- 平台登录失败分支会复制上游端到端响应头；合并顺序必须让 BFF 同名 CORS 头优先，避免上游放宽或污染浏览器边界。
- 普通代理必须继续使用流式 pipeline，修复响应头时不得引入整段缓冲。
- 2026-10-27 16:29 仅把 SR-01/SR-02 调整为框架要求的二级标题，需求语义和用户选择不变，重新核对后仍无未决分支。

## plan/P-001

- status: completed
- provider: grill-me
- provider_version: local-skill
- question_protocol: inline-confirmation-v1
- input_digest: 27c959c77b076aba106ee8b11ca84cd837430b3a01c7098a3abecbf75e50ef8f
- started_at: 2026-10-27T16:22:42+08:00
- completed_at: 2026-10-27T16:23:40+08:00
- classification: non-trivial
- classification_reason: 计划涉及 CORS 安全边界、共享 raw response 写出路径和接管前 dirty 基线，需明确合并优先级与最小测试范围。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: no
- complexity.database_or_migration: no
- complexity.permission_or_security: yes
- complexity.concurrency: no
- complexity.performance: no
- complexity.multiple_repositories: no
- complexity.external_service: no
- complexity.deployment: no
- complexity.destructive_operation: no
- complexity.uncertain: no

### 问答

| 问题 | 推荐答案 | 用户选择 | 状态 | 确认依据 |
|---|---|---|---|---|
| Q2 响应头修复怎样落地且不扩大回归？ | 新增一个纯合并辅助函数，由普通代理和平台登录失败分支共用；BFF 同名头优先，普通正文 pipeline 不变；执行三个定向 spec 与 build，不启动服务。 | 按推荐做 | resolved | 用户原话：`自动存审批直到处理完所有任务`，授权自动保存计划审批并连续完成任务。 |

### 假设与风险

- `adx-bff-backend` 当前存在 011/012 的未提交改动，本轮使用真实仓库共享检出并逐文件保护 dirty 基线。
- 当前没有其他 implement/verify 活动轮次占用同一仓库，因此不创建 worktree。
- 当前授权不包含服务启停，验证边界停在定向单测、build、静态差异和框架校验。
