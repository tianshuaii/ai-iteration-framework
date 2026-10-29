---
name: iteration-test-verification
description: Verify an iteration with real commands and acceptance cases, preserving versions, exit codes, failures, reruns, and controlled waivers.
---

# Iteration Test Verification

Use this during `verify` only after all implementation tasks and the single iteration-level implementation review are complete, and only when the current intent route explicitly authorizes verification. `完成所有任务` by itself is not verification authorization.

Select the required checks from each task's `T0`-`T4` risk row, then run the applicable automated checks and formal AC/TC cases against the intended code and environment. Also execute the applicable registered `SR-xx` shallow regression cases. The SR set covers direct functionality and one-hop adjacent functionality; honor its stopping boundary and do not expand into unrelated full-system regression.

Record the command, target repository, timestamp, exit code, tested HEAD or workspace baseline, environment, and observable result. Static inspection or old results do not replace a live check when the plan requires one.

Preserve failures in the rework history. Evidence may be reused only when code, dependencies, configuration, and generated inputs are unchanged, with the prior record and reason documented. After a fix, rerun affected automated checks, AC/TC, and SR cases; keep unrelated evidence instead of rerunning it. A waiver is valid only with explicit user confirmation and a stated residual risk in the relevant test records.

Write or replace the test-verification section in `evidence/delivery/final-review.md`; the delivery review appends its section only after separate closure authorization. Add a fresh `test-verification` row to `capability-log.md`. Do not report pass while a required case is untested or failed. When closure is not jointly authorized, leave the iteration at `verify / blocked`, report the verification result, and wait.
