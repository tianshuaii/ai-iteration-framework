---
name: iteration-design-interview
description: Run the framework fallback design-tree interview before requirement or plan approval when the preferred grill-me skill is unavailable.
---

# Iteration Design Interview

Use this only as the registered fallback for the `design-interview` capability.

Respect the bound iteration's `workflow_profile`. `lite` may skip both stages only when every complexity field is `no`; `standard` requires a non-trivial requirements interview but may skip the plan interview; `strict` requires both non-trivial interviews. A skip still needs a complete complexity checklist, matching input digest, timestamps, provider, reason, and zero unresolved questions.

Build a decision tree and work it in rounds. In each round, ask every currently unblocked decision question, number the questions, and provide a recommended answer. Every user-facing blocking message must repeat each `Qxx` question in full, its recommendation, material alternatives or impact, and a directly copyable reply; never show a bare question ID. Do not ask the user for facts that can be obtained from the repository, documentation, or read-only tools.

Persist each new attempt with `question_protocol: inline-confirmation-v1`. While waiting, use `用户选择=待确认`, `状态=pending`, and `确认依据=无`; set `work_state: blocked`, and make `next_action` contain the full question text plus the recommended reply. Only after a direct user answer may a row become `resolved`; preserve that message as `确认依据=用户原话：...`, update the unresolved count, and then rerun the stage review. Never infer confirmation from a recommendation, an approval phrase, silence, or previous write authorization.

The interview is complete only when no decision remains unresolved. An explicitly accepted assumption or residual risk is a resolved decision. Do not replace the existing requirement or plan approval command with another approval.

If protected input changes, mark the old attempt `superseded`, retain it, and ask only the affected branches again.
