# 产品仓库基线

开始修改产品文件前填写当前任务会涉及的仓库。每次切换任务或发现已有改动时更新，不把接管前的 dirty 文件算成当前 Agent 新产生的改动。dirty 状态必须逐文件记录，不能只写数量。

001、002 都已是 `done`。没有别的 `implement` 或 `verify` 轮次占用同一检出。用户已选择共享检出、不建 worktree。下面这些 dirty 文件是 002 收尾留下的，本轮不覆盖。

更新时间：2026-10-22T21:38:43+08:00

| 仓库 | 产品检出路径 | 隔离方式 | 分支 | HEAD | 接管前状态 | 当前任务涉及的文件 |
|---|---|---|---|---|---|---|
| adx-admin-backend | /Users/mrzater/docker/adx/adx-admin-backend | 共享检出 | master | f6ddc92 | 有 dirty，见下 | prisma/schema.prisma、prisma/migrations/20261022213000_interface_kind_and_http_transport/migration.sql |
| adx-bff-backend | /Users/mrzater/docker/adx/adx-bff-backend | 共享检出 | main | 186ec23 | 有 dirty，见下 | prisma/schema.prisma |
| adx-bff-frontend | /Users/mrzater/docker/adx/adx-bff-frontend | 共享检出 | main | 8bb56cc | 有 dirty，见下 | T-01 不改前端 |
| adx-sso-backend | /Users/mrzater/docker/adx/adx-sso-backend | 共享检出 | 未切换 | fccc45f | 有 dirty，本轮不改 | 无 |
| adx-admin-frontend | /Users/mrzater/docker/adx/adx-admin-frontend | 共享检出 | 未切换 | fc95491 | 干净 | 无 |

## 接管前 dirty 明细

### adx-admin-backend

- M nacos-config.dev.yml
- M nacos-config.test.yml
- M src/clients/bff.client.ts
- M src/clients/platform-proto.resolver.ts
- M src/clients/sso.client.ts
- M src/config/app.config.ts
- M src/nacos/nacos-naming.service.spec.ts
- M src/nacos/nacos-naming.service.ts
- M src/nacos/nacos-subscription.registry.spec.ts
- M src/nacos/nacos-subscription.registry.ts
- ?? src/clients/bff.client.spec.ts
- ?? src/clients/sso.client.spec.ts

### adx-bff-backend

- M nacos-config.dev.yml
- M nacos-config.test.yml
- M src/admin/admin.service.spec.ts
- M src/admin/admin.service.ts
- M src/clients/admin-forward-context.client.ts
- M src/clients/sso.client.ts
- M src/common/sub-service-environment.util.spec.ts
- M src/common/sub-service-environment.util.ts
- M src/config/app.config.ts
- M src/nacos/nacos-naming.service.ts
- M src/openapi/grpc-proto.util.ts
- M src/platform/platform-service.constants.ts
- M src/platform/platform-service.registry.spec.ts
- M src/platform/platform-sso-sub-service.bootstrap.ts
- M src/runtime-interface/services/runtime-interface-resolver.service.ts
- ?? src/clients/sso.client.spec.ts
- ?? src/nacos/nacos-naming.service.spec.ts
- ?? src/platform/platform-runtime-package.bootstrap.spec.ts
- ?? src/platform/platform-runtime-package.bootstrap.ts
- ?? src/platform/platform-sso-sub-service.bootstrap.spec.ts

### adx-bff-frontend

- M src/features/resources/ResourcePage.tsx
- M src/lib/platform-service-row.ts

### adx-sso-backend

本轮不改。记录是为了确认没有别的轮次在改同一批文件。

- M nacos-config.dev.yml
- M nacos-config.test.yml
- M src/config/app.config.ts
- M src/nacos/nacos-naming.service.ts
- ?? src/nacos/nacos-naming.service.spec.ts

### adx-admin-frontend

- 无

## 运行资源

本轮实现只跑定向测试，不启动前后端，不执行数据库迁移。

| 资源标识 | 占用方式 | 用途 |
|---|---|---|
| 无 | 共享 | 定向测试不占用端口、数据库或 Nacos |
