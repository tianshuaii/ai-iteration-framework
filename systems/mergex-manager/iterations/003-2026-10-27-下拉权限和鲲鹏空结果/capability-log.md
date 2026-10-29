<!-- capability-log-policy: task-guard-digest-v2 -->
# 能力执行记录

- adopted_at: 2026-10-27T18:10:02+08:00
- migration_base_phase: new
- migration_current_task: 无
- migration_task_state: 无
- note: 新轮次从需求阶段启用完整能力门禁。

本文件只保存能力执行索引，不替代 `status.md`。详细证据放在 `evidence/`；每条任务的 implementation guard 使用自己的 `T-xx`，`input_digest` 绑定该任务正文、改动范围及计划检出/资源区，不绑定整轮其他任务。首次全部任务完成后的统一 code-review 使用 `task=无` 并指向 `evidence/reviews/implementation-review.md`；验收返工产生的新任务使用 `task=T-xx` 的增量 code-review，绑定该任务摘要并追加到同一报告。每条记录仍必须有独立能力名、输入摘要、时间和发现计数。

| id | capability | phase | task | provider | provider_version | status | input_digest | evidence | started_at | completed_at | P0 | P1 | P2-open |
|---|---|---|---|---|---|---|---|---|---|---|---:|---:|---:|
| C-01 | requirements-review | specify | 无 | iteration-requirements-review | capability-gates-v2 | passed | d6fd668dd02f6d0477db0cd4b881e20c1603881a394a5207fb5a71195c8705dd | evidence/analysis/stage-review.md | 2026-10-27T18:17:00+08:00 | 2026-10-27T18:18:00+08:00 | 0 | 0 | 0 |
| C-02 | plan-review | plan | 无 | iteration-plan-review | capability-gates-v2 | passed | 4c781ff637f69bf2df0f714a4dd7250f75ece8e467c1a88d62ff09f7caf99b35 | evidence/analysis/stage-review.md | 2026-10-27T18:21:00+08:00 | 2026-10-27T18:22:00+08:00 | 0 | 0 | 0 |
| C-03 | implementation-guard | implement | T-03 | iteration-implementation-guard | capability-gates-v2 | passed | 10c1fd53cc088ae5c44dadc278b76a689d00ce88be018494a184397dcedc9546 | evidence/reviews/T-03.md | 2026-10-27T18:28:00+08:00 | 2026-10-27T18:28:00+08:00 | 0 | 0 | 0 |
| C-04 | implementation-guard | implement | T-01 | iteration-implementation-guard | capability-gates-v2 | passed | ee871fa74d72993ffad35ad789fad10a752e901f8e512892a68184f0fff41a8c | evidence/reviews/T-01.md | 2026-10-27T18:28:00+08:00 | 2026-10-27T18:28:00+08:00 | 0 | 0 | 0 |
| C-05 | implementation-guard | implement | T-02 | iteration-implementation-guard | capability-gates-v2 | passed | 05ad080cbc0636241d88e895d83de31c8ac8b96e730f06726c0b5c4ff1118edc | evidence/reviews/T-02.md | 2026-10-27T18:28:00+08:00 | 2026-10-27T18:28:00+08:00 | 0 | 0 | 0 |
| C-06 | code-review | implement | 无 | code-review-skill | capability-gates-v2 | passed | 4c781ff637f69bf2df0f714a4dd7250f75ece8e467c1a88d62ff09f7caf99b35 | evidence/reviews/implementation-review.md | 2026-10-27T18:34:00+08:00 | 2026-10-27T18:35:00+08:00 | 0 | 0 | 0 |
| C-07 | test-verification | verify | 无 | iteration-test-verification | capability-gates-v2 | passed | 29a50c3bc8b188a2e774ceb058ea3d6d01c009db66421228a9b5446ade34342c | evidence/delivery/final-review.md | 2026-10-27T18:46:30+08:00 | 2026-10-27T18:52:00+08:00 | 0 | 0 | 0 |
| C-08 | delivery-review | verify | 无 | iteration-delivery-review | capability-gates-v2 | passed | 29a50c3bc8b188a2e774ceb058ea3d6d01c009db66421228a9b5446ade34342c | evidence/delivery/final-review.md | 2026-10-27T18:46:30+08:00 | 2026-10-27T18:52:00+08:00 | 0 | 0 | 0 |
