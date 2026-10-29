<!-- design-interview-policy: design-tree-v1 -->
# 设计访谈

本文件持久保存需求和计划阶段的设计树访谈。事实由 Agent 使用只读源码、文档或 MCP 查询；用户只决定方案。历史尝试不得删除，输入摘要变化后把旧尝试标记为 `superseded` 并追加新尝试。

复杂度字段只使用 `yes`、`no` 或 `unknown`。任一字段为 `yes` 或 `unknown` 时按 `non-trivial`。`lite` 只有全部为 `no` 才能跳过两阶段访谈；`standard` 的非简单需求必须访谈，计划阶段可用计划评审代替第二次访谈；`strict` 的非简单需求和计划都必须访谈。

## requirements/R-001

- status: completed
- provider: iteration-design-interview
- provider_version: design-tree-v1
- question_protocol: inline-confirmation-v1
- input_digest: ae8bc03ceebfdd42c3fca070d8cb71f426e3e36a6bf0f50fea1569a6d57d6dc9
- started_at: 2026-10-27T15:00:14+08:00
- completed_at: 2026-10-27T15:04:00+08:00
- classification: non-trivial
- classification_reason: 改登录返回和管理端鉴权。涉及接口形状、安全权限和两个仓库。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: no
- complexity.permission_or_security: yes
- complexity.concurrency: no
- complexity.performance: no
- complexity.multiple_repositories: yes
- complexity.external_service: no
- complexity.deployment: no
- complexity.destructive_operation: no
- complexity.uncertain: no

### 问答

| 问题 | 推荐答案 | 用户选择 | 状态 | 确认依据 |
|---|---|---|---|---|
| Q1 写死的密钥用哪一串？ | 你给一串密钥，放进管理端已有常量类。迭代文档里不写这串密钥。 | 由实现时生成一串密钥，只放进常量类，不写入迭代文档 | resolved | 用户原话：Q1 密钥是：你来生成一个 |
| Q2 两个头带了但密钥不对，或用户不存在、已停用，还退回 token 吗？ | 直接拒绝。只有没带这两个头、只带 token 时，才走原来的 token。 | 按推荐做 | resolved | 用户原话：Q2 按推荐做 |
| Q3 没有 token 时，角色和时区从哪来？ | 用请求头里的用户编号查用户。角色、时区用这个用户自己的。不再查登录会话。后面的业务代码不改。 | 按推荐做 | resolved | 用户原话：Q3 按推荐做 |
| Q4 页面登录现在把整个 data 当成 token。要不要改成只存 data.token？ | 要改这一处取值。data 仍是字符串时照旧存储，避免另一套登录被带坏。userId 先只返回，页面不另做用途。 | 按推荐做 | resolved | 用户原话：Q4 按推荐做 |

### 假设与风险

- 已核对：登录接口现在返回的 data 是一串 token。页面把这整段存成登录凭证。
- 已核对：业务里的当前用户、角色、时区都是从 token 里解出来的。只在拦截器放行、不补这些值，后面的接口会当成没登录。

## plan/P-001

- status: completed
- provider: grill-me
- provider_version: design-tree-v1
- question_protocol: inline-confirmation-v1
- input_digest: 7ff3f8e64be5d8d7e5ab94201ce5a7bd93fba197fdb9ca15a3cc421e2d4c5ef5
- started_at: 2026-10-27T15:12:00+08:00
- completed_at: 2026-10-27T15:14:00+08:00
- classification: non-trivial
- classification_reason: 计划沿用已批准的需求。失败时回现有的 token 无效。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: no
- complexity.permission_or_security: yes
- complexity.concurrency: no
- complexity.performance: no
- complexity.multiple_repositories: yes
- complexity.external_service: no
- complexity.deployment: no
- complexity.destructive_operation: no
- complexity.uncertain: no

### 问答

| 问题 | 推荐答案 | 用户选择 | 状态 | 确认依据 |
|---|---|---|---|---|
| Q1 两个新头没通过时，接口回哪一种现有失败？ | 回现在 token 无效那一种，编号 50008。不新造一句，也不区分是密钥错了还是用户不行。 | 按推荐做 | resolved | 用户原话：1按推荐做 |

### 假设与风险

- 已核对：两个仓库当前都在 `feat-20261027-bff`。另一条实现中的轮次用的是另一套仓库，所以本轮用真实目录，不建副本。
- 已核对：登录失败和缺 token 现在走的是现有错误码。开放接口仍走 `x-api-key`。
- 本地已有的环境文件改动不纳入本轮。
