# 使用指南

这套框架用于管理一套系统的多轮 AI 迭代。框架保存系统说明、迭代规格、任务、测试和状态，产品源码长期仍留在原仓库中。默认直接使用真实仓库，未提交修改只登记基线；只有另一 `implement` 或 `verify` 轮次使用同一仓库时，才可在根目录 `.worktrees/` 创建受控临时 Git worktree。收口时先把成果同步到真实仓库的显式目标分支并验证，再删除副本并保留分支与 HEAD 证据。

你只需要记住两个启动位置：

| 从哪里启动 Agent | 用来做什么 | Agent 如何定位 |
|---|---|---|
| `systems/` | 登记一套还不存在的系统 | 读取 `systems/AGENTS.md`，进入系统登记流程 |
| `systems/<system>/` | 查看系统、选择活动轮次，或新开迭代 | 读取系统 `AGENTS.md` 并按活动轮次数量绑定 |
| `systems/<system>/iterations/<iteration>/` | 直接继续指定轮次 | 绑定当前目录这轮并读取其 `status.md` |

这里的“启动”是指新建 Agent 任务时，直接把对应目录选择为任务工作目录。不要先用框架根目录创建任务，再只在任务终端执行 `cd systems/<system>`；终端目录变化不会使已经创建的任务重新加载下级 `AGENTS.md`。

## 一、使用前确认

在终端进入框架根目录并运行一次校验：

```bash
frameworkRoot="/你的实际路径/ai-iteration-framework"
cd "$frameworkRoot"
ruby scripts/validate-framework.rb
```

看到下面的结果，说明框架结构可以继续使用：

```text
OK: framework validation passed
```

把示例中的 `/你的实际路径/ai-iteration-framework` 换成框架在本机的真实路径。文档不固定某台机器的安装位置。

## 二、登记一套新系统

### 1. 在 `systems/` 启动 Agent

新建 Agent 任务时，把任务工作目录直接设为：

```text
<框架根目录>/systems
```

支持目录规则自动发现的 Agent 会先读取 `systems/AGENTS.md`，然后按 `prompts/00-register-system.md` 工作。已经在其他目录创建的任务，即使终端后来 `cd` 到这里，也不等于从本目录重新启动。

### 2. 告诉 Agent 系统信息

建议一次提供这些内容：

- 系统英文名：使用小写英文和短横线，例如 `order-center`。
- 系统职责：用一句话说明这套系统解决什么问题。
- 产品仓库：每个仓库的绝对路径和职责。
- 系统边界：不能破坏的业务、数据、权限、迁移和部署规则。
- 知识库：已有文档目录的绝对路径；没有就明确写“无”。
- 检查命令：各仓库真实可用的测试、lint 或构建命令；不确定就写“待确认”。

第一次可以先让 Agent 只读预检：

```text
请预检一套新系统：
- 系统名：order-center
- 职责：负责订单创建、查询和状态流转
- 仓库：/绝对路径/order-backend，后端服务
- 知识库：/绝对路径/order-docs
- 边界：数据库迁移只允许在 order-backend 执行
先检查信息和路径是否完整，不要修改文件。
```

确认预检结果后，再单独发出写入请求：

```text
开始处理，按刚才确认的信息登记这套系统，不要创建第一轮迭代。
```

登记完成后通常会得到：

```text
systems/order-center/
  AGENTS.md
  overview.md
  agent/README.md
  iterations/
  knowledge-base -> /绝对路径/order-docs   # 有知识库时才创建
```

产品源码不会复制进系统或迭代目录，也不会创建指向产品仓库的目录快捷方式。仓库路径只登记在 `overview.md`；原仓库 dirty 时仍使用该路径。只有同仓库产品阶段并行需要的临时检出，才由受控脚本放进根目录 `.worktrees/`。

## 三、进入已有系统

新建 Agent 任务，并把任务工作目录直接设为具体系统目录：

```text
<框架根目录>/systems/<system>
```

下面的命令只用于帮助你确认目标路径；真正创建任务时仍要在 Codex 的工作目录选择器中选中这个目录：

