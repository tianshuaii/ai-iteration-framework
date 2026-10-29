# 计划范围补充评审证据

- capability: plan-review
- provider: manual-plan-review
- provider_version: 2026-10-26-local
- phase: plan
- task: 无
- input_digest: e9159b5b488e38ad090fd3384910070abfa466aede3d8ba902e2dbe79d0003dd
- started_at: 2026-10-26T16:12:19+08:00
- completed_at: 2026-10-26T16:12:19+08:00
- result: passed

## 评审范围

- `implementation-plan.md` 新增删除启动时旧路由绑定清理与授权缓存刷新。
- `tasks.md` 的 T-04 新增 `src/main.ts` 与 `scripts/run-route-binding-cleanup.ts`。
- 既有 `risks.md`、`workspace.md` 计划预留、需求、决策、验收、测试与迁移边界未改变。
- `design-interview.md` 的 `plan/P-002` 已记录用户明确选择，未决问题为 0。

## 只读事实与影响

- `src/main.ts` 在数据库连接后调用 `GovernanceService.repairInvalidRouteBindings()`，随后刷新已经删除的 Portal 路由/权限缓存。
- `scripts/run-route-binding-cleanup.ts` 直接导入本轮已删除的 `route-binding-cleanup.util`。
- 保留任一入口都会导致当前构建失败，并在 T-06 删除治理表后形成不可用的运行时访问。
- 删除两处入口是既定“彻底删除非账户治理代码”的必要收口，不新增业务能力、依赖、运行资源或数据库操作。

## 发现与处置

| 编号 | 优先级 | 发现 | 处置 | 状态 |
|---|---|---|---|---|
| PRA-01 | P1 | 原 T-04 文件清单遗漏两个直接依赖已删除治理代码的入口，导致构建失败。 | 补入 T-04 并删除入口/脚本；用户已明确允许并重新批准计划。 | resolved |

## 结论

- P0: 0；P1: 0；P2-open: 0。
- 调整后 T-04 文件范围完整、依赖顺序不变、定向测试命令仍可执行。
- 本评审仅恢复计划门禁，不授权迁移、服务启动、提交、推送或部署。
