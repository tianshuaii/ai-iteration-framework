<!-- design-interview-policy: design-tree-v1 -->
# 设计访谈

本文件持久保存需求和计划阶段的设计树访谈。事实由 Agent 使用只读源码、文档或 MCP 查询；用户只决定方案。历史尝试不得删除，输入摘要变化后把旧尝试标记为 `superseded` 并追加新尝试。

复杂度字段只使用 `yes`、`no` 或 `unknown`。任一字段为 `yes` 或 `unknown` 时按 `non-trivial`。`lite` 只有全部为 `no` 才能跳过两阶段访谈；`standard` 的非简单需求必须访谈，计划阶段可用计划评审代替第二次访谈；`strict` 的非简单需求和计划都必须访谈。

## requirements/R-001

- status: superseded
- provider: skill/iteration-design-interview
- provider_version: local-2026-10-29
- question_protocol: inline-confirmation-v1
- input_digest: e705caf0d584066bcb5c8aee31bf695713e1b7b219b95204a927d71597c1bf73
- started_at: 2026-10-29T15:56:00+08:00
- completed_at: 2026-10-29T17:12:30+08:00
- classification: non-trivial
- classification_reason: 综合报表筛选要同时改前端页面和后端应用列表接口，属于多仓库接口变更。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: no
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
| Q1 状态变化后已选应用如何处理 | 移除不再符合所选状态的应用，并按现有级联刷新广告位、流量分组和广告源 | 仍在新下拉中的已选应用保留，不在新下拉中的取消选中 | resolved | 用户原话：如果【已选应用】依旧在下拉列表中，保留选中状态（也就是筛选时有这个应用的选项）；如果【已选应用】不在下拉列表中，取消选中状态（也就是筛选时没有这个应用的选项） |
| Q2 应用状态一个都没选时应用下拉展示什么 | 不展示任何应用 | 默认仍为启用和暂停；一个都没选时应用下拉为空 | resolved | 用户原话：应用状态默认值不变，还是启用和暂停；应用状态一个都没选时，应用下拉列表为空 |
| Q3 应用列表按状态过滤的接口方式 | GET /app/applistForD 和 POST /app/getAppListByAdminIdList 都增加可选状态参数；不传时各自保持现有结果。综合报表两次调用都传入当前选中状态 | 只扩展 applistForD，增加可选账户和状态参数；综合报表不再调用 getAppListByAdminIdList | resolved | 用户原话：Q3 只扩展/app/applistForD，可选账户和状态参数，不再使用getAppListByAdminIdList |

### 假设与风险

- 首选 `grill-me` 在本机不可用，本轮需求访谈使用登记的降级技能 `iteration-design-interview`。
- 综合报表查询本身已按 `appStsList` 过滤应用。这次缺口是应用下拉的候选项，不是报表结果口径。
- 综合报表改为只调用扩展后的 applistForD。不传账户和状态时，动态包等现有调用保持当前结果。小时报表选中账户时仍调用 getAppListByAdminIdList，本轮不改该接口。

## plan/P-001

- status: superseded
- provider: skill/iteration-design-interview
- provider_version: local-2026-10-29
- question_protocol: inline-confirmation-v1
- input_digest: 7c881ce1801e4d00de4d167f2b3f9828be0121be8c2bd9a039f9f2b8ab864f44
- started_at: 2026-10-29T17:18:02+08:00
- completed_at: 2026-10-29T17:21:17+08:00
- classification: non-trivial
- classification_reason: 两个仓库都要改，并且后端要把最新 main 合入已有的 tianshuai 分支。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: no
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
| Q4 后端 tianshuai 如何合入最新 main | 在 tianshuai 上用 merge 合入 origin/main，保留现有提交。取得拉取授权后才执行 | 按推荐做 | resolved | 用户原话：Q4 按推荐做 |

### 假设与风险

- 首选 grill-me 在本机不可用，计划访谈使用降级技能 iteration-design-interview。
- 2026-10-29 只读查看时，后端在 tianshuai，前端在 mediatom-test，两个工作区都没有未提交文件。
- 同一系统没有其他 implement 或 verify 轮次，计划使用共享检出。
- 计划审批不授权拉取、建分支或修改产品代码。

## plan/P-002

- status: superseded
- provider: skill/iteration-design-interview
- provider_version: local-2026-10-29
- question_protocol: inline-confirmation-v1
- input_digest: dc8048eefa5b7b84c81bbb5be64e42eceed1e895734212de5d3b437f81a095a4
- started_at: 2026-10-29T17:24:02+08:00
- completed_at: 2026-10-29T17:24:02+08:00
- classification: non-trivial
- classification_reason: 用户限定了 main 与 tianshuai 的合并方向，计划正文因此更新。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: no
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
| Q1 执行前的合并方向 | 在 tianshuai 上 merge origin/main，不把 tianshuai 合入 main | 执行前将 main 合并至 tianshuai，不将 tianshuai 合并至 main | resolved | 用户原话：执行前将main合并至tianshuai，不将tianshuai合并至main |

