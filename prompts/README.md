# 入口

从 `systems/` 启动且系统尚未登记时，先用 [00-register-system](./00-register-system.md)。进入已有系统后，按该系统 `agent/README.md` 的规则给当前 Agent 会话绑定一个轮次，再读所绑定轮次的 `status.md` 并打开对应入口。一个 Agent 会话一次只做一个轮次的一个阶段。

同一系统允许多个活动轮次并存。工作目录已在轮次目录或用户明确点名轮次时直接绑定；系统目录只有一个活动轮次时自动绑定；存在多个活动轮次且用户未点名时，只列出候选并请用户选择，不得自行用最新序号或聊天记录猜测。

恢复工作且没有当前用户消息时运行 `ruby scripts/iteration-context.rb <轮次目录>`；绑定后的每个用户回合把完整原话作为单个经过 shell 安全转义的参数传给 `ruby scripts/iteration-context.rb <轮次目录> --intent SAFE_USER_MESSAGE`，禁止拼接未转义原话。先按 `intent_route` 决定审批与执行范围，再按 `read_next` 打开必要正文；识别成功后不得要求用户换成固定口令。`checkpoint` 是已经验证的断点，`next_action` 是恢复后要做的第一件事；上下文脚本只是只读汇总，不替代 `status.md`。

所有阶段的过程更新都使用同一契约：写明 `已完成：`、`下一步：`，并根据是否需要用户介入选择 `无需你操作：` 或 `需要你：`。服务启停、健康检查、测试结果和故障恢复都不能只报状态后停止。回合结束时，用户可见的下一步必须与 `status.md` 的 `next_action` 一致；等待 `Qxx` 时必须同屏展示问题全文、推荐答案和可复制回复，未确认前不得写成 `resolved`。

`status.md` 是唯一动态状态源。每次修改任一状态字段后，从框架根目录运行 `ruby scripts/refresh-iteration-overview.rb systems/<system>`，把所有轮次重新投影到该系统 `overview.md` 的固定管理块；不得手工编辑生成表。新建轮次由 `create-iteration.rb` 在创建锁内自动完成这一步。

需求和计划各有一次不可合并的逻辑审批。`stage-approvals.md` 保存用户原话、审批时间和当时文档摘要；它不是进度源。用户可说“需求审批通过”“计划审批通过”或目标与批准动作明确的等价自然语言，也可一次说“自动审批需求和计划”或“自动完成需求和计划审批流程”。收到联合原话时先记录已就绪的需求；计划仍停在 `plan / blocked`，直到计划访谈和评审完成，再由 `scripts/record-stage-approval.rb` 复用原话并绑定计划摘要。普通“继续”“开始处理”“可以”只能作为写入授权，不能代替审批。

根目录 `capabilities.yml` 登记阶段能力、三级档位、首选 Skill、降级 Skill 和 MCP 权限。使用 `iteration-governor` 从 `capability-log.md` 与证据恢复门禁。三个档位都保留双审批、首次整轮审核、返工增量审核和按风险验收；测试证据只在输入未变化时复用。MCP 默认只读，任何外部写入仍需当前请求明确授权。

统一代码审核固定写入 `evidence/reviews/implementation-review.md`；受控浅功能回归使用 `SR-xx`，只覆盖直接功能与一层高概率相邻功能。

需求审批绑定需求、决策、范围、验收和测试设计；这些内容改变后旧需求审批失效，计划也必须重审。计划审批绑定实现计划、任务正文、风险和 `workspace.md` 的计划检出与资源预留区；这些内容改变后旧计划审批失效。运行期 HEAD、dirty、同步结果、验收结果和任务完成勾选不改变摘要。`计划审批通过` 只允许进入 `implement / ready`；“完成所有任务”只授权连续完成本轮实现任务与统一审核，然后停在 `verify / blocked`。“开始验收”只授权测试验证并再次等待收口；“确认收口”只在新鲜验收证据有效时授权交付复核和 `done`。明确联合表达可以连续执行对应范围，但这些指令都不授权提交、推送、合并、拉取、部署、数据库迁移、服务启动或外部写入。

| phase | 入口 |
|---|---|
| 系统尚未登记 | [00-register-system](./00-register-system.md) |
| 还没有这一轮 | [01-open-iteration](./01-open-iteration.md) |
| `specify` | [02-specify](./02-specify.md)，完成后等待需求审批 |
| `plan` | [03-plan](./03-plan.md)，完成后等待计划审批 |
| `implement` | [04-implement](./04-implement.md) |
| `verify` 或准备收口 | [05-verify](./05-verify.md) |

新轮次只使用标准英文文件名。历史轮次缺少标准文件时，只读该轮自己的 `file-map.md`；通用入口不得记录某套系统或某一轮的兼容映射。

新建迭代必须通过 `scripts/create-iteration.rb`，禁止人工创建轮次目录或复制模板。创建脚本不可用时保持只读并报告阻塞，不能绕过系统级并发锁。

仓库地址只看该系统的 `overview.md`。不要在系统或迭代目录里找产品源码，也不要创建指向产品仓库的目录快捷方式。默认使用真实仓库，dirty 只登记基线；只有另一 `implement` 或 `verify` 轮次登记使用同一仓库时，才允许由 `scripts/create-worktree.rb` 创建到根目录 `.worktrees/` 的受控临时 Git worktree。收口前先按授权由 `scripts/sync-worktree.rb` 把显式目标分支拉取到真实仓库并验证包含最终 HEAD，再由 `scripts/cleanup-worktree.rb` 清理。本轮临时脚本放在该轮 `scripts/`。
