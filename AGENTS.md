# AI 迭代框架 Agent 规则

本目录只管理系统说明、迭代文档和临时校验脚本。产品源码仍在各系统 `overview.md` 登记的原仓库中。

## 启动定位

1. 在框架根目录工作时，先读 [README.md](./README.md) 和 [iteration-standard.md](./iteration-standard.md)。
2. 在 `systems/` 工作时，继续读 [systems/AGENTS.md](./systems/AGENTS.md)。
3. 在 `systems/<system>/` 工作时，继续读该系统自己的 `AGENTS.md`。
4. Codex 任务的工作目录必须在创建任务时直接选择；在任务终端里执行 `cd` 不视为重新加载下级 `AGENTS.md`。
5. 用户从框架根目录点名已有系统时，使用 `systems/<system>/` 作为兜底入口，显式读取该系统的 `AGENTS.md`，再按该入口规则绑定一个轮次；不要要求用户重复文件中已有的阶段或任务。
6. 一次 Agent 会话只能绑定一个轮次。绑定后先运行 `ruby scripts/iteration-context.rb <轮次目录>` 获取最小恢复摘要，再按其中 `read_next` 读取当前阶段必要文件；当前档位和进度只以所绑定轮次的 `status.md` 为准。
7. 绑定轮次后的每个用户回合，都把当前完整用户原话作为单个经过 shell 安全转义的参数传给 `ruby scripts/iteration-context.rb <轮次目录> --intent SAFE_USER_MESSAGE`，禁止直接拼接未转义原话。优先按输出的 `intent_route` 推进；识别为审批或执行授权后不得要求用户改说固定口令。该路由只解释意图，不能越过未决问题、能力证据、摘要和外部写入门禁。

## 写入授权

- 默认只读。用户在当前请求中说“开始执行”“开始处理”，或以明确自然语言下达阶段审批、执行当前任务、完成所有任务、开始验收、确认收口等可执行指令时，才允许在该指令范围内修改文件；疑问、条件、否定和普通讨论不构成授权。
- 授权只覆盖用户当前明确要求的范围，不自动延续到下一轮迭代、提交、推送、部署或外部系统写入。
- 写入前先说明准备修改的范围；遇到需求、范围或风险歧义时先询问。

## 双审批门禁

- 写入授权不等于阶段审批。规格完成后保持 `specify / blocked`，用户以“需求审批通过”或含义明确的等价自然语言批准需求，才可用 `scripts/record-stage-approval.rb` 把原话写入本轮 `stage-approvals.md` 并进入 `plan`。
- 计划完成后保持 `plan / blocked`，用户以“计划审批通过”或等价自然语言批准计划，才可记录计划审批并进入 `implement / ready`。用户可以一次说“自动审批需求和计划”；需求审批立即记录，计划仍需等计划访谈和评审完成后复用同一原话并绑定计划摘要。普通“继续”“开始处理”“可以”都不能代替任一审批。
- 审批记录绑定当时文档摘要；需求文档变化会使需求和计划都需重批，计划文档变化会使计划需重批。`计划审批通过` 只允许推进阶段，不自动授权执行代码；“完成所有任务”只授权连续完成本轮实现任务与统一代码审核，随后停在 `verify / blocked` 等待验收授权。验收完成后再次停在 `verify / blocked` 等待收口授权；只有“验收并收口”“完成所有任务并验收收口”等明确联合表达才允许连续跨越对应边界。上述指令均不授权提交、推送、合并、拉取、部署、数据库迁移、服务启动或外部写入。

## Skills 与 MCP 能力门禁

- 先读根目录 `capabilities.yml`，再用 `scripts/iteration-context.rb` 汇总所绑定轮次的档位、审批、任务和能力索引；仅按 `read_next` 继续读需要的正文和证据。使用 `iteration-governor` 选择当前阶段能力；总控 Skill 不能替用户审批，也不能扩大写入授权。
- `workflow_profile` 使用 `lite`、`standard`、`strict`。`lite` 只用于全部复杂度字段明确为 `no` 的低风险工作；`standard` 用于无高风险条件的普通产品代码，非简单需求使用一次 `grill-me`，计划阶段由计划评审替代第二次访谈；接口/Schema、数据库、安全权限、并发、性能、多仓库、外部服务、部署、破坏性操作或不确定项必须 `strict`，需求和计划审批前都使用 `grill-me`。不可用时降级到 `iteration-design-interview`。
- 必需能力无法产生可信证据时将 `work_state` 设为 `blocked`。MCP 默认只读；评论、提交、推送、部署、数据库或其他外部变更仍需当前请求明确授权。
- 每条代码任务写入前必须在 `capability-log.md` 留下 implementation guard 索引；首次进入验收前对整轮差异执行一次 `task=无` 的统一 code review，验收返工后只追加覆盖新任务守卫的 `task=T-xx` 增量审核。两类审核都记录到 `evidence/reviews/implementation-review.md`；P0/P1 必须修复，P2 必须修复或明确处置。
- 访谈等待 `Qxx` 时，用户可见消息和 `status.md.next_action` 都必须写出问题全文、推荐答案与可复制回复，不能只显示编号。未确认的问题保持 `待确认 / pending / 无`；只有用户直接回答后才能标 `resolved` 并记录确认原话。

