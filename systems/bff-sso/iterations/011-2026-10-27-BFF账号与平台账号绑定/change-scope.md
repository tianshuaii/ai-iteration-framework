# 改动范围

仓库绝对路径写在这套系统的 `overview.md`。默认按那个路径打开原仓库；未提交修改不改变路径。只有另一 `implement` 或 `verify` 轮次使用同一仓库时，才按本轮 `workspace.md` 中由脚本登记的 `.worktrees/` 临时检出打开。系统名：`bff-sso`

## 要改的项目

| 项目 | 这一轮它负责什么 |
|---|---|
| `adx-admin-backend` | 作为治理 Schema 唯一迁移源，新增接入平台、平台-子服务、BFF-平台账号绑定表及约束。 |
| `adx-bff-backend` | 同步 Prisma 模型，提供超管专用的平台与绑定 CRUD，复用子服务/接口清单并校验登录配置。 |
| `adx-admin-frontend` | 将“账号”改名为“BFF 账号”，新增“接入平台”与“平台账号绑定”页、路由、菜单、表单和请求封装。 |

## 页面上要改的位置

| 位置 | 现在 | 改完 |
|---|---|---|
| Admin 左侧菜单 | 只有“账号”。 | 按顺序显示“BFF 账号”、“接入平台”、“平台账号绑定”。 |
| BFF 账号列表 | 标题、说明、按钮和提示使用“账号”。 | 用户可见名称改为“BFF 账号”；筛选、表格列、新建/编辑/设密/启停/软删除行为不变。 |
| 接入平台列表 | 无。 | 展示名称、子服务、登录子服务、登录接口、配置状态、创建/更新时间和编辑/删除操作。 |
| 接入平台新建/编辑弹窗 | 无。 | 名称必填；子服务多选；登录子服务单选且必须来自已选子服务；登录接口单选且随登录子服务联动。 |
| 平台账号绑定列表 | 无。 | 展示 BFF 账号、接入平台、平台账号 ID、BFF 账号状态、平台登录配置状态、创建/更新时间和编辑/解绑操作；账号失效时保留旧绑定并明确标识。 |
| 平台账号绑定新建/编辑弹窗 | 无。 | 新建时选 BFF 账号、平台并填平台账号 ID；编辑时两个主体只读，只能改 ID。 |
| 空状态、校验和冲突提示 | 无。 | 明确区分无数据、平台名重复、绑定冲突、BFF 账号失效、登录配置失效和有绑定不可删平台。 |

## 大致文件

### `adx-admin-backend`

- `prisma/schema.prisma`：新增三类模型、关系、`yn` 和字段注释。
- `prisma/migrations/<本轮迁移>/migration.sql`：新建 `sys_access_platform`、`sys_access_platform_sub_service_link`、`sys_bff_platform_account_link` 及有效数据唯一索引。
- `prisma/scripts/public-management-comment-manifest.ts`：同步新表和字段注释清单。

### `adx-bff-backend`

- `prisma/schema.prisma`：只同步新模型，不新增迁移。
- `src/admin/admin.controller.ts` 或职责等价的独立 Controller：新增 `/api/admin/access-platforms` 与 `/api/admin/platform-account-bindings` CRUD。
- `src/admin/admin.service.ts` 或拆分后的平台/绑定 Service：实现数据事务、软删除、唯一性冲突和失效配置判定。
- `src/admin/dto/admin.dto.ts` 或职责等价的独立 DTO：新增列表、新建、编辑入参校验。
- `src/openapi/service-openapi-sync.service.ts`：仅在需要提供稳定接口标识或批量校验时做最小扩展。
- `src/admin/**/*.spec.ts`：补平台生命周期、唯一性、权限和失效配置定向测试。

### `adx-admin-frontend`

- `src/components/layout/AdminLayout.tsx`：三个菜单及选中态。
- `src/app/router.tsx`、`src/app/lazy-pages.ts`、`src/app/route-paths.ts`：新增超管路由与懒加载入口。
- `src/lib/admin-api.ts`：平台、子服务/接口选项、绑定的类型和 API 封装。
- `src/features/accounts/AccountPage.tsx` 及相关弹窗：只改用户可见名称。
- `src/features/access-platforms/**`：新增平台列表、编辑弹窗和表单模型。
- `src/features/platform-account-bindings/**`：新增绑定列表、编辑弹窗和表单模型。
- `src/**/*.spec.tsx`：补路由、表单联动、唯一性错误和改名回归。

## 明确不动

| 项目 | 为什么不动 |
|---|---|
| `adx-sso-backend` | 本轮不实际调用外部登录接口，SSO 不读新表。 |
| `adx-bff-frontend` | 需求只改 Admin 账号管理页，不改网关管理页。 |

