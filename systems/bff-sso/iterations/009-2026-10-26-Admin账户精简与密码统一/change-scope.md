# 改动范围

仓库绝对路径写在这套系统的 `overview.md`。本阶段只读产品源码，最终精确文件范围在访谈结论后收敛。系统名：`bff-sso`。

## 要改的项目

| 项目 | 这一轮它负责什么 |
|---|---|
| `adx-admin-frontend` | 只保留账户页面和必要壳层，删除其余页面、菜单、路由、资源配置、审计查询和失效 SDK。 |
| `adx-admin-backend` | 收敛账户治理接口；删除非账户服务、RPC、模型和数据表；数据库迁移只在这里建立和执行。 |
| `adx-sso-backend` | 统一密码生成/校验/改密，并在删除角色后按最终身份模型完成登录判断。 |
| `adx-bff-backend` | 删除非账户治理转发接口；将仍需的超管/会话判断从角色依赖迁到最终账户模型。 |
| `adx-bff-frontend` | 在后端删除角色返回后，改用账户权威字段维持网关管理端门禁；不删除网关运行日志页面。 |

## 页面上要改的位置

同一页上相关的说明、筛选、表格、弹窗都要写。不要只写用户圈出的那一块。

| 位置 | 现在 | 改完 |
|---|---|---|
| Admin 侧栏 | 概览、数据管理、关联管理、审计日志。 | 只显示账户入口。 |
| Admin 默认路由 | 登录后进入概览。 | 登录后进入账户列表。 |
| 账户列表 | 含创建者、角色、租户及租户管理员等依赖字段。 | 展示账号、昵称、账户类型、状态、创建/更新时间和操作；提供关键词、账户类型和状态筛选。 |
| 账户新增/编辑 | 创建者和角色为必填，并含租户相关选项。 | 新增含账号、双次密码、昵称、账户类型和状态；编辑时账号和类型只读，只改昵称/状态；重设密码独立弹窗；表单在输入与失焦时校验，保留必填星号并关闭标签冒号。 |
| 审计日志 | `/audit-logs` 可访问并查询治理记录。 | 页面、菜单、路由和查询调用不存在。 |

## 大致文件

### `adx-admin-frontend`

- `src/app/router.tsx`、`src/app/lazy-pages.ts`：只保留账户相关路由。
- `src/components/layout/AdminLayout.tsx`：只保留账户菜单和与最终身份模型一致的顶栏。
- `src/features/resources/**`、`src/features/accounts/**`：收敛到账户列表、表单和详情所需代码。
- `src/features/dashboard/**`、`src/features/relations/**`：删除非账户与治理审计页面代码。
- `src/api/sub-services/**`：同步删除已下线 RPC 的生成客户端。

### `adx-admin-backend`

- `proto/admin/v1/governance.proto`、`governance_models.proto`：只保留账户治理合约。
- `src/governance/**`、`src/grpc/governance-grpc.server.ts`：删除非账户治理与审计查询，重构账户依赖。
- `src/gateway/forward-context.service.ts`、`src/authz/**`、`src/catalog/**`：删除角色、租户、路由和权限依赖，以账户权威字段重构 ForwardContext；Portal 动态授权稳定返回空集合。
- `prisma/schema.prisma`、`prisma/migrations/**`、`prisma/seed*.ts`：删除账户关系字段并同步最终账户模型、48 字符密码规则和一次性超管恢复入口；迁移只在本项目建立。

### `adx-sso-backend`

- `src/auth/auth.service.ts`、`src/auth/dto/auth.dto.ts` 及对应测试：统一密码和登录身份判断。
- 新增独立的 48 字符密码编解码工具，以 Node `crypto` 生成数字盐，统一创建、登录、改密和管理员设密，避免散落硬编码。

### `adx-bff-backend`

- `src/admin/admin.controller.ts`、治理转发与 RPC 目录文件：删除非账户治理和审计查询入口。
- `src/admin/gateway-admin.service.ts`、`src/auth/**`、`src/clients/admin-forward-context.client.ts`：管理门禁统一改查 `accountType === SUPER_ADMIN`，不再查角色；`PLATFORM_STAFF` 只保留普通代理会话；密码、状态和软删除变更同步吊销目标 Session。

### `adx-bff-frontend`

- `src/lib/admin-api.ts`、`src/stores/auth.store.ts`、角色门禁组件及测试：改用 `accountType`，仅 `SUPER_ADMIN` 可进入网关管理端。

### 补测试

- 五个涉及项目为被删除入口、账户 CRUD、旧密码失效与重设、登录、Session ForwardContext 和网关超管门禁补定向自动测试。

## 明确不动

| 项目 | 为什么不动 |
|---|---|
| `/Users/mrzater/java/mergex-manager` | 仅作为密码逻辑参考，不属于本系统产品仓库。 |
| 网关接口编辑、接入服务与运行包模块 | 与账户单一化无关。 |
| 网关请求查询与实时日志 | 与截图中的治理审计不同，已确认继续保留。 |
