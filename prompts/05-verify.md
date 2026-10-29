# 验收

先读该轮 `status.md`。`phase` 不是 `verify` 就停。还有未勾任务时，不直接调用只接受 `implement` 阶段的入口；先按本页“失败后的返工入口”完成交接，再进入 [04-implement](./04-implement.md)。若该轮存在 `file-map.md`，按本轮映射定位历史文件。

同时读取当前回合 `iteration-context.rb --intent` 的结果。只有 `intent_route` 为 `run_verification`、`verification_then_close`，或从实现阶段明确联合授权后续验收的路由时，才开始或继续验收。`all_implementation_tasks`、`execution_not_ready` 和普通“完成所有任务”都不构成验收授权。只有 `close_iteration`、`verification_then_close`，或明确联合授权收口的跨阶段路由，才允许执行本页的收口部分。

## 先读

- 该轮的测试策略、测试用例、验收标准、改动范围、评审清单
- [验收与测试](../standards/05-acceptance-and-testing.md)
- [风险与评审](../standards/06-risk-and-review.md)

## 只许改这些

该轮的 `test-log.md`、`acceptance.md`、`review-checklist.md`、`capability-log.md`、`evidence/tests/`、`evidence/delivery/` 和 `status.md`。仅在代码缺陷返工交接时，还可在 `tasks.md` 追加一条未完成任务，并在 `workspace.md` 更新产品检出与资源预留；不能在验收阶段修改产品文件。历史轮次按本轮映射使用实际文件名。本轮文件夹保留，不删除。

向 `knowledge-base` 写结论属于框架目录外写入，必须取得该项明确授权，并在写入前说明目标文件。

先按 `test-strategy.md` 的任务风险表确定本次深度与宽度，再执行必须项、正式 AC/TC 和受控浅功能回归。`T0` 到 `T4` 由运行影响决定，不由代码行数决定；小改动涉及权限、数据、并发或共享契约时仍应升级。浅回归只覆盖已登记的直接功能与一层高概率相邻功能，不临时扩大到无影响依据的模块或全系统回归。

自动检查记录实际命令、目标仓库、执行时间、退出码、所测 HEAD 或工作区基线；有 CI/PR 时附链接。代码、依赖、配置和生成物输入均未变化时，可以引用 `test-log.md` 的既有记录并说明未失效原因；任一输入变化时只重跑受影响项。人工用例记录环境与可复核的结果，文字“通过”不能代替执行或复用证据。

开始验收时把 `work_state` 改为 `in_progress`。只在验收组切换、阻塞、恢复或回合交接时更新 `status.md`；单条命令和同组连续用例只写入 `test-log.md`，不反复改状态。`verify` 阶段保持 `current_task: 无`；有未过或无法执行的项目时，把 `work_state` 改为 `blocked`，在断点中记录事实和恢复入口，不把结果写成通过。用户明确接受残余风险时可以使用受控豁免：测试结果写“豁免”，现象列写明用户确认和残余风险；对应验收结果写 `豁免：用户确认……；残余风险……`。

汇报服务启停、健康检查或某组用例结果时，按 [入口](./README.md) 的过程汇报契约明确写出接下来继续哪条检查；若必须由用户登录或执行外部动作，写成一条可直接执行的 `需要你：`，并记录阻塞状态。

全部验收完成后，对最终差异和测试记录做一次共享读取：使用 `iteration-test-verification` 核对正式 AC/TC、浅功能回归范围、结果和停止边界，写 `evidence/delivery/final-review.md` 的测试验证章节，并在 `capability-log.md` 保留独立索引和发现计数。若当前原话没有收口授权，到这里把 `work_state` 改为 `blocked`；`checkpoint` 记录验收通过项、复用证据、豁免和残余风险，`next_action` 写明等待用户确认收口。向用户汇报验收结果后停止，不调用 `iteration-delivery-review`，不清理 worktree，也不改成 `done`。

取得收口授权后，使用 `iteration-delivery-review` 在同一文件追加范围、审批、统一代码审核、豁免、同步和残余风险章节，并在 `capability-log.md` 写独立索引。单独收到 `close_iteration` 时必须先确认已有新鲜且通过的 `test-verification` 证据；缺失或失效时保持 `verify / blocked`，要求先验收，不能用收口授权反推验收授权。