```bash
cd "$frameworkRoot/systems/bff-sso"
```

Agent 应按下面的顺序恢复上下文：

1. 读取 `AGENTS.md`，取得本系统的启动规则。
2. 读取 `overview.md`，确认系统边界和产品仓库绝对路径。
3. 按工作目录、用户点名和 `iterations/*/status.md` 绑定一个轮次。
4. 只有一个活动轮次时自动绑定；存在多个且你没有点名时，先列出轮次、阶段和下一步，由你选择。
5. 没有当前用户消息时运行 `ruby scripts/iteration-context.rb <轮次目录>`；每个用户回合把完整原话作为单个经过 shell 安全转义的参数传给 `ruby scripts/iteration-context.rb <轮次目录> --intent SAFE_USER_MESSAGE`，取得 `intent_route`、`workflow_profile`、六个进度字段、审批状态、当前任务、能力索引和 `read_next`；禁止拼接未转义原话，先按路由行动，再按清单读取必要正文，不能要求用户改说固定口令。
6. `current_task` 不是“无”时，读取任务清单中的对应任务；恢复产品修改时先核对 `workspace.md`，不重做断点前已经完成的步骤。
7. 根据 `phase` 打开 `prompts/` 中对应的阶段入口。

系统 `overview.md` 还会显示所有轮次的 `phase`、`work_state`、`approval_gate`、更新时间和下一步，适合先看全局进度。该表由各轮 `status.md` 和 `stage-approvals.md` 自动生成，只是只读投影；需要恢复某一轮时，动态进度仍以该轮 `status.md` 为准，审批证据以 `stage-approvals.md` 为准。

开工前，Agent 应先汇报类似下面的状态：

```text
系统：bff-sso
绑定轮次：001-2026-10-22-接入服务直连
绑定依据：系统目录下唯一活动轮次 / 用户点名 / 轮次目录启动
phase：implement
current_task：T-01
work_state：ready
updated_at：2026-10-22T14:00:00+08:00
checkpoint：规格和任务已经写完，产品代码尚未修改
next_action：执行 T-01，为账号后端增加接入类型和直连地址
定位方式：系统目录启动 / 兜底定位
本次写入授权：有 / 无
```

如果系统只有一个活动轮次，你只想查看进度时不用手工告诉 Agent 轮次或阶段，也不要给写入授权：

```text
读取当前系统和迭代状态，告诉我现在做到哪里、下一步是什么，不要修改文件。
```

## 四、新开一轮迭代

在具体系统目录启动 Agent 后，可以先让它确认当前状态：

```text
列出当前系统的活动轮次和潜在工作区冲突，只读分析，不要修改文件。
```

确认新需求主题后即可发送：

```text
开始处理，为当前系统新开一轮迭代，主题是“订单取消流程”。
```

Agent 会按 `prompts/01-open-iteration.md` 创建，并且必须执行 `ruby scripts/create-iteration.rb systems/<system> 中文主题`：

```text
iterations/00N-YYYY-MM-DD-中文主题/
```

其中：

- `00N` 接续本系统已有序号，从 `001` 开始。
- 日期使用新建当天的日期。
- 主题保持中文。
- 新轮次使用标准英文文件名。
- `status.md` 初始为 `workflow_profile: standard`、`phase: specify`、`current_task: 无`；规格完成前按复杂度调整到最低安全档位。
- `stage-approvals.md` 初始为需求、计划双 `pending`，不能手工改成已审批。
- `work_state` 初始为 `ready`，`updated_at` 写创建时的带时区 ISO 8601 时间，并写明“规格尚未编写”的断点与下一步。
- 不创建或更新全局“当前轮次”指针；新轮次和其他活动轮次可以并存。
- 创建脚本会自动取得该系统的 `.iteration-create.lock`，防止并发 Agent 使用相同序号；禁止人工创建轮次目录或复制模板，脚本失败时应停止并报告。

