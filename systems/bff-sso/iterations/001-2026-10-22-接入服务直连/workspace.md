# 产品仓库基线

本表在框架接管当前状态时采集。三个仓库已经有与本轮相关的未提交改动，因此这些文件全部视为接管前已有内容；后续 Agent 必须先核对 diff，不得覆盖或声称由自己新建。

更新时间：2026-10-22T16:44:46+08:00

| 仓库 | 产品检出路径 | 隔离方式 | 分支 | HEAD | 接管前状态 | 当前轮涉及的文件 |
|---|---|---|---|---|---|---|
| `adx-admin-backend` | `/Users/mrzater/docker/adx/adx-admin-backend` | 共享检出 | `master` | `437f6d6` | dirty：3 个已跟踪文件、1 个迁移目录未跟踪 | `prisma/schema.prisma`、`prisma/migrations/README.md`、`prisma/migrations/20261022160000_sub_service_access_type/`、`prisma/scripts/public-management-comment-manifest.ts` |
| `adx-bff-backend` | `/Users/mrzater/docker/adx/adx-bff-backend` | 共享检出 | `main` | `b165f7f` | dirty：18 个已跟踪文件 | Prisma 模型、保存校验、解析器、转发、订阅、连通测试及对应测试 |
| `adx-bff-frontend` | `/Users/mrzater/docker/adx/adx-bff-frontend` | 共享检出 | `main` | `696df24` | dirty：5 个已跟踪文件 | `ResourcePage.tsx`、`ServiceConnectivityModal.tsx`、`admin-api.ts`、筛选工具及测试 |

## 接管前 dirty 明细

以下内容来自只读 `git status --short`；只记录状态和路径，不包含文件正文。

### `adx-admin-backend`

- `M prisma/migrations/README.md`
- `M prisma/schema.prisma`
- `M prisma/scripts/public-management-comment-manifest.ts`
- `?? prisma/migrations/20261022160000_sub_service_access_type/`

### `adx-bff-backend`

- `M prisma/schema.prisma`
- `M prisma/scripts/public-management-comment-manifest.ts`
- `M src/admin/admin.service.spec.ts`
- `M src/admin/admin.service.ts`
- `M src/admin/dto/admin.dto.ts`
- `M src/admin/sub-service-connectivity.service.spec.ts`
- `M src/admin/sub-service-connectivity.service.ts`
- `M src/admin/sub-service-connectivity.types.ts`
- `M src/clients/admin-forward-context.client.ts`
- `M src/nacos/nacos-subscription.registry.spec.ts`
- `M src/nacos/nacos-subscription.registry.ts`
- `M src/nacos/nacos-target.resolver.spec.ts`
- `M src/nacos/nacos-target.resolver.ts`
- `M src/openapi/service-openapi-sync.service.ts`
- `M src/portal/portal-authz-forward.service.spec.ts`
- `M src/portal/portal-authz-forward.service.ts`
- `M src/proxy/proxy.service.spec.ts`
- `M src/proxy/proxy.service.ts`

### `adx-bff-frontend`

- `M src/features/resources/ResourcePage.tsx`
- `M src/features/resources/ServiceConnectivityModal.tsx`
- `M src/lib/admin-api.ts`
- `M src/lib/service-list-filter.util.test.ts`
- `M src/lib/service-list-filter.util.ts`

## 运行资源

资源标识只用于防止其他活动轮次误用同一套验收环境，不保存真实地址、连接串或密钥。

| 资源标识 | 占用方式 | 用途 |
|---|---|---|
| `bff-sso-local-gateway-runtime` | 独占 | 当前轮 `/proxy` 和连通测试验收使用的本地网关进程 |
| `bff-sso-nacos-acceptance-pool` | 独占 | TC-07、TC-08 使用的 Nacos 服务与健康实例集合 |
