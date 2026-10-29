# bff-sso Agent

从本目录启动时，按下面顺序恢复当前工作。

## 开工先读

1. 读 [overview.md](./overview.md)，确认五个仓库和治理表迁移边界。
2. 按 [agent/README.md](./agent/README.md) 绑定一个轮次：工作目录已在某轮目录时绑定该轮；用户点名轮次时绑定点名轮次；否则扫描 `iterations/*/status.md`。
3. 系统目录下只有一个活动轮次时自动绑定；有多个且用户未点名时列出轮次、阶段和下一步，请用户选择，不得写入；没有活动轮次时只处理新开轮次或历史查询。
4. 先读根目录 `capabilities.yml`，再运行 `ruby ../../scripts/iteration-context.rb iterations/<轮次>`；脚本只读汇总 `stage-approvals.md`、`capability-log.md` 和 `evidence/` 索引，从摘要恢复 `workflow_profile`、阶段、任务、断点与审批，再按 `read_next` 读取必要正文；`status.md` 仍是唯一动态来源。
5. 绑定后的每个用户回合都把完整原话作为单个经过 shell 安全转义的参数传给 `ruby ../../scripts/iteration-context.rb iterations/<轮次> --intent SAFE_USER_MESSAGE`，优先按 `intent_route` 推进；禁止拼接未转义原话，命中审批或执行意图后不得要求用户换成固定口令。意图路由不替代双审批、能力证据或外部写入授权。
5. 所绑定轮次存在 `file-map.md` 时，先按该轮自己的映射定位标准文件；没有时使用标准英文文件名，不读取其他轮次的映射。
6. `current_task` 不是“无”时，继续读取映射后的任务清单中的对应任务，不重做 `checkpoint` 已确认完成的步骤。
7. 根据 `phase` 打开 [阶段入口](../../prompts/README.md)，一次只处理所绑定轮次的当前阶段和当前任务。

## 状态汇报

开始工作前先说明：系统 `bff-sso`、任务工作目录、绑定轮次、绑定依据、`workflow_profile`、`phase`、`current_task`、`work_state`、`updated_at`、`checkpoint`、`next_action`，以及当前请求是否包含写入授权。直接从本目录启动时标记“系统目录启动”；从轮次目录启动时标记“轮次目录启动”；从上层目录点名本系统时标记“兜底定位”。

缺少状态字段、任务条目不一致或工作目录与用户预期不一致时停止写入，先报告冲突。不得要求用户重复文件中已有的轮次和阶段。

## 过程汇报

- 每次汇报命令结果、服务启停、故障处理或阶段进展时，都写 `已完成：` 和 `下一步：`，不能只报当前状态。
- 可以继续时写 `无需你操作：`，并说明 Agent 会继续什么；需要用户输入、授权或外部操作时写 `需要你：` 和一条可以直接执行的动作。
- 真正受阻时同步更新 `work_state: blocked`、`updated_at`、`checkpoint` 和 `next_action`。回合结束时，用户可见的下一步必须与 `status.md` 一致。

## 系统边界

- 可只读检查关联调用链、测试和配置；只修改当前任务与改动范围共同允许的文件。
- 使用 `iteration-governor` 按 `lite / standard / strict` 选择能力。standard 非简单需求只做一次需求访谈，计划由计划评审把关；strict 两阶段都访谈。双审批、全部任务后的迭代级统一代码审核、真实验收和受控浅功能回归始终保留。
- 产品源码按 [overview.md](./overview.md) 的绝对路径打开，不复制到本目录。
- `specify` 和 `plan` 阶段不修改产品仓库。
- 规格和计划分别保持 blocked，直到用户用“需求审批通过”“计划审批通过”或含义明确的等价自然语言批准，再用 `scripts/record-stage-approval.rb` 分阶段记录到 `stage-approvals.md`。一句“自动审批需求和计划”可作为共同原话，但计划仍需等自身评审完成后绑定摘要；普通“继续”“开始处理”“可以”不是审批。“完成所有任务”只授权本轮实现任务和统一审核；“开始验收”与“确认收口”分别授权后续两段，联合表达才连续执行；所有这些授权都不包含外部变更。
- 需求或计划受保护文档改变后旧摘要自动失效，必须回到对应阶段重新审批。计划审批只允许阶段推进，不自动授权执行代码；同回合执行任务还需明确要求“并执行当前任务 T-xx”。
- 治理表迁移只允许在 `adx-admin-backend` 执行；BFF 和 SSO 只能同步模型。
- 开始任何阶段的实际工作时把 `work_state` 改为 `in_progress`；只在阶段切换、任务切换、阻塞、恢复或回合交接时更新状态，连续命令不重复写微小断点。
- `status.md` 是唯一动态状态源；每次修改后，从框架根目录运行 `ruby scripts/refresh-iteration-overview.rb systems/bff-sso` 刷新 `overview.md` 的只读投影。不得手工修改投影表，进入 `done` 前必须确认总览已显示本轮完成状态。
- 进入 `implement / ready` 前先在当前轮 `workspace.md` 预留产品检出路径、隔离方式和运行资源；默认使用 `overview.md` 的真实仓库。修改产品文件前再逐文件记录分支、HEAD 和接管前 dirty 状态；已有改动不得覆盖，dirty 本身不触发 worktree。
- 多个活动轮次可以并存；`specify` 和 `plan` 可以直接并行。只有另一 `implement` 或 `verify` 轮次登记使用同一仓库时，当前轮才创建独立 worktree；产品检出路径及独占运行资源无法隔离时留在 `plan / blocked`。
- 符合同仓库产品阶段并行条件时，只能用框架 `scripts/create-worktree.rb` 在根目录 `.worktrees/` 创建受控副本。成果进入目标分支后，先取得拉取授权并用 `scripts/sync-worktree.rb` 在真实仓库执行快进拉取和最终 HEAD 验证；进入 `done` 前再用 `scripts/cleanup-worktree.rb` 清理并由本轮 `workspace.md` 恢复原仓库路径。脏 worktree 禁止强删，用户明确确认保留时才可作为终态例外。
- 新建迭代必须调用根目录 `scripts/create-iteration.rb`（从本目录执行 `ruby ../../scripts/create-iteration.rb . 中文主题`），禁止人工创建轮次目录或复制模板；脚本不可用时停止并报告阻塞。
- 单条代码任务实现完成即可勾选；全部任务勾选后保持 `implement` 和 `current_task: 无`，统一执行检查、整轮 code review、修复和复验，写入 `implementation-review.md`，通过后才进入 `verify`。受控浅功能回归覆盖本轮直接功能和一层高概率相邻功能，不做全系统回归。
- 等待访谈 `Qxx` 时必须同屏展示问题全文、推荐答案、影响和可复制回复；未确认问题保持 `待确认 / pending / 无`，不能提前写 `resolved`、通过评审或阶段审批，用户回答后保存确认原话。