一套系统可以同时有多个未完成的活动轮次。新轮次默认从 `specify` 开始；已有轮次保持自己的阶段和断点，不会因为新建而被切换。

多个轮次并存时，建议在请求里写完整轮次名：

```text
开始处理，继续轮次 002-2026-10-22-订单取消流程，完善规格。
```

也可以直接把 Agent 工作目录选择为该轮 `iterations/<iteration>/`。未点名且系统里有多个活动轮次时，Agent 只能列出候选并请你选择，不能按最新序号猜测。

## 五、按阶段推进

Agent 不靠聊天记录猜进度，只认所绑定轮次 `status.md` 中的结构化状态。上下文脚本只读汇总档位、阶段、任务、审批、能力索引、已验证断点和恢复后的第一步；它不会生成第二份状态，也不会默认读取全部证据正文。

## Skills 与 MCP 怎么用

根目录 `capabilities.yml` 是稳定能力登记表：Skills 负责需求访谈、计划评审、实现守卫、代码审核、测试验证和交付复核；MCP 只提供实时事实或已经单独授权的动作，默认只读。`iteration-governor` 负责选择能力和核对证据，但不能替用户批准需求或计划，也不能扩大写入范围。

工作流按复杂度分为三级：`lite` 用于所有复杂度字段为 no 的低风险工作；`standard` 用于普通产品代码；`strict` 用于接口、数据库、安全权限、并发、性能、多仓库、外部服务、部署、破坏性操作或不确定项。双审批、首次统一审核、返工增量审核和按风险真实验收不随档位降低。

需求评审和计划评审分节写入 `evidence/analysis/stage-review.md`；每条任务只把实现守卫写入 `evidence/reviews/<task-id>.md`，首次统一审核与验收返工后的任务级增量审核都追加到 `evidence/reviews/implementation-review.md`；测试验证和交付复核写入 `evidence/delivery/final-review.md`。`capability-log.md` 仍保留每项能力的独立摘要、时间和发现计数。

用户直接回答结构化访谈问题时，只授权 Agent 更新当前轮的访谈、状态和对应需求或计划文档；产品源码、提交、推送、部署、数据库和 MCP 外部写入仍分别需要明确授权。必需能力及其降级方式都不可用时，本轮进入 `blocked`，`next_action` 写出缺少的证据或用户决定。

等待访谈回答时，Agent 必须同屏展示每个 `Qxx` 的问题全文、推荐答案、主要影响和可直接复制的回复，不能只给“Q23 按推荐做”一类孤立口令。`design-interview.md` 在用户回答前保持 `待确认 / pending / 无`；收到直接回答后才写 `resolved`，确认依据保存用户原话。`iteration-context.rb` 会展开新协议下的 pending 问题，恢复会话时必须原样展示。

| `phase` | 目标 | 主要产物 | 对话示例 |
|---|---|---|---|
| `specify` | 写清需求、决策、范围、验收和测试设计；完成后等待需求审批 | `requirements.md`、`decisions.md`、`change-scope.md` 等 | `开始处理，完善当前轮规格；有歧义先列出来。` |
| `plan` | 拆实现计划、任务和风险；完成后等待计划审批 | `implementation-plan.md`、`tasks.md`、`risks.md` | `开始处理，按当前规格拆分可执行任务。` |
| `implement` | 依次实现任务；全部任务后统一检查与审核 | 产品仓库代码、任务守卫和 `implementation-review.md` | `开始处理，执行当前任务；全部任务完成后统一审核。` |
| `verify` | 按用例验收、执行受控浅功能回归并做最终评审 | `test-log.md`、`acceptance.md`、`review-checklist.md` | `开始处理，验收当前迭代并完成受控浅功能回归。` |
| `done` | 本轮已经完成 | 保留完整迭代档案 | 只读查看结果，或准备下一轮 |

阶段之间的约束是：

```text
specify -> 需求审批 -> plan -> 计划审批 -> implement -> verify -> done
                                      ^            |
                                      |-- 代码缺陷 --|
specify <- 需求或范围变化 ------------------------- verify
```

