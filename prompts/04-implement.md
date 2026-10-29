# 实现

先读该轮 `status.md`。`phase` 不是 `implement` 就停。`current_task` 为 `T-xx` 时一次只实现这一条；为 `无` 时只做全部任务完成后的统一检查与审核。若该轮存在 `file-map.md`，按本轮映射定位历史文件。

同时检查 `stage-approvals.md`：需求和计划审批都必须有效且摘要匹配当前文档；缺失、待审批或失效时停止产品写入，返回对应阶段重新确认。再按 `capabilities.yml` 和本轮 `capability-log.md` 确认前序能力门禁有效。用户仅批准计划时只记录审批并进入 `implement / ready`；用户明确要求“执行当前任务”时只做当前任务，要求“完成所有任务”时可连续完成本轮实现任务和统一审核，但不得据此开始验收或收口，也不得扩大到提交、推送、合并、拉取、部署、数据库迁移、服务启动或外部写入。

继续读取任务清单里的当前任务，并按 `work_state` 恢复：`ready` 从 `next_action` 开始；`in_progress` 先核对 `checkpoint`、`workspace.md` 中的仓库基线和测试证据，再从 `next_action` 继续；`blocked` 先确认阻塞条件已经解除。不要重做 `checkpoint` 已经确认完成的步骤。

若从 `verify` 返回，先读失败记录和新增修复任务，确认修复仍在既定需求及改动范围内；旧结果只在代码、依赖、配置或生成物输入已变化时对相应范围失效。当前请求没有产品写入授权时只做只读核对，不能因为阶段已回到 `implement` 就动代码。

## 先读

- 该系统的 `overview.md`
- 该轮的改动范围、任务清单、决策、验收
- [AI 开发约束](../standards/07-ai-constraints.md)

## 只读范围

可以搜索当前任务相关的调用链、同类实现、测试、配置和仓库状态，用来确认实现方式与影响范围。只读范围不等于写入范围。

## 写入范围

`current_task` 点名的文件，而且这些路径必须已经写在该轮改动范围里。按 `overview.md` 的绝对路径打开原来的仓库。

还可以修改该轮 `tasks.md`、`status.md`、`workspace.md`、`test-log.md` 和 `review-checklist.md` 的当前任务记录。临时脚本可以写进该轮 `scripts/`。不要复制产品源码，也不要写密码、令牌或内网地址。

进入本阶段时先复核 `workspace.md` 中预留的产品检出路径、隔离方式和运行资源。真正开始修改每条任务前，使用 `iteration-implementation-guard` 检查授权、范围、依赖、隔离、分支、HEAD 和逐文件 dirty 基线；把守卫结果写入 `evidence/reviews/<task-id>.md`，索引写入 `capability-log.md`。新策略的 `input_digest` 使用 `iteration-context.rb` 输出的 `current_task_digest`，只绑定当前任务正文、改动范围和计划检出/资源区；守卫失败时阻塞，不得先改代码再补证据。

守卫通过并确认没有与其他 `implement` 或 `verify` 轮次冲突后，才把 `work_state` 改为 `in_progress`。只在阶段切换、任务切换、阻塞、恢复或回合交接时更新 `updated_at`、`checkpoint` 和 `next_action`；普通读取、同一连续修改和每条检查命令不单独制造状态写入。阻塞时把 `work_state` 改为 `blocked`，并在 `next_action` 写清解除条件。

没有其他 `implement` 或 `verify` 轮次登记使用同一仓库时，继续使用真实仓库；接管前 dirty 只登记和保护，不创建 worktree。存在同仓库并行轮次且计划使用独立 worktree 时，必须运行框架 `scripts/create-worktree.rb <轮次目录> <仓库名> <分支名> [起点ref]`，由脚本复核并行前提、创建到根目录 `.worktrees/` 并更新 `workspace.md`；禁止手工指定其他目录。实现阶段不得提前运行 `scripts/sync-worktree.rb` 或 `scripts/cleanup-worktree.rb`：同步只在成果已经提交、合入并推送目标分支且取得拉取授权后执行，清理只在同步验证成功后执行；脏 worktree 禁止强删。

向用户汇报实现进展时，按 [入口](./README.md) 的过程汇报契约同时说明已完成事项、下一步和是否需要用户操作；不能只贴命令结果或服务状态。

当前任务的代码和必要测试实现完成后即可在任务清单勾选，不在这里运行完整检查或 code review。任务正文若遗留逐任务完整 review 要求，以当前框架的统一审核规则为准，不重复执行。还有未勾任务时，`phase` 保持 `implement`，把 `current_task` 改成下一条未勾任务、`work_state` 改为 `ready`；`checkpoint` 记录上一条任务已经实现完成，`next_action` 写下一条任务的第一步。

最后一条任务勾选后不要直接进入 `verify`。首次进入验收前，保持 `phase: implement`，把 `current_task` 改为 `无`、`work_state` 改为 `ready`，汇总并去重所有任务的检查命令，再使用 `code-review-skill` 审核本轮全部实际差异；不可用时降级为 `iteration-code-review`。验收返工且已有有效 `task=无` 审核基线时，只检查新增修复任务的实际差异及一层受影响调用链，并在守卫之后追加 `task=T-xx` 的增量 code-review；未变化仓库和已被基线覆盖的差异不重复审核。P0/P1 必须修复，P2 必须修复或明确处置，修复后只重跑受影响检查。检查、审核、修复和复验都追加到 `evidence/reviews/implementation-review.md`。

## 不许做

有任务编号时不跳到下一条；统一审核时不再新增功能。不改改动范围以外的文件。范围不够就停，先把路径补进改动范围，再继续。不顺手重构旁边的模块。不替人启动前后端服务。所有临时副本只认 `.worktrees`、`create-worktree.rb`、`sync-worktree.rb` 和 `cleanup-worktree.rb` 声明的生命周期。

## 做完

只有首次迭代级统一审核，或覆盖最新返工守卫的增量审核通过后，才把 `phase` 改为 `verify`、`current_task` 保持 `无`、`work_state` 改为 `blocked`；`checkpoint` 记录本次实际执行与复用的证据，`next_action` 写明等待用户授权按风险档位开始验收。向用户汇报实现与审核结果，不得把“完成所有任务”解释为验收授权。若当前原话还明确包含“并验收”，则可按路由直接进入 [05-verify](./05-verify.md)，否则必须停下。
