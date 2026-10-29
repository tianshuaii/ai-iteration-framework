# ai-iteration-framework

标准和模版对任何一套系统都一样。一套系统放在 [systems](./systems/README.md) 下面。仓库只在说明里写绝对路径，不把长期源码放进来；默认直接使用真实仓库，未提交修改只登记基线。只有另一 `implement` 或 `verify` 轮次使用同一仓库时，临时 Git worktree 才由脚本创建在根目录 `.worktrees/`，并在轮次收口时清理。Agent 从目录启动后由适用的 `AGENTS.md` 自动定位系统，再给当前会话绑定一个轮次，按 [prompts](./prompts/README.md)、该轮 `status.md`、`stage-approvals.md` 和 `capability-log.md` 恢复阶段、任务、断点、下一步、审批及能力门禁。

规格完成和计划完成各有一道强制用户审批：用户可用“需求审批通过”“计划审批通过”等价自然语言明确表达，也可一次说“自动审批需求和计划”或“自动完成需求和计划审批流程”。`scripts/record-stage-approval.rb` 仍在两个阶段分别把原话写入本轮 `stage-approvals.md` 并绑定各自摘要；计划未完成时不会提前过门。普通继续或写入授权不能替代审批，受保护文档变化后旧审批自动失效。用户说“完成所有任务”时，Agent 只连续完成本轮实现任务和统一审核，然后停在 `verify / blocked`；“开始验收”只执行按风险验收并再次等待收口；只有“验收并收口”等明确联合表达才连续进入 `done`。这些指令都不会授权提交、推送、合并、拉取、部署、迁移数据库、启动服务或写外部系统。

阶段能力由 [capabilities.yml](./capabilities.yml) 登记，并按 `lite / standard / strict` 三档运行。三个档位都保留双审批、首次迭代级统一代码审核和真实验收；验收返工只追加覆盖新任务守卫的增量审核。测试按任务使用 `T0` 到 `T4` 风险档位，深度和影响宽度分别判断；输入未变化的证据允许复用，避免一两行修复反复触发多仓全量测试。验收仍覆盖直接功能和一层高概率相邻功能，但不扩展成无依据的全系统回归。

设计访谈等待用户时，Agent 必须在同一条消息写出 `Qxx` 问题全文、推荐答案、影响和可直接复制的回复。未确认问题只能保存为 `待确认 / pending / 无`；收到用户直接回答后才能标记 `resolved` 并保留确认原话，未决问题不能进入阶段审批。

第一次使用请先看 [使用指南](./USAGE.md)。指南包含新系统登记、进入已有系统、打开迭代、阶段推进和可直接复制的对话示例。

```text
ai-iteration-framework/
  AGENTS.md
  standards/
  templates/
  prompts/
  scripts/
    capability-digest-support.rb
    capability-support.rb
    user-intent-support.rb
    review-coverage-support.rb
    risk-test-support.rb
    refresh-iteration-overview.rb
    iteration-context.rb
    validate-framework.rb
    record-stage-approval.rb
    create-worktree.rb
    sync-worktree.rb
    cleanup-worktree.rb
  .worktrees/        按需创建的临时产品 worktree；不属于迭代档案
  systems/
    AGENTS.md
    <system>/
      AGENTS.md          进入本系统时的自动入口
      overview.md        含各仓库的绝对路径，不放源码
      agent/README.md    说明会话级轮次绑定规则，不保存共享当前指针
      knowledge-base     绝对路径软链接，指向这套系统的文档目录
      iterations/
        001-YYYY-MM-DD-中文主题/
          scripts/          这一轮临时用的脚本，必有
          knowledge-base/   可选
```

