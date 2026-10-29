# 需求评审证据

- capability: requirements-review
- provider: local-deterministic-review
- provider_version: 2026-10-26
- phase: specify
- task: 无
- input_digest: 0c9d4d9e36451fb283de5d7a9e9182f1d63ad11159cc373f78ac4686117b63d2
- started_at: 2026-10-26T20:41:23+08:00
- completed_at: 2026-10-26T20:41:23+08:00
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

## 只读事实证据

- `public_management` 有 57 张表；其中 1,158 行为 `yn=0`。
- `sys_sub_service` 有 4 个有效服务、3 个删除服务；运行包中有 147 个 `yn=0` 包和 28 个未被有效 activation 的 active/previous 引用的历史包。
- `sys_interface_project` 有 4 个有效项目、30 个删除项目；接口包记录中 168 行指向删除项目。
- 当前五仓排除 migration、构建产物、覆盖率和依赖目录后，23 张历史业务/配置表没有直接 SQL 或 ORM 引用；`sys_sub_service.service_kind` 未被当前 Prisma 模型映射。
- `sys_audit_log` 仍由认证和管理写操作写入，不能仅因审计页面/API 已删除而清表。

## 发现与处置

| 编号 | 优先级 | 发现 | 处置 | 状态 |
|---|---|---|---|---|
| RR-01 | P2 | “删除无用数据”可能误伤有效服务的回滚包。 | D-06 明确保留每个有效环境的 active 与 previous 包，并由 AC-04/TC-05 覆盖。 | resolved |
| RR-02 | P2 | Blob 可能跨包或跨项目共用。 | 需求要求只删除清理后无引用 Blob，AC-03/AC-05 和 TC-04/TC-06 覆盖。 | resolved |
| RR-03 | P2 | 审计页面已删但表仍被运行代码写入。 | D-08 明确保留审计表与数据。 | resolved |
| RR-04 | P2 | 物理删除与默认软删除规则冲突。 | requirements.md 记录为用户本轮明确例外；D-02 固化。 | resolved |

## 完整性结论

- Q1-Q6 均已由用户原话“Q1-Q6 都按推荐做”确认，设计访谈无未决分支。
- 需求、范围、验收、测试及追踪覆盖 Schema、数据、服务包、接口项目、模型同步、备份恢复和运行回归。
- P0: 0；P1: 0；P2-open: 0。
- 本评审不等于需求审批，不授权计划、产品源码、数据库迁移、物理删除、提交、推送或部署。

## R-002 格式返工复核

- input_digest: `9cb6d3ed3ac37a0aa858d1b9ba662c7ae1e772e826c12ab820b3691ba80a278b`
- completed_at: `2026-10-27T11:18:00+08:00`
- result: `passed`

SR 标题由三级改为二级以满足框架索引；需求内容、决策、改动范围、AC/TC 映射及 P0/P1/P2 结论均未变化。P0: 0；P1: 0；P2-open: 0。
