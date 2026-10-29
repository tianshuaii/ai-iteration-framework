# 产品仓库基线

开始修改产品文件前填写当前任务会涉及的仓库。每次切换任务或发现已有改动时更新，不把接管前的 dirty 文件算成当前 Agent 新产生的改动。dirty 状态必须逐文件记录，不能只写数量。

001、002、003 都已是 `done`。没有别的 `implement` 或 `verify` 轮次占用同一检出。沿用这套系统已经在用的共享检出，不新建 worktree。HEAD 和 dirty 留到 T-01 动手改文件前再逐文件采集。

更新时间：2026-10-23T12:49:57+08:00

| 仓库 | 产品检出路径 | 隔离方式 | 分支 | HEAD | 接管前状态 | 当前任务涉及的文件 |
|---|---|---|---|---|---|---|
| `adx-admin-backend` | `/Users/mrzater/docker/adx/adx-admin-backend` | 共享检出 | master | f6ddc92 | 有 dirty，见下。schema 已有 003 的改动，本任务只追加 | prisma/schema.prisma、prisma/migrations/ 下的新迁移 |
| `adx-bff-backend` | `/Users/mrzater/docker/adx/adx-bff-backend` | 共享检出 | main | 186ec23 | 有 dirty，见下。schema 已有 003 的改动，本任务只追加 | prisma/schema.prisma |
| `adx-bff-frontend` | `/Users/mrzater/docker/adx/adx-bff-frontend` | 共享检出 | main | 8bb56cc | 有 dirty，见下。T-05 动手前采集 | 接口项目页、服务接口包页、查看抽屉、admin-api.ts |
| `adx-sso-backend` | `/Users/mrzater/docker/adx/adx-sso-backend` | 共享检出 | 尚未采集 | 尚未采集 | T-01 不改 | 无 |
| `adx-admin-frontend` | `/Users/mrzater/docker/adx/adx-admin-frontend` | 共享检出 | 尚未采集 | 尚未采集 | T-01 不改 | 无 |

## 接管前 dirty 明细

### adx-admin-backend

- M nacos-config.dev.yml
- M nacos-config.test.yml
- M prisma/schema.prisma
- M src/clients/bff.client.ts
- M src/clients/platform-proto.resolver.ts
- M src/clients/sso.client.ts
- M src/config/app.config.ts
- M src/nacos/nacos-naming.service.spec.ts
- M src/nacos/nacos-naming.service.ts
- M src/nacos/nacos-subscription.registry.spec.ts
- M src/nacos/nacos-subscription.registry.ts
- ?? prisma/migrations/20261022213000_interface_kind_and_http_transport/
- ?? prisma/migrations/20261022221500_widen_direct_address/
- ?? src/clients/bff.client.spec.ts
- ?? src/clients/sso.client.spec.ts

### adx-bff-backend

- M nacos-config.dev.yml
- M nacos-config.test.yml
- M prisma/schema.prisma
- M src/admin/admin.service.spec.ts
- M src/admin/admin.service.ts
- M src/admin/dto/admin.dto.ts
- M src/admin/sub-service-connectivity.service.spec.ts
- M src/admin/sub-service-connectivity.service.ts
- M src/admin/sub-service-connectivity.types.ts
- M src/apifox/apifox.client.spec.ts
- M src/apifox/apifox.client.ts
- M src/clients/admin-forward-context.client.ts
- M src/clients/sso.client.ts
- M src/common/sub-service-environment.util.spec.ts
- M src/common/sub-service-environment.util.ts
- M src/config/app.config.ts
- M src/interface-version/dto/interface-version.dto.ts
- M src/interface-version/interface-version.controller.ts
- M src/interface-version/interface-version.module.ts
- M src/interface-version/services/import-json.service.spec.ts
- M src/interface-version/services/import-json.service.ts
- M src/interface-version/services/import-proto.service.ts
- M src/interface-version/services/project.service.spec.ts
- M src/interface-version/services/project.service.ts
- M src/nacos/nacos-host.util.ts
- M src/nacos/nacos-naming.service.ts
- M src/nacos/nacos-subscription.registry.spec.ts
- M src/nacos/nacos-subscription.registry.ts
- M src/nacos/nacos-target.resolver.spec.ts
- M src/nacos/nacos-target.resolver.ts
- M src/openapi/grpc-proto.util.ts
- M src/platform/platform-service.constants.ts
- M src/platform/platform-service.registry.spec.ts
- M src/platform/platform-sso-sub-service.bootstrap.ts
- M src/proxy/proxy.service.spec.ts
- M src/proxy/proxy.service.ts
- M src/runtime-interface/services/runtime-interface-resolver.service.ts
- M src/runtime-interface/services/runtime-package-import.service.spec.ts
- M src/runtime-interface/services/runtime-package-import.service.ts
- ?? src/admin/dto/direct-address.spec.ts
- ?? src/clients/admin-forward-context.origin.spec.ts
- ?? src/clients/sso.client.spec.ts
- ?? src/interface-version/services/import-apifox.service.spec.ts
- ?? src/interface-version/services/import-apifox.service.ts
- ?? src/nacos/nacos-naming.service.spec.ts
- ?? src/platform/platform-runtime-package.bootstrap.spec.ts
- ?? src/platform/platform-runtime-package.bootstrap.ts
- ?? src/platform/platform-sso-sub-service.bootstrap.spec.ts

### adx-bff-frontend

T-05 动手前，分支 `main`，HEAD `8bb56cc`。下面这些是接管前就有的改动，没有覆盖。

- M src/features/interface-version/InterfaceBranchPage.tsx
- M src/features/interface-version/InterfaceProjectPage.tsx
- M src/features/openapi/OpenapiUpstreamPage.tsx
- M src/features/openapi/components/CompositeOrchestrationPanel.tsx
- M src/features/resources/ResourcePage.tsx
- M src/features/resources/ServiceConnectivityModal.tsx
- M src/lib/admin-api.ts
- M src/lib/platform-service-row.ts
- M src/lib/service-list-filter.util.ts

本轮在网关后端新增：

- src/proxy/http-passthrough.controller.ts
- src/proxy/http-passthrough.service.ts
- src/proxy/http-passthrough.service.spec.ts
- src/proxy/proxy.module.ts（只注册上面的入口）

### adx-sso-backend

- 尚未采集

### adx-admin-frontend

- 尚未采集

## 运行资源

实现阶段不启动网关、账号后端或页面。不独占端口。数据库迁移文件只准备，不执行。

无
