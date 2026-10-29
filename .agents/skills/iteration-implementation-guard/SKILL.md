---
name: iteration-implementation-guard
description: Guard the start or resume of one implementation task by checking approvals, scope, repository baseline, isolation, and authorization.
---

# Iteration Implementation Guard

Run this immediately before changing product files for the current task.

Verify that both stage approvals are current, `current_task` exists and is unfinished, dependencies are complete, every writable file is allowed by both the task and change scope, and the product checkout and exclusive runtime resources do not conflict with another active iteration. Record the branch, HEAD, and each pre-existing dirty file before writing. Dirty files alone never justify a worktree; require another `implement` or `verify` iteration in the same system to record the same repository before accepting an independent worktree plan.

Confirm that the current user request authorizes this task's product writes. Approval of a plan is not execution authorization. Explicit “执行当前任务” or equivalent scopes authorization to the current task; explicit “完成所有任务” or equivalent permits each remaining implementation task to proceed through its own guard and the consolidated code review without asking again. It does not authorize verification or closure. None of these expressions grants commit, push, merge, pull, deployment, database migration, service start, or external-write authority.

Write or replace the implementation-guard section in `evidence/reviews/<task-id>.md`. For a `task-guard-digest-v2` capability log, use the bound iteration's `iteration-context.rb` `current_task_digest` as the capability row `input_digest`; it binds only the current task text, change scope, and planned checkout/resource scope. Do not substitute the whole plan approval digest. Do not append a full task review or repeated validation; those are consolidated after all tasks in `evidence/reviews/implementation-review.md`, even if an older task line still asks for per-task review. Add a fresh `implementation-guard` row to `capability-log.md`. Any failed guard blocks the task; do not convert it into a warning.
