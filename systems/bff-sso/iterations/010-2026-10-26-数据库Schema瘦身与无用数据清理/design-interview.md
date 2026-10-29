<!-- design-interview-policy: design-tree-v1 -->
# 设计访谈

本文件持久保存需求和计划阶段的设计树访谈。事实由 Agent 使用只读源码、文档或 MCP 查询；用户只决定方案。历史尝试不得删除，输入摘要变化后把旧尝试标记为 `superseded` 并追加新尝试。

复杂度字段只使用 `yes`、`no` 或 `unknown`。任一字段为 `yes` 或 `unknown` 时按 `non-trivial`。`lite` 只有全部为 `no` 才能跳过两阶段访谈；`standard` 的非简单需求必须访谈，计划阶段可用计划评审代替第二次访谈；`strict` 的非简单需求和计划都必须访谈。

## requirements/R-001

- status: superseded
- provider: grill-me
- provider_version: local-skill
- question_protocol: inline-confirmation-v1
- input_digest: 0c9d4d9e36451fb283de5d7a9e9182f1d63ad11159cc373f78ac4686117b63d2
- started_at: 2026-10-26T20:36:12+08:00
- completed_at: 2026-10-26T20:41:23+08:00
- classification: non-trivial
- classification_reason: 涉及线上测试 Schema、物理删除、迁移、三后端模型同步与恢复边界。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: yes
- complexity.permission_or_security: no
- complexity.concurrency: yes
- complexity.performance: yes
- complexity.multiple_repositories: yes
- complexity.external_service: no
- complexity.deployment: yes
- complexity.destructive_operation: yes
- complexity.uncertain: no

### 问答

| 问题 | 推荐答案 | 用户选择 | 状态 | 确认依据 |
|---|---|---|---|---|
| Q1 目标环境：是否只处理线上测试库 `public_management`，不触碰生产库和其他 Schema？ | 只处理线上测试 Schema。 | 按推荐做 | resolved | 用户原话：Q1-Q6 都按推荐做 |
| Q2 未使用判定：是否以五个当前仓库、4 个有效服务、4 个有效接口项目和数据库依赖为真源，并保留两个迁移元数据表？ | 采用该真源；删除其余无引用历史表。 | 按推荐做 | resolved | 用户原话：Q1-Q6 都按推荐做 |
| Q3 运行包保留：有效服务是否只保留每个环境的 active 与 previous，并删除另外 28 个未引用的 `yn=1` 历史包？ | 只保留 active 与 previous。 | 按推荐做 | resolved | 用户原话：Q1-Q6 都按推荐做 |
| Q4 接口项目历史：是否保留 4 个有效项目的完整版本历史，只删除 30 个 `yn=0` 项目及依赖？ | 保留有效项目完整历史。 | 按推荐做 | resolved | 用户原话：Q1-Q6 都按推荐做 |
| Q5 审计数据：`sys_audit_log` 仍被运行代码写入，是否保留全部数据和表？ | 保留，审计保留期另开需求。 | 按推荐做 | resolved | 用户原话：Q1-Q6 都按推荐做 |
| Q6 恢复门禁：是否强制备份、删除前后清单和恢复演练通过后才允许清理线上测试库？ | 强制执行。 | 按推荐做 | resolved | 用户原话：Q1-Q6 都按推荐做 |

### 假设与风险

- 直接删除 `yn=0` 父记录会被 RESTRICT 外键阻止，必须先按依赖顺序处理子记录。
- Blob 可能被有效与失效数据共享，只能删除清理后无引用的 Blob。
- 本轮与“业务默认只软删除”的习惯冲突，按用户本轮明确物理清理要求作为单轮例外。
- 009 成果仍在五个真实仓库的 dirty 工作区中；本轮计划必须逐文件登记并保护这些基线。

## requirements/R-002

