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
| `adx-admin-frontend` | `/Users/mrzater/docker/adx/adx-admin-frontend` | 共享检出 | `main` |
| `adx-sso-backend` | `/Users/mrzater/docker/adx/adx-sso-backend` | 共享检出 | `master` |
| `adx-bff-backend` | `/Users/mrzater/docker/adx/adx-bff-backend` | 共享检出 | `main` |
| `adx-bff-frontend` | `/Users/mrzater/docker/adx/adx-bff-frontend` | 共享检出 | `main` |

| 资源标识 | 占用方式 | 用途 |
|---|---|---|
| `public_management-test-schema` | 独占 | 迁移预检、执行与回滚演练；实际使用前另行授权。 |
| `bff-sso-local-stack` | 独占 | 五服务联调端口、Nacos 实例和本机进程；计划阶段不启动。 |
| `bff-session-test-namespace` | 独占 | 旧 Session 失效与按账号吊销验证，避免影响共享 Redis 数据。 |
<!-- plan-approval-scope:end -->

更新时间：2026-10-26T15:50:00+08:00

| 仓库 | 产品检出路径 | 隔离方式 | 分支 | HEAD | 接管前状态 | 当前任务涉及的文件 |
|---|---|---|---|---|---|---|
| `adx-sso-backend` | `/Users/mrzater/docker/adx/adx-sso-backend` | 共享检出 | `master` | `6437527b4eab8f86b0b697b88d81bbdbf310d1c0` | 干净 | T-01 已完成：`src/auth/password-codec.ts`、`src/auth/password-codec.spec.ts`、`src/auth/super-admin-recovery.cli.ts`、`src/auth/super-admin-recovery.spec.ts`、`src/auth/auth.service.ts`、`src/auth/auth.service.spec.ts`、`src/auth/dto/auth.dto.ts` |
| `adx-admin-backend` | `/Users/mrzater/docker/adx/adx-admin-backend` | 共享检出 | `master` | `f519c0f39f6df73f8e1943036f5e8475c703f8b0` | 含本轮 T-02 至 T-06、T-12 已登记未提交成果 | T-02 seed；T-03 账户合约与服务；T-04 非账户治理退场；T-06 最终模型和唯一迁移；T-12 只修正 `20261026170000_account_only_governance/migration.sql` 的账户依赖删除顺序与唯一约束对齐 |
| `adx-bff-backend` | `/Users/mrzater/docker/adx/adx-bff-backend` | 共享检出 | `main` | `c57b594194cdfd40f3d24e6d7836ebc0b0e453da` | 含本轮已登记成果与三处接管前 dirty，见下方明细 | T-05 已接管治理转发、账户门禁、Portal、Session、SSO/Admin 客户端、可信上下文与对应测试；T-13 接管本人改密文件；T-14 只允许继续修改 `src/auth/auth.service.ts`、`src/auth/auth.service.spec.ts`，明确排除 HTTP 直通 dirty |
| `adx-admin-frontend` | `/Users/mrzater/docker/adx/adx-admin-frontend` | 共享检出 | `main` | `345226fbcc8a8477b77cce103444c8576e3ff85c` | 干净 | T-09 已接管路由、布局、账户页、账户 API、前端账户类型门禁，并删除废弃治理页面、关系工具、生成 SDK 与同步脚本 |
| `adx-bff-frontend` | `/Users/mrzater/docker/adx/adx-bff-frontend` | 共享检出 | `main` | `a91961d050eaf28199481f37ab6d283ff0145ea8` | 干净 | T-10 已接管 AdminMe 类型、auth store、超级管理员门禁与对应定向测试；运行日志、接口编辑和路由保持不变 |

## 接管前 dirty 明细

按仓库粘贴 `git status --short` 的文件状态；干净仓库明确写“无”。不要记录文件内容、密码、令牌或环境变量值。

### adx-sso-backend

- 无（`git status --short` 无输出）。

### adx-admin-backend

