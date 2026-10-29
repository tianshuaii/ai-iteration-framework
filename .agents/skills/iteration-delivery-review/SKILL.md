---
name: iteration-delivery-review
description: Review final delivery readiness, evidence, approvals, residual risk, repository synchronization, and temporary worktree cleanup before done.
---

# Iteration Delivery Review

Use this only after test verification is complete and the current user intent explicitly authorizes closure. Verification authorization alone is insufficient.

Confirm that approvals remain current, every implemented task has guard evidence, and one fresh iteration-level code-review record covers the complete implementation diff. P0/P1 must be zero and P2 findings disposed. Confirm that formal acceptance results agree with TC records and that every registered SR shallow regression item has a passed or controlled-waiver result, a justified direct or adjacent scope, and a stopping boundary. Verify that no file outside the approved scope changed.

For an isolated worktree, require the authorized commit, integration, push, real-checkout `git pull --ff-only`, containment verification, and cleanup evidence in the framework-defined order. Do not infer permission for any of those external actions.

Append or replace the delivery-review section in `evidence/delivery/final-review.md`, preserving the test-verification section. Add a fresh `delivery-review` row to `capability-log.md`. Only fresh passing evidence permits `done`.
