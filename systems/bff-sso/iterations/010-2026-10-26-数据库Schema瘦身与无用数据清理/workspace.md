<!-- workspace-policy: managed-worktree-v2 -->
# 产品仓库基线

开始修改产品文件前填写当前任务会涉及的仓库。每次切换任务或发现已有改动时更新，不把接管前的 dirty 文件算成当前 Agent 新产生的改动。dirty 状态必须逐文件记录，不能只写数量。

进入 `implement / ready` 前先登记拟使用的产品检出路径、隔离方式和运行资源，并与其他 `implement` 或 `verify` 轮次核对。默认使用 `overview.md` 的真实仓库和“共享检出”；原仓库存在未提交修改时只登记并保护 dirty 基线，不因此创建 worktree。只有另一产品活动轮次登记使用同一仓库时，才允许使用框架根目录的 `scripts/create-worktree.rb` 创建到 `.worktrees/`；有检出或资源冲突且无法隔离时留在 `plan / blocked`。隔离方式只写“独立 worktree”或“共享检出”。`specify` 和尚未完成预留的 `plan` 可以保留占位内容；真正修改产品文件前再逐文件采集 HEAD 和 dirty 基线。

<!-- plan-approval-scope:start -->
## 计划检出与资源预留

本区块属于计划审批摘要。只写计划采用的仓库、检出路径、隔离方式、目标分支和资源策略；审批后改变这些决定，计划审批会失效。运行期采集的 HEAD、dirty、创建时间和同步结果不放在本区块。

| 仓库 | 计划产品检出路径 | 隔离方式 | 目标分支 |
|---|---|---|---|
| `adx-admin-backend` | `/Users/mrzater/docker/adx/adx-admin-backend` | 共享检出 | `master` |
| `adx-bff-backend` | `/Users/mrzater/docker/adx/adx-bff-backend` | 共享检出 | `main` |
| `adx-sso-backend` | `/Users/mrzater/docker/adx/adx-sso-backend` | 共享检出 | `master` |

| 资源标识 | 占用方式 | 用途 |
|---|---|---|
| 线上测试 `public_management` 的迁移窗口 | 独占 | 备份、恢复演练和唯一迁移；窗口内停止五项本机服务写入。 |
| 独立临时恢复数据库 | 独占 | Q7 的备份恢复演练；通过核验后删除。 |
| 本机五服务端口与受控回归会话 | 共享 | 仅迁移后定向回归使用；不在实现阶段启动或改写。 |
<!-- plan-approval-scope:end -->

更新时间：2026-10-27T11:08:00+08:00

| 仓库 | 产品检出路径 | 隔离方式 | 分支 | HEAD | 接管前状态 | 当前任务涉及的文件 |
|---|---|---|---|---|---|---|
| `adx-admin-backend` | `/Users/mrzater/docker/adx/adx-admin-backend` | 共享检出 | `master` | `f519c0f39f6df73f8e1943036f5e8475c703f8b0` | 含 009 未提交成果；逐文件清单见下。 | T-01：`prisma/schema.prisma`、`prisma/scripts/public-management-comment-manifest.ts`、`prisma/migrations/<本轮迁移>/migration.sql`。 |
| `adx-bff-backend` | `/Users/mrzater/docker/adx/adx-bff-backend` | 共享检出 | `main` | `c57b594194cdfd40f3d24e6d7836ebc0b0e453da` | 含 009 未提交成果；逐文件清单见下。 | T-02、T-03：`prisma/schema.prisma` 与仅有的受影响 `src/**`、`*.spec.ts`。 |
| `adx-sso-backend` | `/Users/mrzater/docker/adx/adx-sso-backend` | 共享检出 | `master` | `6437527b4eab8f86b0b697b88d81bbdbf310d1c0` | 含 009 未提交成果；逐文件清单见下。 | T-02：`prisma/schema.prisma` 与仅有的受影响 `src/**`、`*.spec.ts`。 |

## 接管前 dirty 明细

按仓库粘贴 `git status --short` 的文件状态；干净仓库明确写“无”。不要记录文件内容、密码、令牌或环境变量值。

### `adx-admin-backend`

