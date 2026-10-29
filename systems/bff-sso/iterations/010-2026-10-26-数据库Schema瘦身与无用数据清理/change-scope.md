# 改动范围

仓库绝对路径写在这套系统的 `overview.md`。默认按那个路径打开原仓库；未提交修改不改变路径。只有另一 `implement` 或 `verify` 轮次使用同一仓库时，才按本轮 `workspace.md` 中由脚本登记的 `.worktrees/` 临时检出打开。系统名：`bff-sso`

## 要改的项目

| 项目 | 这一轮它负责什么 |
|---|---|
| `adx-admin-backend` | 新增唯一数据库迁移、删除清单自检与迁移测试；治理表结构变化只在这里执行。 |
| `adx-bff-backend` | 同步 Prisma 模型，并修正因删除表、字段或数据而受影响的查询与测试。 |
| `adx-sso-backend` | 同步 `public_management` 的最小 Prisma 模型，删除已经不存在或本轮确认删除的字段声明。 |

## 页面上要改的位置

同一页上相关的说明、筛选、表格、弹窗都要写。不要只写用户圈出的那一块。

| 位置 | 现在 | 改完 |
|---|---|---|
| BFF 服务/接口项目/运行包管理页 | 可能仍能查询历史软删或冗余包数据。 | 只展示物理清理后保留的有效服务、项目和运行包。 |

## 大致文件

### `adx-admin-backend`

- `prisma/schema.prisma`：同步清理后的表和字段模型。
- `prisma/migrations/<本轮迁移>/migration.sql`：按依赖顺序执行数据和结构清理，并提供前置保护条件。
- `prisma/migrations/<本轮迁移>/` 下的定向自检：校验候选集、删除后不变量和可重复失败保护。

### `adx-bff-backend`

- `prisma/schema.prisma`：同步保留结构。
- `src/**` 中实际引用删除对象的最小调用点：仅在只读影响分析确认后逐项列明，当前不得泛化修改整个 `src/`。

### `adx-sso-backend`

- `prisma/schema.prisma`：同步 `sys_sub_service` 当前真实字段，清除已不存在的旧字段声明。
- `src/**` 中实际引用删除对象的最小调用点：仅在只读影响分析确认后逐项列明。

### 补测试

- 迁移前置检查、迁移后清单、关键外键与 active/previous 包保留检查。
- BFF 服务列表、运行包激活/回滚、接口项目查询和转发定向回归。
- SSO 登录与会话定向回归。

## 明确不动

| 项目 | 为什么不动 |
|---|---|
| `adx-admin-frontend` | 当前需求没有新增页面或交互；只要接口返回有效数据即可。 |
| `adx-bff-frontend` | 当前需求没有前端行为变化。 |
| `mergex-manager` | 仅作为密码逻辑参考，且不属于本系统登记仓库。 |
