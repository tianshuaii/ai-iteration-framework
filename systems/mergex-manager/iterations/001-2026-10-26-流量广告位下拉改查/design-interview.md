<!-- design-interview-policy: design-tree-v1 -->
# 设计访谈

本文件持久保存需求和计划阶段的设计树访谈。事实由 Agent 使用只读源码、文档或 MCP 查询；用户只决定方案。历史尝试不得删除，输入摘要变化后把旧尝试标记为 `superseded` 并追加新尝试。

复杂度字段只使用 `yes`、`no` 或 `unknown`。任一字段为 `yes` 或 `unknown` 时按 `non-trivial`。`lite` 只有全部为 `no` 才能跳过两阶段访谈；`standard` 的非简单需求必须访谈，计划阶段可用计划评审代替第二次访谈；`strict` 的非简单需求和计划都必须访谈。

## requirements/R-001

- status: completed
- provider: grill-me
- provider_version: design-tree-v1
- input_digest: e41fa33a82d6b7982261885ddf9e8aafa22bb4690d2063d49fc14d36a1d96fae
- started_at: 2026-10-26T16:45:30+08:00
- completed_at: 2026-10-26T17:07:04+08:00
- classification: non-trivial
- classification_reason: 新增搜索接口，并改 ADX 报表传参。多曝光报表要删除页面、接口和菜单。页面在 mediatom-web，接口和菜单数据在 mergex-manager。report_kunpeng 没有流量广告位列，选中后不拿它筛表。选中供应商且关键字为空时会一次返回这些 ID。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: yes
- complexity.permission_or_security: yes
- complexity.concurrency: no
- complexity.performance: yes
- complexity.multiple_repositories: yes
- complexity.external_service: no
- complexity.deployment: no
- complexity.destructive_operation: yes
- complexity.uncertain: no

### 问答

| 问题 | 推荐答案 | 用户选择 | 状态 |
|---|---|---|---|
| 只有 ADX 报表改用新的流量广告位查询吗？ | 是。Funlink 分析、鲲鹏报表和映射管理继续用老接口。老接口不删除。 | 改 ADX 报表和鲲鹏报表。多曝光报表删除页面及其代码。老接口不删除。 | 已决 |
| 没选供应商时，下拉查哪些数据？广告位筛选还收窄它吗？ | 没选时按当前账号能看到的供应商查关联表。选了就只查选中的供应商。广告位不再收窄这个下拉。 | 对齐应用包名的异步搜索。供应商一变就再查。没选供应商时只按搜索关键字查。 | 已决 |
| 下拉怎么展示、怎么搜？ | 每行只显示流量广告位 ID，只按 ID 搜。同一个 ID 只留一行。搜索提示去掉「名称」。 | 只显示 ID。 | 已决 |
| 鲲鹏选了流量广告位后，报表按这个 ID 查出数吗？ | 要查出数。现在一带这个条件就返回空，下拉改了却仍然没数，筛选等于没用。 | 出数。随后核对表里没有这一列，改按下面一条执行。 | 已决 |
| 供应商变了，搜索框还是空的，要不要查？ | 不查。和包名一样，没有关键字且没有已选项时不请求。供应商变化时，只有搜索框里已经有字，才用新的供应商加上当前关键字再查。已选中的 ID 留着，不清空。 | 查。只查选中的供应商的流量广告位。 | 已决 |
| 多曝光报表删到哪一层？ | 删掉页面目录、路由组件、只给这页用的前端接口，以及后端 `POST /report/multiImpressReport` 和对应下载。菜单如果还在库里，页面删了会点不进去，菜单项也要一起下掉。聚合配置里名字带 funlink 的编辑限制不动，那不是这张报表。 | 删掉页面、只给它用的前端代码、后端查询和下载。菜单项也一起下掉。 | 已决 |
| 报表还认不认旧的「广告位 ID_流量广告位 ID」？ | 认。新选择只传流量广告位 ID。请求里如果还是旧拼接，取下划线后面那段再查，避免已保存的筛选条件突然没数。 | 认。 | 已决 |
| 鲲鹏表没有流量广告位列，选中后怎么出数？ | 下拉照改。选中的 ID 不拿去筛 report_kunpeng，取消「选了就返回空」，报表按其他条件出数。不用供应商反查冒充按流量广告位筛选。 | 按推荐做。 | 已决 |

