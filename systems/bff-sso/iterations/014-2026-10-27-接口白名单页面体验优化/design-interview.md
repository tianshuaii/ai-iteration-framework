<!-- design-interview-policy: design-tree-v1 -->
# 设计访谈

本文件持久保存需求和计划阶段的设计树访谈。事实由 Agent 使用只读源码、文档或 MCP 查询；用户只决定方案。历史尝试不得删除，输入摘要变化后把旧尝试标记为 `superseded` 并追加新尝试。

复杂度字段只使用 `yes`、`no` 或 `unknown`。任一字段为 `yes` 或 `unknown` 时按 `non-trivial`。`lite` 只有全部为 `no` 才能跳过两阶段访谈；`standard` 的非简单需求必须访谈，计划阶段可用计划评审代替第二次访谈；`strict` 的非简单需求和计划都必须访谈。

## requirements/R-001

- status: completed
- provider: grill-me
- provider_version: local-skill
- question_protocol: inline-confirmation-v1
- input_digest: 8bd2ec80142dc8f581dc17a1f74a074f22a91bf031acafe5a8e6cde57c306d84
- started_at: 2026-10-27T17:43:08+08:00
- completed_at: 2026-10-27T17:49:50+08:00
- classification: non-trivial
- classification_reason: 要改网关管理端的接口白名单页，属于普通产品代码。不改接口、数据、免登录规则，所以不用升到严格档。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: no
- complexity.database_or_migration: no
- complexity.permission_or_security: no
- complexity.concurrency: no
- complexity.performance: no
- complexity.multiple_repositories: no
- complexity.external_service: no
- complexity.deployment: no
- complexity.destructive_operation: no
- complexity.uncertain: no

### 问答

| 问题 | 推荐答案 | 用户选择 | 状态 | 确认依据 |
|---|---|---|---|---|
| Q1 这一轮是否只改网关管理的接口白名单页，而且不改现有功能？ | 只改这一页的排法和操作。勾选、搜索、筛选、保存和免登录规则保持原样。 | 只改这一页的样子和用法 | resolved | 用户原话：优化接口白名单页面，不改功能，只做UI和UX优化，现在这一版本太丑了，也不好用 |
| Q2 配色是否继续用现在的管理端，也就是浅灰底、白侧栏、近黑按钮？ | 沿用现有配色。这一页要一眼能看出来，不只拉开间距。 | 沿用现有配色 | resolved | 用户原话：开始处理 |
| Q3 搜索、筛选、已选数量和保存要不要固定在列表上方，列表再长也能看见保存？ | 要。这一条固定在列表上方。窄屏时搜索和筛选可以换行，保存仍留在这一条里。 | 按推荐做 | resolved | 用户原话：Q3 按推荐做。Q4 按推荐做。Q5 按推荐做 |
| Q4 接口列表要不要仍用表格，但把方法、路径、摘要分成主次，方便扫读？ | 要。继续用表格勾选。方法用能区分的标签，路径是主文字，摘要是次要文字。窄屏表格可以横滑，不改成树或卡片墙。 | 按推荐做 | resolved | 用户原话：Q3 按推荐做。Q4 按推荐做。Q5 按推荐做 |
| Q5 勾选和已保存名单不一致时，要不要在保存旁边写明还有修改没保存？ | 要。写「有未保存的修改」。保存成功后这句话消失，搜索和是否加入的筛选留着。 | 按推荐做 | resolved | 用户原话：Q3 按推荐做。Q4 按推荐做。Q5 按推荐做 |

### 假设与风险

- 现有页把搜索、筛选、保存和「已选多少条」放在同一行，往下滚就看不见保存。
- 失效接口的黄字现在也在这一行。确认 Q3 后，这句警告要跟着保存一起留在视线里。
- 运行包抽屉里的白名单展示不在本轮。用户没有点名它。
- 设计树已收敛：操作区留在列表上方，表格分成主次，未保存时写明还有修改。没有开放分支。

## plan/P-001

- status: skipped
- provider: grill-me
- provider_version: local-skill
- question_protocol: inline-confirmation-v1
- input_digest: d0c0b18110e571081277d1c67df6d9dbcc376b1702b857d89f9ed18586fd39ab
- started_at: 2026-10-27T18:13:20+08:00
- completed_at: 2026-10-27T18:13:20+08:00
- classification: non-trivial
- classification_reason: 这是普通产品代码。standard 档位的计划不再重复访谈，改由计划评审检查任务、风险、测试和检出。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: no
- complexity.database_or_migration: no
- complexity.permission_or_security: no
- complexity.concurrency: no
- complexity.performance: no
- complexity.multiple_repositories: no
- complexity.external_service: no
- complexity.deployment: no
- complexity.destructive_operation: no
- complexity.uncertain: no

### 问答

| 问题 | 推荐答案 | 用户选择 | 状态 | 确认依据 |
|---|---|---|---|---|

### 假设与风险

- 需求阶段已经确认操作区、表格主次和未保存提示。计划只把这三件落在同一页，不新开问题。
- 没有其他进行中的实现或验收轮次占用网关前端，所以用真实目录的共享检出，不另开临时目录。
