# 改动范围

仓库绝对路径写在这套系统的 `overview.md`。系统名：`mergex-manager`。

当前范围只包含广告平台账号的前端接入和后端独立策略存储。本阶段只定义范围，不修改产品文件。

## 要改的项目

| 项目 | 这一轮它负责什么 |
|---|---|
| `mediatom-web` | 在 MergeX 广告平台账号新增/编辑页接入现有 `TrafficDirectionV4`，保持字段结构，权限前缀使用 `platform:`，并补齐列表加载、默认值、提交和回显。 |
| `mergex-manager` | 为广告平台账号补齐流量筛选保存、回显和策略生效能力，并新增专用 `policy_manage` 维度与挂载字段。 |

## 页面上要改的位置

| 位置 | 现在 | 改完 |
|---|---|---|
| 广告平台账号新增/编辑 | 只有账号基础信息、过滤类型和 QPS 等，没有流量筛选。 | 增加完整流量筛选，权限前缀为 `platform:`；新增/编辑均可保存、回显并真实生效。 |
| 连接管理供应商流量筛选 | 已有完整源表单。 | 仅作为复用真源，不改变现有行为。 |
| 广告源新增/编辑流量筛选 | 已有同构实现和加载范例。 | 仅作为接入参考，不改变现有行为。 |

## 大致文件

### `mediatom-web`

- `src/viewsForManage/Budget/EditPlatAccount/index.vue`：广告平台账号新增/编辑接入点。
- `src/viewsForManage/Budget/EditPlatAccount/data.js`：广告平台默认值与回显结构；若实现前确认文件不存在，则按页面职责新增，避免继续扩大主文件。
- `src/platform/mergex/components/StrategyForms/TrafficDirectionV4/`：共享流量筛选组件；原则上只复用，除非目标接入必需且不改变既有调用方行为。
- `src/apiForManage/advertisement.js`：仅在目标接口契约需要同步时修改。
- 对应广告平台页定向测试。

### `mergex-manager`

- `src/main/java/com/ydmob/mergex/managerserver/model/vo/budget/platform/CreateSysUserPlatformVo.java`：广告平台新增契约。
- `src/main/java/com/ydmob/mergex/managerserver/model/vo/budget/platform/UpdateSysUserPlatformVo.java`：广告平台更新契约。
- `src/main/java/com/ydmob/mergex/managerserver/model/vo/sys/SysUserPlatformVo.java`：新老详情回显契约。
- `src/main/java/com/ydmob/mergex/managerserver/service/budget/impl/PlatAccountServiceImpl.java`：新老增加、更新、详情及删除清理的策略处理。
- `src/main/java/com/ydmob/mergex/managerserver/common/constant/PolicyConstant.java`：复用已有流量定向 `type=1`，新增广告平台账号维度常量。
- `src/main/java/com/ydmob/mergex/managerserver/model/entity/feature/PolicyManage.java`、`model/dto/query/policy/PolicyQuery.java`、`service/feature/impl/PolicyServiceImpl.java` 及 `src/main/resources/mapper/PolicyManage.xml`：增加平台账号挂载字段、查询条件与策略存储支持。
- `sql/policy_manage_plat_account_id.sql`：只新增 `policy_manage.plat_account_id` 字段，不新增、调整或删除任何表索引；只交付文件，不自动执行正式库迁移。
- 对应策略维度与平台账号服务定向测试。

## 明确不动

| 项目或模块 | 为什么不动 |
|---|---|
| 广告位新增/编辑及其后端 | 用户已明确移出范围；不改 `EditPlace`、`CreateAdPlaceVo`、`AdPlaceServerImpl` 或广告位预算过滤。 |
| `mergex-datasyn` | 本需求不是定时任务，不涉及同步或报表推送。 |
| `mediatom-web` 中的 Mediatom 页面 | 系统边界只允许改 MergeX 页面。 |
| React 前端 | 本系统明确不收 React 前端。 |
| 正式数据库和正式数据 | 只交付迁移文件；后续即使需要迁移也必须另行授权。 |
| `policy_manage` 表索引 | 用户明确不需要表索引；产品迁移文件不得新增索引，测试库已有索引也不在本轮自动删除。 |
