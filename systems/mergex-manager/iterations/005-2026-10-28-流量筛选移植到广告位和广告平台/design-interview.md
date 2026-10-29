<!-- design-interview-policy: design-tree-v1 -->
# 设计访谈

本文件持久保存需求和计划阶段的设计树访谈。事实由 Agent 使用只读源码、文档或 MCP 查询；用户只决定方案。历史尝试不得删除，输入摘要变化后把旧尝试标记为 `superseded` 并追加新尝试。

复杂度字段只使用 `yes`、`no` 或 `unknown`。任一字段为 `yes` 或 `unknown` 时按 `non-trivial`。`lite` 只有全部为 `no` 才能跳过两阶段访谈；`standard` 的非简单需求必须访谈，计划阶段可用计划评审代替第二次访谈；`strict` 的非简单需求和计划都必须访谈。

## requirements/R-001

- status: superseded
- provider: grill-me
- provider_version: local-2026-10-28
- question_protocol: inline-confirmation-v1
- input_digest: 19c222ec5121f8f0e37150505cd62c96dd43ed2eec0ffe69396c494f8483eded
- started_at: 2026-10-28T17:16:41+08:00
- completed_at: 2026-10-28T17:46:45+08:00
- classification: non-trivial
- classification_reason: 涉及两个新增/编辑表单、权限控制、广告位同名字段兼容，以及广告平台后端存储是否扩展。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: unknown
- complexity.database_or_migration: unknown
- complexity.permission_or_security: yes
- complexity.concurrency: no
- complexity.performance: no
- complexity.multiple_repositories: unknown
- complexity.external_service: no
- complexity.deployment: no
- complexity.destructive_operation: no
- complexity.uncertain: yes

### 问答

| 问题 | 推荐答案 | 用户选择 | 状态 | 确认依据 |
|---|---|---|---|---|
| Q1：广告位现有预算过滤已经占用 `trafficDirectionSwitch/trafficDirectionVo`，广告平台账号后端没有流量筛选存储。选择 A 替换预算过滤并补平台后端；B 保留预算过滤、另增独立流量筛选并补平台后端；C 只做前端展示、不保存回显生效。 | B：广告位保留预算过滤并新增独立流量筛选；广告平台新增/编辑也支持保存、回显和真实生效。 | 两种策略分别使用独立 `policy_manage` 主记录和各自关联记录；关联记录可按规则生成多条 | resolved | 用户原话：确认，关联记录可以按规则生成多条，Q1 按上述方案处理 |

### 假设与风险

- 广告位不能让同名字段同时表示预算过滤和流量筛选，否则会串写或误解释老数据。
- 广告平台账号没有现成策略维度；选择真实生效会扩大到接口契约和后端策略模型。
- Q1 已确认后规格输入发生变化，本尝试作为历史记录保留；新的广告平台账号挂载问题转入 R-002。

## requirements/R-002

- status: superseded
- provider: grill-me
- provider_version: local-2026-10-28
- question_protocol: inline-confirmation-v1
- input_digest: 4a3d5a5f3206f115c8f4736e83d31cd977b25d15e063690c1a08d0d9218165d3
- started_at: 2026-10-28T17:48:36+08:00
- completed_at: 2026-10-28T17:53:02+08:00
- classification: non-trivial
- classification_reason: Q1 已确认独立策略模型，但 `policy_manage` 尚无广告平台账号维度，需确认是否扩展 Schema。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: yes
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
| Q2：现有 `policy_manage` 没有广告平台账号维度或 `plat_account_id`。A 新增平台账号维度和字段；B 复用其他业务字段；C 新建专用策略主表。 | A：新增广告平台账号维度和 `plat_account_id`，在 `mergex-manager` 交付迁移文件，不复用语义不匹配的旧字段。 | 按推荐 A 处理 | resolved | 用户原话：Q2 按推荐做：给 policy_manage 新增广告平台账号维度和 plat_account_id，不复用其他业务字段。 |

### 假设与风险