- `D docs/portal-select-options.md`
- `D docs/superpowers/plans/2026-09-10-portal-select-options.md`
- `M package.json`；`M pnpm-lock.yaml`
- `D prisma/lib/resolve-seed-super-admin.ts`；`M prisma/schema.prisma`
- `D prisma/scripts/backfill-account-creators-from-role.ts`；`D prisma/scripts/backfill-tenant-admin-role-creators.ts`；`D prisma/scripts/backfill-tenant-creators.ts`
- `M prisma/scripts/public-management-comment-manifest.ts`；`M prisma/seed.ts`
- `M proto/admin/v1/gateway_context.proto`；`M proto/admin/v1/governance.proto`；`M proto/admin/v1/governance_models.proto`；`M proto/admin/v1/portal_authz.proto`
- `D scripts/run-route-binding-cleanup.ts`；`D scripts/split-governance-service.mjs`
- `M src/authz/authz.module.ts`；`M src/authz/authz.service.spec.ts`；`M src/authz/authz.service.ts`；`D src/authz/portal-authz-shared-cache.service.ts`
- `D src/authz/route-display-name.util.spec.ts`；`D src/authz/route-display-name.util.ts`
- `D src/catalog/catalog-query.builder.spec.ts`；`D src/catalog/catalog-query.builder.ts`；`D src/catalog/catalog.mapper.ts`；`M src/catalog/catalog.module.ts`；`D src/catalog/portal-catalog-scope.service.ts`；`D src/catalog/portal-catalog-scope.spec.ts`；`M src/catalog/portal-catalog.service.spec.ts`；`M src/catalog/portal-catalog.service.ts`
- `D src/common/link.util.spec.ts`；`D src/common/link.util.ts`
- `M src/gateway/forward-context.service.spec.ts`；`M src/gateway/forward-context.service.ts`
- `D src/governance/account-role.util.self-check.ts`；`D src/governance/account-role.util.spec.ts`；`D src/governance/account-role.util.ts`；`D src/governance/account-type.util.spec.ts`；`D src/governance/account-type.util.ts`；`D src/governance/admin-delete.guard.spec.ts`；`D src/governance/admin-delete.guard.ts`
- `M src/governance/dto/admin.dto.ts`；`M src/governance/governance-account.service.ts`；`D src/governance/governance-audit.util.ts`；`D src/governance/governance-permission.service.ts`；`D src/governance/governance-role.service.ts`；`D src/governance/governance-route.service.ts`；`D src/governance/governance-service-base.ts`；`D src/governance/governance-tenant.service.ts`；`M src/governance/governance.module.ts`；`M src/governance/governance.service.ts`
- `D src/governance/name-uniqueness.util.spec.ts`；`D src/governance/name-uniqueness.util.ts`；`D src/governance/page-route-component-name.util.spec.ts`；`D src/governance/page-route-component-name.util.ts`；`D src/governance/page-route-path.util.ts`；`D src/governance/role-grant-parent.util.ts`；`D src/governance/route-binding-cleanup.util.spec.ts`；`D src/governance/route-binding-cleanup.util.ts`；`D src/governance/route-list-query.util.ts`；`D src/governance/slug-code.util.ts`；`D src/governance/tenant-admin.util.ts`；`D src/governance/tenant-scope.grant.spec.ts`；`D src/governance/tenant-scope.service.ts`
- `M src/grpc/governance-grpc.server.ts`；`M src/main.ts`
- `?? prisma/migrations/20261026170000_account_only_governance/`；`?? prisma/seed-password.self-check.ts`；`?? prisma/seed-password.ts`；`?? src/governance/governance-account.service.spec.ts`；`?? src/grpc/governance-grpc.server.spec.ts`

### `adx-bff-backend`

- `M README.md`；`M package.json`；`M pnpm-lock.yaml`；`D prisma/lib/resolve-seed-super-admin.ts`；`M prisma/schema.prisma`；`D prisma/scripts/dedupe-account-roles.ts`；`M prisma/scripts/public-management-comment-manifest.ts`；`D prisma/seed-super-admin.ts`；`M scripts/print-trusted-request-context-instances.ts`
- `D src/admin/account-role.util.ts`；`D src/admin/admin-delete.guard.spec.ts`；`D src/admin/admin-delete.guard.ts`；`M src/admin/admin-gov-forward.service.ts`；`M src/admin/admin-gov-grpc.util.spec.ts`；`M src/admin/admin-gov-grpc.util.ts`；`M src/admin/admin-gov-rpc-catalog.ts`；`M src/admin/admin.controller.ts`；`M src/admin/admin.module.ts`；`M src/admin/admin.service.spec.ts`；`M src/admin/admin.service.ts`；`M src/admin/dto/admin.dto.ts`；`M src/admin/gateway-admin.service.ts`
- `D src/admin/role-grant-parent.util.spec.ts`；`D src/admin/role-grant-parent.util.ts`；`D src/admin/route-list-query.util.spec.ts`；`D src/admin/route-list-query.util.ts`；`M src/admin/slug-code.util.spec.ts`；`M src/admin/slug-code.util.ts`；`D src/admin/tenant-admin.util.ts`；`D src/admin/tenant-scope.service.ts`
- `M src/auth/auth.controller.ts`；`M src/auth/auth.service.ts`；`M src/clients/sso.client.ts`；`M src/common/account-type.util.spec.ts`；`M src/common/account-type.util.ts`；`M src/common/decorators/api-doc.decorator.ts`；`M src/common/decorators/current-account.decorator.ts`；`M src/common/guards/session.guard.spec.ts`；`M src/common/guards/session.guard.ts`；`D src/common/link.util.ts`；`M src/common/openapi/response-docs.ts`
- `M src/openapi/governance-proto-document.spec.ts`；`M src/openapi/portal-authz-proto-document.spec.ts`；`M src/openapi/portal-catalog-proto-document.spec.ts`
- `M src/portal/portal-authz-forward.service.spec.ts`；`D src/portal/portal-governance.controller.ts`；`D src/portal/portal-governance.service.spec.ts`；`D src/portal/portal-governance.service.ts`；`M src/portal/portal.module.ts`；`D src/portal/portal.service.spec.ts`；`D src/portal/portal.service.ts`
- `M src/proxy/forward-metadata.util.spec.ts`；`M src/proxy/forward-metadata.util.ts`；`M src/proxy/http-passthrough.service.spec.ts`；`M src/proxy/http-passthrough.service.ts`；`M src/proxy/trusted-request-context.util.spec.ts`；`M src/proxy/trusted-request-context.util.ts`；`M src/runtime-interface/utils/governance-inventory.util.spec.ts`
- `M src/session/account-status-cache.ts`；`M src/session/session-forward-context.types.ts`；`M src/session/session.service.spec.ts`；`M src/session/session.service.ts`；`M src/session/session.types.ts`；`M src/session/test-forward-context.fixture.ts`
- `?? CODE_REVIEW.md`；`?? src/admin/admin-account.controller.ts`；`?? src/admin/gateway-admin.controller.ts`；`?? src/auth/auth.controller.spec.ts`；`?? src/auth/auth.service.spec.ts`；`?? src/auth/dto/change-password.dto.ts`

