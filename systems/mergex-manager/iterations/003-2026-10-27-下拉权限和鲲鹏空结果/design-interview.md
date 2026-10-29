<!-- design-interview-policy: design-tree-v1 -->
# 设计访谈

本文件持久保存需求和计划阶段的设计树访谈。事实由 Agent 使用只读源码、文档或 MCP 查询；用户只决定方案。历史尝试不得删除，输入摘要变化后把旧尝试标记为 `superseded` 并追加新尝试。

复杂度字段只使用 `yes`、`no` 或 `unknown`。任一字段为 `yes` 或 `unknown` 时按 `non-trivial`。`lite` 只有全部为 `no` 才能跳过两阶段访谈；`standard` 的非简单需求必须访谈，计划阶段可用计划评审代替第二次访谈；`strict` 的非简单需求和计划都必须访谈。

## requirements/R-001

- status: completed
- provider: iteration-design-interview
- provider_version: design-tree-v1
- question_protocol: inline-confirmation-v1
- input_digest: d6fd668dd02f6d0477db0cd4b881e20c1603881a394a5207fb5a71195c8705dd
- started_at: 2026-10-27T18:12:00+08:00
- completed_at: 2026-10-27T18:16:00+08:00
- classification: non-trivial
- classification_reason: 下拉会看到别人的流量广告位，属于权限。请求对象要换位置。页面和接口分在两个仓库。
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
| Q1 鲲鹏报表选了流量广告位时，应该怎么处理？ | 页面上把这个筛选项藏起来或禁用，后端恢复成选了就返回空。这样不会把全量数据当成筛选结果。 | 按推荐做 | resolved | 用户原话：Q1 按推荐做 |

### 假设与风险

- 已核对：新下拉只在三个条件不全空时才查。只传关键字时 SQL 没有供应商 `IN`。老下拉在供应商列表为空时，用 `publisherServer.list` 收口到当前用户能看的供应商。
- 已核对：鲲鹏列表、趋势、导出都走 `hasUnsupportedFilters`。流量广告位已经从「不支持」里拿掉，所以会返回未按它过滤的数据。
- 已核对：请求对象是 `TrafficPlaceService` 里的内部类。字段是 `publisherIdList`、`searchKey`、`trafficPlaceIdList`。

## plan/P-001

- status: completed
- provider: iteration-design-interview
- provider_version: design-tree-v1
- question_protocol: inline-confirmation-v1
- input_digest: 4c781ff637f69bf2df0f714a4dd7250f75ece8e467c1a88d62ff09f7caf99b35
- started_at: 2026-10-27T18:20:00+08:00
- completed_at: 2026-10-27T18:22:00+08:00
- classification: non-trivial
- classification_reason: 计划沿用已批准的需求。002 还占着两个真实目录，检出方式要先定。
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
| Q1 002 还占着原来的两个代码目录。这次改动放到各自的新分支副本上，可以吗？ | 可以。管理端从 feat-zhoutao 拉出 feat-zhoutao-dropdown-scope，页面从 feat-20261027-bff 拉出 feat-20261027-bff-dropdown-scope。改完停在新分支，不自动合并，也不改 002 的目录。 | 按推荐做 | resolved | 用户原话：Q1 按推荐做。 |

### 假设与风险

- 已核对：002 处于验收，计划检出仍是两个真实目录。管理端真实目录当前在 `feat-zhoutao`，页面真实目录当前在 `feat-20261027-bff`。同一条分支不能再检出到副本。

