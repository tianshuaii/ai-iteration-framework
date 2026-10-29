<!-- capability-log-policy: task-guard-digest-v2 -->
# 能力执行记录

- adopted_at: 2026-10-28T11:35:36+08:00
- migration_base_phase: new
- migration_current_task: 无
- migration_task_state: 无
- note: 新轮次从需求阶段启用完整能力门禁。

本文件只保存能力执行索引，不替代 `status.md`。详细证据放在 `evidence/`；每条任务的 implementation guard 使用自己的 `T-xx`，`input_digest` 绑定该任务正文、改动范围及计划检出/资源区，不绑定整轮其他任务。首次全部任务完成后的统一 code-review 使用 `task=无` 并指向 `evidence/reviews/implementation-review.md`；验收返工产生的新任务使用 `task=T-xx` 的增量 code-review，绑定该任务摘要并追加到同一报告。每条记录仍必须有独立能力名、输入摘要、时间和发现计数。

| id | capability | phase | task | provider | provider_version | status | input_digest | evidence | started_at | completed_at | P0 | P1 | P2-open |
|---|---|---|---|---|---|---|---|---|---|---|---:|---:|---:|
| C-001 | design-interview | specify | 无 | grill-me | local-skill | passed | cefa6a8fa3cfb9058bba85920ace075948f8fa2d3dfd7530f431711e1ba9208d | evidence/analysis/design-interview.md | 2026-10-28T11:36:00+08:00 | 2026-10-28T11:43:00+08:00 | 0 | 0 | 0 |
| C-002 | requirements-review | specify | 无 | local-deterministic-review | 2026-10-28 | passed | cefa6a8fa3cfb9058bba85920ace075948f8fa2d3dfd7530f431711e1ba9208d | evidence/analysis/stage-review.md | 2026-10-28T11:40:27+08:00 | 2026-10-28T11:43:00+08:00 | 0 | 0 | 0 |
| C-003 | design-interview | plan | 无 | grill-me | local-skill | passed | 96b1e18cc4cfb4acda7fa9a11cc051601b0080b84a3966307f945f3ec5894806 | evidence/analysis/plan-design-interview.md | 2026-10-28T11:42:00+08:00 | 2026-10-28T11:47:33+08:00 | 0 | 0 | 0 |
| C-004 | plan-review | plan | 无 | local-deterministic-review | 2026-10-28 | passed | 96b1e18cc4cfb4acda7fa9a11cc051601b0080b84a3966307f945f3ec5894806 | evidence/analysis/stage-review.md | 2026-10-28T11:47:33+08:00 | 2026-10-28T11:47:33+08:00 | 0 | 0 | 0 |
| C-005 | implementation-guard | implement | T-01 | local-deterministic-guard | 2026-10-28 | passed | bb449c7edfb79db30f633b495b807db205181863a6184510fb8cb51d43c03a5d | evidence/reviews/T-01.md | 2026-10-28T11:51:27+08:00 | 2026-10-28T11:52:35+08:00 | 0 | 0 | 0 |
| C-006 | implementation-guard | implement | T-02 | local-deterministic-guard | 2026-10-28 | passed | fdbbadd340c8c85940a5184c88dea9e95f88bb912ff3c115cfb442e22075fe2b | evidence/reviews/T-02.md | 2026-10-28T11:53:00+08:00 | 2026-10-28T11:53:56+08:00 | 0 | 0 | 0 |
| C-007 | implementation-guard | implement | T-03 | local-deterministic-guard | 2026-10-28 | passed | 174b54fd631f969338143cb0e094882e7b906e6f426b52bfc2db751ee14becba | evidence/reviews/T-03.md | 2026-10-28T11:53:30+08:00 | 2026-10-28T11:53:56+08:00 | 0 | 0 | 0 |
| C-008 | code-review | implement | 无 | local-deterministic-review | 2026-10-28 | passed | 96b1e18cc4cfb4acda7fa9a11cc051601b0080b84a3966307f945f3ec5894806 | evidence/reviews/implementation-review.md | 2026-10-28T11:53:56+08:00 | 2026-10-28T11:53:56+08:00 | 0 | 0 | 0 |
| C-009 | test-verification | verify | 无 | local-deterministic-review | 2026-10-28 | passed | fdd35d4445c71cee2c9c97467a7282eb87176a7090e1e40a96525f8d6389322d | evidence/delivery/final-review.md | 2026-10-28T11:54:10+08:00 | 2026-10-28T11:54:10+08:00 | 0 | 0 | 0 |
| C-010 | delivery-review | verify | 无 | local-deterministic-review | 2026-10-28 | passed | fdd35d4445c71cee2c9c97467a7282eb87176a7090e1e40a96525f8d6389322d | evidence/delivery/final-review.md | 2026-10-28T11:54:10+08:00 | 2026-10-28T11:54:10+08:00 | 0 | 0 | 0 |