### `adx-sso-backend`

- `M package.json`；`M pnpm-lock.yaml`；`M prisma/schema.prisma`；`M proto/sso/v1/auth.proto`；`M src/auth/auth.service.spec.ts`；`M src/auth/auth.service.ts`；`M src/auth/dto/auth.dto.ts`；`D src/auth/tenant-admin.util.spec.ts`；`D src/auth/tenant-admin.util.ts`；`M src/grpc/auth-grpc.server.ts`
- `?? src/auth/password-codec.spec.ts`；`?? src/auth/password-codec.ts`；`?? src/auth/super-admin-recovery.cli.ts`；`?? src/auth/super-admin-recovery.spec.ts`

## 运行资源

只登记用于发现并发冲突的稳定资源标识，不记录密码、令牌、连接串或真实地址。端口、数据库、Nacos 服务、测试账号等无法安全共享的资源使用“独占”；确实支持并发且不会互相改写的资源才使用“共享”。没有运行资源时明确写“无”。

| 资源标识 | 占用方式 | 用途 |
|---|---|---|
| `线上测试 public_management 迁移窗口` | 独占 | 已完成备份、隔离恢复演练、唯一迁移和数据库验收；备份保留。 |
| `独立临时恢复数据库` | 独占 | 演练完成后已删除，不作为目标库。 |
| `BFF/SSO/Admin 后端端口 3000/5003、3001/5001、3002/5002` | 共享 | 迁移窗口内已停止；未自行重启，等待真实接口回归授权。 |
| `Admin/BFF 前端端口 5173、5174` | 共享 | 迁移窗口内已停止；未自行重启，等待真实接口回归授权。 |

## 临时 worktree 生命周期

只有使用独立 worktree 的仓库才填写。创建和清理分别运行 `scripts/create-worktree.rb` 与 `scripts/cleanup-worktree.rb`，由脚本维护本表和上面的产品检出路径。状态只使用“使用中”“待清理”“已删除”，或 `用户确认保留：用户确认……；保留原因……`。`done` 前必须清理为“已删除”；确需保留时必须在状态中同时写明用户确认和保留原因。临时目录删除后不抹掉历史路径、成果分支和最终 HEAD。清理前必须先完成下面的成果同步。

| 仓库 | 原仓库路径 | 临时 worktree 路径 | 分支 | 创建 HEAD | 最终 HEAD | 创建时间 | 状态 | 清理时间 |
|---|---|---|---|---|---|---|---|---|

## worktree 成果同步

worktree 成果提交并合入目标分支的上游后，取得拉取授权，再运行 `scripts/sync-worktree.rb <轮次目录> <仓库名> <目标分支>`。脚本要求真实仓库目录干净且已经检出目标分支，使用 `git pull --ff-only` 拉取，并验证目标分支包含 worktree 最终 HEAD。目标分支不写死为 `main` 或 `master`。只有状态为“已同步验证”且清理脚本复核仍成立，才能删除临时 worktree。

| 仓库 | 目标分支 | worktree 最终 HEAD | 原仓库同步 HEAD | 同步时间 | 状态 |
|---|---|---|---|---|---|
