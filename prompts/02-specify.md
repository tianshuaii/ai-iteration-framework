# 写规格

先读该轮 `status.md`。`phase` 不是 `specify` 就停。若该轮存在 `file-map.md`，按本轮映射定位历史文件。

## 先读

- 该系统的 `overview.md` 和 `knowledge-base/`
- [原则](../standards/00-principles.md)
- [需求与决策](../standards/02-requirements-and-decisions.md)
- [改动范围](../standards/03-change-scope.md)
- [验收与测试](../standards/05-acceptance-and-testing.md)

## 只许改这些

该轮文件夹里的 `requirements.md`、`decisions.md`、`change-scope.md`、`acceptance.md`、`test-strategy.md`、`test-cases.md`、`traceability.md`、`design-interview.md`、`capability-log.md`、`evidence/analysis/` 和 `status.md`。仅在验收返工回到本阶段时，还可修改 `test-log.md`，用来保留历史失败并将新规格的当前结果置为“未测”。历史轮次按本轮映射使用实际文件名。

改动范围要写成可以改的具体路径，并写明不许动的仓库。同一页面上会跟着变的文案、列、筛选、弹窗都要写上。

把尚有歧义的问题写在 `decisions.md` 的“待确认事项”，涉及接口、数据、权限、兼容行为或验收口径的选择需取得用户明确确认并记录依据；没有答复时保持 `specify / blocked`，不要由 Agent 自行拍板。验收返工回到本阶段时，更新受影响的需求、范围、AC/TC 和跟踪关系；旧用例结果先移入返工历史，再按新用例清单建立“未测”的当前记录，保留原失败事实。

## 不许做

不改 `overview.md` 里列出的仓库。不写实现计划和任务清单。

## 做完并等待审批

先按 `capabilities.yml` 填完复杂度字段并把 `status.md` 的 `workflow_profile` 调整为最低安全档位：全部为 `no` 可用 `lite`；只有普通产品代码为 yes/unknown 且没有高风险项时用 `standard`；接口/Schema、数据库、安全权限、并发、性能、多仓库、外部服务、部署、破坏性操作或不确定项为 yes/unknown 时必须 `strict`。`lite` 可按确定性清单记录 skipped；`standard` 和 `strict` 的非简单需求使用 `grill-me`，不可用时使用 `iteration-design-interview`。等待回答时必须同屏展示每个 `Qxx` 的问题全文、推荐答案、主要影响和可复制回复，访谈行保持 `待确认 / pending / 无`；只有收到用户直接回答后才写 `resolved` 和 `用户原话：...`。再使用 `iteration-requirements-review`，把需求评审追加到 `evidence/analysis/stage-review.md` 的 requirements 章节，并在 `capability-log.md` 留下独立索引。未决问题或未处置发现不允许发起审批。

用户对结构化访谈的直接回答只授权更新本轮访谈、状态和本阶段文档，不授权产品代码、提交、推送、部署、迁移或 MCP 外部写入。

规格写完且关键待确认事项已解决后，不能直接进入 `plan`。把所绑定轮次的 `status.md` 保持为 `phase: specify`、`current_task: 无`，将 `work_state` 设为 `blocked`；`updated_at` 写当前时间，`checkpoint` 记录规格已完成、确认依据和等待审批，`next_action` 写明需要用户明确批准需求，并可给“需求审批通过”作为示例，不要求逐字回复。

只有当前用户以“需求审批通过”或含义明确的等价自然语言批准需求时，才运行 `ruby scripts/record-stage-approval.rb <轮次目录> requirements "用户原话"`。若原话同时批准需求和计划，先记录需求并保留原话，不能跳过计划访谈和评审。脚本会再次检查访谈和需求评审证据。命令成功后再把 `status.md` 更新为 `phase: plan`、`current_task: 无`、`work_state: ready`，写明开始拆实现计划和任务，并刷新系统总览。普通“继续”“开始处理”“可以”或先前的写入授权都不能作为需求审批。下一步用 [03-plan](./03-plan.md)。