### 假设与风险

- 已核对：应用包名搜索在关键字为空、且没有已选包名时，前端不发请求，后端也直接返回空列表。单个关键字按包含匹配。
- 已核对：ADX 全量报表查询前只保留带下划线的流量广告位值。鲲鹏查询、导出只要请求里带了流量广告位，就直接返回空。
- 已核对：`report_kunpeng` 的维度是日期、供应商、广告源、操作系统、样式、平台账号、平台。没有流量广告位列，SQL 里也没有这个条件。
- 已核对：多曝光页面在 `mediatom-web` 的 `FunlinkAnalyse`，接口是 `/report/multiImpressReport`。菜单来自 `sys_route_permission`，停用用 status，不是写死在前端。
- 已核对：`publisher_traffic_place_link` 只有供应商 id 和流量广告位 id。同步在 mergex-datasyn，本轮不改定时任务，也不建表。
- 聚合配置里的 funlink 编辑限制是另一处功能，不随多曝光报表一起删。

## plan/P-001

- status: completed
- provider: grill-me
- provider_version: design-tree-v1
- input_digest: a7d9fb8734ad7d85f030adcd4e53de80fec45b98e0a6e600d38b4486a2970edd
- started_at: 2026-10-26T17:10:30+08:00
- completed_at: 2026-10-26T17:16:00+08:00
- classification: non-trivial
- classification_reason: 计划要新增搜索接口、放宽报表 ID 解析、停用菜单并删除多曝光页面和接口。页面和接口分属两个仓库。选中供应商且关键字为空时一次返回这些 ID。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: yes
- complexity.permission_or_security: yes
- complexity.concurrency: no
- complexity.performance: yes
- complexity.multiple_repositories: yes
- complexity.external_service: no
- complexity.deployment: no
- complexity.destructive_operation: yes
- complexity.uncertain: no

### 问答

| 问题 | 推荐答案 | 用户选择 | 状态 |
|---|---|---|---|
| 两个仓库用共享目录还是单独副本？ | 用现在的真实目录。这套系统里没有别的实现中或验收中轮次占用这两个仓库。 | 需求审批没有要求单独副本。按框架默认用真实仓库。 | 已决 |
| 搜索页和公共文件已经超过 300 行，这轮先拆文件吗？ | 不拆。已批准的文件名单里没有新文件。拆文件要改需求范围，需求审批会失效。这轮只改流量广告位那几处。 | 按已批准的文件名单做，不扩大范围。 | 已决 |
| 关键字拆分和去重放在哪，测试要不要连数据库？ | 放在管理端现有服务里，单测直接调用。SQL 只负责查出 ID。测试不连数据库。 | 按推荐。规格已经要求去重，测试策略也要求不连库就能挡住这些错误。 | 已决 |
| 菜单 SQL 这轮执行吗？ | 只把脚本放进管理端仓库，不执行。 | 规格写明执行要另外授权。需求审批没有授权改库。 | 已决 |

### 假设与风险

- 已核对：管理端当前分支是 `feat-zhoutao`，页面仓库当前分支是 `feat-20261021-dashboard-today`。
- 已核对：系统里另一条实现或验收轮次在 bff-sso，不使用这两个仓库。
- 已核对：菜单组件名存在前端路由表的 `FunlinkAnalyse`，库字段是 `route_config`，启用查询用 `status = 'A'`。
- 已核对：ADX 搜索页 370 行，鲲鹏搜索页接近 300 行，公共 mixin 超过 300 行。本轮不新增页面文件。
- 菜单脚本执行前，菜单项还会显示。页面代码删掉后旧地址进不去。菜单是否消失要等另外授权后再验。
