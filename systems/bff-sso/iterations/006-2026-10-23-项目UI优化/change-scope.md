# 改动范围

仓库绝对路径写在这套系统的 `overview.md`。系统名：`bff-sso`。

网关前端的改动在真实仓库 `/Users/mrzater/docker/adx/adx-bff-frontend` 的分支 `iteration-006-ui`。账号权限前端在 `/Users/mrzater/docker/adx/adx-admin-frontend`。临时目录已删除。

## 要改的项目

| 项目 | 这一轮它负责什么 |
|---|---|
| `adx-bff-frontend` | 全部页面的排法，以及和现在功能对不上的说明。 |
| `adx-admin-frontend` | 同上。 |
| `adx-bff-backend` | 只改会显示给人的提示，且仅当它还把网关说成只维护子服务或 OpenAPI。找到后再补具体文件。 |
| `adx-admin-backend` | 同上。没有这样的句子就不改。 |

## 页面上要改的位置

每个页面都包括：页头、筛选、表头、空状态、按钮旁说明、新增和编辑弹窗、结果弹窗、详情、抽屉。

| 位置 | 现在 | 改完 |
|---|---|---|
| 网关登录 | 左栏一句长说明，右栏表单直接铺开 | 左栏三句短话，右栏白卡片 |
| 账号权限登录 | 同上 | 同一套排法，三句保持账号权限自己的意思 |
| 两个前端的每个登录后页面 | 页头、筛选、表格、弹窗各排各的 | 页头一行，筛选宽屏一排，表格不贴边，弹窗和抽屉同一套间距 |
| 网关概览第一张卡片 | 子服务 | 接入服务 |
| 页面说明 | 有的还在讲旧功能，或和菜单叫法不一致 | 改成现在的说法。类型名「功能子服务」「业务子服务」「子服务类型」不改 |
| 请求查询 | 耗时说法已经定过 | 排法和其余说明可以改。耗时列、详情耗时、时间线阶段名、记录不完整提示不改 |
| 接口错误弹出的句子 | 个别句子可能还在讲旧功能 | 只改「只维护子服务 / OpenAPI」这类过时说法 |

## 大致文件

改现有文件，不新增迁移。样式入口两边都包括 `src/styles/global.css`、`src/app/providers.tsx`、`src/components/layout/AdminLayout.tsx`。

网关前端页面：

- `src/features/auth/LoginPage.tsx`、`src/features/auth/ForbiddenPage.tsx`
- `src/features/dashboard/DashboardPage.tsx`
- `src/features/resources/ResourcePage.tsx`、`src/features/resources/ServiceConnectivityModal.tsx`
- `src/features/interface-version/InterfaceProjectPage.tsx`、`InterfaceBranchPage.tsx`、`InterfacePackagePage.tsx`、`InterfaceWhitelistPage.tsx`、`RuntimePackagePage.tsx`、`BranchWorkspaceDraftDrawer.tsx`、`RuntimePackageInventoryDrawer.tsx`
- `src/features/openapi/OpenapiUpstreamPage.tsx`、`OpenapiFacadeListPage.tsx`、`OpenapiFacadeEditPage.tsx`、`OpenapiEndpointDetailPage.tsx`、`OpenapiCompositeListPage.tsx`、`OpenapiCompositeEditPage.tsx`、`OpenapiCompositeConfigPage.tsx`、`components/ProtoEnumValuesModal.tsx`、`components/ReconcilePreviewModal.tsx`
- `src/features/request-logs/RequestQueryPage.tsx`、`ConsoleLogsPage.tsx`、`request-logs-table.util.tsx`、`request-log-timeline.util.ts`、`RequestLogLifecycleTimeline.tsx`

账号权限前端页面：

- `src/features/auth/LoginPage.tsx`、`src/features/auth/ForbiddenPage.tsx`
- `src/features/dashboard/DashboardPage.tsx`
- `src/features/resources/ResourcePage.tsx`、`ResourceListPanel.tsx`、`ResourceFilters.tsx`、`ResourceDetailDrawer.tsx`、`resource-columns.tsx`
- `src/features/accounts/AccountSystemPage.tsx`
- `src/features/relations/` 下全部页面：租户治理授权、页面权限绑定、角色路由授权、角色权限授权、账号路由直授、账号权限直授，以及这几项的配置页

两个后端：检索后再补具体文件。补上之前不准改。

## 不动

- `adx-sso-backend`
- 原来那份 `adx-bff-frontend` 目录
- 请求查询里的耗时原文，以及第 005 轮后端耗时文件
- 「功能子服务」「业务子服务」「子服务类型」
- 表结构、已保存数据、菜单项和登录判断函数
