<!-- workspace-policy: managed-worktree-v2 -->
# 产品仓库基线

开始修改产品文件前填写当前任务会涉及的仓库。每次切换任务或发现已有改动时更新，不把接管前的 dirty 文件算成当前 Agent 新产生的改动。dirty 状态必须逐文件记录，不能只写数量。

进入 `implement / ready` 前先登记拟使用的产品检出路径、隔离方式和运行资源，并与其他 `implement` 或 `verify` 轮次核对。默认使用 `overview.md` 的真实仓库和“共享检出”；原仓库存在未提交修改时只登记并保护 dirty 基线，不因此创建 worktree。只有另一产品活动轮次登记使用同一仓库时，才允许使用框架根目录的 `scripts/create-worktree.rb` 创建到 `.worktrees/`；有检出或资源冲突且无法隔离时留在 `plan / blocked`。隔离方式只写“独立 worktree”或“共享检出”。`specify` 和尚未完成预留的 `plan` 可以保留占位内容；真正修改产品文件前再逐文件采集 HEAD 和 dirty 基线。

<!-- plan-approval-scope:start -->
## 计划检出与资源预留

本区块属于计划审批摘要。只写计划采用的仓库、检出路径、隔离方式、目标分支和资源策略；审批后改变这些决定，计划审批会失效。运行期采集的 HEAD、dirty、创建时间和同步结果不放在本区块。

| 仓库 | 计划产品检出路径 | 隔离方式 | 目标分支 |
|---|---|---|---|
| `mediatom-web` | `/Users/mrzater/project/mediatom-web` | 共享检出 | `feat-20261028-traffic-filter` |
| `mergex-manager` | `/Users/mrzater/java/mergex-manager` | 共享检出 | `feat-20261028-traffic-filter` |

| 资源标识 | 占用方式 | 用途 |
|---|---|---|
| 无 | 共享 | 返工阶段仅编辑 `mergex-manager/sql/policy_manage_plat_account_id.sql` 并执行静态检查；不启动服务、不执行数据库迁移或测试库索引删除。 |
<!-- plan-approval-scope:end -->

更新时间：2026-10-29T11:35:14+08:00

| 仓库 | 产品检出路径 | 隔离方式 | 分支 | HEAD | 接管前状态 | 当前任务涉及的文件 |
|---|---|---|---|---|---|---|
| `mediatom-web` | `/Users/mrzater/project/mediatom-web` | 共享检出 | `feat-20261028-traffic-filter` | `a5d7cd611ed7d5b90dbb5fa00141a21146714703` | 1 个接管前 dirty，见下方 | T-01 点名的 EditPlatAccount、对应 data.js 与定向测试；共享 TrafficDirectionV4 和 API 仅在契约确需时改，EditPlace 不动 |
| `mergex-manager` | `/Users/mrzater/java/mergex-manager` | 共享检出 | `feat-20261028-traffic-filter` | `43371ee5d3c5c362b71feee640648816566613ba` | 既有 T-01 差异及 1 个更早的用户配置 dirty，见下方 | 当前返工只涉及 `sql/policy_manage_plat_account_id.sql`；其他 T-01 差异保持不动 |

## 收口后提交结果

| 仓库 | 分支 | 提交 HEAD | 提交后状态 |
|---|---|---|---|
| `mergex-manager` | `feat-20261028-traffic-filter` | `015a43bb4dcef78223df2bcdd9df192d9bbcff82` | 工作区干净 |
| `mediatom-web` | `feat-20261028-traffic-filter` | `f23b60f56b1a8be58022b198b2913c923af62208` | 仅保留接管前 `build/env/development/adx.js` 改动 |

本次未 push、未 merge、未 pull、未 deploy。上表是收口后的用户授权提交，不改写下方的接管前基线记录。

## 接管前 dirty 明细

按仓库粘贴 `git status --short` 的文件状态；干净仓库明确写“无”。不要记录文件内容、密码、令牌或环境变量值。

