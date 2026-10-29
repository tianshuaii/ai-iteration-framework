# 阶段评审

## requirements

- reviewer: iteration-requirements-review
- reviewed_at: 2026-10-28T19:02:20+08:00
- input_digest: df4f1bf612186168fb0f8cf5032d34b4678dbef45cb4a3ad4811999a0e8c063c
- result: passed

对照了重写后的需求、决策、改动范围、验收、测试策略、用例和跟踪表。当前只保留广告平台账号流量筛选；广告位已从产品修改列表删除，并通过 AC/TC-07 防止范围泄漏。既有只读源码证据仍确认：`policy_manage` 现有维度不包含广告平台账号，表和 Mapper 也没有 `plat_account_id`；平台账号页存在新老两套 add/update/getById 分流。

| 编号 | 级别 | 发现 | 影响文档 | 必须修正 | 处置 |
|---|---|---|---|---|---|
| F-01 | P1 | 原规格、验收和测试仍包含广告位流量筛选，与用户新边界冲突。 | requirements.md、change-scope.md、acceptance.md、test-strategy.md、test-cases.md、traceability.md | 删除广告位实现分支，并增加差异边界检查。 | 已修正；广告位只出现在“不做/明确不动”和 AC/TC-07 范围排除中。 |
| F-02 | P2 | 广告平台账号在 `policy_manage` 中没有可用的专用维度和字段。 | decisions.md、change-scope.md、AC/TC-06 | 不得复用其他业务字段，必须明确 Schema 扩展与验收。 | 已处置；用户原话确认新增广告平台账号维度和 `plat_account_id`，迁移、实体、查询和常量已纳入范围与用例。 |
| F-03 | P2 | 迁移文件的交付与真实执行授权容易混淆。 | requirements.md、change-scope.md、test-cases.md | 区分“交付 SQL”和“执行正式库迁移”。 | 已处置；本轮只交付 `mergex-manager/sql/` 迁移文件，不自动执行正式库迁移或改数。 |
| F-04 | P2 | 广告平台存在新老两组新增、更新和详情接口，容易只改一组。 | requirements.md、change-scope.md、test-strategy.md、AC/TC-03 | 将新老接口兼容列入范围、验收和自动检查。 | 已处置；`/platAccount/add|update|getById` 与 `oldAdd|oldUpdate|oldGetById` 均在契约和回归范围。 |

没有未关闭的 P0、P1 或 P2。需求、AC/TC、改动范围和 T4 测试深度一致，跟踪表无缺口；广告位不再是实现对象。

本评审不代替需求审批，也不授权修改产品代码、执行迁移或其他外部变更。

### 2026-10-29 无索引需求变更复审

- reviewer: iteration-requirements-review
- reviewed_at: 2026-10-29T10:54:44+08:00
- input_digest: b26d460aa8a1a3de17ce95a04aa3bb83c80b153066ad0dbf17552d5715cbf439
- result: passed

本次仅复审验收中新增的 Schema 边界：保留广告平台账号维度与 `plat_account_id`，迁移文件不新增、调整或删除任何表索引。需求、决策、范围、AC-06、TC-06、测试策略和跟踪关系已同步，原 TC-06 结果已作为旧规格历史保留并将当前结果重置为未测。

| 编号 | 级别 | 发现 | 影响文档 | 必须修正 | 处置 |
|---|---|---|---|---|---|
| F-05 | P1 | 已实现迁移和旧 TC-06 证据仍包含唯一索引，与用户最新“我不需要表索引”冲突。 | requirements.md、decisions.md、change-scope.md、acceptance.md、test-strategy.md、test-cases.md、traceability.md、test-log.md | 将迁移边界改为只新增字段且不操作索引；旧通过证据不得继续作为当前结果。 | 已修正；D-06 明确无索引边界，AC/TC-06 已同步，当前 TC-06 为未测，测试库已有索引未擅自删除。 |

没有未关闭的 P0、P1 或 P2。该变更没有引入新的用户决策：字段、维度、独立 `type=1` 策略记录、多条关联及账号隔离仍沿用已确认方案；Q6 已由用户原话直接解决。取消索引不改变页面与接口验收，但会使既有产品 SQL、需求审批、计划审批和 TC-06 证据失效，后续必须按新摘要重新审批、返工和复验。

本复审不代替需求审批，不授权修改产品 SQL，也不授权删除测试库已存在的索引。

## plan

- reviewer: iteration-plan-review
- reviewed_at: 2026-10-28T19:09:37+08:00
- input_digest: 1cf0067247e5bf9e6271af203f30f3957f5cf1c4f2f3c41e12e6e77254adbda1
- result: passed