- 复用 `publisher_id` 或 `place_id` 会混淆业务语义，并可能与现有维度查询冲突。
- 选择 A 会新增表结构迁移文件，但本轮不自动执行正式库迁移。
- Q2 已按用户原话确认；需求阶段无未决设计问题，可进入需求评审。

## requirements/R-003

- status: superseded
- provider: grill-me
- provider_version: local-2026-10-28
- question_protocol: inline-confirmation-v1
- input_digest: df4f1bf612186168fb0f8cf5032d34b4678dbef45cb4a3ad4811999a0e8c063c
- started_at: 2026-10-28T18:54:31+08:00
- completed_at: 2026-10-28T19:02:20+08:00
- classification: non-trivial
- classification_reason: 范围已收缩为广告平台账号，但仍涉及权限、新老接口、`policy_manage` Schema 和前后端两个仓库。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: yes
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
| Q4：需求变更后的页面范围如何处理？A 只保留广告平台账号流量筛选，广告位整体移出；B 广告位仍保留实现但默认关闭。 | A：仅保留广告平台，广告位前端、载荷、服务和预算过滤全部不动。 | 选择 A，不需要广告位上的流量筛选 | resolved | 用户原话：停一下当前迭代，迭代需求有改变，不需要加广告位上的流量筛选了 |

### 假设与风险

- 设计树新的顶层边界已由用户直接确认：广告位分支删除，只保留广告平台账号流量筛选。
- 广告平台账号挂载方案仍使用用户已直接确认的专用维度和 `plat_account_id`，不需要重问 Q2。
- 剩余实现分支已被既有源码事实和已确认决策唯一确定，当前设计树 frontier 为空，没有新的用户决策问题。
- 确认依据：用户原话“停一下当前迭代，迭代需求有改变，不需要加广告位上的流量筛选了”和“重新制定迭代”。

## plan/P-001

- status: superseded
- provider: grill-me
- provider_version: local-2026-10-28
- question_protocol: inline-confirmation-v1
- input_digest: 1266d8868aafe4568befeb6ef64ef97dd0282cdb306ec9d407e15ae8240b029a
- started_at: 2026-10-28T17:58:33+08:00
- completed_at: 2026-10-28T18:06:33+08:00
- classification: non-trivial
- classification_reason: 计划同时涉及数据库 Schema、多仓接口契约、权限前缀、新老平台账号分流和广告位两类策略隔离。源码事实核对后，实现分层和兼容边界均已由已审需求唯一确定，无新的用户方案分支。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: yes
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

### 假设与风险

- 本尝试在评审时发现新载荷改名了已审需求保护的表单字段，因此保留为历史证据并转入 P-002。
- 广告平台页实际存在新老两套 add/update/getById 分流，因此后端两套都覆盖，不作为可缩减的可选项。
- `plat_account_id` 在 Java 使用 `Long`；SQL 物理类型在实现前核对测试库 DDL，不让用户猜测源码可读取的事实。
- 两仓采用真实仓库共享检出，保护前端 `build/env/development/adx.js` 和后端 `application.yml` 的接管前 dirty，不将它们计入本轮改动。

## plan/P-002

- status: superseded
- provider: grill-me
- provider_version: local-2026-10-28
- question_protocol: inline-confirmation-v1
- input_digest: ebb12555c1104655bef6b460f056b1d5652b653e295f5c08b317f57b7eca8bb0
- started_at: 2026-10-28T18:06:33+08:00
- completed_at: 2026-10-28T18:08:18+08:00
- classification: non-trivial
- classification_reason: 计划同时涉及数据库 Schema、多仓接口契约、权限前缀、新老平台账号分流和广告位两类策略隔离。已将新契约收敛为外层 `trafficTargeting`，内层保持已审表单字段不变，无新的用户方案分支。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: yes
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

### 假设与风险

