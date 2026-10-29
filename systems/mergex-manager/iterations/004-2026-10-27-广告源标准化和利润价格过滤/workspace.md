<!-- workspace-policy: managed-worktree-v2 -->
# 产品仓库基线

开始修改产品文件前填写当前任务会涉及的仓库。每次切换任务或发现已有改动时更新，不把接管前的 dirty 文件算成当前 Agent 新产生的改动。dirty 状态必须逐文件记录，不能只写数量。

进入 `implement / ready` 前先登记拟使用的产品检出路径、隔离方式和运行资源，并与其他 `implement` 或 `verify` 轮次核对。默认使用 `overview.md` 的真实仓库和“共享检出”；原仓库存在未提交修改时只登记并保护 dirty 基线，不因此创建 worktree。只有另一产品活动轮次登记使用同一仓库时，才允许使用框架根目录的 `scripts/create-worktree.rb` 创建到 `.worktrees/`；有检出或资源冲突且无法隔离时留在 `plan / blocked`。隔离方式只写“独立 worktree”或“共享检出”。`specify` 和尚未完成预留的 `plan` 可以保留占位内容；真正修改产品文件前再逐文件采集 HEAD 和 dirty 基线。

<!-- plan-approval-scope:start -->
## 计划检出与资源预留

本区块属于计划审批摘要。只写计划采用的仓库、检出路径、隔离方式、目标分支和资源策略；审批后改变这些决定，计划审批会失效。运行期采集的 HEAD、dirty、创建时间和同步结果不放在本区块。

| 仓库 | 计划产品检出路径 | 隔离方式 | 目标分支 |
|---|---|---|---|
| mergex-manager | /Users/mrzater/java/mergex-manager | 共享检出 | feat-zhoutao |
| mediatom-web | /Users/mrzater/project/mediatom-web | 共享检出 | feat-20261027mer3779 |

| 资源标识 | 占用方式 | 用途 |
|---|---|---|
| 无 | 共享 | 不占端口，不代启服务，不跑正式库迁移 |
<!-- plan-approval-scope:end -->

更新时间：2026-10-27T19:21:00+08:00

| 仓库 | 产品检出路径 | 隔离方式 | 分支 | HEAD | 接管前状态 | 当前任务涉及的文件 |
|---|---|---|---|---|---|---|
| mergex-manager | /Users/mrzater/java/mergex-manager | 共享检出 | feat-zhoutao | ed5ccad358dfc82005aef97879d8f2575c67347c | dirty（见下） | sql/dsp_place_app_std.sql；DspPlace；DspPlaceSaveVo；DspPlaceMapper.xml；DspPlaceServiceImpl；PriceStrategyServiceImpl |
| mediatom-web | /Users/mrzater/project/mediatom-web | 共享检出 | feat-20261027mer3779 | 86c774fe172500141c2c6447d113de93840de2e7 | dirty（见下） | EditSource BaseInfoForm/data；budget 中英 i18n；UpdateLinkConfig index/data |

## 接管前 dirty 明细

实现前再采集。当前已知本地环境文件可能仍在，不算本轮功能。

### mergex-manager

- `src/main/resources/application.yml`（接管前已有，本轮不改）

### mediatom-web

- `build/env/development/adx.js`（接管前已有，本轮不改）

## 运行资源

| 资源标识 | 占用方式 | 用途 |
|---|---|---|
| 无 | 共享 | 不占端口，不代启服务 |

## 临时 worktree 生命周期

| 仓库 | 原仓库路径 | 临时 worktree 路径 | 分支 | 创建 HEAD | 最终 HEAD | 创建时间 | 状态 | 清理时间 |
|---|---|---|---|---|---|---|---|---|

## worktree 成果同步

| 仓库 | 目标分支 | worktree 最终 HEAD | 原仓库同步 HEAD | 同步时间 | 状态 |
|---|---|---|---|---|---|
