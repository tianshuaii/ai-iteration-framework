<!-- workspace-policy: managed-worktree-v2 -->
# 产品仓库基线

开始修改产品文件前填写当前任务会涉及的仓库。每次切换任务或发现已有改动时更新，不把接管前的 dirty 文件算成当前 Agent 新产生的改动。dirty 状态必须逐文件记录，不能只写数量。

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
| `public_management-iteration-012-test-schema` | 独占 | 密钥字段、唯一索引、老数据兼容和迁移回退验证；实际使用前另行授权。 |
| `bff-sso-platform-login-stack-iteration-012` | 独占 | Admin/BFF/前端、Redis 和模拟 HTTP 上游的运行态验收；计划阶段不启动。 |
| `bff-platform-login-fixtures-iteration-012` | 独占 | 平台密钥、账号绑定和失效态验收夹具命名空间；创建前另行授权。 |
<!-- plan-approval-scope:end -->

更新时间：2026-10-27T15:38:00+08:00

| 仓库 | 产品检出路径 | 隔离方式 | 分支 | HEAD | 接管前状态 | 当前任务涉及的文件 |
|---|---|---|---|---|---|---|
| `adx-admin-backend` | `/Users/mrzater/docker/adx/adx-admin-backend` | 共享检出 | `master` | `303b62bf52b08f2c770393d122bb9097dbf72b1a` | 含第 011 轮未提交改动，见下方逐文件明细 | T-01：Schema、字段注释和本轮 migration。 |
| `adx-bff-backend` | `/Users/mrzater/docker/adx/adx-bff-backend` | 共享检出 | `main` | `da98f0c40bab372e247c39a6541e02a6eec281a9` | 含第 011 轮未提交改动及 `CODE_REVIEW.md`，见下方逐文件明细 | T-01/T-02：Prisma、平台、Auth、Session、Proxy、配置与测试。 |
| `adx-admin-frontend` | `/Users/mrzater/docker/adx/adx-admin-frontend` | 共享检出 | `main` | `441332b9d75652a02469c802e7dd656223c5ee54` | 含第 011 轮未提交改动，见下方逐文件明细 | T-03：平台弹窗、模型、Admin API 与测试。 |

## 接管前 dirty 明细

以下文件均为本轮开始前已经存在的第 011 轮成果或用户文件。本轮只在任务允许文件上追加改动，不把这些基线当作第 012 轮新增，也不使用 reset/checkout 覆盖。

### adx-admin-backend

- `M prisma/schema.prisma`
- `M prisma/scripts/public-management-comment-manifest.ts`
- `?? prisma/migrations/20261027120000_bff_platform_account_binding/`

### adx-bff-backend

- `M prisma/schema.prisma`
- `M src/admin/admin.module.ts`
- `?? CODE_REVIEW.md`（用户已有文件，本轮明确排除）
- `?? src/admin/access-platform.controller.ts`
- `?? src/admin/access-platform.service.spec.ts`
- `?? src/admin/access-platform.service.ts`
- `?? src/admin/dto/access-platform.dto.ts`
- `?? src/admin/dto/platform-account-binding.dto.ts`
- `?? src/admin/login-interface-identity.util.spec.ts`
- `?? src/admin/login-interface-identity.util.ts`
- `?? src/admin/platform-account-binding.controller.ts`
- `?? src/admin/platform-account-binding.service.spec.ts`
- `?? src/admin/platform-account-binding.service.ts`

### adx-admin-frontend

- `M src/app/lazy-pages.ts`
- `M src/app/route-paths.ts`
- `M src/app/router.spec.tsx`
- `M src/app/router.tsx`
- `M src/components/layout/AdminLayout.tsx`
- `M src/features/accounts/AccountPage.tsx`
- `M src/lib/admin-api.ts`
- `?? src/features/access-platforms/`
- `?? src/features/platform-account-bindings/`

## 运行资源

| 资源标识 | 占用方式 | 用途 |
|---|---|---|
| `public_management-iteration-012-test-schema` | 独占 | 15:28–15:37 已使用并释放；本轮 migration 验收通过后保留。 |
| `bff-sso-platform-login-stack-iteration-012` | 独占 | 已使用并释放；三端与模拟上游已关闭，相关端口已释放。 |
| `bff-platform-login-fixtures-iteration-012` | 独占 | 已使用并释放；夹具已软删除，活动计数均为 0，Redis 与临时文件已清理。 |

## 临时 worktree 生命周期

本轮计划使用共享检出，目前不创建独立 worktree。

| 仓库 | 原仓库路径 | 临时 worktree 路径 | 分支 | 创建 HEAD | 最终 HEAD | 创建时间 | 状态 | 清理时间 |
|---|---|---|---|---|---|---|---|---|

## worktree 成果同步

本轮计划不使用 worktree；若后续出现同仓库产品阶段并行，必须先返回计划阶段重做隔离和审批。

| 仓库 | 目标分支 | worktree 最终 HEAD | 原仓库同步 HEAD | 同步时间 | 状态 |
|---|---|---|---|---|---|
