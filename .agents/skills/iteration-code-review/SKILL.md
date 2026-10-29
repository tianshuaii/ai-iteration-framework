---
name: iteration-code-review
description: Perform the framework fallback iteration-level code review after all implementation tasks are complete when code-review-skill is unavailable.
---

# Iteration Code Review

Use this only as the registered fallback for the `code-review` capability.

Before the first verification, use this once after every implementation task is checked and `current_task` has become `无`. Do not run a full review after each task. If verification later creates a repair task and a valid `task=无` review base already exists, review only that task's actual diff and one-hop affected call chain.

Collect and deduplicate the check commands from all tasks, run them, then review the iteration's complete actual diff against requirements, decisions, change scope, all task files, and acceptance criteria. Inspect correctness, edge cases, security, permissions, concurrency, performance, error handling, compatibility, maintainability, comments, and test quality. Use formatters and linters for mechanical formatting rather than subjective comments.

Classify findings as P0, P1, P2, or P3. P0/P1 must be fixed. P2 must be fixed or receive an explicit disposition. P3 is optional but remains recorded. After fixes, review the changed diff again and rerun affected checks.

Write the checks, review, fixes, dispositions, and reruns to `evidence/reviews/implementation-review.md`. The first review adds `task=无`; a later repair adds `task=T-xx` after its implementation guard and binds the task digest. Do not rerun or rereview unchanged repositories merely to refresh timestamps, and do not enter `verify` from an unverified narrative claim.
