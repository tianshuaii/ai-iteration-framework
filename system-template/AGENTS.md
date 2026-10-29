# 系统 Agent

从本系统目录启动时，按下面顺序恢复上下文。

## 开工先读

1. 读 [overview.md](./overview.md)，确认系统边界和产品仓库绝对路径。
2. 按 [agent/README.md](./agent/README.md) 绑定一个轮次：工作目录已在某轮目录时绑定该轮；用户点名轮次时绑定点名轮次；否则扫描 `iterations/*/status.md`。
3. 系统目录下只有一个活动轮次时自动绑定；有多个且用户未点名时列出轮次、阶段和下一步，请用户选择，不得写入；没有活动轮次时只处理新开轮次或历史查询。
4. 先读根目录 `capabilities.yml`，再运行 `ruby ../../scripts/iteration-context.rb iterations/<轮次>`；脚本只读汇总 `stage-approvals.md`、`capability-log.md` 和 `evidence/` 索引，从摘要恢复 `workflow_profile`、阶段、任务、断点与审批，再按 `read_next` 读取必要正文。`status.md` 仍是唯一动态来源。
5. 绑定后的每个用户回合都把完整原话作为单个经过 shell 安全转义的参数传给 `ruby ../../scripts/iteration-context.rb iterations/<轮次> --intent SAFE_USER_MESSAGE`，优先按 `intent_route` 推进；禁止拼接未转义原话，命中审批或执行意图后不得要求用户换成固定口令。意图路由不替代双审批、能力证据或外部写入授权。
5. 若该轮存在 `file-map.md`，先按其中的兼容映射定位历史文件；否则使用标准英文文件名。
6. 若 `current_task` 不是“无”，继续读取映射后的任务清单中对应任务；不要重做 `checkpoint` 已确认完成的步骤。
7. 模板复制到 `systems/<system>/` 后，根据 `phase` 打开 `../../prompts/README.md`，一次只处理所绑定轮次的当前阶段和当前任务；用户明确要求新开迭代时改用 `../../prompts/01-open-iteration.md`。

## 状态汇报

开始工作前先说明：系统名、任务工作目录、绑定轮次、绑定依据、`workflow_profile`、`phase`、`current_task`、`work_state`、`updated_at`、`checkpoint`、`next_action` 和本轮是否取得写入授权。直接从系统目录启动时标记“系统目录启动”；从轮次目录启动时标记“轮次目录启动”；从上层目录点名系统并显式读取时标记“兜底定位”。

缺少字段、任务条目与 `current_task` 不一致、或工作目录与用户预期不一致时停止写入，先报告冲突。不得让用户重新描述文件中已经存在的状态。

## 过程汇报

- 每次汇报命令结果、服务启停、故障处理或阶段进展时，都写 `已完成：` 和 `下一步：`，不能只报当前状态。
- 可以继续时写 `无需你操作：`，并说明 Agent 会继续什么；需要用户输入、授权或外部操作时写 `需要你：` 和一条可以直接执行的动作。
- 真正受阻时同步更新 `work_state: blocked`、`updated_at`、`checkpoint` 和 `next_action`。回合结束时，用户可见的下一步必须与 `status.md` 一致。

## 边界

- 可只读搜索调用链、同类实现、测试和配置；写入范围仍只限当前任务点名的产品文件和阶段允许的迭代状态文件。
- 使用 `iteration-governor` 按 `lite / standard / strict` 选择当前阶段能力。standard 非简单需求只做一次需求访谈，计划阶段由计划评审把关；strict 两阶段都访谈。双审批、首次迭代级统一审核、返工增量审核和按风险真实验收在三个档位都不能跳过。
- `specify` 和 `plan` 阶段不修改产品仓库。
- 规格和计划分别保持 blocked，直到用户用“需求审批通过”“计划审批通过”或含义明确的等价自然语言批准，再用 `scripts/record-stage-approval.rb` 分阶段记录到 `stage-approvals.md`。一句“自动审批需求和计划”可保存为共同证据，但计划仍需等自身评审完成后绑定摘要；普通“继续”“开始处理”“可以”不是审批。“完成所有任务”只授权实现任务和统一审核，“开始验收”与“确认收口”分别授权后续两段。只有明确联合表达才连续跨越对应边界，所有这些指令都不授权外部变更。
- 需求审批绑定规格摘要，规格变化后需求和计划都需重批；计划审批绑定计划摘要，计划变化后需重批。计划审批本身不等于执行当前任务的授权，同回合改代码必须同时明确要求执行 `T-xx`。
- 产品源码按 `overview.md` 的绝对路径打开，不复制进本系统目录，也不创建源码仓库快捷方式。
- 临时脚本只放当前轮次的 `scripts/`。
- 单条任务实现完成即可勾选；首次全部任务勾选后保持 `implement` 和 `current_task: 无`，统一执行检查与整轮 review。验收返工只追加新任务的增量审核，两类证据都写入 `implementation-review.md`；verify 按 `T0` 到 `T4` 风险档位重跑受影响项和受控浅功能回归，并复用未失效证据。
- 等待访谈 `Qxx` 时必须向用户同屏写出问题全文、推荐答案、影响和可复制回复；未确认行保持 `待确认 / pending / 无`，收到直接回答后才可 `resolved` 并记录用户原话。
- 开始任何阶段的实际工作时把 `work_state` 改为 `in_progress`。只在阶段切换、任务切换、阻塞、恢复或回合交接时更新 `updated_at`、`checkpoint` 和 `next_action`；连续读取和同一执行步骤不重复写状态。
- `status.md` 是唯一动态状态源；每次修改后，从框架根目录运行 `ruby scripts/refresh-iteration-overview.rb systems/<system>` 刷新 `overview.md` 的只读投影。不得手工修改投影表，进入 `done` 前必须确认总览已显示本轮完成状态。
- 进入 `implement / ready` 前先在当前轮 `workspace.md` 预留产品检出路径、隔离方式和运行资源；默认使用 `overview.md` 的真实仓库。修改产品文件前再逐文件记录分支、HEAD 和接管前 dirty 状态；已有改动不得覆盖，也不得算成当前 Agent 新产生的改动，dirty 本身不触发 worktree。
- 多个活动轮次可以并存；`specify` 和 `plan` 可以直接并行。只有另一 `implement` 或 `verify` 轮次登记使用同一仓库时，当前轮才创建独立 worktree；产品检出路径及独占运行资源无法隔离时留在 `plan / blocked`。
- 符合同仓库产品阶段并行条件时，只能用框架 `scripts/create-worktree.rb` 在根目录 `.worktrees/` 创建受控副本。成果进入目标分支后，先取得拉取授权并用 `scripts/sync-worktree.rb` 在真实仓库执行快进拉取和最终 HEAD 验证；进入 `done` 前再用 `scripts/cleanup-worktree.rb` 清理并由本轮 `workspace.md` 恢复原仓库路径。脏 worktree 禁止强删，用户明确确认保留时才可作为终态例外。
- 没有活动轮次时使用复制后相对路径 `../../prompts/01-open-iteration.md`。有活动轮次也可以新开一轮，但不得因此切换或改写其他会话已经绑定的轮次。
- 新建迭代必须调用根目录 `scripts/create-iteration.rb`（从本目录执行 `ruby ../../scripts/create-iteration.rb . 中文主题`），禁止人工创建轮次目录或复制模板；脚本不可用时停止并报告阻塞。
