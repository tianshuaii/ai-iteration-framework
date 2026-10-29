# 迭代标准

每次新开迭代，先读本文件和 [standards](./standards/README.md)，再由创建脚本从 [templates](./templates/README.md) 生成文档。这里的「项目」是一套系统，不是单个代码仓库。一套系统里可以只有一个仓库，也可以有多个。标准和模版不绑死某一套系统。

这套写法对齐现在常见的规格驱动开发（先规格、再计划、再任务、再改代码、最后对照验收），以及测试里要有的策略、用例、记录、跟踪。

## 目录

```text
ai-iteration-framework/
  AGENTS.md
  README.md
  iteration-standard.md
  standards/
  templates/
  prompts/
  scripts/
  .worktrees/                    按需创建的受控临时产品 worktree
  systems/
    AGENTS.md
    <system>/
      AGENTS.md                 从本系统启动时自动读取
      overview.md               含各仓库的绝对路径及状态、审批门禁只读视图
      agent/README.md           说明会话级轮次绑定规则，不保存共享当前指针
      knowledge-base            绝对路径软链接，指向这套系统的文档目录
      iterations/
        001-YYYY-MM-DD-中文主题/
          scripts/              这一轮临时用的脚本，必有
          knowledge-base/       可选。这一轮没有额外资料就不建
```

系统文件夹放说明、知识库链接和迭代。仓库地址写在 `overview.md`，只写绝对路径；其中迭代状态表是由全部 `status.md` 生成的只读投影，不是第二份状态源。不要把源码复制进系统或迭代目录，也不要做指向仓库的文件夹快捷方式。默认使用真实仓库，dirty 只登记基线；只有另一 `implement` 或 `verify` 轮次登记使用同一仓库时，才允许由框架脚本在根目录 `.worktrees/` 创建临时 Git worktree。它必须有生命周期记录并在收口时清理或记录用户确认保留。知识库软链接必须是绝对路径，正文留在它原来的文档目录里。同一系统允许多个活动轮次，但每个 Agent 会话只绑定其中一个。

迭代文件夹放在这套系统的 `iterations/` 下，一轮只有一份正文。文件夹名用三位序号加日期加中文主题，例如 `001-2026-10-22-接入服务直连`。序号从 `001` 起，同一套系统里不要重复。主题保持中文。需要额外资料时，在该轮下再建 `knowledge-base`；不需要就可以没有。

## 每一次迭代文件夹里必须有的文件

| 顺序 | 文件 | 作用 |
|---|---|---|
| 0 | `status.md` | 工作流档位、当前阶段、任务、工作状态、更新时间、已验证断点和下一步；这是唯一动态进度源 |
| 0A | `stage-approvals.md` | 需求审批、计划审批、用户原话、时间和对应文档摘要；不是进度源 |
| 0B | `design-interview.md` | 需求与计划设计树访谈、复杂度判定、用户选择和未决问题 |
| 0C | `capability-log.md` | Skills/MCP 能力执行索引、提供者、版本、摘要、证据和发现计数 |
| 0D | `evidence/` | 阶段评审、实现守卫、代码审核、测试与交付的详细证据 |
| 1 | `requirements.md` | 要做什么、默认行为、明确不做的事 |
| 2 | `decisions.md` | 已经拍板的选择，避免做的时候又改口 |
| 3 | `change-scope.md` | 要改哪些项目、哪些文件可以改、哪些仓库不许动 |
| 4 | `implementation-plan.md` | 技术上怎么改，先改哪一层 |
| 5 | `tasks.md` | 可执行的小任务，每条写到文件和一条检查命令 |
| 6 | `acceptance.md` | 怎样算做完，每条能打勾 |
| 7 | `test-strategy.md` | 自动测试和手工测试各覆盖什么 |
| 8 | `test-cases.md` | 手工步骤和期望 |
| 9 | `test-log.md` | 真的跑过之后填结果，开始时全部未测 |
| 10 | `traceability.md` | 需求、验收、用例、文件互相能对上 |
| 11 | `risks.md` | 可能弄坏什么，怎样退回 |
| 12 | `review-checklist.md` | 收口前对照改动范围做一次检查 |
| 13 | `workspace.md` | 产品检出路径、隔离方式、分支、HEAD、接管前 dirty 文件、当前任务涉及文件、运行资源和临时 worktree 生命周期 |
|  | `scripts/` | 这一轮临时用的脚本和代码。产品源码仍在原来的仓库 |