- 广告位保留顶层预算过滤字段，新流量定向使用外层 `trafficTargeting`，内层仍为 `trafficDirectionSwitch/trafficDirectionVo`。
- 广告平台页实际存在新老两套 add/update/getById 分流，因此后端两套都覆盖，不作为可缩减的可选项。
- `plat_account_id` 在 Java 使用 `Long`；SQL 物理类型在实现前核对测试库 DDL，不让用户猜测源码可读取的事实。
- 两仓采用真实仓库共享检出，保护前端 `build/env/development/adx.js` 和后端 `application.yml` 的接管前 dirty，不将它们计入本轮改动。

## plan/P-003

- status: superseded
- provider: grill-me
- provider_version: local-2026-10-28
- question_protocol: inline-confirmation-v1
- input_digest: 31089edd5a6f6b3d58d319650010205921e715f333523ed478da08f23136c68e
- started_at: 2026-10-28T18:10:30+08:00
- completed_at: 2026-10-28T18:11:33+08:00
- classification: non-trivial
- classification_reason: 已审需求的风险表以一个 T4 任务保护整条跨仓契约；计划将数据、后端和两个页面收束为一个端到端 T-01，技术步骤仍在实现计划中分层执行，无新的用户方案分支。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: yes
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

### 假设与风险

- T-01 是一个端到端契约任务；实现顺序仍按 `implementation-plan.md` 的 Schema、广告位后端、平台后端、两个页面分步进行，完成后统一检查和 review。
- 广告位保留顶层预算过滤字段，新流量定向使用外层 `trafficTargeting`，内层仍为 `trafficDirectionSwitch/trafficDirectionVo`。
- 广告平台新老 add/update/getById 均覆盖；`plat_account_id` 在 Java 使用 `Long`，SQL 物理类型实现前核对测试库 DDL。
- 两仓采用真实仓库共享检出，保护前端 `build/env/development/adx.js` 和后端 `application.yml` 的接管前 dirty。

## plan/P-004

- status: superseded
- provider: grill-me
- provider_version: local-2026-10-28
- question_protocol: inline-confirmation-v1
- input_digest: 31089edd5a6f6b3d58d319650010205921e715f333523ed478da08f23136c68e
- started_at: 2026-10-28T18:20:11+08:00
- completed_at: 2026-10-28T18:23:04+08:00
- classification: non-trivial
- classification_reason: 当前计划把 Schema、广告位后端、广告平台后端和两个页面收束为一个端到端 T4 任务；严格档位要求用户直接确认该任务组织方案，不能由阶段审批倒推。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: yes
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
| Q3：实现任务如何组织？A 保持一个端到端 T-01，内部按 Schema、广告位后端、广告平台后端、两个页面分步实现，最后统一检查和 code review；B 拆成多条独立任务，并同步重写已审批的风险与测试策略后重新评审。 | A：保持一个端到端 T-01。它与当前 T4 风险行和跨仓契约一致，同时实现步骤仍分层执行，不会把代码混成一步。 | 按推荐 A，保持一个端到端 T-01 | resolved | 用户原话：Q3 按推荐做，保持一个端到端 T-01。 |

### 假设与风险

- 选择 A 不改变当前实现计划摘要，确认后可复用已经通过的计划评审。
- 选择 B 会改变任务、风险和测试设计，需要重新生成摘要并重新执行计划评审与审批。
- 用户已直接选择 A，当前计划摘要不变，可复用已通过的计划评审与此前明确给出的计划审批原话。

## plan/P-005

- status: superseded
- provider: grill-me
- provider_version: local-2026-10-28
- question_protocol: inline-confirmation-v1
- input_digest: 1cf0067247e5bf9e6271af203f30f3957f5cf1c4f2f3c41e12e6e77254adbda1
- started_at: 2026-10-28T19:07:11+08:00
- completed_at: 2026-10-28T19:09:37+08:00
- classification: non-trivial
- classification_reason: 新计划仍涉及 Schema、新老平台账号契约、权限和两个仓库；广告位分支已完全删除。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: yes
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
| Q5：范围收缩后，任务是否仍保持一个端到端 T-01？A 保持一个 T-01，内部按 Schema/策略、平台新老接口、目标页面和测试分步实现；B 拆分多任务并重写风险行。 | A：保持一个端到端 T-01，与当前 T4 风险行和跨仓契约一致，技术步骤仍分层执行。 | 按推荐 A，保持一个端到端 T-01 | resolved | 用户原话：Q3 按推荐做，保持一个端到端 T-01。 |

