# 模版

新开一轮时，由 `scripts/create-iteration.rb` 把本目录里除本文件和 `optional-knowledge-base` 以外的文件原样复制到 `systems/<system>/iterations/00N-YYYY-MM-DD-中文主题/`，包括 `scripts/`、`evidence/`、双 `pending` 的 `stage-approvals.md`、`design-interview.md` 和 `capability-log.md`。脚本会在系统级文件锁内取得下一个编号，并把 `status.md` 的 `updated_at` 与能力日志的 `adopted_at` 占位符替换为同一个带时区 ISO 8601 时间。再按 [standards](../standards/README.md) 填空。其他活动轮次不需要先完成，主题使用中文。禁止人工创建轮次目录或复制模板。

规格阶段先按 `capabilities.yml` 选择 `lite / standard / strict`：lite 使用确定性清单，standard 只在非简单需求阶段访谈一次，strict 在需求和计划阶段都访谈。需求与计划评审分节写入同一份 `evidence/analysis/stage-review.md`，再分别等待用户用“需求审批通过”“计划审批通过”或含义明确的等价自然语言批准。联合审批原话仍在两个阶段分别绑定摘要；使用 `scripts/record-stage-approval.rb` 保存用户证据，脚本会拒绝缺失或过期的能力证据。不要手工把模板里的 `pending` 改成 `approved`。“完成所有任务”只授权本轮实现任务和统一审核；验收与收口各自需要明确授权，联合表达才可连续执行。所有这些授权都不包含外部变更。

实现阶段每条任务只留下写入前守卫并完成代码；首次进入验收前用 `task=无` 审核本轮完整差异，验收返工用 `task=T-xx` 增量审核新任务。进入 `verify` 后按风险档位执行受影响的 AC/TC 和浅回归，未失效证据可注明依据后复用。

必须用 `ruby scripts/create-iteration.rb systems/<system> 中文主题` 完成复制、编号和真实时间写入；模板目录本身保留占位符，不直接当真实轮次使用。所有文件在创建时一次发布，填写内容则按阶段逐步进行；不要求在 `specify` 阶段写好实现计划或测试结果。脚本不可用或执行失败时停止并报告，不得手工兜底。

某一轮需要额外资料时，另把 `optional-knowledge-base` 复制到该轮并改名为 `knowledge-base`；不需要就不要建。

`workspace.md` 带有受控 worktree 生命周期表和真实仓库同步表。默认使用真实仓库，dirty 只登记基线；只有另一 `implement` 或 `verify` 轮次使用同一仓库时，独立检出才可由根目录 `scripts/create-worktree.rb` 创建到 `.worktrees/`。收口前先按授权由 `scripts/sync-worktree.rb` 在真实仓库拉取显式目标分支并验证包含最终 HEAD，再由 `scripts/cleanup-worktree.rb` 清理。模板本身不创建临时目录。
