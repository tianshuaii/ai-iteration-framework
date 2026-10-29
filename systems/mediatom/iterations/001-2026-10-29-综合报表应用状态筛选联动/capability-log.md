<!-- capability-log-policy: task-guard-digest-v2 -->
# 能力执行记录

- adopted_at: 2026-10-29T15:54:43+08:00
- migration_base_phase: new
- migration_current_task: 无
- migration_task_state: 无
- note: 新轮次从需求阶段启用完整能力门禁。

本文件只保存能力执行索引，不替代 `status.md`。详细证据放在 `evidence/`；每条任务的 implementation guard 使用自己的 `T-xx`，`input_digest` 绑定该任务正文、改动范围及计划检出/资源区，不绑定整轮其他任务。首次全部任务完成后的统一 code-review 使用 `task=无` 并指向 `evidence/reviews/implementation-review.md`；验收返工产生的新任务使用 `task=T-xx` 的增量 code-review，绑定该任务摘要并追加到同一报告。每条记录仍必须有独立能力名、输入摘要、时间和发现计数。

| id | capability | phase | task | provider | provider_version | status | input_digest | evidence | started_at | completed_at | P0 | P1 | P2-open |
|---|---|---|---|---|---|---|---|---|---|---|---:|---:|---:|
| C-001 | design-interview | specify | 无 | skill/iteration-design-interview | local-2026-10-29 | passed | e9067aa64716256497461630ea830db7bcc9fa83b4310a95ddcf8df9791ad4a4 | design-interview.md | 2026-10-29T15:56:00+08:00 | 2026-10-29T17:12:30+08:00 | 0 | 0 | 0 |
| C-002 | requirements-review | specify | 无 | skill/iteration-requirements-review | local-2026-10-29 | passed | e9067aa64716256497461630ea830db7bcc9fa83b4310a95ddcf8df9791ad4a4 | evidence/analysis/stage-review.md | 2026-10-29T17:12:40+08:00 | 2026-10-29T17:13:39+08:00 | 0 | 0 | 0 |
| C-003 | design-interview | plan | 无 | skill/iteration-design-interview | local-2026-10-29 | superseded | 7c881ce1801e4d00de4d167f2b3f9828be0121be8c2bd9a039f9f2b8ab864f44 | design-interview.md | 2026-10-29T17:18:02+08:00 | 2026-10-29T17:21:17+08:00 | 0 | 0 | 0 |
| C-004 | plan-review | plan | 无 | skill/iteration-plan-review | local-2026-10-29 | superseded | 7c881ce1801e4d00de4d167f2b3f9828be0121be8c2bd9a039f9f2b8ab864f44 | evidence/analysis/stage-review.md | 2026-10-29T17:21:17+08:00 | 2026-10-29T17:21:17+08:00 | 0 | 0 | 0 |
| C-005 | design-interview | plan | 无 | skill/iteration-design-interview | local-2026-10-29 | passed | dc8048eefa5b7b84c81bbb5be64e42eceed1e895734212de5d3b437f81a095a4 | design-interview.md | 2026-10-29T17:24:02+08:00 | 2026-10-29T17:24:02+08:00 | 0 | 0 | 0 |
| C-006 | plan-review | plan | 无 | skill/iteration-plan-review | local-2026-10-29 | passed | dc8048eefa5b7b84c81bbb5be64e42eceed1e895734212de5d3b437f81a095a4 | evidence/analysis/stage-review.md | 2026-10-29T17:24:02+08:00 | 2026-10-29T17:24:02+08:00 | 0 | 0 | 0 |
| C-007 | implementation-guard | implement | T-01 | skill/iteration-implementation-guard | local-2026-10-29 | passed | 9c1e2d04e5dc7dd02ca750665ea541b5f8cf0e136cd0a29f1761696de0d9a5f5 | evidence/reviews/T-01.md | 2026-10-29T17:26:58+08:00 | 2026-10-29T17:26:58+08:00 | 0 | 0 | 0 |
| C-008 | implementation-guard | implement | T-02 | skill/iteration-implementation-guard | local-2026-10-29 | passed | 20659a741dcbee86b25f86a75e7c56d877949129453b53bc3a4093007239215b | evidence/reviews/T-02.md | 2026-10-29T17:28:54+08:00 | 2026-10-29T17:28:54+08:00 | 0 | 0 | 0 |
| C-009 | code-review | implement | 无 | skill/iteration-code-review | local-2026-10-29 | passed | dc8048eefa5b7b84c81bbb5be64e42eceed1e895734212de5d3b437f81a095a4 | evidence/reviews/implementation-review.md | 2026-10-29T17:32:00+08:00 | 2026-10-29T17:32:00+08:00 | 0 | 0 | 0 |
| C-010 | requirements-review | specify | 无 | skill/iteration-requirements-review | local-2026-10-29 | passed | e705caf0d584066bcb5c8aee31bf695713e1b7b219b95204a927d71597c1bf73 | evidence/analysis/stage-review.md | 2026-10-29T17:33:50+08:00 | 2026-10-29T17:33:50+08:00 | 0 | 0 | 0 |
| C-011 | test-verification | verify | 无 | skill/iteration-test-verification | local-2026-10-29 | failed | 88e7e01515790f2ed469c4520caed7582a73886c7ac744a436e289372d5ce4f8 | evidence/delivery/final-review.md | 2026-10-29T17:38:49+08:00 | 2026-10-29T17:38:49+08:00 | 0 | 1 | 0 |
| C-012 | requirements-review | specify | 无 | skill/iteration-requirements-review | local-2026-10-29 | passed | 227dd88150767121f73ebf558e50b02f0c6745f3a80a1b3bb13008c16f8a5d53 | evidence/analysis/stage-review.md | 2026-10-29T17:47:54+08:00 | 2026-10-29T17:47:54+08:00 | 0 | 0 | 0 |
| C-013 | design-interview | specify | 无 | skill/iteration-design-interview | local-2026-10-29 | passed | 227dd88150767121f73ebf558e50b02f0c6745f3a80a1b3bb13008c16f8a5d53 | design-interview.md | 2026-10-29T17:44:00+08:00 | 2026-10-29T17:47:54+08:00 | 0 | 0 | 0 |
| C-014 | requirements-review | specify | 无 | skill/iteration-requirements-review | local-2026-10-29 | passed | 036b89034baf90b9eee9fb93f05a609a2ace7a179e86f5f061ebb1a4b17986ae | evidence/analysis/stage-review.md | 2026-10-29T18:50:36+08:00 | 2026-10-29T18:50:36+08:00 | 0 | 0 | 0 |
| C-015 | design-interview | specify | 无 | skill/iteration-design-interview | local-2026-10-29 | passed | 036b89034baf90b9eee9fb93f05a609a2ace7a179e86f5f061ebb1a4b17986ae | design-interview.md | 2026-10-29T18:48:00+08:00 | 2026-10-29T18:50:36+08:00 | 0 | 0 | 0 |
| C-016 | design-interview | plan | 无 | skill/iteration-design-interview | local-2026-10-29 | passed | 8a34f5108fcd29abee35638c9ebdc78b7d4f22fdc4c5df829bd16efcfa2a33cf | design-interview.md | 2026-10-29T18:52:00+08:00 | 2026-10-29T18:53:25+08:00 | 0 | 0 | 0 |
| C-017 | plan-review | plan | 无 | skill/iteration-plan-review | local-2026-10-29 | passed | 8a34f5108fcd29abee35638c9ebdc78b7d4f22fdc4c5df829bd16efcfa2a33cf | evidence/analysis/stage-review.md | 2026-10-29T18:53:25+08:00 | 2026-10-29T18:53:25+08:00 | 0 | 0 | 0 |
| C-018 | implementation-guard | implement | T-01 | skill/iteration-implementation-guard | local-2026-10-29 | passed | 192f798f64a4c391b1a24c181a32ed29a047c12b497ee16496c6179d99a161ab | evidence/reviews/T-01.md | 2026-10-29T18:56:13+08:00 | 2026-10-29T18:56:13+08:00 | 0 | 0 | 0 |
| C-019 | implementation-guard | implement | T-02 | skill/iteration-implementation-guard | local-2026-10-29 | passed | fd73d3584b4b3ea0341a8bb39d613a0631d92fd5175d32fd899c22ed63f8db7d | evidence/reviews/T-02.md | 2026-10-29T19:01:00+08:00 | 2026-10-29T19:01:00+08:00 | 0 | 0 | 0 |
| C-020 | code-review | implement | 无 | skill/iteration-code-review | local-2026-10-29 | passed | 8a34f5108fcd29abee35638c9ebdc78b7d4f22fdc4c5df829bd16efcfa2a33cf | evidence/reviews/implementation-review.md | 2026-10-29T19:02:00+08:00 | 2026-10-29T19:02:00+08:00 | 0 | 0 | 0 |
| C-021 | test-verification | verify | 无 | skill/iteration-test-verification | local-2026-10-29 | failed | 8ac85fb8fd00f6a566bc03663e900eeae1d9441638634daabecfcd05d047fac0 | evidence/delivery/final-review.md | 2026-10-29T19:03:43+08:00 | 2026-10-29T19:03:43+08:00 | 0 | 1 | 0 |
| C-022 | test-verification | verify | 无 | skill/iteration-test-verification | local-2026-10-29 | passed | e1b7f6eb2d56e1bb6b1b4ee9ba484fc6bdb4a4ba7172a90dccf08c0573ee37d3 | evidence/delivery/final-review.md | 2026-10-29T19:32:23+08:00 | 2026-10-29T19:32:23+08:00 | 0 | 0 | 0 |
| C-023 | test-verification | verify | 无 | skill/iteration-test-verification | local-2026-10-29 | passed | c6b9f5a3496a1a083158f98150e4431e3dd79a671db275178bf7251e4df74e46 | evidence/delivery/final-review.md | 2026-10-29T19:37:09+08:00 | 2026-10-29T19:37:09+08:00 | 0 | 0 | 0 |
| C-024 | delivery-review | verify | 无 | skill/iteration-delivery-review | local-2026-10-29 | passed | c6b9f5a3496a1a083158f98150e4431e3dd79a671db275178bf7251e4df74e46 | evidence/delivery/final-review.md | 2026-10-29T19:37:09+08:00 | 2026-10-29T19:37:09+08:00 | 0 | 0 | 0 |
