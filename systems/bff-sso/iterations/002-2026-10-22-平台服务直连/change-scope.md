# 改动范围

仓库绝对路径写在这套系统的 `overview.md`，按那个路径打开原来的仓库。系统名：`bff-sso`。

## 要改的项目

| 项目 | 这一轮它负责什么 |
|---|---|
| `adx-admin-backend` | 找网关、找登录服务时，按配置走 Nacos 或固定地址。直连时仍踢登录、仍设密码。这一部分已经做完。 |
| `adx-bff-backend` | 内建服务第一次写入时用直连。地址读 Nacos 配置。已有记录不改。 |

## 页面上要改的位置

没有页面。不改管理页的说明、筛选、表格和弹窗。

| 位置 | 现在 | 改完 |
|---|---|---|
| 管理页 | 没有这项配置 | 仍然没有。切换只在服务配置里。 |

## 大致文件

### adx-admin-backend

- `src/config/app.config.ts`：读 `BFF_ACCESS_TYPE`、`SSO_ACCESS_TYPE`。不写时是 `nacos`。直连地址和接口文件路径沿用已有字段。
- `src/clients/bff.client.ts`：直连时用 `BFF_GRPC_URL` 调 `RevokeByAccount`，用 `BFF_SESSION_PROTO_PATH` 加载接口文件。缺了就失败。`nacos` 时保持现在的发现和下载。
- `src/clients/sso.client.ts`：直连时用 `SSO_GRPC_URL` 调 `SetPassword`，用 `SSO_PROTO_PATH` 加载接口文件。缺了就失败。
- `src/clients/platform-proto.resolver.ts`：Nacos 下载接口文件的路径保持给 `nacos` 用。直连不要走进这个下载。
- `src/nacos/nacos-subscription.registry.ts`：只有网关接入方式是 `nacos` 时才订阅网关。
- `nacos-config.dev.yml`、`nacos-config.test.yml`：补上两个接入方式的示例，默认 `nacos`。不写真实地址。

### adx-bff-backend

- `src/platform/platform-sso-sub-service.bootstrap.ts`：没有登录服务记录才新建，并写入直连地址。已有记录不新建。`SYNC_DIRECT_ADDRESS` 不是 `true` 时，不改已有地址。
- `src/platform/platform-sso-sub-service.bootstrap.spec.ts`：覆盖新建、不更新、以及开关为 true 时更新。
- `src/platform/platform-service.registry.spec.ts`：启动仍会走到同步。没有地址时不新建。
- `src/config/app.config.ts`：同步地址用 `SSO_DIRECT_ADDRESS`、`ADMIN_DIRECT_ADDRESS`。服务编码用 `ADMIN_DIRECT_SERVICE_CODES`，逗号分隔，可以写多条。不读带 grpc 的旧字段，也不用代码里的默认地址。
- `nacos-config.dev.yml`、`nacos-config.test.yml`：示例用上面的地址字段。线上这份把 `SYNC_DIRECT_ADDRESS` 写成 `true`，两条账号后端都会更新。
- `adx-bff-frontend/src/features/resources/ResourcePage.tsx`：发现方式一列把完整地址显示出来，不再截断。

### 补测试

- `src/clients/bff.client.spec.ts`：直连踢登录打到配置地址，不查 Nacos；缺地址或接口文件失败；`nacos` 仍去查实例。
- `src/clients/sso.client.spec.ts`：直连设密码打到配置地址；缺地址失败。
- `src/nacos/nacos-subscription.registry.spec.ts`：网关为直连时不订阅；为 `nacos` 时仍订阅。没有这个文件就新增。

## 明确不动

| 项目 | 为什么不动 |
|---|---|
| `adx-bff-backend` 里其它接入服务的保存和转发 | 001 已经做完。启动只同步登录服务和账号后端这两条的直连地址。 |
| `adx-bff-frontend` | 没有页面改动。 |
| `adx-sso-backend` | 登录服务不发起踢登录。它继续听自己的端口，继续按现在的方式注册。 |
| `adx-admin-frontend` | 没有页面改动。 |
| 数据库和迁移 | 不改表。 |
