# 生命周期

一轮迭代按这个顺序走。前一步没写完，不要跳到改代码。当前阶段和恢复断点统一写在该轮 `status.md`，不另建第二份进度表。同一系统可以同时有多轮处于非 `done` 状态，但一个 Agent 会话只能推进所绑定的一轮。

正常路径是 `specify → 需求访谈/评审 → 需求审批 → plan → 计划访谈/评审 → 计划审批 → implement → 等待验收授权 → verify → 等待收口授权 → done`。需求和计划完成时先产生 `capability-log.md` 与 `evidence/` 能力证据，再保持当前 phase 和 `blocked`，等待用户以明确的等价自然语言批准对应阶段，由 `scripts/record-stage-approval.rb` 分别检查能力证据并写入 `stage-approvals.md`。一句话可同时授权两道逻辑审批，但计划只能在自身材料与评审完成后绑定摘要；普通“继续”“开始处理”“可以”不是审批。“完成所有任务”可连续推进本轮实现任务和统一审核，但不隐含验收或收口；明确联合表达才连续跨越对应边界。这不是只能向前的流水线：验收发现代码缺陷时，按 [验收入口](../prompts/05-verify.md) 建立返工任务并回到 `implement`；发现需求、范围或验收标准变化时，先回到 `specify`，重新完成两次审批、计划与受影响的检查。每次回退都要在测试记录保留失败事实、原因和受影响编号；阶段切换不授予新的产品写入权限。

`status.md` 的六个状态字段必须一起维护：`phase` 表示阶段，`current_task` 表示当前实现任务，`work_state` 表示当前阶段待开始、进行中、阻塞或完成，`updated_at` 表示最后一次确认状态的时间，`checkpoint` 只写已经核实的事实，`next_action` 写恢复后的第一件具体事情。

`stage-approvals.md` 只保存审批证据，不保存动态阶段。需求摘要覆盖需求、决策、范围、验收与测试设计；计划摘要覆盖实现计划、任务正文、风险和 `workspace.md` 的稳定计划区。任务勾选、运行期仓库基线、同步记录和验收结果不会使审批失效；其余受保护内容改变后必须回到对应阶段重批。历史已完成轮次不追溯补审批，活动轮次从下一个未经过门禁启用能力策略，后续新轮次完整执行。

| phase | 允许 | 禁止 |
|---|---|---|
| `specify` | 写需求、决策、改动范围、验收、测试策略、测试用例、跟踪表 | 改 `overview.md` 里列出的仓库 |
| `plan` | 写实现计划、任务清单、风险 | 改 `overview.md` 里列出的仓库 |
| `implement` | 有 `T-xx` 时只实现当前任务；任务全部勾选后使用 `current_task: 无` 集中执行检查、整轮 code review、修复和复验 | 跳任务、逐任务重复完整审核，或改写入范围外的文件 |
| `verify` | 跑计划内自动测试、正式 AC/TC 和受控浅功能回归，填写测试记录、验收结果和评审清单；失败时记录原因并按返工规则转阶段 | 把浅回归扩成无关全系统回归、借验收顺手改功能，或有未过且未取得受控豁免的项目时进入 `done` |
| `done` | 所有验收与测试已通过或取得受控豁免，临时 worktree 已删除或取得用户确认保留，保留本轮完整档案；另有授权时把结论同步到系统知识库 | 再改代码，除非新开一轮 |

`specify`、`plan` 和 `verify` 没有当前代码任务，必须使用 `current_task: 无`；它们和 `implement` 的 `work_state` 只能是 `ready`、`in_progress` 或 `blocked`。`implement` 实现任务时使用 `T-xx`，首次统一审核或返工增量审核窗口使用 `无`。`done` 使用 `current_task: 无` 和 `work_state: done`。

`specify` 和 `plan` 不写产品代码，可以与其他轮次并行。进入 `implement / ready` 前（含验收返工），必须在 `workspace.md` 预留产品检出路径、隔离方式和运行资源。默认使用真实仓库；原仓库 dirty 时逐文件登记基线并保护既有改动，不创建 worktree。只有另一 `implement` 或 `verify` 轮次登记使用同一仓库时，当前轮才创建独立检出。端口、数据库、服务注册或测试夹具等共享环境也要声明稳定的资源标识；检出或独占资源无法隔离时留在 `plan / blocked`，按轮次串行执行。

同仓库产品阶段并行时，使用根目录 `scripts/create-worktree.rb` 创建到 `.worktrees/<system>/<iteration>/<repo>/`，由脚本验证并行前提并同步 `workspace.md` 的当前检出路径和生命周期记录。验收完成后，先按单独授权提交、推送并把成果合入目标分支；再取得拉取授权，使用 `scripts/sync-worktree.rb` 要求真实仓库处于显式目标分支且目录干净，执行 `git pull --ff-only`，并验证目标分支包含 worktree 最终 HEAD。只有同步状态为“已同步验证”且复核仍成立，才使用 `scripts/cleanup-worktree.rb` 清理；脚本拒绝脏工作区、不使用强制删除、不删除成果分支，并把当前检出路径恢复为 `overview.md` 中的真实仓库。状态仍为“使用中”或“待清理”，或 v2 记录缺少同步证据时不得进入 `done`。确需继续保留目录时，状态必须写明用户确认和保留原因。

| 阶段 | 要有的文件 | 结束时的样子 |
|---|---|---|
| 说清要什么 | `requirements.md`、`decisions.md` | 能看出默认行为、老数据、明确不做的事 |
| 圈范围 | `change-scope.md` | 每个要动的项目都有大致文件；同一页面的说明、筛选、表格和弹窗都列清；不动的项目写明不动 |
| 怎样算完 | `acceptance.md`、`test-strategy.md`、`test-cases.md`、`traceability.md` | 每条需求能对到验收和用例 |
| 怎么做 | `implementation-plan.md`、`tasks.md`、`risks.md` | 任务有顺序，且都落在改动范围内 |
| 改代码 | `tasks.md` 逐条勾、`evidence/reviews/implementation-review.md` | 只改点名文件；全部任务完成后统一检查和审核 |
| 验证 | `test-log.md`、`acceptance.md` | 正式用例和受控浅功能回归有通过或未过 |
| 收口 | `review-checklist.md`、`workspace.md` | 所有任务和清单通过，验收与用例通过或取得受控豁免，真实仓库目标分支已同步并验证，临时 worktree 已删除或取得用户确认保留后，才进入 `done` |

对应外面常见的叫法：规格、澄清后的决策、技术计划、任务、实现、测试记录、评审收口。新轮次统一使用英文文件名；历史轮次若保留旧文件名，只在本轮 `file-map.md` 维护兼容映射。