- `specify` 和 `plan` 阶段不能修改产品源码。
- 规格写完后保持 `specify / blocked`，你可以说 `需求审批通过` 或含义明确的等价自然语言，Agent 才会记录需求审批并进入 `plan`。
- 计划写完后保持 `plan / blocked`，你可以说 `计划审批通过` 或等价自然语言，Agent 才会记录计划审批并进入 `implement / ready`。也可以提前说 `自动审批需求和计划` 或 `自动完成需求和计划审批流程`：需求先记录，计划等计划评审完成后复用同一原话并绑定摘要；Agent 不得要求改说另一句口令。
- `完成所有任务` 表示连续完成本轮实现任务和统一代码审核，不需要每个 `T-xx` 再确认；随后停在 `verify / blocked` 并报告结果。它不包含验收、收口、提交、推送、合并、拉取、部署、数据库迁移、启动服务或外部写入。
- `开始验收` 或等价表达只执行按风险验收和测试验证；通过后仍保持 `verify / blocked`，报告结果并等待收口。`确认收口` 才执行交付复核并在所有门禁通过后进入 `done`。你也可以明确说“验收并收口”或“完成所有任务并验收收口”，让对应阶段连续执行，而不需要固定照抄示例文案。
- 普通“继续”“开始处理”“可以”只是写入授权，不是阶段审批。需求文档变化后需求和计划都需重批；计划文档变化后计划需重批。任务勾选和验收结果不会使摘要失效。
- `implement` 有 `T-xx` 时一次只实现当前任务，并且只能修改任务与 `change-scope.md` 共同允许的文件；任务完成即可勾选。全部任务勾选后改为 `current_task: 无`，统一运行去重后的检查命令并审核整轮差异，通过后进入 `verify / blocked` 等待验收授权。
- 活动阶段的 `work_state` 使用 `ready`、`in_progress` 或 `blocked`；完成阶段使用 `done`。
- `updated_at` 使用带时区的 ISO 8601 时间，用于判断 `in_progress` 是当前工作还是历史中断。
- `checkpoint` 只记录已经核实的事实，`next_action` 写重新进入任务后要做的第一件具体事情。
- 进入 `implement / ready` 前先在 `workspace.md` 登记拟使用的产品检出路径、隔离方式和运行资源。没有同仓库产品活动轮次时默认使用共享检出；原仓库 dirty 只需逐文件登记并保护接管前改动，不能因此创建 worktree。
- 多轮可以同时处于 `specify` 或 `plan`；只有另一轮已经处于 `implement` 或 `verify` 且登记使用同一仓库时，当前轮才创建独立 Git worktree。两个产品活动轮次不能复用同一检出路径；无法隔离时保持 `plan / blocked`。`workspace.md` 的隔离方式统一写“独立 worktree”或“共享检出”。
- 端口、数据库、Nacos 服务、测试账号等不能安全共享的环境要登记为独占运行资源；无法隔离时串行验收。
- 单个任务不重复做完整检查和 code review；首次统一审核覆盖当时全部差异，返工只追加覆盖新任务守卫的增量审核，不重审未变化仓库。
- `verify` 按每条任务的 `T0` 到 `T4` 风险档位执行正式 AC/TC 和受控浅功能回归。代码、依赖、配置和生成物输入未变化时可复用证据；返工只重跑受影响项，并保留纳入理由与停止边界。
- 需求发生变化时，先回到文档修正规格和范围，再继续实现。
- 关键接口、数据、权限、兼容行为或验收口径在 `decisions.md` 留待确认项，得到明确答复后再进入实现；当前请求的写入授权不会因阶段回退自动延续。
- 自动检查需留下命令、目标仓库、时间、退出码、所测版本；有 PR/CI 时核对必需检查。新增行为需能从实际差异追到需求、AC 和 TC，静态校验不能替代这一步。
- `done` 不等于已发布。发布交接和上线观察仅在另行授权发布时记录与执行。
- 每次修改 `status.md` 后运行 `ruby scripts/refresh-iteration-overview.rb systems/<system>`；新建轮次时创建脚本会自动刷新。若忘记刷新，框架校验会以“迭代状态视图已过期”阻断收口。

