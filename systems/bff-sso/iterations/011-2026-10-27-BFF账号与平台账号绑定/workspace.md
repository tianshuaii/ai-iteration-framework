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
| `adx-admin-frontend` | `/Users/mrzater/docker/adx/adx-admin-frontend` | 共享检出 | `main` |

| 资源标识 | 占用方式 | 用途 |
|---|---|---|
| `public_management-iteration-011-test-schema` | 独占 | 本轮迁移执行、唯一性并发验证与回退检查；实际使用前另行授权。 |
| `bff-sso-admin-local-stack-iteration-011` | 独占 | Admin/BFF/前端运行态验收端口和进程；计划阶段不启动。 |
| `bff-platform-account-fixtures-iteration-011` | 独占 | 平台与绑定验收夹具命名空间，避免与共享数据混用。 |
<!-- plan-approval-scope:end -->

更新时间：2026-10-27T12:09:47+08:00

| 仓库 | 产品检出路径 | 隔离方式 | 分支 | HEAD | 接管前状态 | 当前任务涉及的文件 |
|---|---|---|---|---|---|---|
| `adx-admin-backend` | `/Users/mrzater/docker/adx/adx-admin-backend` | 共享检出 | `master` | `303b62bf52b08f2c770393d122bb9097dbf72b1a` | 干净 | T-01：`prisma/schema.prisma`、`prisma/migrations/20261027120000_bff_platform_account_binding/migration.sql`、`prisma/scripts/public-management-comment-manifest.ts`。 |
| `adx-bff-backend` | `/Users/mrzater/docker/adx/adx-bff-backend` | 共享检出 | `main` | `da98f0c40bab372e247c39a6541e02a6eec281a9` | 含接管前未跟踪文件，见下方明细 | T-02：`prisma/schema.prisma`、拆分后的平台/绑定 Admin 模块与定向测试。 |
| `adx-admin-frontend` | `/Users/mrzater/docker/adx/adx-admin-frontend` | 共享检出 | `main` | `441332b9d75652a02469c802e7dd656223c5ee54` | 干净 | T-03：账号页文案、路由、菜单、Admin API、平台与绑定页面及定向测试。 |

## 接管前 dirty 明细

按仓库粘贴 `git status --short` 的文件状态；干净仓库明确写“无”。不要记录文件内容、密码、令牌或环境变量值。

### adx-admin-backend

- 无（`git status --short` 无输出）。

### adx-bff-backend

- `?? CODE_REVIEW.md`（接管前未跟踪文件，本轮明确排除且不得覆盖）。

### adx-admin-frontend

- 无（`git status --short` 无输出）。

## 运行资源

只登记用于发现并发冲突的稳定资源标识，不记录密码、令牌、连接串或真实地址。端口、数据库、Nacos 服务、测试账号等无法安全共享的资源使用“独占”；确实支持并发且不会互相改写的资源才使用“共享”。没有运行资源时明确写“无”。

| 资源标识 | 占用方式 | 用途 |
|---|---|---|
| `public_management-iteration-011-test-schema` | 独占 | 本轮迁移执行、唯一性并发验证与回退检查；尚未使用。 |
| `bff-sso-admin-local-stack-iteration-011` | 独占 | Admin/BFF/前端运行态验收端口和进程；尚未启动。 |
| `bff-platform-account-fixtures-iteration-011` | 独占 | 平台与绑定验收夹具命名空间；尚未创建。 |

## 临时 worktree 生命周期

只有使用独立 worktree 的仓库才填写。创建和清理分别运行 `scripts/create-worktree.rb` 与 `scripts/cleanup-worktree.rb`，由脚本维护本表和上面的产品检出路径。状态只使用“使用中”“待清理”“已删除”，或 `用户确认保留：用户确认……；保留原因……`。`done` 前必须清理为“已删除”；确需保留时必须在状态中同时写明用户确认和保留原因。临时目录删除后不抹掉历史路径、成果分支和最终 HEAD。清理前必须先完成下面的成果同步。

| 仓库 | 原仓库路径 | 临时 worktree 路径 | 分支 | 创建 HEAD | 最终 HEAD | 创建时间 | 状态 | 清理时间 |
|---|---|---|---|---|---|---|---|---|

## worktree 成果同步

worktree 成果提交并合入目标分支的上游后，取得拉取授权，再运行 `scripts/sync-worktree.rb <轮次目录> <仓库名> <目标分支>`。脚本要求真实仓库目录干净且已经检出目标分支，使用 `git pull --ff-only` 拉取，并验证目标分支包含 worktree 最终 HEAD。目标分支不写死为 `main` 或 `master`。只有状态为“已同步验证”且清理脚本复核仍成立，才能删除临时 worktree。

| 仓库 | 目标分支 | worktree 最终 HEAD | 原仓库同步 HEAD | 同步时间 | 状态 |
|---|---|---|---|---|---|
