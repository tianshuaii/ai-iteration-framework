# 改动范围

仓库绝对路径写在这套系统的 `overview.md`。默认按那个路径打开原仓库；未提交修改不改变路径。只有另一 `implement` 或 `verify` 轮次使用同一仓库时，才按本轮 `workspace.md` 中由脚本登记的 `.worktrees/` 临时检出打开。系统名：mediatom

## 要改的项目

| 项目 | 这一轮它负责什么 |
|---|---|
| `mediatom-web` | 综合报表和小时报表都把应用状态放在应用前面，并按同一套规则刷新应用下拉 |
| `mediatom-manager` | applistForD 增加可选账户和状态参数，不传时保持现有结果 |

## 页面上要改的位置

同一页上相关的说明、筛选、表格、弹窗都要写。不要只写用户圈出的那一块。

| 位置 | 现在 | 改完 |
|---|---|---|
| 综合报表筛选条 | 应用在前，应用状态在后 | 应用状态在前，应用在后 |
| 综合报表应用下拉 | 未选账户走 applistForD，选中账户走 getAppListByAdminIdList | 两种情况都走扩展后的 applistForD，并只展示当前所选状态 |
| 综合报表广告位、流量分组、广告源 | 随已选应用级联 | 已选应用因状态被取消后，这些下拉跟着刷新 |
| 小时报表筛选条 | 应用在前，应用状态在后 | 应用状态在前，应用在后 |
| 小时报表应用下拉 | 未选账户走无参数 applistForD，选中账户走 getAppListByAdminIdList，状态不刷新下拉 | 与综合报表相同：按所选状态请求 applistForD，选中账户时同时传账户；空状态不请求 |
| 小时报表广告位、流量分组、广告源 | 随已选应用级联 | 已选应用因状态被取消后，这些下拉跟着刷新 |

## 大致文件

### mediatom-web

- `src/views/reportdatas/SynthReport/SynthSearch/index.vue`：调整筛选顺序；状态或账户变化时用当前账户和状态请求 applistForD；一个状态都没选时清空应用下拉
- `src/views/reportdatas/HoursReport/HoursSearch/index.vue`：应用状态移到应用前面；按综合报表同一套规则传状态和账户、保留仍可见的已选应用，并在状态变化后刷新后续下拉
- `src/views/reportdatas/shared/reportSearchLoader.js`：综合报表和小时报表都走 applistForD。不再让这两个页面调用 getAppListByAdminIdList
- `src/api/media.js`：getGlobalAppListForD 增加可选账户和状态参数。不改 `src/api/common.js` 里的账户应用接口定义

### mediatom-manager

- `src/main/java/com/ymob/saas/managerserver/controller/traffic/AppController.java` 及对应 Service：`GET /app/applistForD` 接收可选账户编号和可选应用状态
- `src/main/resources/mapper/AppMapper.xml` 的 `getAppListNewIncludeD`：按上面的参数口径过滤，并选出 `apiSource`。不改 `getAppListByAdminIdList`

### 补测试

- 后端为状态过滤补不连库的参数或 SQL 条件测试；具体命令等计划阶段按仓库现有 Surefire 跳过测试的情况再定

## 明确不动

| 项目 | 为什么不动 |
|---|---|
| `mediatom-web` 的 `src/viewsForManage` | MergeX 页面不归这套系统 |
| 小时报表的日期、SDK 版本、应用版本 | 这些筛选不是应用状态下拉联动 |
| 小时报表未选应用且未选账户时的广告位全量加载 | 只对齐应用状态和应用下拉，不改这条原有广告位口径 |
| `POST /app/getAppListByAdminIdList` | 页面不再调用。接口封装和默认 SQL 保留，本轮不改 |
| 应用状态枚举和报表结果里已有的 `appStsList` 过滤 | 已有口径继续使用，本轮补的是下拉候选项 |
| 数据库表结构 | 状态字段已经存在，不新增迁移 |