### mediatom-web

- ` M build/env/development/adx.js`（接管前用户改动；本轮不覆盖、不格式化、不计入本轮差异）

### mergex-manager

- ` M src/main/resources/application.yml`（接管前用户改动；本轮不覆盖、不格式化、不计入本轮差异）

### 2026-10-29 验收返工接管前差异

- `M` `src/main/java/com/ydmob/mergex/managerserver/common/constant/PolicyConstant.java`
- `M` `src/main/java/com/ydmob/mergex/managerserver/model/dto/query/policy/PolicyQuery.java`
- `M` `src/main/java/com/ydmob/mergex/managerserver/model/entity/feature/PolicyManage.java`
- `M` `src/main/java/com/ydmob/mergex/managerserver/model/vo/budget/platform/CreateSysUserPlatformVo.java`
- `M` `src/main/java/com/ydmob/mergex/managerserver/model/vo/budget/platform/UpdateSysUserPlatformVo.java`
- `M` `src/main/java/com/ydmob/mergex/managerserver/model/vo/sys/SysUserPlatformVo.java`
- `M` `src/main/java/com/ydmob/mergex/managerserver/service/budget/impl/PlatAccountServiceImpl.java`
- `M` `src/main/java/com/ydmob/mergex/managerserver/service/feature/impl/PolicyServiceImpl.java`
- `M` `src/main/resources/mapper/PolicyManage.xml`
- `M` `src/main/resources/application.yml`（用户环境改动，继续保护）
- `M` `src/test/java/com/ydmob/mergex/managerserver/model/validation/budget/platform/SysUserPlatformValidatorTest.java`
- `??` `sql/policy_manage_plat_account_id.sql`（当前返工唯一可写产品文件）
- `??` `src/test/java/com/ydmob/mergex/managerserver/service/budget/impl/PlatAccountServiceImplTrafficTargetingTest.java`
- `??` `src/test/java/com/ydmob/mergex/managerserver/service/feature/impl/PolicyServiceImplPlatformAccountDimensionTest.java`

## 运行资源

只登记用于发现并发冲突的稳定资源标识，不记录密码、令牌、连接串或真实地址。端口、数据库、Nacos 服务、测试账号等无法安全共享的资源使用“独占”；确实支持并发且不会互相改写的资源才使用“共享”。没有运行资源时明确写“无”。

| 资源标识 | 占用方式 | 用途 |
|---|---|---|

无

## 临时 worktree 生命周期

只有使用独立 worktree 的仓库才填写。创建和清理分别运行 `scripts/create-worktree.rb` 与 `scripts/cleanup-worktree.rb`，由脚本维护本表和上面的产品检出路径。状态只使用“使用中”“待清理”“已删除”，或 `用户确认保留：用户确认……；保留原因……`。`done` 前必须清理为“已删除”；确需保留时必须在状态中同时写明用户确认和保留原因。临时目录删除后不抹掉历史路径、成果分支和最终 HEAD。清理前必须先完成下面的成果同步。

| 仓库 | 原仓库路径 | 临时 worktree 路径 | 分支 | 创建 HEAD | 最终 HEAD | 创建时间 | 状态 | 清理时间 |
|---|---|---|---|---|---|---|---|---|

## worktree 成果同步

worktree 成果提交并合入目标分支的上游后，取得拉取授权，再运行 `scripts/sync-worktree.rb <轮次目录> <仓库名> <目标分支>`。脚本要求真实仓库目录干净且已经检出目标分支，使用 `git pull --ff-only` 拉取，并验证目标分支包含 worktree 最终 HEAD。目标分支不写死为 `main` 或 `master`。只有状态为“已同步验证”且清理脚本复核仍成立，才能删除临时 worktree。

| 仓库 | 目标分支 | worktree 最终 HEAD | 原仓库同步 HEAD | 同步时间 | 状态 |
|---|---|---|---|---|---|