新开的轮次使用上面的英文文件名，并且带上 `scripts/`。历史轮次保留旧文件名时，在本轮增加 `file-map.md`，只在本轮维护标准名到实际文件名的映射。阶段锁和阶段入口见 [prompts](./prompts/README.md)。

少一份就不算这次迭代的文档齐了，但新建时只要求完整模板与有效 `status.md`，正文按阶段逐步填写，不要在早期制造虚假的计划和测试结果。新建必须运行 `ruby scripts/create-iteration.rb systems/<system> 中文主题`，禁止人工创建轮次目录或复制模板；脚本不可用时停止并报告阻塞。代码还没写时，测试记录保持「未测」，不要提前写成通过。

## 工作顺序

按 [prompts](./prompts/README.md) 里的入口做。绑定轮次后先运行 `scripts/iteration-context.rb`，再按 `read_next` 读取当前动作的最小正文集合；它会结合阶段、当前任务、待确认问题和明确验收/收口意图收窄建议。阶段或任务切换后重新运行入口，再获取下一组材料，不为联合授权提前加载未来阶段。`done` 阶段固定返回 `read_next: 无`，交付证据只在用户明确要求审计或复核时按需读取。任务或评审正文明确引用了建议外材料时仍按需读取，`read_next` 不是禁止访问清单。`status.md` 的 `phase` 没到那一步，就不要做后面的事；恢复时同时读取 `workflow_profile`、`current_task`、`work_state`、`updated_at`、`checkpoint` 和 `next_action`。

