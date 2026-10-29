# 实现计划

## 做法

### 1. 扩展广告平台账号策略挂载维度

- 在 `mergex-manager/sql/` 交付 `policy_manage` 增量 SQL：只新增可空 `plat_account_id` 及字段注释，移除已实现的 `ADD UNIQUE INDEX`，不新增、调整或删除任何普通、唯一或联合索引。Java 字段按新老平台账号主键使用 `Long`，SQL 使用与现有账号主键一致的 `BIGINT`。本轮只交付文件，不执行任何环境迁移。
- `PolicyConstant` 增加具名的广告平台账号维度常量，使用下一个未占用值 `9`；业务代码只引用常量。
- `PolicyManage`、`PolicyQuery`、`PolicyManage.xml` 同步 `platAccountId`；新维度只用 `plat_account_id` 查询，不解释或改写其他业务维度。
- 扩展 `PolicyServiceImpl` 的策略创建、查询与导出查询构建，让广告平台账号使用专用维度读写 `type=1` 策略。

### 2. 广告平台新老接口统一接入

- `CreateSysUserPlatformVo`、`UpdateSysUserPlatformVo`、`SysUserPlatformVo` 均新增 `trafficTargeting`，类型复用 `RtbTrafficDirectionVo`，内部仍使用 `trafficDirectionSwitch/trafficDirectionVo`。
- `PlatAccountServiceImpl` 对新老新增/更新都在账号 ID 确定后构建“平台账号维度 + `platAccountId`”的 `PolicyQuery`：开启时写入 `type=1`，关闭时只删该账号的流量定向。
- `/platAccount/getById` 和 `/platAccount/oldGetById` 统一回显；删除账号时同步清理该账号的 `type=1` 策略及关联。
- 主记录与规则写入复用现有 `PolicyService` 的 `updateTrafficDirection/deleteTrafficDirection/getTrafficDirection`，不新建另一套策略表或复制规则编解码。

### 3. 广告平台页复用流量筛选组件

- 在 `EditPlatAccount` 接入 `TrafficDirectionV4`，绑定 `formquery.trafficTargeting.trafficDirectionSwitch/trafficDirectionVo`，权限使用 `platform:trafficTargeting` 和 `platform:more`。
- 编辑页为导出组件提供广告平台账号维度 `9` 和当前账号 ID。
- 补齐品牌、安装应用、地区、国家、广告位类型和人群列表加载；回显时只做源组件需要的 `citySelectList`、`rangeDate` 和时段归一化。
- 在独立 `data.js` 中集中定义默认值，避免继续扩大已超 300 行的页面主文件，不把魔法值分散到提交和回显分支。
- 保留现有表单结构和校验方式，不关闭必填星，不改其他页面样式。

### 4. 按 T4 风险定向验证

- 后端增加平台账号策略维度和新老接口的 Mockito/JUnit 定向测试，覆盖开启、关闭、回显、删除清理与账号隔离。
- 前端增加广告平台页定向用例，检查默认关闭、权限前缀、列表加载、提交载荷与回显归一化。
- 通过差异边界检查确认广告位文件没有本轮改动。
- 静态检查迁移 SQL 只含 `plat_account_id` 字段 DDL，不含 `INDEX`、`KEY` 或其他索引操作；测试库已有索引不执行删除。
- 任务实现完成后统一执行去重检查和整轮 code review；本阶段不启动服务、不连正式库。

## 为什么这样切

- 表结构、查询对象和 Mapper 是“平台账号维度”的唯一真源，不让页面或平台 Service 猜测挂载字段。
- 平台账号新老接口最终都收口到 `PolicyService`，页面分流不会导致两套策略语义。
- 页面只组装表单、列表和载荷；规则的生成、更新和删除继续由后端策略层负责。

## 怎样避开「不做」

- 只改 `mediatom-web` 中 MergeX 的广告平台账号页，不改 `EditPlace`、Mediatom 页面和 React 前端。
- 不修改广告位 VO、Service 或既有预算过滤；实现后用差异列表作为范围门禁。
- 不改连接管理供应商、广告源已有业务语义；共享组件若不需要修正参数兼容，就不改它的字段和样式。
- 不修改 `mergex-datasyn`，不动正式数据，不自动执行 SQL、提交、推送、部署或启动服务。
- 不通过迁移文件新增或删除 `policy_manage` 表索引；测试库现有索引属于环境现状，不在本轮产品返工中处理。

## 字段变化

| 字段或路径 | 谁在用 | 计划变化 |
|---|---|---|
| `policy_manage.plat_account_id` | 策略主记录/查询/导出 | 新增可空 `BIGINT`，Java 使用 `Long`，仅平台账号维度使用；不配套新增表索引。 |
| `PolicyConstant` 平台账号维度 | 后端策略查询 | 新增具名常量，计划值 `9`。 |
| `trafficTargeting.trafficDirectionSwitch` | 广告平台账号新增/编辑 | 新增流量定向开关，默认 `0`。 |
| `trafficTargeting.trafficDirectionVo` | 广告平台页及后端 PolicyService | 新增外层包装下的规则对象，内部字段与源 `TrafficDirectionVo` 一致。 |