### 多轮并行时怎样使用 `.worktrees`

只有当另一个 `implement` 或 `verify` 轮次已经在自己的 `workspace.md` 登记使用同一产品仓库时，才进入本流程。原仓库有未提交修改但没有同仓库并行产品轮次时，继续使用真实仓库，逐文件登记 dirty 基线，不运行创建脚本。符合并行条件时，不要随手复制仓库，也不要自行选择一个长期目录；先在新一轮 `workspace.md` 规划隔离方式，再在取得本次写入授权后，从框架根目录运行：

```bash
ruby scripts/create-worktree.rb \
  systems/<system>/iterations/<iteration> \
  <overview中的仓库名> \
  <本轮功能分支名> \
  [起点ref]
```

脚本会做这些事：

- 扫描同一系统其他轮次，找不到处于 `implement/verify` 且登记同一仓库的轮次时直接拒绝创建。
- 只从该系统 `overview.md` 读取原仓库绝对路径，不接受任意源目录。
- 固定创建到 `.worktrees/<system>/<iteration>/<repo>/`。
- 分支不存在时从指定起点（默认原仓库当前 `HEAD`）创建；分支已存在时复用，不重置。
- 自动把本轮 `workspace.md` 的产品检出路径切到临时 worktree，并记录原路径、分支、创建 HEAD、创建时间和“使用中”状态。
- 不提交、不推送、不启动服务，也不修改原仓库当前检出的分支。

验收完成后，先把 worktree 成果提交，并按单独授权完成成果分支推送、合入目标分支及目标分支推送。确保 worktree 与真实仓库的 `git status --porcelain` 都为空，真实仓库已经检出目标分支；取得本次拉取授权后运行：

```bash
ruby scripts/sync-worktree.rb \
  systems/<system>/iterations/<iteration> \
  <overview中的仓库名> \
  <目标分支>
```

同步脚本不会合并或推送代码，也不会自动切换真实仓库分支。它只在 `overview.md` 登记的真实仓库执行 `git pull --ff-only`，然后验证 worktree 最终 HEAD 是真实仓库当前 HEAD 的祖先。目标分支不固定为 `main` 或 `master`。拉取成功但仍不包含成果提交时，脚本会保留 worktree，并要求先完成成果分支的推送与合并。

`workspace.md` 的“worktree 成果同步”状态变成“已同步验证”后，再运行：

```bash
ruby scripts/cleanup-worktree.rb \
  systems/<system>/iterations/<iteration> \
  <overview中的仓库名>
```

清理脚本只删除生命周期表登记且与固定 `.worktrees` 规则完全一致的目标。删除前会再次确认真实仓库仍在已登记目标分支、工作区干净，并且当前 HEAD 仍包含同步 HEAD 与 worktree 最终 HEAD。然后调用 `git worktree remove` 和 `git worktree prune`，不使用 `--force` 或 `rm -rf`。完成后会删除空的仓库/轮次/系统父目录，把 `workspace.md` 的当前产品路径恢复为 `overview.md` 中的真实仓库，并保留临时路径、成果分支、最终 HEAD、同步 HEAD 和时间。功能分支不会自动删除。

正常情况下，轮次进入 `done` 前，生命周期状态必须是“已删除”。如果确实要继续保留临时目录，必须由你明确确认，并在状态中写成：

```text
用户确认保留：用户确认……；保留原因……
```

“使用中”或“待清理”都不是完成态；v2 轮次缺少“已同步验证”证据也不能收口。同步与清理脚本都不会替你切换真实仓库分支；成果必须已经进入显式目标分支，真实目录才能拉取并通过验证。

### 过程更新应该长什么样

Agent 每次汇报服务启停、健康检查、测试结果或故障处理时，都必须同时说明下一步以及是否需要你操作。例如：