- ` M prisma/seed.ts`（本轮 T-02 已验证成果）。
- `?? prisma/seed-password.self-check.ts`（本轮 T-02 已验证成果）。
- `?? prisma/seed-password.ts`（本轮 T-02 已验证成果）。
- ` M proto/admin/v1/governance.proto`（本轮 T-03 已验证成果）。
- ` M proto/admin/v1/governance_models.proto`（本轮 T-03 已验证成果）。
- ` M src/governance/dto/admin.dto.ts`（本轮 T-03 已验证成果）。
- ` M src/governance/governance-account.service.ts`（本轮 T-03 已验证成果）。
- ` M src/governance/governance.service.ts`（本轮 T-03 已验证成果）。
- ` M src/grpc/governance-grpc.server.ts`（本轮 T-03 已验证成果）。
- `?? src/governance/governance-account.service.spec.ts`（本轮 T-03 已验证成果）。

### adx-bff-backend

- ` M src/proxy/http-passthrough.service.ts`（接管前既有改动，本轮排除）。
- ` M src/proxy/http-passthrough.service.spec.ts`（接管前既有改动，本轮排除）。
- `?? CODE_REVIEW.md`（接管前既有文件，本轮排除）。
- ` M src/auth/auth.service.ts`（本轮 T-05 已登记未提交成果；T-13 在保留既有差异的前提下追加本人改密编排）。
- `src/auth/auth.controller.ts`、`src/auth/auth.module.ts`：T-13 接管前无 dirty。
- `src/auth/dto/change-password.dto.ts`、`src/auth/auth.controller.spec.ts`、`src/auth/auth.service.spec.ts`：T-13 接管前不存在。

### adx-admin-frontend

- 无（`git status --short` 无输出）。

### adx-bff-frontend

- 无（`git status --short` 无输出）。

## 运行资源

只登记用于发现并发冲突的稳定资源标识，不记录密码、令牌、连接串或真实地址。端口、数据库、Nacos 服务、测试账号等无法安全共享的资源使用“独占”；确实支持并发且不会互相改写的资源才使用“共享”。没有运行资源时明确写“无”。

| 资源标识 | 占用方式 | 用途 |
|---|---|---|
| `mergex_manager_iter009_20261026` | 独占 | T-12 迁移、备份恢复和恢复后二次迁移；不连接共享开发库。 |
| `bff-session-redis-db14` | 独占 | 运行态验收命名空间；当前已清空。 |
| `bff-sso-local-stack-310x-510x-527x` | 独占 | 剩余运行态验收完成后五服务已停止；T-14 修复后仅按既有授权重启门禁复验。 |

## 临时 worktree 生命周期

只有使用独立 worktree 的仓库才填写。创建和清理分别运行 `scripts/create-worktree.rb` 与 `scripts/cleanup-worktree.rb`，由脚本维护本表和上面的产品检出路径。状态只使用“使用中”“待清理”“已删除”，或 `用户确认保留：用户确认……；保留原因……`。`done` 前必须清理为“已删除”；确需保留时必须在状态中同时写明用户确认和保留原因。临时目录删除后不抹掉历史路径、成果分支和最终 HEAD。清理前必须先完成下面的成果同步。

| 仓库 | 原仓库路径 | 临时 worktree 路径 | 分支 | 创建 HEAD | 最终 HEAD | 创建时间 | 状态 | 清理时间 |
|---|---|---|---|---|---|---|---|---|

## worktree 成果同步

worktree 成果提交并合入目标分支的上游后，取得拉取授权，再运行 `scripts/sync-worktree.rb <轮次目录> <仓库名> <目标分支>`。脚本要求真实仓库目录干净且已经检出目标分支，使用 `git pull --ff-only` 拉取，并验证目标分支包含 worktree 最终 HEAD。目标分支不写死为 `main` 或 `master`。只有状态为“已同步验证”且清理脚本复核仍成立，才能删除临时 worktree。

| 仓库 | 目标分支 | worktree 最终 HEAD | 原仓库同步 HEAD | 同步时间 | 状态 |
|---|---|---|---|---|---|
