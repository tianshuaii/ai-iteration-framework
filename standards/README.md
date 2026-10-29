# 标准

这些是每次迭代都要遵守的写法。某一轮的具体内容写在该轮文件夹里，不要写在这里。

| 文件 | 管什么 |
|---|---|
| [00-principles](./00-principles.md) | 任何一套系统都要守的做法 |
| [01-lifecycle](./01-lifecycle.md) | 从需求到收口的顺序 |
| [02-requirements-and-decisions](./02-requirements-and-decisions.md) | 需求和已经拍板的事怎么写 |
| [03-change-scope](./03-change-scope.md) | 系统、仓库和文件范围怎么圈 |
| [04-plan-and-tasks](./04-plan-and-tasks.md) | 实现计划和任务清单怎么拆 |
| [05-acceptance-and-testing](./05-acceptance-and-testing.md) | 验收、策略、用例、记录、跟踪 |
| [06-risk-and-review](./06-risk-and-review.md) | 风险、回退、收口检查 |
| [07-ai-constraints](./07-ai-constraints.md) | 交给 AI 改代码时必须守的规矩 |
| [08-capabilities-and-evidence](./08-capabilities-and-evidence.md) | Skills、MCP、阶段能力和持久化证据 |

新开一轮时必须运行 `ruby scripts/create-iteration.rb systems/<system> 中文主题`，由脚本在系统级文件锁内把 [templates](../templates/README.md) 发布到新轮次，再按上面的顺序填。禁止人工创建轮次目录或复制模板。序号接在这套系统已有轮次后面，主题用中文。

默认使用 `overview.md` 登记的真实仓库，接管前 dirty 只登记基线。只有另一 `implement` 或 `verify` 轮次登记使用同一仓库时，才使用 `scripts/create-worktree.rb` 创建根目录 `.worktrees/` 下的受控临时副本；收口前先按授权使用 `scripts/sync-worktree.rb` 在真实仓库拉取显式目标分支并验证包含 worktree 最终 HEAD，再使用 `scripts/cleanup-worktree.rb` 清理并恢复迭代文档中的真实仓库路径。脏 worktree 不强删，成果分支不自动删除。
