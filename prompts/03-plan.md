# 拆任务

先读该轮 `status.md`。`phase` 不是 `plan` 就停。若该轮存在 `file-map.md`，按本轮映射定位历史文件。

## 先读

- 该轮的需求、决策、改动范围、验收
- [计划与任务](../standards/04-plan-and-tasks.md)
- [风险与评审](../standards/06-risk-and-review.md) 里风险那一节

## 只许改这些

该轮文件夹里的：`implementation-plan.md`、`tasks.md`、`risks.md`、`workspace.md`、`design-interview.md`、`capability-log.md`、`evidence/analysis/`、`status.md`。`workspace.md` 只登记拟使用的检出与运行资源，不在计划阶段修改产品仓库。

每条任务写成：`- [ ] T-01 说明。依赖：无。文件：路径。检查：一条命令`。同时在 `test-strategy.md` 为每条任务填写 `T0` 到 `T4`、影响范围、必跑项、可复用证据和升级条件。文件不在改动范围里的不能写进任务；测试程度按风险和影响决定，不能按代码行数决定。

若是验收后因需求或范围变化返回计划阶段，先对照变更后的 AC/TC 和改动范围重审既有任务：受影响任务恢复为未完成，补充必要检查；已经核实且完全不受影响的任务可以保留完成状态，但必须写明判断依据。不得把旧计划直接当作新规格的实现依据。

## 不许做

不改 `overview.md` 里列出的仓库。

## 做完

先在该轮 `workspace.md` 的 `plan-approval-scope` 标记区登记第一条任务将使用的产品检出路径、隔离方式、目标分支和运行资源，并与其他 `implement`、`verify` 轮次核对。没有另一产品活动轮次使用同一仓库时，计划必须采用 `overview.md` 登记的真实仓库和“共享检出”；原仓库 dirty 只登记基线，不触发 worktree。标记区外的 HEAD、dirty、时间和同步结果留给运行期采集。检出路径或独占资源冲突且无法隔离时，保持 `phase: plan`、`work_state: blocked`，写明等待条件；不要先进入 `implement / ready`。

只有另一 `implement` 或 `verify` 轮次登记使用同一仓库时，才规划独立 worktree；规划阶段不手工执行 Git 创建命令。取得产品写入授权后，使用框架根目录的 `scripts/create-worktree.rb`，把副本固定创建到 `.worktrees/<system>/<iteration>/<repo>/`；脚本会复核并行前提并同步本轮 `workspace.md`。计划里同时写明目标分支：成果提交、合入并推送后，取得拉取授权，先运行 `scripts/sync-worktree.rb` 在真实仓库执行 `git pull --ff-only` 并验证包含最终 HEAD，再运行 `scripts/cleanup-worktree.rb`。脏 worktree 不得强删，功能分支不随目录自动删除。

确认隔离、任务和风险都已写完后，按已经批准的档位处理计划设计：`lite` 用确定性清单记录 skipped；`standard` 不重复执行第二次 grill-me，按当前计划摘要记录 skipped，并由 `iteration-plan-review` 检查任务、风险、测试和资源隔离；`strict` 使用 `grill-me` 完成计划设计树访谈，不可用时降级为 `iteration-design-interview`。等待回答时必须同屏展示每个 `Qxx` 的问题全文、推荐答案、主要影响和可复制回复，未确认行只能是 `待确认 / pending / 无`；用户直接回答后才写 `resolved` 和确认原话。测试策略必须登记受控浅功能回归：至少一条直接功能和一条一层高概率相邻功能，并写明纳入理由与停止边界。计划评审追加到 `evidence/analysis/stage-review.md` 的 plan 章节，`capability-log.md` 仍保存独立能力索引。

能力门禁通过后仍不能直接进入 `implement`。把所绑定轮次的 `status.md` 保持为 `phase: plan`、`current_task: 无`，将 `work_state` 设为 `blocked`；`updated_at` 写当前时间，`checkpoint` 记录规格、计划、资源核对和哪些旧任务经复核仍有效。若需求审批保存的原话已明确联合批准计划，直接复用该原话记录计划摘要；否则 `next_action` 请求用户明确批准计划，并可给“计划审批通过”作为示例。

只有用户以“计划审批通过”或含义明确的等价自然语言批准计划，或需求记录中已有联合审批原话时，才运行 `ruby scripts/record-stage-approval.rb <轮次目录> plan ["用户原话"]`。脚本会再次检查访谈和计划评审证据。命令成功后再把 `status.md` 更新为 `phase: implement`、`current_task` 为第一条未完成任务编号、`work_state: ready`，并刷新系统总览。计划审批本身不授权修改产品代码；“完成所有任务”只授权连续完成本轮实现任务和统一审核，验收与收口仍需分别授权。进入实际修改前，再逐文件采集 HEAD 和 dirty 基线。临时副本只按 `.worktrees`、`create-worktree.rb`、`sync-worktree.rb`、`cleanup-worktree.rb` 这套生命周期处理。下一步用 [04-implement](./04-implement.md)。
