<!-- workspace-policy: managed-worktree-v2 -->
# 产品仓库基线

开始修改产品文件前填写当前任务会涉及的仓库。每次切换任务或发现已有改动时更新，不把接管前的 dirty 文件算成当前 Agent 新产生的改动。dirty 状态必须逐文件记录，不能只写数量。

进入 `implement / ready` 前先登记拟使用的产品检出路径、隔离方式和运行资源，并与其他 `implement` 或 `verify` 轮次核对。默认使用 `overview.md` 的真实仓库和“共享检出”；原仓库存在未提交修改时只登记并保护 dirty 基线，不因此创建 worktree。只有另一产品活动轮次登记使用同一仓库时，才允许使用框架根目录的 `scripts/create-worktree.rb` 创建到 `.worktrees/`；有检出或资源冲突且无法隔离时留在 `plan / blocked`。隔离方式只写“独立 worktree”或“共享检出”。`specify` 和尚未完成预留的 `plan` 可以保留占位内容；真正修改产品文件前再逐文件采集 HEAD 和 dirty 基线。

<!-- plan-approval-scope:start -->
## 计划检出与资源预留

本区块属于计划审批摘要。只写计划采用的仓库、检出路径、隔离方式、目标分支和资源策略；审批后改变这些决定，计划审批会失效。运行期采集的 HEAD、dirty、创建时间和同步结果不放在本区块。

同一系统没有另一轮处于 `implement` 或 `verify`，因此使用 overview 登记的真实仓库和共享检出。不创建 worktree。

| 仓库 | 计划产品检出路径 | 隔离方式 | 目标分支 |
|---|---|---|---|
| `mediatom-manager` | `/Users/mac/Documents/yidian/mediatom/mediatom-manager` | 共享检出 | `tianshuai` |
| `mediatom-web` | `/Users/mac/Documents/yidian/mediatom/mediatom-web` | 共享检出 | `feat-jira2785-appstatus` |

| 资源标识 | 占用方式 | 用途 |
|---|---|---|
| `mediatom-no-exclusive-runtime` | 共享 | 实现阶段不启动服务，不占用独占端口或数据库 |
<!-- plan-approval-scope:end -->

更新时间：2026-10-29T19:33:00+08:00

| 仓库 | 产品检出路径 | 隔离方式 | 分支 | HEAD | 接管前状态 | 当前任务涉及的文件 |
|---|---|---|---|---|---|---|
| `mediatom-manager` | `/Users/mac/Documents/yidian/mediatom/mediatom-manager` | 共享检出 | `tianshuai` | `f65a579af3d7f7df397a34f0dd72d342bc9c5eae` | 无 | T-01 应用列表接口 |
| `mediatom-web` | `/Users/mac/Documents/yidian/mediatom/mediatom-web` | 共享检出 | `feat-jira2785-appstatus` | `59bc8b9b4ead4ce430f5fa9984b2dc741f6b5292` | 2026-10-29T19:33 从 `feat-funlink@db688e470` 切回。四个报表文件的未提交改动随工作区带过来 | T-02 综合报表和小时报表筛选 |

## 接管前 dirty 明细

计划阶段只读查看。真正修改产品文件前再逐文件采集 HEAD。

### mediatom-manager

接管前无未提交文件。当前未提交：

- `M src/main/java/com/ymob/saas/managerserver/controller/traffic/AppController.java`
- `M src/main/java/com/ymob/saas/managerserver/mapper/traffic/AppMapper.java`
- `M src/main/java/com/ymob/saas/managerserver/service/traffic/AppService.java`
- `M src/main/java/com/ymob/saas/managerserver/service/traffic/impl/AppServiceImpl.java`
- `M src/main/resources/mapper/AppMapper.xml`

### mediatom-web

接管前无未提交文件。当前未提交：

- `M src/api/media.js`
- `M src/views/reportdatas/SynthReport/SynthSearch/index.vue`
- `M src/views/reportdatas/HoursReport/HoursSearch/index.vue`
- `M src/views/reportdatas/shared/reportSearchLoader.js`

## 收口后提交结果

| 仓库 | 分支 | 提交 HEAD | 提交后状态 |
|---|---|---|---|
| `mediatom-manager` | `tianshuai` | `88dad1f0b4b6f3be9ea3634ffecae59eeb0949b6` | 已推送到 `origin/tianshuai`，工作区干净 |
| `mediatom-web` | `feat-jira2785-appstatus` | `df6ebadce64bc420f812e9b3676a843181824b78` | 已推送到 `origin/feat-jira2785-appstatus`，工作区干净 |

用户原话「提交推送」。没有把 `tianshuai` 合入 `main`，没有拉取，没有部署。上表不改写接管前基线。

## 运行资源

无

## 临时 worktree 生命周期

只有使用独立 worktree 的仓库才填写。创建和清理分别运行 `scripts/create-worktree.rb` 与 `scripts/cleanup-worktree.rb`，由脚本维护本表和上面的产品检出路径。状态只使用“使用中”“待清理”“已删除”，或 `用户确认保留：用户确认……；保留原因……`。`done` 前必须清理为“已删除”；确需保留时必须在状态中同时写明用户确认和保留原因。临时目录删除后不抹掉历史路径、成果分支和最终 HEAD。清理前必须先完成下面的成果同步。

| 仓库 | 原仓库路径 | 临时 worktree 路径 | 分支 | 创建 HEAD | 最终 HEAD | 创建时间 | 状态 | 清理时间 |
|---|---|---|---|---|---|---|---|---|

## worktree 成果同步

worktree 成果提交并合入目标分支的上游后，取得拉取授权，再运行 `scripts/sync-worktree.rb <轮次目录> <仓库名> <目标分支>`。脚本要求真实仓库目录干净且已经检出目标分支，使用 `git pull --ff-only` 拉取，并验证目标分支包含 worktree 最终 HEAD。目标分支不写死为 `main` 或 `master`。只有状态为“已同步验证”且清理脚本复核仍成立，才能删除临时 worktree。

| 仓库 | 目标分支 | worktree 最终 HEAD | 原仓库同步 HEAD | 同步时间 | 状态 |
|---|---|---|---|---|---|