### 假设与风险

- P-001 已确认用 merge 保留 tianshuai 现有提交。这次只补充方向：main 进入 tianshuai，tianshuai 不进入 main。
- 当前仍是计划阶段，本回合不执行合并，也不改产品仓库。实现开始时才按这个方向 merge。

## requirements/R-002

- status: superseded
- provider: skill/iteration-design-interview
- provider_version: local-2026-10-29
- question_protocol: inline-confirmation-v1
- input_digest: 227dd88150767121f73ebf558e50b02f0c6745f3a80a1b3bb13008c16f8a5d53
- started_at: 2026-10-29T17:44:00+08:00
- completed_at: 2026-10-29T17:47:54+08:00
- classification: non-trivial
- classification_reason: 小时报表与综合报表共用加载器，改调用会同时影响两个页面的应用列表来源。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: no
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
| Q5 小时报表选中账户后的应用列表是否也改用 applistForD | 选中账户时只传账户编号，不传应用状态；未选账户仍无参数调用。不改筛选顺序，应用状态不联动应用下拉，不删除原接口 | 确认小时报表选中账户也改用 applistForD | resolved | 用户原话：确认小时报表选中账户也改用 applistForD，开始处理 |

### 假设与风险

- 首选 grill-me 在本机不可用，这次需求补充使用登记的降级技能 iteration-design-interview。
- R-001 里“小时报表继续走原接口”已过时。只传账户时沿用已批准的 applistForD 口径：这些账户未删除的应用，按应用去重，不叠加登录用户数据范围。
- 小时报表现有应用状态筛选仍只触发查询，不刷新应用下拉。这次不把综合报表的状态联动带过去。
- 本回合只更新规格，不改产品代码。旧需求审批会因文档变化失效。

## requirements/R-003

- status: completed
- provider: skill/iteration-design-interview
- provider_version: local-2026-10-29
- question_protocol: inline-confirmation-v1
- input_digest: 036b89034baf90b9eee9fb93f05a609a2ace7a179e86f5f061ebb1a4b17986ae
- started_at: 2026-10-29T18:48:00+08:00
- completed_at: 2026-10-29T18:50:36+08:00
- classification: non-trivial
- classification_reason: 小时报表要改成和综合报表同一套筛选联动，仍然同时涉及两个页面和已扩展的应用列表接口。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: no
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
| Q6 小时报表的应用状态联动要做到哪一步 | 与综合报表相同：应用状态放在应用前面，下拉按状态过滤，保留仍可见的已选应用并刷新后续下拉，空状态不请求，有账户时同时传账户和状态 | 逻辑完全同综合报表，包括应用状态放到应用下拉前面 | resolved | 用户原话：确保逻辑完全同综合报表，包括应用状态放到应用下拉前面 |

### 假设与风险

- 首选 grill-me 在本机不可用，这次补充使用登记的降级技能 iteration-design-interview。
- R-002 里“不改小时报表顺序、不联动状态”已过时。
- 小时报表的日期、SDK 版本、应用版本，以及未选应用且未选账户时的广告位全量加载，保持原样。
- 本回合只更新规格，不改产品代码。

## plan/P-003

- status: completed
- provider: skill/iteration-design-interview
- provider_version: local-2026-10-29
- question_protocol: inline-confirmation-v1
- input_digest: 8a34f5108fcd29abee35638c9ebdc78b7d4f22fdc4c5df829bd16efcfa2a33cf
- started_at: 2026-10-29T18:52:00+08:00
- completed_at: 2026-10-29T18:53:25+08:00
- classification: non-trivial
- classification_reason: 小时报表要补进已有的双仓库实现，分支方向仍受已确认的单向合并约束。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: no
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
| Q1 执行前的合并方向 | 在 tianshuai 上 merge origin/main，不把 tianshuai 合入 main | 执行前将 main 合并至 tianshuai，不将 tianshuai 合并至 main | resolved | 用户原话：执行前将main合并至tianshuai，不将tianshuai合并至main |

### 假设与风险

- 首选 grill-me 在本机不可用，计划访谈使用降级技能 iteration-design-interview。
- 这次计划变化是小时报表按已批准需求补齐同一套联动，没有新的方案选择。合并方向沿用上面的原话，并且 origin/main 已经快进合入 tianshuai。
- T-01 不重开。小时报表只会传 T-01 已实现的状态和账户参数。
- 本回合不改产品代码，不启动服务，不把 tianshuai 合入 main。