收口授权有效时再检查 `workspace.md` 的临时 worktree 生命周期。受控副本只能由 `scripts/create-worktree.rb` 创建在框架根目录 `.worktrees/`。确认成果已经提交、合入并推送目标分支后，先取得本次拉取授权，运行 `scripts/sync-worktree.rb <轮次目录> <仓库名> <目标分支>`；它要求真实仓库干净且已检出目标分支，使用 `git pull --ff-only`，并验证目标分支包含 worktree 最终 HEAD。同步记录为“已同步验证”后，再运行 `scripts/cleanup-worktree.rb <轮次目录> <仓库名>`。清理脚本会二次验证两端 HEAD，再用 Git 原生命令删除副本、执行 prune、把产品检出路径恢复为 `overview.md` 的真实仓库，并保留成果分支、最终 HEAD 和同步证据。脏 worktree 不得使用强制参数清理；用户明确要求保留时，在状态中写 `用户确认保留：用户确认……；保留原因……`。

## 不许做

有未过且未取得受控豁免的项目时，不得进入 `done`；完成下面的返工交接后可按原因回到 `implement` 或 `specify`，否则 `phase` 保持 `verify`。普通“收口”“跳过”或 `SKIP` 不能代替豁免。不借验收顺手改功能。不替人启动服务，除非这一轮写明了并且人已经同意。

## 失败后的返工入口

先把未通过事实、失败命令或用例、受影响的 AC/TC 与原因写入 `test-log.md`，对应验收保持“未通过”。不能把旧结果擦掉假装从未失败。

- 仅是现有规格内的代码缺陷、且修复文件已在 `change-scope.md`：在 `tasks.md` 追加唯一编号的未完成修复任务，列出依赖、文件和检查命令；将受影响的评审项恢复为未勾选。把旧结果移入 `test-log.md` 的返工历史，再将本轮 AC/TC 当前结果重置为“未测”。复核 `workspace.md` 的检出路径和独占资源；有冲突时先保持 `verify / blocked`，待隔离后再切到 `implement / ready` 和新任务编号。下一步使用 [实现入口](./04-implement.md)。若当前请求没有写入授权，只读报告返工建议，不修改任何文件；阶段切换也不授予下次产品写入权限。
- 需求、验收标准或允许改动的文件需要变化：保留失败记录，将 `phase` 切回 `specify`、`current_task` 设为“无”，在 `checkpoint` 写明变更原因与受影响编号；按 [规格入口](./02-specify.md) 重新确认需求，再更新计划、任务与用例。规格文件一旦改变，原需求摘要自动失效；需求重新审批时旧计划审批会重置为待审批，必须再次经过“需求审批通过”和“计划审批通过”两道用户门禁。旧的 AC/TC 结果不能直接沿用，在新规格确认后将当前结果重置为“未测”，历史结果保留在返工历史。若资源冲突，重走 `plan / blocked` 的隔离门禁。
- 修复后重新进入 `verify` 时，按新任务的风险档位重跑受影响的 AC/TC、自动检查和 SR 项；不受影响的自动检查与浅回归保留原记录并写明复用依据。旧失败记录留作历史，当前结果单独更新。

## 做完

只有当前回合具有收口授权，并且评审清单全部通过、每条验收和测试都为“通过”或具有完整受控豁免、测试验证与交付评审能力证据有效，且 `.worktrees` 中属于本轮的记录都已由 `sync-worktree.rb` 证明真实仓库目标分支包含最终 HEAD、再由 `cleanup-worktree.rb` 变成“已删除”，或具有完整用户确认保留证据后，才把所绑定轮次的 `status.md` 更新为：`phase: done`、`current_task: 无`、`work_state: done`；更新 `updated_at`，`checkpoint` 记录通过项、豁免项、用户确认和残余风险，`next_action` 写 `无`。随后从框架根目录运行 `ruby scripts/refresh-iteration-overview.rb systems/<system>`，确认 `overview.md` 的只读视图已显示本轮 `done / done`。没有收口授权、仍有未过且未豁免的项目、能力证据或同步证据缺失、或 worktree 处于“使用中/待清理”时不要改成 `done`，把事实和恢复入口留在 `checkpoint` 与 `next_action`。