对照已审批的新规格、改动范围、实现计划、任务、风险、测试策略和资源预留进行了计划评审。当前仅保留一个广告平台账号端到端 T4 任务，按“Schema/策略基础 → 平台新老接口 → 目标页面 → 定向测试”分层实现。两仓无其他 `implement/verify` 轮次占用，使用真实仓库共享检出，不因已有 dirty 创建 worktree；实现阶段不占用服务端口或数据库迁移资源。

| 编号 | 级别 | 发现 | 影响文档 | 必须修正 | 处置 |
|---|---|---|---|---|---|
| PF-01 | P1 | 旧计划和任务仍列出广告位后端、页面、测试与预算过滤兼容。 | implementation-plan.md、tasks.md、risks.md、workspace.md | 删除全部广告位实现步骤和目标文件，只保留差异边界门禁。 | 已修正；T-01 不再包含 `EditPlace`、`CreateAdPlaceVo`、`AdPlaceServerImpl` 或广告位测试。 |
| PF-02 | P2 | 后端 POM 默认跳过测试，普通 `mvn test` 会产生伪通过证据。 | tasks.md、test-strategy.md | Maven 定向命令必须显式开启测试。 | 已处置；后端命令保留 `-DskipTests=false`，并只运行平台账号受影响测试。 |
| PF-03 | P2 | 前端和后端真实仓库各有一个接管前配置改动。 | workspace.md、risks.md | 不得覆盖、格式化或计入本轮差异。 | 已处置；计划保护 `build/env/development/adx.js` 和 `application.yml`，实现前再核对 HEAD 和 dirty。 |
| PF-04 | P2 | 平台账号页存在新老 API 分流，只改一套会导致部分账号无法保存回显。 | implementation-plan.md、tasks.md、test-strategy.md | 新老 add/update/getById 全部进入同一策略契约和定向测试。 | 已处置；端到端 T-01 同时覆盖新老路径。 |
| PF-05 | P2 | 新计划必须同时有直接与一层相邻浅回归，但不得扩展成全系统回归。 | test-strategy.md、test-cases.md | 为每个 SR 写明纳入理由与停止边界。 | 已处置；SR-01/SR-02 覆盖直接功能，SR-03 覆盖共用载荷的平台基础字段，SR-04 仅在共享组件有差异时扩大。 |

没有未关闭的 P0、P1 或 P2。任务、风险、定向检查、资源预留与已审需求一致，首个任务没有未解决的范围、依赖、检出或独占资源冲突。

本评审不代替计划审批，也不授权修改产品代码、执行数据库迁移或其他外部变更。

### 2026-10-29 无索引返工计划复审

- reviewer: iteration-plan-review
- reviewed_at: 2026-10-29T11:00:16+08:00
- input_digest: 39ffc75149e10f74262978ce5b4cf75291c666d70a83452580e9ea730a0fa494
- result: passed

本次计划只让受需求变化影响的 T-01 迁移部分恢复为未完成。产品写入范围收窄为 `mergex-manager/sql/policy_manage_plat_account_id.sql`，操作是删除现有 `ADD UNIQUE INDEX` 并修正 SQL 语法；不改业务代码、前端或测试库 Schema。两仓继续使用既有功能分支的真实共享检出，没有其他 `implement/verify` 轮次占用，也没有独占运行资源。

| 编号 | 级别 | 发现 | 影响文档 | 必须修正 | 处置 |
|---|---|---|---|---|---|
| PF-06 | P1 | 旧实现计划和迁移文件仍要求查询/唯一索引，与已审批无索引需求冲突。 | implementation-plan.md、tasks.md、risks.md | 计划明确只保留字段 DDL并删除索引 DDL，任务恢复未完成。 | 已修正；T-01 返工文件仅为迁移 SQL，测试库索引不删除。 |
| PF-07 | P2 | 若沿用旧 T4 全套检查，会对未变化的前后端代码机械重跑。 | tasks.md、test-log.md | 只让迁移结构和 AC/TC-06 证据失效，其他输入未变的通过证据复用。 | 已修正；任务只执行无索引扫描与 SQL `diff --check`，完成后做一次增量 review 和 TC-06 复验。 |
| PF-08 | P2 | “无索引”可能被误解为需要立即删除测试库已有索引。 | risks.md、workspace.md | 明确产品脚本不操作索引，环境 DDL 需要单独授权。 | 已修正；无服务、数据库、端口或测试账号资源预留，不执行 `DROP INDEX`。 |

没有未关闭的 P0、P1 或 P2。任务依赖、文件交集、回退方式、共享检出、目标分支和资源边界均明确；既有 SR-01～SR-04 仍覆盖直接与一层相邻功能，其代码输入未变化，可继续复用，返工不会扩展成全系统回归。

本复审不代替计划审批，也不授权修改产品 SQL、执行数据库迁移或删除测试库索引。