1. 在 `systems/` 下确认这套系统已经登记；没有时使用 [00-register-system](./prompts/00-register-system.md)。仓库绝对路径写在 `overview.md`，迭代目录里不放源码。`knowledge-base` 是绝对路径软链接，不在这里复制正文。
2. 新建一轮必须运行 `ruby scripts/create-iteration.rb systems/<system> 中文主题`，由脚本在系统锁内取得下一个编号、原子发布，并刷新 `overview.md` 的迭代状态视图；不要求其他活动轮次先进入 `done`。`status.md` 初始为 `specify`、无当前任务、工作状态 `ready`，写入真实时间、规格尚未开始的断点和下一步。脚本不可用或执行失败时停止，禁止人工创建轮次目录或复制模板。这一轮若要对照额外资料，再从 `templates/optional-knowledge-base` 抄一份并改名为 `knowledge-base`；没有就不建。
3. 填需求、决策、改动范围，并按 `capabilities.yml` 选择最低安全档位：全部复杂度明确为 `no` 使用 `lite`；无高风险项的普通产品代码使用 `standard`；接口/Schema、数据库、安全权限、并发、性能、多仓库、外部服务、部署、破坏性操作或不确定项使用 `strict`。访谈等待用户时必须同屏展示问题全文和推荐方案，未确认问题保持 pending 并保存空确认依据；收到直接回答后才可 resolved 并记录用户原话。范围没写清不要改代码。
4. 填验收标准、测试策略、测试用例、跟踪表；测试策略按任务选择 `T0` 到 `T4`，分别写清风险深度、影响宽度、必跑项、可复用证据和升级条件，不能按改动行数机械降级。lite 可用确定性清单跳过访谈，standard 和 strict 的非简单需求先完成需求访谈；需求评审写入 `evidence/analysis/stage-review.md`。规格全部完成后保持 `specify / blocked`，等待用户用“需求审批通过”或等价自然语言明确批准；用 `scripts/record-stage-approval.rb` 记录审批和文档摘要后才能进入 `plan`。
5. 填实现计划和任务清单。每条任务带依赖、允许改的文件和一条检查命令。standard 的计划阶段不重复 grill-me，由计划评审把关；strict 继续完成计划访谈；计划评审追加到 `evidence/analysis/stage-review.md`。任务不得超出改动范围。进入 `implement` 前，先在 `workspace.md` 的计划审批区登记将使用的产品检出路径、隔离方式、目标分支和运行资源；默认使用真实仓库，原仓库 dirty 不触发 worktree。只有另一 `implement` 或 `verify` 轮次登记使用同一仓库时，才用 `scripts/create-worktree.rb` 创建到根目录 `.worktrees/` 并登记生命周期；检出或资源冲突且无法隔离时留在 `plan / blocked`。完成计划访谈和评审能力证据后保持 `plan / blocked`，等待用户用“计划审批通过”或等价自然语言批准；联合审批原话可在此时复用，但必须绑定当前计划摘要。记录审批后才把 `phase` 改为 `implement`、`current_task` 改为第一条未完成任务、`work_state` 改为 `ready`。计划审批不自动执行产品任务；“完成所有任务”只允许连续执行本轮实现任务和统一审核，不包含验收、收口或外部变更。
6. 收到本次写入授权后，先复核 `workspace.md` 里已经预留的产品检出路径、隔离方式和运行资源，再逐文件记录当前任务涉及仓库的分支、HEAD 和已有 dirty 状态，不能只写数量。每条任务写入前的实现守卫写入 `evidence/reviews/<task-id>.md` 并在能力日志独立索引；其摘要只绑定当前任务正文、`change-scope.md` 和 `workspace.md` 的计划检出/资源区，不绑定其他任务。没有同仓库并行产品轮次时继续使用共享检出并保护接管前改动，有同仓库并行 `implement` 或 `verify` 轮次时先用受控 worktree 隔离。一次只实现 `current_task` 并只改任务与 `change-scope.md` 共同点名的产品文件；任务实现完成即可勾选和切换，不在每条任务后重复完整检查或代码审核。轮次任务正文若遗留逐任务完整 review 要求，以本框架的迭代级统一审核规则为准，不重复执行。
7. 全部任务勾完后保持 `implement`，把 `current_task` 改为 `无`。首次进入验收前汇总检查并对整轮差异执行一次 `task=无` code review。验收返工已有有效基线时，只对新增修复任务及一层影响追加 `task=T-xx` 增量审核；不重复审核未变化仓库。P0/P1 必须修复，P2 必须修复或明确处置，证据统一追加到 `evidence/reviews/implementation-review.md`。审核通过后切到 `verify / blocked`，汇报实现与审核结果，并等待用户明确授权验收；`完成所有任务` 到此停止。
8. 取得“开始验收”或等价授权后，按任务风险档位执行必须项、正式 AC/TC 和受控浅功能回归；至少覆盖直接功能和一层高概率相邻功能，并写清停止边界。代码、依赖、配置和生成物输入未变化的既有证据可以复用并注明依据；返工只让受影响证据失效。把实际执行或复用的基线和结果写入测试记录，不能扩展成无依据的全系统回归。验收通过后保持 `verify / blocked`，汇报结果并等待明确收口授权；单独验收授权不运行最终交付收口。
9. 取得“确认收口”或等价授权后，用评审清单和交付复核检查最终结果。有未过且未取得受控豁免的项目，不要把 `phase` 改成 `done`。豁免必须记录用户确认和残余风险，并在验收与测试记录中对应。独立 worktree 的成果提交、合入并推送显式目标分支后，另行取得拉取授权，用 `scripts/sync-worktree.rb` 在真实仓库执行 `git pull --ff-only` 并验证包含最终 HEAD；验证成功且目录干净后，才用 `scripts/cleanup-worktree.rb` 清理并恢复产品路径。状态仍为“使用中/待清理”或缺少“已同步验证”证据时不能进入 `done`，用户明确确认保留并记录原因时除外。全部通过或受控豁免后，把状态改为 `done`，再运行 `scripts/refresh-iteration-overview.rb`，确认系统总览已显示完成状态。用户明确说“验收并收口”时，第 8、9 步可以连续执行；向系统知识库同步结论仍属于框架外写入，只有另行取得授权时才执行。

需求变了，先改文档再改代码，并重新完成需求和计划审批；计划变了则重新完成计划审批。审批摘要由 `stage-approvals.md` 记录，普通“继续”“开始处理”“可以”不能替代审批。`specify` 和 `plan` 阶段不许改仓库里的代码。`done` 只代表本轮验收收口，不自动获得提交、推送、部署或迁移授权；发布交接按 [风险与评审](./standards/06-risk-and-review.md) 可选记录。

框架结构、链接、状态和门禁规则由 `ruby scripts/validate-framework.rb` 全局校验；日常绑定轮次可先用 `ruby scripts/validate-framework.rb --iteration systems/<system>/iterations/<iteration>` 做局部校验，但局部绿色不能替代最终全局校验。校验器自身的失败路径由 `ruby scripts/test-validate-framework.rb` 回归，worktree 创建、目标分支同步与清理由 `ruby scripts/test-worktree-lifecycle.rb` 在临时 Git 仓库中回归。
