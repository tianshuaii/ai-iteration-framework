---
name: iteration-plan-review
description: Review implementation tasks, risks, tests, dependencies, checkout isolation, and runtime reservations before plan approval.
---

# Iteration Plan Review

Review the plan against the approved specification and allowed change scope.

Check task ordering, dependencies, file paths, targeted checks, rollback, risks, test coverage, repository checkout isolation, target branches, exclusive runtime resources, and worktree lifecycle. Confirm that task checks can be deduplicated and run once after all implementation tasks. Require a bounded shallow functional regression plan with at least one direct `SR-xx` item and one one-hop adjacent `SR-xx` item; each needs an impact reason and explicit stopping boundary. Reject an unbounded full-system regression disguised as shallow testing.

Default to the real shared checkout; pre-existing dirty files require a recorded baseline but never justify a worktree. Permit a worktree only when another `implement` or `verify` iteration in the same system records the same repository. A task must not write outside the intersection of `tasks.md` and `change-scope.md`.

Write or replace the plan section in `evidence/analysis/stage-review.md`. Preserve the requirements section, record P0-P3 findings and dispositions, then add a fresh `plan-review` row to `capability-log.md` using the protected plan digest.

Passing means the first task can start without an unresolved scope, dependency, checkout, or exclusive-resource conflict. This review does not approve the plan or authorize product changes.