```text
已完成：目标服务已重新启动，健康检查正常。
下一步：确认新进程已经发现依赖服务，再继续当前轮测试用例。
无需你操作：我会继续检查；如果必须由你登录，会改成“需要你：请在登录页完成登录”。
```

只有当前动作确实依赖你的输入、额外授权或外部操作时，Agent 才应暂停并使用 `需要你：`。普通进展使用 `无需你操作：`，随后继续工作，不能只报状态就停住。

## 六、写入授权怎么说

框架默认只读。当前请求明确包含“开始执行”“开始处理”，或用等价自然语言下达阶段审批、执行当前任务、完成所有任务、开始验收、确认收口等可执行指令时，Agent 才能在该指令范围内修改文件。实现、验收、收口分别授权；疑问、条件、否定和普通讨论保持只读。

写入授权与阶段审批是两件事。需求和计划审批不要求逐字回复示例文案，但原话必须以等价自然语言明确包含审批目标和批准动作，并由 `scripts/record-stage-approval.rb` 保存原话、时间和文档摘要；不能用一次普通“开始处理”跨过两道门禁。

授权只对当前请求生效，不会自动延续到下一条消息。例如：

```text
查看 T-01 的实现方案，不要修改文件。
```

这是只读请求。

```text
开始处理，执行当前任务 T-01。
```

这是当前请求的文件写入授权。

下面这些操作不会因为“开始处理”自动获得授权，仍需要你明确点名：

- Git commit、push、merge 或 pull。
- 部署和发布。
- 数据库迁移。
- 写入框架外的知识库。
- 启动前端或后端服务。

## 七、目录里的状态分别归谁管理

| 文件 | 唯一职责 |
|---|---|
| `systems/<system>/overview.md` | 系统职责、仓库绝对路径、系统边界和自动生成的迭代状态视图 |
| `systems/<system>/agent/README.md` | 说明会话级轮次绑定规则，不保存动态指针 |
| `iterations/<iteration>/status.md` | 唯一动态进度源；保存阶段、任务、工作状态、更新时间、已验证断点和下一步 |
| `iterations/<iteration>/stage-approvals.md` | 保存需求与计划的用户审批证据、时间和文档摘要；不保存动态进度 |
| `iterations/<iteration>/design-interview.md` | 保存需求与计划访谈历史、复杂度判定、用户选择和未决问题 |
| `iterations/<iteration>/capability-log.md` | 保存能力提供者、版本、输入摘要、证据索引和未处置发现计数 |
| `iterations/<iteration>/evidence/` | 保存阶段评审、逐任务实现守卫、迭代级统一代码审核、测试验证和交付复核报告 |
| `iterations/<iteration>/tasks.md` | 保存全部任务及完成状态 |
| `iterations/<iteration>/change-scope.md` | 限定本轮允许修改的产品文件 |
| `iterations/<iteration>/workspace.md` | 保存产品检出路径、隔离方式、分支、HEAD、接管前 dirty 文件、当前任务涉及文件、运行资源、临时 worktree 生命周期和真实仓库同步证据 |
| `iterations/<iteration>/scripts/` | 保存本轮临时脚本；不放产品源码 |

不要在多个文件重复维护同一状态。发生冲突时，应停止写入并先修正状态源。

## 八、日常使用建议

推荐按下面的节奏工作：

1. 在系统目录启动 Agent。
2. 只有一个活动轮次时让 Agent 自动绑定；有多个时点名轮次，再让 Agent 汇报工作目录、绑定依据、阶段、工作状态、更新时间、断点和下一步。
3. 只读讨论当前阶段的方案和风险。
4. 确认后，用包含“开始处理”或“开始执行”的新请求授权写入。
5. 每完成一个阶段或任务，查看 `status.md` 和对应产物。
6. 框架结构有变化时，在框架根目录运行校验。

常用校验命令：

```bash
ruby scripts/validate-framework.rb --iteration systems/<system>/iterations/<iteration>
ruby scripts/validate-framework.rb
```