### 假设与风险

- 用户对任务组织的明确选择未因范围收缩而改变；新计划只从 T-01 中删除广告位步骤。
- 两仓继续使用真实仓库共享检出，保护前端 `build/env/development/adx.js` 和后端 `application.yml` 的接管前 dirty。
- 本轮不启动服务、不执行数据库迁移；实现完成后统一执行定向检查和 code review。

## plan/P-006

- status: completed
- provider: grill-me
- provider_version: local-2026-10-29
- question_protocol: inline-confirmation-v1
- input_digest: 39ffc75149e10f74262978ce5b4cf75291c666d70a83452580e9ea730a0fa494
- started_at: 2026-10-29T10:58:17+08:00
- completed_at: 2026-10-29T10:59:53+08:00
- classification: non-trivial
- classification_reason: 返工本身仅改迁移 SQL，但轮次仍涉及已实现的 Schema、权限、新老接口和两个仓库；计划必须明确哪些证据失效、哪些可以复用。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: yes
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
| Q7：取消表索引后如何组织返工？A 保持用户已确认的一个端到端 T-01，将它恢复为未完成，但本次写入只移除迁移 SQL 的索引 DDL，并复用未受影响证据；B 新建第二条任务并机械重跑全部端到端测试；C 推翻现有实现重新开发。 | A：保持一个 T-01，返工范围精确收窄到迁移 SQL；只让 AC/TC-06 和迁移结构证据失效，其他代码与测试输入未变时复用。 | 保持一个端到端 T-01，并取消表索引 | resolved | 用户原话：Q3 按推荐做，保持一个端到端 T-01。用户原话：我不需要表索引。 |

### 假设与风险

- 两个用户决定共同唯一确定返工结构：任务数量不变，索引 DDL 删除；不需要再次向用户询问已经回答的问题。
- 当前产品差异中只有 `sql/policy_manage_plat_account_id.sql` 与新规格冲突，其他实现文件不在返工写入范围。
- 后端 9/9、前端 3/3、ESLint、导入边界和广告位排除证据的代码、依赖、配置及生成物输入未因计划文档变化而改变，可以复用。
- 测试库已有索引不删除；本轮无独占运行资源，不启动服务或执行迁移。

## requirements/R-004

- status: completed
- provider: grill-me
- provider_version: local-2026-10-29
- question_protocol: inline-confirmation-v1
- input_digest: b26d460aa8a1a3de17ce95a04aa3bb83c80b153066ad0dbf17552d5715cbf439
- started_at: 2026-10-29T10:53:39+08:00
- completed_at: 2026-10-29T10:53:39+08:00
- classification: non-trivial
- classification_reason: 验收中改变 Schema 迁移边界，会使已审批需求、计划和 TC-06 证据失效，但不改变专用字段、策略存储模型或页面契约。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: yes
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
| Q6：`policy_manage.plat_account_id` 迁移是否需要新增表索引？A 保留当前唯一索引；B 只新增字段，不新增任何普通、唯一或联合索引；C 连字段和索引一起取消。 | B：保留已确认的专用字段和广告平台账号维度，但迁移文件只新增字段，不操作表索引；测试库已有索引不在未授权情况下删除。 | 不需要表索引，按 B 处理 | resolved | 用户原话：我不需要表索引。 |

### 假设与风险

- `plat_account_id` 字段、广告平台账号维度、每个账号独立 `type=1` 主记录及多条关联规则仍按既有用户确认保留。
- 取消索引后，账号隔离与挂载正确性由业务查询条件和数据验收保证；本轮不新增性能验收目标。
- 测试库已经存在的 `uk_policy_manage_plat_account` 是验收前置环境的历史现状，删除属于额外 Schema 写入，未经单独授权不执行。
- 需求摘要已变化，旧需求与计划审批自动过期；产品迁移文件需在重新审批和执行授权后返工。

