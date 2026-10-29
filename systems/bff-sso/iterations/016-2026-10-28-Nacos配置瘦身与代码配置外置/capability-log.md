<!-- capability-log-policy: task-guard-digest-v2 -->
# 能力执行记录

- adopted_at: 2026-10-28T14:50:23+08:00
- migration_base_phase: new
- migration_current_task: 无
- migration_task_state: 无
- note: 新轮次从需求阶段启用完整能力门禁。

本文件只保存能力执行索引，不替代 `status.md`。详细证据放在 `evidence/`；每条任务的 implementation guard 使用自己的 `T-xx`，`input_digest` 绑定该任务正文、改动范围及计划检出/资源区，不绑定整轮其他任务。首次全部任务完成后的统一 code-review 使用 `task=无` 并指向 `evidence/reviews/implementation-review.md`；验收返工产生的新任务使用 `task=T-xx` 的增量 code-review，绑定该任务摘要并追加到同一报告。每条记录仍必须有独立能力名、输入摘要、时间和发现计数。

| id | capability | phase | task | provider | provider_version | status | input_digest | evidence | started_at | completed_at | P0 | P1 | P2-open |
|---|---|---|---|---|---|---|---|---|---|---|---:|---:|---:|
| C-001 | design-interview | specify | 无 | grill-me | local-skill | superseded | 09a24bdffc6257523d4fa015002b067d3b11050453f8442ab62b04c4596fbd32 | evidence/analysis/design-interview.md | 2026-10-28T14:58:00+08:00 | 2026-10-28T14:59:36+08:00 | 0 | 0 | 0 |
| C-002 | requirements-review | specify | 无 | iteration-requirements-review | repository-skill-2026-10-28 | superseded | 09a24bdffc6257523d4fa015002b067d3b11050453f8442ab62b04c4596fbd32 | evidence/analysis/stage-review.md | 2026-10-28T14:59:36+08:00 | 2026-10-28T15:02:32+08:00 | 0 | 0 | 0 |
| C-003 | design-interview | specify | 无 | grill-me | local-skill | passed | 33662de70dc6d1c2cb4c01c87b347faf2ed75e0203798bcd5c222bd3b0bcba59 | evidence/analysis/design-interview.md | 2026-10-28T15:17:00+08:00 | 2026-10-28T15:22:33+08:00 | 0 | 0 | 0 |
| C-004 | requirements-review | specify | 无 | iteration-requirements-review | repository-skill-2026-10-28 | passed | 33662de70dc6d1c2cb4c01c87b347faf2ed75e0203798bcd5c222bd3b0bcba59 | evidence/analysis/stage-review.md | 2026-10-28T15:17:00+08:00 | 2026-10-28T15:22:33+08:00 | 0 | 0 | 0 |
| C-005 | design-interview | plan | 无 | grill-me | local-skill | passed | b44f2e132a010df404d9dc0d5b79b069e177255e077ade040d90573d4d865764 | evidence/analysis/plan-design-interview.md | 2026-10-28T15:15:50+08:00 | 2026-10-28T15:24:22+08:00 | 0 | 0 | 0 |
| C-006 | plan-review | plan | 无 | iteration-plan-review | repository-skill-2026-10-28 | passed | b44f2e132a010df404d9dc0d5b79b069e177255e077ade040d90573d4d865764 | evidence/analysis/stage-review.md | 2026-10-28T15:22:33+08:00 | 2026-10-28T15:24:22+08:00 | 0 | 0 | 0 |
| C-007 | implementation-guard | implement | T-01 | iteration-implementation-guard | repository-skill-2026-10-28 | passed | 75aea2de24bb225664a2db4f7293624071dace7b3606f03704094aad2a7a442e | evidence/reviews/T-01.md | 2026-10-28T15:40:37+08:00 | 2026-10-28T15:40:37+08:00 | 0 | 0 | 0 |
| C-008 | implementation-guard | implement | T-02 | iteration-implementation-guard | repository-skill-2026-10-28 | passed | 96eaef1eeb421686a390a6bbbadd6a818c55a3366a6ca47f4bcdf99350bc8921 | evidence/reviews/T-02.md | 2026-10-28T15:44:31+08:00 | 2026-10-28T15:44:31+08:00 | 0 | 0 | 0 |
| C-009 | implementation-guard | implement | T-03 | iteration-implementation-guard | repository-skill-2026-10-28 | passed | 650a6f6c7b4c40cf975fc5c602938aaf271900247729c2bf711ef7cb40cc25ec | evidence/reviews/T-03.md | 2026-10-28T15:47:34+08:00 | 2026-10-28T15:47:34+08:00 | 0 | 0 | 0 |
| C-010 | implementation-guard | implement | T-04 | iteration-implementation-guard | repository-skill-2026-10-28 | passed | cd5a8d3e22f4ebb0092c07d9c0a09b0bc004e476bbfd857ae3600ba5f96a1e6a | evidence/reviews/T-04.md | 2026-10-28T15:55:37+08:00 | 2026-10-28T15:55:37+08:00 | 0 | 0 | 0 |
| C-011 | code-review | implement | 无 | code-review-skill | local-skill-2026-10-28 | passed | b44f2e132a010df404d9dc0d5b79b069e177255e077ade040d90573d4d865764 | evidence/reviews/implementation-review.md | 2026-10-28T16:05:50+08:00 | 2026-10-28T16:08:08+08:00 | 0 | 0 | 0 |
| C-012 | test-verification | verify | 无 | iteration-test-verification | repository-skill-2026-10-28 | passed | 1ebc2b617216883a41a0b62351520c1a3ab311ed1159c6b670352d72887f1a6d | evidence/delivery/final-review.md | 2026-10-28T16:09:57+08:00 | 2026-10-28T16:11:00+08:00 | 0 | 0 | 0 |
| C-013 | delivery-review | verify | 无 | iteration-delivery-review | repository-skill-2026-10-28 | passed | 1ebc2b617216883a41a0b62351520c1a3ab311ed1159c6b670352d72887f1a6d | evidence/delivery/final-review.md | 2026-10-28T16:11:00+08:00 | 2026-10-28T16:11:00+08:00 | 0 | 0 | 0 |