带 `--iteration` 的命令用于日常绑定轮次，只检查通用框架契约和目标轮次，不让其他历史轮次的档案问题阻断当前工作；成功文案会明确写 `scoped iteration validation passed`。它不会证明其他轮次、系统级状态投影或跨轮次隔离全部有效。无参数命令执行全局治理校验，框架修改、最终治理检查和交付前必须运行。下面三条全量回归只在修改框架或校验器时运行；普通产品迭代只运行任务与测试策略登记的产品命令。

```bash
ruby scripts/test-validate-framework.rb
ruby scripts/test-create-iteration.rb
ruby scripts/test-worktree-lifecycle.rb
```

回归测试在临时副本中制造错误，验证校验器、迭代创建器和 worktree 生命周期脚本确实能够阻断危险状态。这些命令不会进入已登记产品仓库执行命令或修改产品文件；worktree 回归使用自己创建的临时 Git 仓库。

## 九、常见问题

### Agent 没有自动识别当前系统

确认 Codex 任务创建时选择的工作目录就是 `systems/<system>/`，并确认该目录存在 `AGENTS.md`。不要把“在任务终端执行 `cd`”当成重新选择任务工作目录，也不要只在框架外层打开产品仓库后期待它自动找到这里的状态。

### Agent 找不到产品源码

检查系统 `overview.md` 中登记的绝对路径。长期产品源码不在系统或迭代目录中，这是设计边界；不要把源码复制进 `iterations/`。若本轮使用受控 worktree，则以 `workspace.md` 记录的根目录 `.worktrees/` 路径为准。

### Agent 读到了轮次，但不知道当前任务

先确认本次会话绑定的是哪一轮，再检查该轮 `status.md` 的 `workflow_profile` 和六个进度字段，以及任务清单里的对应任务。系统存在多个活动轮次且没有点名时，Agent 不会自行选择。

### Agent 知道任务编号，但不知道任务内部做到哪里

检查 `status.md` 的 `work_state`、`updated_at`、`checkpoint` 和 `next_action`，再核对 `workspace.md` 的产品仓库基线。只在阶段切换、任务切换、阻塞、恢复或回合交接时更新状态；普通读取、单条命令和同一连续步骤不重复写状态。不要另建第二份进度文件。

### 想同时做两轮迭代

可以直接新开第二轮，不要求第一轮先进入 `done`。`specify` 和 `plan` 可以并行；如果两轮进入 `implement/verify` 后使用不同仓库，仍各自使用真实仓库。只有它们使用同一仓库时，后进入产品阶段的一轮才使用上面的 `create-worktree.rb`；独占运行资源仍需单独隔离。无法隔离时保持 `plan / blocked`，等待前一轮完成。

### Agent 在框架目录留下了 worktree

先不要手工删目录。检查对应轮次 `workspace.md` 的“临时 worktree 生命周期”：

- 状态为“使用中”且目录有 dirty：先提交、转移或明确放弃这些改动；清理脚本会阻断。
- 状态为“使用中”且目录干净：运行 `cleanup-worktree.rb`。
- 状态为“待清理”：再次运行同一清理命令，它会按已保存的最终 HEAD 恢复中断流程。
- 状态为“已删除”但目录仍在：运行框架校验定位不一致，不要递归强删。
- 没有生命周期记录：说明它不是受控脚本创建的目录，先用 `git worktree list --porcelain` 确认归属，再决定迁移或清理，框架脚本不会猜测删除。

### 校验失败

按终端输出的相对路径逐项修复，然后重新运行：

```bash
ruby scripts/validate-framework.rb --iteration systems/<system>/iterations/<iteration>
ruby scripts/validate-framework.rb
```

先用局部命令定位当前轮，再在要求全局绿色的边界运行无参数命令。不要把局部通过表述为全局通过，也不要在当前轮自己的校验失败时继续推进产品代码。

## 十、进一步阅读

- [框架说明](./README.md)
- [迭代标准](./iteration-standard.md)
- [阶段入口](./prompts/README.md)
- [系统登记说明](./systems/README.md)
- [标准与门禁](./standards/README.md)
- [迭代文档模板](./templates/README.md)