把 Codex 任务工作目录直接选择为 `systems/` 可以登记新系统；选择具体系统目录后，只有一个活动轮次时会自动恢复，有多个时需要点名轮次；也可以直接以某个轮次目录创建任务。绑定后每个用户回合把完整原话作为单个经过 shell 安全转义的参数传给 `ruby scripts/iteration-context.rb <轮次目录> --intent SAFE_USER_MESSAGE`，按输出的 `intent_route` 和 `read_next` 推进；禁止拼接未转义原话，不再依赖固定口令或默认全量加载整轮档案。`read_next` 会按阶段、当前任务、待确认问题和明确验收/收口意图给出当下最小集合，阶段切换后重新运行入口，不提前加载后续阶段正文。完成态输出 `read_next: 无`，只有用户明确要求审计或复核时才按需读取交付证据。单参数形式只用于无当前消息的只读恢复。只在任务终端执行 `cd` 不会重新加载下级 `AGENTS.md`。写法见 [使用指南](./USAGE.md) 和 [iteration-standard](./iteration-standard.md)。当前系统登记以 [systems/README.md](./systems/README.md) 为准，不在根说明重复维护系统名单。

新开一轮必须在框架根目录运行 `ruby scripts/create-iteration.rb systems/<system> 中文主题`；它先取得系统级文件锁，再写好模板与真实状态时间并发布完整轮次。禁止人工创建轮次目录或复制模板；脚本不可用时停止并报告。失败返工按 [生命周期](./standards/01-lifecycle.md) 返回实现或规格阶段，不把未通过项改成“通过”。

每套系统的 `overview.md` 都包含一张自动生成的迭代状态与审批门禁视图。权威动态状态仍只在各轮 `status.md`，审批证据只在 `stage-approvals.md`；创建和审批脚本会自动刷新总览，其他状态变化后运行 `ruby scripts/refresh-iteration-overview.rb systems/<system>`。不要手工改生成表，`validate-framework.rb` 会阻止漏轮次、审批摘要失效或字段过期的视图。

当另一 `implement` 或 `verify` 轮次已经登记使用同一仓库时，运行 `ruby scripts/create-worktree.rb systems/<system>/iterations/<iteration> <仓库名> <分支名> [起点ref]`。脚本会拒绝没有同仓库并行轮次的创建请求；原仓库 dirty 不构成例外。脚本只从 `overview.md` 解析原仓库，并固定创建到 `.worktrees/<system>/<iteration>/<repo>/`。成果提交、合入并推送目标分支后，取得拉取授权，运行 `ruby scripts/sync-worktree.rb systems/<system>/iterations/<iteration> <仓库名> <目标分支>`；它在 `overview.md` 登记的真实仓库执行 `git pull --ff-only`，并验证目标分支包含 worktree 最终 HEAD。验证成功后再运行 `ruby scripts/cleanup-worktree.rb systems/<system>/iterations/<iteration> <仓库名>`；脏 worktree 或同步证据失效都会被阻断，功能分支不会自动删除，`workspace.md` 会恢复指向真实仓库并保留最终 HEAD 与同步证据。

框架修改后运行：

```bash
ruby scripts/validate-framework.rb
ruby scripts/test-validate-framework.rb
ruby scripts/test-create-iteration.rb
ruby scripts/test-worktree-lifecycle.rb
```

GitHub Actions 在推送到 `main` 和面向 `main` 的 Pull Request 上执行同样四条命令。托管 runner 通过 `AI_ITERATION_FRAMEWORK_PORTABLE_VALIDATION=1` 只跳过无法随仓库分发的本机产品仓库、知识库和临时检出实体存在性；目录结构、链接边界、状态、审批、能力证据、路径格式、worktree 记录关系和全部回归仍会校验。本机不设置该变量，继续执行包含外部实体的完整校验。

普通业务轮次可先运行 `ruby scripts/validate-framework.rb --iteration systems/<system>/iterations/<iteration>`，只检查通用框架契约和这一轮，避免无关历史档案阻断日常恢复。局部通过不代表全局通过；框架修改、最终治理检查和交付前仍运行无参数全局校验。
