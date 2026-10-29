# 轮次绑定规则

本目录不保存全局“当前轮次”。同一系统可以同时存在多个活动轮次，共享指针会让并行 Agent 相互覆盖，因此每个 Agent 会话都必须独立绑定一个轮次。

绑定顺序：

1. 任务工作目录位于 `iterations/<iteration>/` 时，绑定该轮。
2. 用户明确点名轮次路径或完整名称时，绑定点名轮次。
3. 从系统目录启动且只有一个非 `done` 轮次时，自动绑定该轮。
4. 存在多个非 `done` 轮次且用户未点名时，列出各轮的 `phase`、`work_state` 和 `next_action`，请用户选择；未选择前不得写入。
5. 没有活动轮次时，可以查询历史轮次，或在取得写入授权后通过 `scripts/create-iteration.rb` 新开一轮；禁止人工创建轮次目录或复制模板。

绑定只对当前 Agent 会话有效，不写回共享文件。轮次状态始终以该轮 `status.md` 为唯一动态来源；`stage-approvals.md` 只保存审批证据。先读根目录 `capabilities.yml`，再运行 `scripts/iteration-context.rb`，由它只读汇总 `capability-log.md` 和 `evidence/` 索引，取得 `workflow_profile`、当前任务和 `read_next`，不默认全量读取档案。若有未确认问题，必须同屏展示问题全文、推荐方案、关键影响和可直接复制的回答，不能只写 `Qxx`；未收到用户直接回答并保存原话前禁止标成 `resolved` 或跨过审批。单条任务只做实现守卫和代码实现；全部任务完成后使用 `current_task: 无` 统一检查与审核，证据写入 `implementation-review.md`，通过后进入 `verify / blocked` 等待验收授权和受控浅功能回归。使用 `iteration-governor` 按 `lite / standard / strict` 选择门禁；MCP 默认只读，能力证据不替代用户审批或外部写入授权。规格与计划分别接受“需求审批通过”“计划审批通过”或等价自然语言，并由 `scripts/record-stage-approval.rb` 分阶段记录；联合原话仍需分别绑定摘要，普通写入授权不能替代审批。“完成所有任务”只允许连续完成实现任务和统一审核；“开始验收”完成按风险验收后再次等待，“确认收口”才允许交付复核和 `done`，联合表达可连续执行对应范围。所有这些授权都不含外部变更。默认使用真实仓库，dirty 只登记基线；只有另一 `implement` 或 `verify` 轮次使用同一仓库时，才用框架 `scripts/create-worktree.rb` 创建到根目录 `.worktrees/`。轮次收口前先按授权用 `scripts/sync-worktree.rb` 在真实仓库拉取显式目标分支并验证包含最终 HEAD，再用 `scripts/cleanup-worktree.rb` 清理并恢复 `workspace.md` 的真实仓库路径，禁止强删脏 worktree。

绑定后每个用户回合都将当前完整原话作为单个经过 shell 安全转义的参数传给 `scripts/iteration-context.rb <轮次目录> --intent SAFE_USER_MESSAGE`，禁止拼接未转义原话，优先执行 `intent_route`；识别成功后不得要求用户改说固定口令。
