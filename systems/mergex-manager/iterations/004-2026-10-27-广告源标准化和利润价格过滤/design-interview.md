<!-- design-interview-policy: design-tree-v1 -->
# 设计访谈

本文件持久保存需求和计划阶段的设计树访谈。事实由 Agent 使用只读源码、文档或 MCP 查询；用户只决定方案。历史尝试不得删除，输入摘要变化后把旧尝试标记为 `superseded` 并追加新尝试。

复杂度字段只使用 `yes`、`no` 或 `unknown`。任一字段为 `yes` 或 `unknown` 时按 `non-trivial`。`lite` 只有全部为 `no` 才能跳过两阶段访谈；`standard` 的非简单需求必须访谈，计划阶段可用计划评审代替第二次访谈；`strict` 的非简单需求和计划都必须访谈。

## requirements/R-001

- status: superseded
- provider: grill-me
- provider_version: skill
- question_protocol: inline-confirmation-v1
- input_digest: d7be664eab9f7030d8a7c38a31a7f3d4bffec8405a8ff48436357b5cbddd1e37
- started_at: 2026-10-27T19:10:30+08:00
- completed_at: 2026-10-27T19:12:40+08:00
- classification: non-trivial
- classification_reason: 有库表迁移、接口字段写死、双仓库页面改动
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: yes
- complexity.permission_or_security: no
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
| Q1：`app_std` 本轮是否只做开关落库与回显，还是还要改竞价/同步里真正用到应用名标准化的逻辑？ | 只做开关 + 落库 + 回显 | 按推荐做 | resolved | 用户原话：都按推荐做 |
| Q2：写死「媒体低价」是否就是 `bidFilterType=1`（媒体底价）？是否只改连接管理利润策略保存？ | 是 1；只改这条链路 | 按推荐做 | resolved | 用户原话：都按推荐做 |
| Q3：库里已是平台底价的旧连接，要不要一次性刷成媒体底价？ | 不刷库；下次保存时写死为 1 | 按推荐做 | resolved | 用户原话：都按推荐做 |

### 假设与风险

- 代码里价格过滤枚举：0 默认、1 媒体底价、2 平台底价、3 自定义。
- 用户原文「媒体低价」已确认为媒体底价 `1`。
- 正式库 ALTER 与批量刷数本轮都不自动执行。
- 引擎侧若不读 `app_std`，本轮开关只影响配置落库，竞价行为不变。

## requirements/R-002

- status: completed
- provider: grill-me
- provider_version: skill
- question_protocol: inline-confirmation-v1
- input_digest: bd12205f2b0c657f5c0155e28a8bab65ec063fd61cd85a407199a4cbc0ebd73f
- started_at: 2026-10-27T19:33:00+08:00
- completed_at: 2026-10-27T19:41:00+08:00
- classification: non-trivial
- classification_reason: 规格扩大到全部利润策略位置；仍有库表与双仓库改动
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: yes
- complexity.permission_or_security: no
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
| Q1：`app_std` 是否仍只做开关落库与回显？ | 是，本轮不改引擎消费 | 按推荐做 | resolved | 用户原话：都按推荐做 |
| Q2：价格过滤要覆盖哪些位置？写死是否仍是媒体底价 `1`？ | MergeX 全部利润策略位置（连接各 type + AB）；固定 `1`；不改 Mediatom 旧弹窗 | 所有位置都得动 | resolved | 用户原话：有点问题，价格策略，所有位置的都得动，现在只改了供应商位置 |
| Q3：旧数据是否仍不刷库？ | 不刷库；下次保存写死为 1 | 按推荐做 | resolved | 用户原话：都按推荐做 |

### 假设与风险

- R-001 的「只改连接管理」已被用户纠正；以本尝试为准。
- 正式库 ALTER 与批量刷数本轮仍不自动执行。

## plan/P-001

- status: superseded
- provider: grill-me
- provider_version: skill
- question_protocol: inline-confirmation-v1
- input_digest: c01999199bb607896f1decbb1d299a0ad5b1c46467d3e912a4a1dc0410b9e3a1
- started_at: 2026-10-27T19:15:30+08:00
- completed_at: 2026-10-27T19:19:00+08:00
- classification: non-trivial
- classification_reason: 双仓库共享检出，目标分支与脏文件基线需确认
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: yes
- complexity.permission_or_security: no
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
| Q1：本轮是否用共享检出，管理端继续 `feat-zhoutao`、页面继续 `feat-20261027mer3779`？本地环境脏文件只登记不提交、不建 worktree。 | 按推荐：共享检出 + 这两条分支 | 按推荐做 | resolved | 用户原话：Q1 按推荐做 |

### 假设与风险

- 当前无其他 implement/verify 活动轮次，不需要 worktree。
- 管理端本地可能有 `application.yml` 脏文件，页面可能有 `adx.js`，不算本轮功能。

## plan/P-002

- status: completed
- provider: grill-me
- provider_version: skill
- question_protocol: inline-confirmation-v1
- input_digest: 9ceef7ac2ac39a12953a56d0588bc0b77cfe1a3ff3f3c329b7aebaf2d1ee9feb
- started_at: 2026-10-27T19:36:00+08:00
- completed_at: 2026-10-27T19:41:00+08:00
- classification: non-trivial
- classification_reason: 范围修订后增加 T-05；检出与资源策略不变
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: yes
- complexity.permission_or_security: no
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
| Q1：检出、分支和脏文件策略是否仍按 P-001？T-05 是否只补全位置不另开 worktree？ | 仍用共享检出与原分支；T-05 在原检出补齐 | 按推荐做 | resolved | 用户原话：Q1 按推荐做 |

### 假设与风险

- 不占端口，不代启服务，不跑正式库迁移。
