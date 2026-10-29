<!-- capability-log-policy: task-guard-digest-v2 -->
# 能力执行记录

- adopted_at: 2026-10-27T17:41:35+08:00
- migration_base_phase: new
- migration_current_task: 无
- migration_task_state: 无
- note: 新轮次从需求阶段启用完整能力门禁。

本文件只保存能力执行索引，不替代 `status.md`。详细证据放在 `evidence/`；每条任务的 implementation guard 使用自己的 `T-xx`，`input_digest` 绑定该任务正文、改动范围及计划检出/资源区，不绑定整轮其他任务。首次全部任务完成后的统一 code-review 使用 `task=无` 并指向 `evidence/reviews/implementation-review.md`；验收返工产生的新任务使用 `task=T-xx` 的增量 code-review，绑定该任务摘要并追加到同一报告。每条记录仍必须有独立能力名、输入摘要、时间和发现计数。

| id | capability | phase | task | provider | provider_version | status | input_digest | evidence | started_at | completed_at | P0 | P1 | P2-open |
|---|---|---|---|---|---|---|---|---|---|---|---:|---:|---:|
| C-001 | design-interview | specify | 无 | grill-me | local-skill | passed | 8bd2ec80142dc8f581dc17a1f74a074f22a91bf031acafe5a8e6cde57c306d84 | evidence/analysis/design-interview.md | 2026-10-27T17:43:08+08:00 | 2026-10-27T17:49:50+08:00 | 0 | 0 | 0 |
| C-002 | requirements-review | specify | 无 | local-deterministic-review | 2026-10-27 | passed | 8bd2ec80142dc8f581dc17a1f74a074f22a91bf031acafe5a8e6cde57c306d84 | evidence/analysis/stage-review.md | 2026-10-27T17:49:50+08:00 | 2026-10-27T17:49:50+08:00 | 0 | 0 | 0 |
| C-003 | design-interview | plan | 无 | grill-me | local-skill | skipped | d0c0b18110e571081277d1c67df6d9dbcc376b1702b857d89f9ed18586fd39ab | evidence/analysis/plan-design-interview.md | 2026-10-27T18:13:20+08:00 | 2026-10-27T18:13:20+08:00 | 0 | 0 | 0 |
| C-004 | plan-review | plan | 无 | local-deterministic-review | 2026-10-27 | passed | d0c0b18110e571081277d1c67df6d9dbcc376b1702b857d89f9ed18586fd39ab | evidence/analysis/stage-review.md | 2026-10-27T18:13:20+08:00 | 2026-10-27T18:13:20+08:00 | 0 | 0 | 0 |
| C-005 | implementation-guard | implement | T-01 | local-deterministic-guard | 2026-10-27 | passed | 80d7404e07dcb2525642641a1b7413d997369a096c806d196885b055ead0956d | evidence/reviews/T-01.md | 2026-10-27T18:19:00+08:00 | 2026-10-27T18:19:00+08:00 | 0 | 0 | 0 |
| C-006 | code-review | implement | 无 | local-deterministic-review | 2026-10-27 | passed | d0c0b18110e571081277d1c67df6d9dbcc376b1702b857d89f9ed18586fd39ab | evidence/reviews/implementation-review.md | 2026-10-27T18:21:30+08:00 | 2026-10-27T18:22:28+08:00 | 0 | 0 | 0 |
| C-007 | test-verification | verify | 无 | local-deterministic-review | 2026-10-27 | passed | 2ed09e4d762e6fcf223276492cb9fba100d133e82ccebfd23ce2155bdddef456 | evidence/delivery/final-review.md | 2026-10-27T18:26:42+08:00 | 2026-10-27T18:31:01+08:00 | 0 | 0 | 0 |
| C-008 | delivery-review | verify | 无 | local-deterministic-review | 2026-10-27 | passed | 2ed09e4d762e6fcf223276492cb9fba100d133e82ccebfd23ce2155bdddef456 | evidence/delivery/final-review.md | 2026-10-27T18:26:42+08:00 | 2026-10-27T18:31:01+08:00 | 0 | 0 | 0 |