## 过程汇报

- 每次汇报命令结果、服务启停、故障处理或阶段进展时，都要明确写出 `已完成：` 和 `下一步：`，不能只报当前状态就结束。
- 不需要用户介入时写 `无需你操作：`，说明 Agent 会继续执行什么，不把普通进展变成等待用户回复。
- 需要用户输入、额外授权或外部操作时写 `需要你：`，给出一条可以直接执行的动作；真正受阻时同步把 `work_state` 改为 `blocked`。
- 正在处理已登记系统轮次时，回合结束的 `下一步：` 必须与该轮 `status.md` 的 `next_action` 一致；`done` 阶段明确写本轮无后续动作。框架自身维护不借用业务轮次状态。

## 通用边界

- 尽量不硬编码系统名、轮次名、仓库路径或历史文件名；系统和仓库信息归 `overview.md`，轮次动态状态归各轮自己的 `status.md`。
- `status.md` 是唯一动态进度源，必须维护 `workflow_profile`、`phase`、`current_task`、`work_state`、`updated_at`、`checkpoint` 和 `next_action`；登记表和需求文档不得复制当前状态。只在阶段切换、任务切换、阻塞、恢复或回合交接时更新状态，普通读取和连续命令不制造微小进度写入。`stage-approvals.md` 只保存用户审批证据和文档摘要，审批只能通过 `record-stage-approval.rb` 记录。系统 `overview.md` 只允许在固定标记内保存由 `scripts/refresh-iteration-overview.rb` 生成的只读投影，不能手工维护。
- 每次新增轮次或修改任一 `status.md` 后，都要刷新对应系统的迭代状态视图；`create-iteration.rb` 会在创建锁内自动刷新，其他状态变化运行 `ruby scripts/refresh-iteration-overview.rb systems/<system>`。视图过期时校验必须失败，收口不能遗漏 `done` 状态。
- 进入 `implement / ready` 前，先在当前轮 `workspace.md` 预留产品检出路径、隔离方式和运行资源；默认使用 `overview.md` 登记的共享检出。修改产品文件前再逐文件记录分支、HEAD 和接管前 dirty 状态；不得只写数量。原仓库存在未提交修改时只登记基线并保护既有改动，不因此创建 worktree。
- 同一系统可以有多个活动轮次。只有另一轮已经处于 `implement` 或 `verify` 且登记使用同一产品仓库时，当前轮才允许创建 worktree；两个产品活动轮次不得复用同一检出路径，也不得争用同一个独占运行资源。无法隔离时留在 `plan / blocked`。
- 符合上述同仓库并行条件时，只能用 `scripts/create-worktree.rb` 在框架根目录 `.worktrees/` 创建受控副本，并由该轮 `workspace.md` 记录完整生命周期。成果提交、合入并推送目标分支后，取得拉取授权，使用 `scripts/sync-worktree.rb` 在真实仓库对显式目标分支执行 `git pull --ff-only` 并验证包含最终 HEAD；验证成功后才能用 `scripts/cleanup-worktree.rb` 删除干净副本、恢复产品路径并保留同步证据。脏 worktree 禁止强删，用户明确确认保留时才可作为终态例外。
- 新建迭代必须使用 `scripts/create-iteration.rb`（按当前工作目录调整相对路径），禁止人工创建轮次目录或复制模板；脚本不可用时停止写入并报告阻塞，不能绕过 `.iteration-create.lock`。
- 修改或新增代码时保持高注释密度，重点说明原因；每十行代码不少于七行注释。
- 单条代码任务实现完成即可勾选并切到下一条，不重复执行完整检查或 code review。首次全部任务勾选后保持 `implement`、将 `current_task` 设为 `无`，集中执行任务检查命令和整轮 code review；返工任务完成后只执行其风险策略必跑项和增量审核。审核通过后进入 `verify / blocked` 并告知用户，未取得明确验收授权时不得开始验收。
- `verify` 按 `test-strategy.md` 的 `T0` 到 `T4` 风险档位执行必须项、正式验收用例和受控浅功能回归；输入未变化的证据可以注明依据后复用。浅回归覆盖直接功能和一层高概率相邻功能，并明确停止边界，不扩展成全系统回归。
- 验收授权只覆盖测试验证与验收记录。全部验收通过后保持 `verify / blocked`，汇报结果并等待明确收口授权；未授权收口时不得运行交付收口评审、清理工作区或把状态改成 `done`。用户当前原话同时明确授权验收和收口时，才可连续执行。
- 不替用户启动前后端服务。提交、推送、合并、拉取、部署、数据库迁移和知识库写入需要各自明确授权。
- 框架自身改动完成后运行 `ruby scripts/validate-framework.rb`、`ruby scripts/test-validate-framework.rb`、`ruby scripts/test-create-iteration.rb` 和 `ruby scripts/test-worktree-lifecycle.rb`，并维护根目录同一份 `CODE_REVIEW.md`。
- 上述四套框架回归只在修改框架本身时运行；普通产品迭代只运行任务和测试策略登记的产品检查，不得把框架回归附加到每个业务任务。
