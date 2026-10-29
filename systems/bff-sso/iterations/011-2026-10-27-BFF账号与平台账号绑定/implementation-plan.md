# 实现计划

## 总体做法

本轮按“治理 Schema 与唯一约束 → BFF 管理接口与状态判定 → Admin 页面与交互”的顺序实施。三个任务完成后统一执行去重检查和整轮 code review，修复并复验后才进入 `verify`；不会在每个任务结束后机械重复全量检查。

三个目标仓库使用 `overview.md` 登记的真实目录。当前没有其他 `implement` 或 `verify` 轮次占用这些仓库，不创建 worktree。`adx-bff-backend/CODE_REVIEW.md` 是接管前未跟踪文件，本轮不得覆盖或纳入成果。

## 1. 治理数据模型与迁移

迁移只在 `adx-admin-backend` 创建，BFF 后端只同步 Prisma 模型：

- `sys_access_platform` 保存平台名称、登录子服务、登录接口类型、稳定接口键与显示快照、`yn`、更新时间和操作者。平台名称 trim 后非空，并对有效数据建立 partial unique 索引。
- `sys_access_platform_sub_service_link` 保存平台和子服务多选关系；有效 `(access_platform_id, sub_service_id)` 组合唯一。
- `sys_bff_platform_account_link` 保存 BFF 账号、平台和平台账号 ID；有效 `(bff_account_id, access_platform_id)` 与 `(access_platform_id, platform_account_id)` 分别唯一。
- 三张表使用 `BigInt` 主键/外键、`yn=1` 表示有效，外键使用 `RESTRICT`，删除业务只更新 `yn`；全部字段进入数据库注释清单。
- Prisma 不伪造无法表达的 partial unique；唯一性由 Admin 后端 migration SQL 建立，BFF 在写入时捕获数据库冲突并返回明确错误。

登录接口没有独立 endpoint 表，因此不建立伪外键。BFF 统一生成稳定键：HTTP 使用规范化的 `METHOD + path`，gRPC 使用 `grpcFullMethod`；同时保存 `operationId`、method、path 或 full method 快照，供配置失效后仍能展示原选择。运行包替换不会回写旧记录。

## 2. BFF 管理接口

现有 `AdminController`、`AdminService` 和 `admin.dto.ts` 已达到或超过文件规模约束，新能力拆成独立 Controller、Service、DTO 与测试，并只在 `admin.module.ts` 注册：

- 平台接口：`GET/POST /api/admin/access-platforms`、`PUT/DELETE /api/admin/access-platforms/:id`。
- 绑定接口：`GET/POST /api/admin/platform-account-bindings`、`PUT/DELETE /api/admin/platform-account-bindings/:id`。
- 继续复用 `GET /api/admin/services`、`GET /api/admin/openapi/endpoints?serviceId=...` 和现有账号列表，不新建第二套选项协议。
- 两组新接口继续受 `AdminSessionGuard` 保护；Guard 已校验 Admin 渠道、启用的 `SUPER_ADMIN`、账号有效性和 Session。

平台保存使用同一事务校验名称、有效子服务、登录子服务归属和当前接口存在性，并软删/恢复/新增多选关联。列表每次用当前生效运行包重新匹配接口键；匹配不到时保留记录并返回“登录配置已失效”。存在有效绑定的平台禁止软删除。

绑定保存使用同一事务校验 BFF 账号启用且未删除、平台及其登录配置有效、平台账号 ID trim 后非空；ID 保留大小写并按数据库精确值判重。编辑只能修改平台账号 ID，不能换 BFF 账号或平台。账号禁用或软删除后列表仍保留旧绑定并返回“BFF 账号已失效”；禁用账号重新启用后按实时状态恢复有效。

## 3. Admin 前端

- 将现有账号菜单、标题、说明和相关提示改为“BFF 账号”，不改变账号字段和操作。
- 新增 `/access-platforms` 与 `/platform-account-bindings` 两条超管路由、懒加载入口和相邻菜单项。
- 两个功能分别拆成 Page、EditorModal、API、model 和测试文件，避免继续扩张已达 300 行的 `AccountPage.tsx`，所有新增前端源码保持不超过 300 行。
- 平台表单选择登录子服务后加载接口；登录子服务变化或从平台子服务多选中移除时清空登录接口，前端先做归属校验，后端仍作为最终裁决。
- 新增/编辑表单统一使用 `colon={false}`、`validateTrigger={['onChange', 'onBlur']}`，有 label 的必填项保留必填星号。
- 绑定新建只提供有效 BFF 账号和有效平台；旧绑定列表仍展示失效账号或失效登录配置。编辑时 BFF 账号和平台只读，只允许修改平台账号 ID。

## 4. 统一检查、审核与验收边界

- 全部任务完成后汇总执行 `tasks.md` 的三组检查，重复的 Prisma 生成、构建或测试只运行一次并记录输入摘要。
- 对三个仓库本轮整体差异执行一次统一 code review，修复 P0/P1/P2 并做必要复验；通过后才进入 `verify`。
- `verify` 按 TC-01 至 TC-10、SR-01 和 SR-02 执行。实际数据库迁移、启动服务和创建验收夹具仍需分别获得明确授权。

## 为什么这样切

- Admin 后端保持治理 Schema 唯一迁移源，避免多仓 migration 漂移。
- BFF 是浏览器唯一业务入口，在这一层集中做权限、事务、唯一性错误转换和实时失效判定，前端不复制数据一致性规则。
- 登录接口用协议稳定键加显示快照，而不是依赖不存在的 endpoint 表，既能动态判定失效，也能保留历史可读性。
- 前端按功能目录拆分，避免继续扩大已经到达行数上限的账号页和后端 Admin 大文件。

## 怎样避开“不做”

- 不修改 `adx-sso-backend` 或 `adx-bff-frontend`。
- 不实际调用外部平台登录接口，不新增凭据、密码、Token、入参映射或 Token 生命周期逻辑。
- 不从外部平台同步账号，不自动迁移已有 BFF 账号绑定。
- 计划和实现阶段都不自动执行数据库迁移、启动服务、提交、推送或部署。

## 字段与接口变化

当前尚未改产品代码；下表是计划目标。

| 字段或路径 | 谁在用 | 计划变化 |
|---|---|---|
| `sys_access_platform` | BFF 平台 CRUD、Admin 平台页 | 新增平台、登录子服务、接口稳定键/快照、软删除和审计字段。 |
| `sys_access_platform_sub_service_link` | BFF 平台保存与列表 | 新增平台和多个子服务的有效关联。 |
| `sys_bff_platform_account_link` | BFF 绑定 CRUD、Admin 绑定页 | 新增 BFF-平台-平台账号 ID 绑定与两组有效唯一约束。 |
| `/api/admin/access-platforms` | Admin 前端 | 新增列表、创建、编辑和软删除。 |
| `/api/admin/platform-account-bindings` | Admin 前端 | 新增列表、创建、修改账号 ID 和软删除解绑。 |
| `/accounts` 用户可见文案 | Admin 用户 | “账号”改为“BFF 账号”，行为不变。 |
