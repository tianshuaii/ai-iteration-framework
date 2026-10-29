---
name: iteration-requirements-review
description: Review an iteration specification for completeness, scope, acceptance, testing, decisions, and traceability before requirement approval.
---

# Iteration Requirements Review

Review the current requirement-stage documents without editing product repositories.

Check that the background, desired behavior, exclusions, compatibility, data handling, permissions, change scope, acceptance criteria, test strategy, test cases, and traceability agree with each other. Resolve factual questions through read-only inspection. Return decision questions to the design interview instead of silently choosing for the user.

Write or replace the requirements section in `evidence/analysis/stage-review.md`. Record findings with P0-P3 severity, affected documents, required correction, and final disposition. Preserve any plan section already present. Then add a fresh `requirements-review` row to `capability-log.md` using the same protected input digest as the requirement approval.

Passing means no P0/P1 remains and every P2 has a recorded disposition. This review does not approve the requirements.
