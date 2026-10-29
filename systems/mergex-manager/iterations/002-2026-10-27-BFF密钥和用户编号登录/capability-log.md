<!-- capability-log-policy: task-guard-digest-v2 -->
# 能力执行记录

- adopted_at: 2026-10-27T15:00:01+08:00
- migration_base_phase: new
- migration_current_task: 无
- migration_task_state: 无
- note: 新轮次从需求阶段启用完整能力门禁。

本文件只保存能力执行索引，不替代 `status.md`。详细证据放在 `evidence/`；每条任务的 implementation guard 使用自己的 `T-xx`，`input_digest` 绑定该任务正文、改动范围及计划检出/资源区，不绑定整轮其他任务。首次全部任务完成后的统一 code-review 使用 `task=无` 并指向 `evidence/reviews/implementation-review.md`；验收返工产生的新任务使用 `task=T-xx` 的增量 code-review，绑定该任务摘要并追加到同一报告。每条记录仍必须有独立能力名、输入摘要、时间和发现计数。

| id | capability | phase | task | provider | provider_version | status | input_digest | evidence | started_at | completed_at | P0 | P1 | P2-open |
|---|---|---|---|---|---|---|---|---|---|---|---:|---:|---:|
| C-01 | requirements-review | specify | 无 | iteration-requirements-review | capability-gates-v2 | passed | ae8bc03ceebfdd42c3fca070d8cb71f426e3e36a6bf0f50fea1569a6d57d6dc9 | evidence/analysis/stage-review.md | 2026-10-27T15:06:00+08:00 | 2026-10-27T15:08:00+08:00 | 0 | 0 | 0 |
| C-02 | plan-review | plan | 无 | iteration-plan-review | capability-gates-v2 | passed | 7ff3f8e64be5d8d7e5ab94201ce5a7bd93fba197fdb9ca15a3cc421e2d4c5ef5 | evidence/analysis/stage-review.md | 2026-10-27T15:13:00+08:00 | 2026-10-27T15:14:00+08:00 | 0 | 0 | 0 |
| C-03 | implementation-guard | implement | T-01 | iteration-implementation-guard | capability-gates-v2 | passed | 06daf4a2933aac04dd2ae94fa6ac48bda64ffd1df8c47cc43aa749f3af95fa7e | evidence/reviews/T-01.md | 2026-10-27T15:17:00+08:00 | 2026-10-27T15:18:00+08:00 | 0 | 0 | 0 |
| C-04 | implementation-guard | implement | T-02 | iteration-implementation-guard | capability-gates-v2 | passed | f5eb02084b07fa93b606caa69482b491a33eeabbbee125768dd986a9c5cd0710 | evidence/reviews/T-02.md | 2026-10-27T15:22:30+08:00 | 2026-10-27T15:23:00+08:00 | 0 | 0 | 0 |
| C-05 | code-review | implement | 无 | code-review-skill | capability-gates-v2 | passed | 7ff3f8e64be5d8d7e5ab94201ce5a7bd93fba197fdb9ca15a3cc421e2d4c5ef5 | evidence/reviews/implementation-review.md | 2026-10-27T15:25:00+08:00 | 2026-10-27T15:26:00+08:00 | 0 | 0 | 0 |
| C-06 | test-verification | verify | 无 | iteration-test-verification | capability-gates-v2 | passed | 81c9f69913566269ba13928ec78bbf9a2db22a02d8dee08324fac1e3b3145e9c | evidence/delivery/final-review.md | 2026-10-27T18:57:00+08:00 | 2026-10-27T18:57:50+08:00 | 0 | 0 | 0 |
| C-07 | delivery-review | verify | 无 | iteration-delivery-review | capability-gates-v2 | passed | 81c9f69913566269ba13928ec78bbf9a2db22a02d8dee08324fac1e3b3145e9c | evidence/delivery/final-review.md | 2026-10-27T18:57:00+08:00 | 2026-10-27T18:57:50+08:00 | 0 | 0 | 0 |
