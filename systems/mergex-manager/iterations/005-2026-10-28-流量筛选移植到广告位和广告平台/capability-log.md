<!-- capability-log-policy: task-guard-digest-v2 -->
# 能力执行记录

- adopted_at: 2026-10-28T17:10:41+08:00
- migration_base_phase: new
- migration_current_task: 无
- migration_task_state: 无
- note: 新轮次从需求阶段启用完整能力门禁。

本文件只保存能力执行索引，不替代 `status.md`。详细证据放在 `evidence/`；每条任务的 implementation guard 使用自己的 `T-xx`，`input_digest` 绑定该任务正文、改动范围及计划检出/资源区，不绑定整轮其他任务。首次全部任务完成后的统一 code-review 使用 `task=无` 并指向 `evidence/reviews/implementation-review.md`；验收返工产生的新任务使用 `task=T-xx` 的增量 code-review，绑定该任务摘要并追加到同一报告。每条记录仍必须有独立能力名、输入摘要、时间和发现计数。

| id | capability | phase | task | provider | provider_version | status | input_digest | evidence | started_at | completed_at | P0 | P1 | P2-open |
|---|---|---|---|---|---|---|---|---|---|---|---:|---:|---:|
| C-01 | design-interview | specify | 无 | grill-me | local-2026-10-28 | superseded | 4a3d5a5f3206f115c8f4736e83d31cd977b25d15e063690c1a08d0d9218165d3 | design-interview.md | 2026-10-28T17:48:36+08:00 | 2026-10-28T17:53:02+08:00 | 0 | 0 | 0 |
| C-02 | requirements-review | specify | 无 | iteration-requirements-review | capability-gates-v2 | superseded | 4a3d5a5f3206f115c8f4736e83d31cd977b25d15e063690c1a08d0d9218165d3 | evidence/analysis/stage-review.md | 2026-10-28T17:53:02+08:00 | 2026-10-28T17:53:25+08:00 | 0 | 0 | 0 |
| C-03 | design-interview | plan | 无 | grill-me | local-2026-10-28 | superseded | 1266d8868aafe4568befeb6ef64ef97dd0282cdb306ec9d407e15ae8240b029a | design-interview.md | 2026-10-28T17:58:33+08:00 | 2026-10-28T18:06:33+08:00 | 0 | 0 | 0 |
| C-04 | design-interview | plan | 无 | grill-me | local-2026-10-28 | superseded | ebb12555c1104655bef6b460f056b1d5652b653e295f5c08b317f57b7eca8bb0 | design-interview.md | 2026-10-28T18:06:33+08:00 | 2026-10-28T18:08:18+08:00 | 0 | 0 | 0 |
| C-05 | plan-review | plan | 无 | iteration-plan-review | capability-gates-v2 | superseded | ebb12555c1104655bef6b460f056b1d5652b653e295f5c08b317f57b7eca8bb0 | evidence/analysis/stage-review.md | 2026-10-28T18:08:18+08:00 | 2026-10-28T18:08:49+08:00 | 0 | 0 | 0 |
| C-06 | design-interview | plan | 无 | grill-me | local-2026-10-28 | superseded | 31089edd5a6f6b3d58d319650010205921e715f333523ed478da08f23136c68e | design-interview.md | 2026-10-28T18:10:30+08:00 | 2026-10-28T18:20:11+08:00 | 0 | 0 | 0 |
| C-07 | plan-review | plan | 无 | iteration-plan-review | capability-gates-v2 | superseded | 31089edd5a6f6b3d58d319650010205921e715f333523ed478da08f23136c68e | evidence/analysis/stage-review.md | 2026-10-28T18:11:33+08:00 | 2026-10-28T18:11:33+08:00 | 0 | 0 | 0 |
| C-08 | design-interview | plan | 无 | grill-me | local-2026-10-28 | superseded | 31089edd5a6f6b3d58d319650010205921e715f333523ed478da08f23136c68e | design-interview.md | 2026-10-28T18:20:11+08:00 | 2026-10-28T18:23:04+08:00 | 0 | 0 | 0 |
| C-09 | implementation-guard | implement | T-01 | iteration-implementation-guard | capability-gates-v2 | superseded | 1ff9f468f6a56d3feb26249a7ee50fda0bb0d946e5f0a5b3c74c02ade94f10cb | evidence/reviews/T-01.md | 2026-10-28T18:38:26+08:00 | 2026-10-28T18:38:26+08:00 | 0 | 0 | 0 |
| C-10 | design-interview | specify | 无 | grill-me | local-2026-10-28 | passed | df4f1bf612186168fb0f8cf5032d34b4678dbef45cb4a3ad4811999a0e8c063c | design-interview.md | 2026-10-28T18:54:31+08:00 | 2026-10-28T19:02:20+08:00 | 0 | 0 | 0 |
| C-11 | requirements-review | specify | 无 | iteration-requirements-review | capability-gates-v2 | passed | df4f1bf612186168fb0f8cf5032d34b4678dbef45cb4a3ad4811999a0e8c063c | evidence/analysis/stage-review.md | 2026-10-28T19:02:20+08:00 | 2026-10-28T19:02:20+08:00 | 0 | 0 | 0 |
| C-12 | design-interview | plan | 无 | grill-me | local-2026-10-28 | passed | 1cf0067247e5bf9e6271af203f30f3957f5cf1c4f2f3c41e12e6e77254adbda1 | design-interview.md | 2026-10-28T19:07:11+08:00 | 2026-10-28T19:09:37+08:00 | 0 | 0 | 0 |
| C-13 | plan-review | plan | 无 | iteration-plan-review | capability-gates-v2 | passed | 1cf0067247e5bf9e6271af203f30f3957f5cf1c4f2f3c41e12e6e77254adbda1 | evidence/analysis/stage-review.md | 2026-10-28T19:09:37+08:00 | 2026-10-28T19:09:37+08:00 | 0 | 0 | 0 |
| C-14 | implementation-guard | implement | T-01 | iteration-implementation-guard | capability-gates-v2 | passed | 2c7b31004b4c588cc5293509cda7df3cb1887a5944f7a153c8853c9519177c0a | evidence/reviews/T-01.md | 2026-10-28T19:19:20+08:00 | 2026-10-28T19:19:20+08:00 | 0 | 0 | 0 |
| C-15 | code-review | implement | 无 | code-review-skill | local-2026-10-28 | passed | 1cf0067247e5bf9e6271af203f30f3957f5cf1c4f2f3c41e12e6e77254adbda1 | evidence/reviews/implementation-review.md | 2026-10-28T19:26:02+08:00 | 2026-10-28T19:29:49+08:00 | 0 | 0 | 0 |
| C-16 | test-verification | verify | 无 | iteration-test-verification | capability-gates-v2 | failed | dab74e6ad7840d40435867b072accb764ca17e3c21a0396c57224ba757115e97 | evidence/delivery/final-review.md | 2026-10-28T19:38:33+08:00 | 2026-10-28T19:44:00+08:00 | 0 | 0 | 0 |
| C-17 | design-interview | specify | 无 | grill-me | local-2026-10-29 | passed | b26d460aa8a1a3de17ce95a04aa3bb83c80b153066ad0dbf17552d5715cbf439 | design-interview.md | 2026-10-29T10:53:39+08:00 | 2026-10-29T10:53:39+08:00 | 0 | 0 | 0 |
| C-18 | requirements-review | specify | 无 | iteration-requirements-review | capability-gates-v2 | passed | b26d460aa8a1a3de17ce95a04aa3bb83c80b153066ad0dbf17552d5715cbf439 | evidence/analysis/stage-review.md | 2026-10-29T10:54:44+08:00 | 2026-10-29T10:54:44+08:00 | 0 | 0 | 0 |
| C-19 | design-interview | plan | 无 | grill-me | local-2026-10-29 | passed | 39ffc75149e10f74262978ce5b4cf75291c666d70a83452580e9ea730a0fa494 | design-interview.md | 2026-10-29T10:58:17+08:00 | 2026-10-29T10:59:53+08:00 | 0 | 0 | 0 |
| C-20 | plan-review | plan | 无 | iteration-plan-review | capability-gates-v2 | passed | 39ffc75149e10f74262978ce5b4cf75291c666d70a83452580e9ea730a0fa494 | evidence/analysis/stage-review.md | 2026-10-29T11:00:16+08:00 | 2026-10-29T11:00:16+08:00 | 0 | 0 | 0 |
| C-21 | implementation-guard | implement | T-01 | iteration-implementation-guard | task-guard-digest-v2 | passed | 7a755024d13b1a4d3caee5d7825e9546b49949bdf3800dddf75def6d0a20e65a | evidence/reviews/T-01.md | 2026-10-29T11:02:35+08:00 | 2026-10-29T11:02:35+08:00 | 0 | 0 | 0 |
| C-22 | code-review | implement | T-01 | code-review-skill | local-2026-10-29 | failed | 7a755024d13b1a4d3caee5d7825e9546b49949bdf3800dddf75def6d0a20e65a | evidence/reviews/implementation-review.md | 2026-10-29T11:03:37+08:00 | 2026-10-29T11:04:01+08:00 | 0 | 0 | 1 |
| C-23 | code-review | implement | T-01 | code-review-skill | local-2026-10-29 | passed | 7a755024d13b1a4d3caee5d7825e9546b49949bdf3800dddf75def6d0a20e65a | evidence/reviews/implementation-review.md | 2026-10-29T11:04:01+08:00 | 2026-10-29T11:06:06+08:00 | 0 | 0 | 0 |
| C-24 | test-verification | verify | 无 | iteration-test-verification | capability-gates-v2 | passed | b7d304be66bb276adc7648068041773a706ae3a6ad3d7e6eafc22d8b04704222 | evidence/delivery/final-review.md | 2026-10-29T11:07:58+08:00 | 2026-10-29T11:20:09+08:00 | 0 | 0 | 0 |
| C-25 | delivery-review | verify | 无 | iteration-delivery-review | capability-gates-v2 | passed | b7d304be66bb276adc7648068041773a706ae3a6ad3d7e6eafc22d8b04704222 | evidence/delivery/final-review.md | 2026-10-29T11:23:40+08:00 | 2026-10-29T11:24:33+08:00 | 0 | 0 | 0 |