- status: completed
- provider: grill-me
- provider_version: local-skill
- question_protocol: inline-confirmation-v1
- input_digest: 9cb6d3ed3ac37a0aa858d1b9ba662c7ae1e772e826c12ab820b3691ba80a278b
- started_at: 2026-10-27T11:18:00+08:00
- completed_at: 2026-10-27T11:18:00+08:00
- classification: non-trivial
- classification_reason: 仅将 SR 用例标题改为框架要求的二级标题；Schema、物理删除、迁移和多仓库风险边界均未改变。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: yes
- complexity.permission_or_security: no
- complexity.concurrency: yes
- complexity.performance: yes
- complexity.multiple_repositories: yes
- complexity.external_service: no
- complexity.deployment: yes
- complexity.destructive_operation: yes
- complexity.uncertain: no

### 问答

| 问题 | 推荐答案 | 用户选择 | 状态 | 确认依据 |
|---|---|---|---|---|
| Q1-Q6 已确认的目标环境、清理真源、运行包保留、项目历史、审计保留和恢复门禁是否因 SR 标题格式变更而改变？ | 不改变；仅将两个 SR 标题由三级改为二级，符合框架索引格式。 | 按既有确认执行 | resolved | 用户原话：Q1-Q6 都按推荐做；开始处理，完成所有的任务，若中途有回归，自行处理并审批，直到所有任务完成 |

### 假设与风险

- 本次格式修复不改变需求、AC、TC 步骤、范围、数据库迁移或外部写入边界。
- 需求摘要变化只来自 SR 标题层级，需重新绑定审批和评审证据，不能沿用旧摘要。

## plan/P-001

- status: completed
- provider: grill-me
- provider_version: local-skill
- question_protocol: inline-confirmation-v1
- input_digest: 07280d9af583f353bb9f72e1427e6e58ec8ed94b9ccc14b898a7c183a8e763ad
- started_at: 2026-10-26T20:46:37+08:00
- completed_at: 2026-10-26T20:53:12+08:00
- classification: non-trivial
- classification_reason: 计划需确定线上测试库的备份恢复门禁、不可逆迁移执行模式和活动数据保护方式。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: yes
- complexity.permission_or_security: no
- complexity.concurrency: yes
- complexity.performance: yes
- complexity.multiple_repositories: yes
- complexity.external_service: no
- complexity.deployment: yes
- complexity.destructive_operation: yes
- complexity.uncertain: no

### 问答

| 问题 | 推荐答案 | 用户选择 | 状态 | 确认依据 |
|---|---|---|---|---|
| Q7 备份与恢复演练：实际迁移前是否采用“逻辑全量备份 + SHA-256 清单 → 恢复至独立临时数据库 → 执行只读不变量核验 → 人工确认后才允许迁移”的门禁？ | 采用。备份和恢复演练均不在原库上执行；演练库验证完成后删除。 | 按推荐做 | resolved | 用户原话：Q7-Q9 都按推荐做 |
| Q8 不可逆执行方式：是否采用一份仅由 `adx-admin-backend` 部署的前向迁移，迁移内先锁定/预检保留集，再按外键顺序删除数据，最后删除字段和表；不提供“回滚 SQL”，恢复只依赖 Q7 备份？ | 采用。物理删除无法可靠 SQL 回滚，禁止把不完整的 down SQL 当恢复方案。 | 按推荐做 | resolved | 用户原话：Q7-Q9 都按推荐做 |
| Q9 迁移期间的运行保护：是否在备份、恢复演练和最终迁移窗口停止五项本机服务对线上测试库的写入，并在迁移后仅启动定向回归所需服务？ | 采用。避免测试流量在清单、备份和删除之间制造漂移；不影响生产。 | 按推荐做 | resolved | 用户原话：Q7-Q9 都按推荐做 |

### 假设与风险

- 恢复演练临时数据库只用于验证备份可用性；不得代替线上测试库迁移前的独立备份。
- 前向迁移中的保留集必须先于任何删除语句用 `RAISE EXCEPTION` 保护；清理失败时停止，不猜测性重跑。
- 实际迁移、恢复演练、启动或停止服务仍需要用户在实施/验收阶段单独授权；本计划不执行这些动作。
