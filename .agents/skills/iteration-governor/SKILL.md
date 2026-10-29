---
name: iteration-governor
description: Restore and orchestrate one AI iteration from its durable status, approvals, capability registry, and evidence without bypassing user gates.
---

# Iteration Governor

Use this skill when opening, resuming, or advancing an iteration managed by this framework.

1. Read the applicable `AGENTS.md` and root `capabilities.yml`. On every user turn, pass the complete current message as one shell-safe escaped argument to `scripts/iteration-context.rb <iteration> --intent SAFE_USER_MESSAGE`; never concatenate unescaped user text into a shell command. Follow `intent_route`, and use `read_next` to load only the current stage's required documents and evidence. Never ask the user to restate an intent that the route already recognized. The one-argument form remains available for read-only recovery without a current message.
2. Treat `status.md` as the only dynamic progress source. Capability and approval files are evidence, not competing phase pointers.
3. Enforce the status `workflow_profile`: lite only for all-no complexity, standard for ordinary product code without high-risk conditions, and strict for high-risk or uncertain work. Select only the capability required for the current stage and task.
4. During implementation, run a guard before each task but do not repeat full checks or code review after that task. Before first verification require one consolidated `task=无` review. After verification rework, accept a later `task=T-xx` incremental review when it follows that task's guard and binds its digest; do not invalidate the unchanged review base.
5. During verification, choose depth from each task's `T0`-`T4` risk row and width from its affected scope. Reuse evidence only when code, dependencies, configuration, and generated inputs are unchanged. Require applicable AC/TC and bounded `SR-xx` checks without broadening to unrelated system-wide testing.
6. Interpret explicit equivalent natural language without requiring a fixed phrase. A joint request such as “自动审批需求和计划” may supply evidence for both logical approvals, but record each only after its own documents and review are ready. “完成所有任务” authorizes only the remaining implementation tasks and the consolidated code review, then stops at `verify / blocked`. “开始验收” authorizes risk-based verification and then stops again for closure approval. Only explicit combined wording such as “验收并收口” may continue through delivery review to `done`. These expressions never authorize commits, pushes, merges, pulls, deployments, migrations, service starts, or external writes. Generic continuation, questions, conditions, and negative statements grant nothing beyond their explicit meaning.
7. Require fresh evidence before crossing a gate. A statement that a skill was used is not evidence.
8. When blocked on design questions, display every `Qxx` question in full together with its recommendation, impact or alternatives, and a directly copyable reply. Keep it pending until the user answers, preserve the user message as confirmation evidence, and never let a bare question ID or an inferred answer cross an approval gate.
9. For other blockers, update the durable checkpoint and give the user one exact next action. When no user action is needed, continue and say so.

The governor may coordinate work, but it never approves requirements or plans and never broadens the user's authorization.
