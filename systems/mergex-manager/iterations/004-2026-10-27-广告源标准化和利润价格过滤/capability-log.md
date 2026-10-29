<!-- capability-log-policy: task-guard-digest-v2 -->
# 能力执行记录

- adopted_at: 2026-10-27T19:09:12+08:00
- migration_base_phase: new
- migration_current_task: 无
- migration_task_state: 无
- note: 新轮次从需求阶段启用完整能力门禁。

本文件只保存能力执行索引，不替代 `status.md`。详细证据放在 `evidence/`；每条任务的 implementation guard 使用自己的 `T-xx`，`input_digest` 绑定该任务正文、改动范围及计划检出/资源区，不绑定整轮其他任务。首次全部任务完成后的统一 code-review 使用 `task=无` 并指向 `evidence/reviews/implementation-review.md`；验收返工产生的新任务使用 `task=T-xx` 的增量 code-review，绑定该任务摘要并追加到同一报告。每条记录仍必须有独立能力名、输入摘要、时间和发现计数。

| id | capability | phase | task | provider | provider_version | status | input_digest | evidence | started_at | completed_at | P0 | P1 | P2-open |
|---|---|---|---|---|---|---|---|---|---|---|---:|---:|---:|
| C-01 | requirements-review | specify | 无 | iteration-requirements-review | capability-gates-v2 | passed | d7be664eab9f7030d8a7c38a31a7f3d4bffec8405a8ff48436357b5cbddd1e37 | evidence/analysis/stage-review.md | 2026-10-27T19:12:40+08:00 | 2026-10-27T19:13:20+08:00 | 0 | 0 | 0 |
| C-02 | plan-review | plan | 无 | iteration-plan-review | capability-gates-v2 | passed | c01999199bb607896f1decbb1d299a0ad5b1c46467d3e912a4a1dc0410b9e3a1 | evidence/analysis/stage-review.md | 2026-10-27T19:18:54+08:00 | 2026-10-27T19:19:00+08:00 | 0 | 0 | 0 |
| C-03 | implementation-guard | implement | T-01 | iteration-implementation-guard | capability-gates-v2 | passed | bb2c353d295aab705cb3c5ea7023a59da43e72e31457ebf879ae391159319ed7 | evidence/reviews/T-01.md | 2026-10-27T19:21:00+08:00 | 2026-10-27T19:22:00+08:00 | 0 | 0 | 0 |
| C-04 | implementation-guard | implement | T-02 | iteration-implementation-guard | capability-gates-v2 | passed | f696caf0dc194fc7fc08f6bd0f59cba8aa794911284988f6c4f6cb273771d9a0 | evidence/reviews/T-02.md | 2026-10-27T19:22:00+08:00 | 2026-10-27T19:22:30+08:00 | 0 | 0 | 0 |
| C-05 | implementation-guard | implement | T-03 | iteration-implementation-guard | capability-gates-v2 | passed | d751bf634aa1446f7bc33bbe40b23dd1e61aa9c26b8e0396d11f2666d6a26732 | evidence/reviews/T-03.md | 2026-10-27T19:22:30+08:00 | 2026-10-27T19:23:00+08:00 | 0 | 0 | 0 |
| C-06 | implementation-guard | implement | T-04 | iteration-implementation-guard | capability-gates-v2 | passed | 623d2cb83c7312a9af9ce598c66ba037d53f4479b0203df7dc806ff202c0b4c3 | evidence/reviews/T-04.md | 2026-10-27T19:23:00+08:00 | 2026-10-27T19:23:30+08:00 | 0 | 0 | 0 |
| C-07 | code-review | implement | 无 | code-review-skill | capability-gates-v2 | passed | c01999199bb607896f1decbb1d299a0ad5b1c46467d3e912a4a1dc0410b9e3a1 | evidence/reviews/implementation-review.md | 2026-10-27T19:27:00+08:00 | 2026-10-27T19:28:00+08:00 | 0 | 0 | 0 |
| C-08 | requirements-review | specify | 无 | iteration-requirements-review | capability-gates-v2 | passed | bd12205f2b0c657f5c0155e28a8bab65ec063fd61cd85a407199a4cbc0ebd73f | evidence/analysis/stage-review.md | 2026-10-27T19:35:30+08:00 | 2026-10-27T19:36:00+08:00 | 0 | 0 | 0 |
| C-09 | plan-review | plan | 无 | iteration-plan-review | capability-gates-v2 | passed | 9ceef7ac2ac39a12953a56d0588bc0b77cfe1a3ff3f3c329b7aebaf2d1ee9feb | evidence/analysis/stage-review.md | 2026-10-27T19:36:00+08:00 | 2026-10-27T19:36:30+08:00 | 0 | 0 | 0 |
| C-10 | implementation-guard | implement | T-05 | iteration-implementation-guard | capability-gates-v2 | passed | 6168f7fd9acb3bc660ac05de72fed39394f947d18e0b4901aa3117b9b7f23ed5 | evidence/reviews/T-05.md | 2026-10-27T19:34:00+08:00 | 2026-10-27T19:35:00+08:00 | 0 | 0 | 0 |
| C-11 | code-review | implement | T-05 | code-review-skill | capability-gates-v2 | passed | 6168f7fd9acb3bc660ac05de72fed39394f947d18e0b4901aa3117b9b7f23ed5 | evidence/reviews/implementation-review.md | 2026-10-27T19:35:30+08:00 | 2026-10-27T19:36:00+08:00 | 0 | 0 | 0 |
| C-12 | code-review | implement | 无 | code-review-skill | capability-gates-v2 | passed | 9ceef7ac2ac39a12953a56d0588bc0b77cfe1a3ff3f3c329b7aebaf2d1ee9feb | evidence/reviews/implementation-review.md | 2026-10-27T19:45:30+08:00 | 2026-10-27T19:46:00+08:00 | 0 | 0 | 0 |
| C-13 | test-verification | verify | 无 | iteration-test-verification | capability-gates-v2 | passed | ee12b1dc4ff1a9ce9b6db27f0d24c873a985a4089d59cfdb9a631f71d6623c47 | evidence/delivery/final-review.md | 2026-10-27T19:45:00+08:00 | 2026-10-27T19:46:30+08:00 | 0 | 0 | 0 |
| C-14 | delivery-review | verify | 无 | iteration-delivery-review | capability-gates-v2 | passed | ee12b1dc4ff1a9ce9b6db27f0d24c873a985a4089d59cfdb9a631f71d6623c47 | evidence/delivery/final-review.md | 2026-10-27T19:45:00+08:00 | 2026-10-27T19:46:30+08:00 | 0 | 0 | 0 |
