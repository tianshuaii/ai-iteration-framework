# 需求评审证据

- capability: requirements-review
- provider: local-deterministic-review
- provider_version: 2026-10-27
- phase: specify
- task: 无
- input_digest: 67ddb28488cd524d5d6d5a67d01e7c86c19325f3a6e17cd16a2f123ac64379a0
- started_at: 2026-10-27T11:49:31+08:00
- completed_at: 2026-10-27T11:49:31+08:00
- result: passed

## 评审范围

- `requirements.md`
- `decisions.md`
- `change-scope.md`
- `acceptance.md`
- `test-strategy.md`
- `test-cases.md`
- `traceability.md`
- `design-interview.md`

## 发现与处置

| 编号 | 优先级 | 发现 | 处置 | 状态 |
|---|---|---|---|---|
| RR-01 | P2 | BFF 账号禁用或软删除后，旧绑定状态和新增绑定边界原先未确定。 | 用户确认 Q7；D-11、AC-06、TC-08 和追踪表统一为保留旧绑定、展示失效、禁止新增绑定且不阻止原账号操作。 | resolved |
| RR-02 | P2 | 登录接口在运行包替换后可能失效，若自动删除会丢失历史关系。 | D-09、AC-06 和 TC-08 要求保留平台与旧绑定、展示失效并阻止新增绑定。 | resolved |
| RR-03 | P2 | 两组绑定基数只靠应用层先查后写会被并发绕过。 | D-01、D-02、AC-05 和 TC-07 要求数据库唯一约束与服务端校验共同保证。 | resolved |
| RR-04 | P2 | 治理表迁移若分散到多个仓库会产生漂移。 | requirements、change-scope 和 AC-08 固定只由 `adx-admin-backend` 执行迁移，BFF 仅同步模型。 | resolved |

## 完整性结论

- Q1-Q7 均有用户原话确认，需求访谈无未决分支。
- 三个目标仓库和两个明确不动仓库边界清楚；本轮不实际调用外部登录接口，不保存平台凭据。
- AC-01 至 AC-08、TC-01 至 TC-10、SR-01 至 SR-02 与追踪表覆盖页面、接口、Schema、权限、唯一性、失效状态和相邻回归。
- T-01、T-02 为 T4，T-03 为 T3，与迁移、并发一致性、权限和前端联动风险匹配。
- P0: 0；P1: 0；P2-open: 0。
- 本评审不等于需求审批，不授权计划、产品源码、数据库迁移、服务操作、提交、推送或部署。
