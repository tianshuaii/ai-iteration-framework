# 需求评审证据

- capability: requirements-review
- provider: iteration-requirements-review
- provider_version: 2026-10-26-local
- phase: specify
- task: 无
- input_digest: f82bbff7b56c70194d29109d2ae9755e8a4268a4b7fefc8a6e6557135d4dd6cb
- started_at: 2026-10-26T14:47:21+08:00
- completed_at: 2026-10-26T14:49:15+08:00
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

- `/Users/mrzater/java/mergex-manager/src/main/java/com/ydmob/mergex/managerserver/common/utils/MD5Util.java`：参考项目使用 16 位数字盐与 32 位 MD5 摘要交织的 48 字符格式，原实现的盐来自 `java.util.Random`。
- `/Users/mrzater/docker/adx/adx-admin-backend/prisma/schema.prisma`：当前 `AccountType` 仍有四类，角色、租户、路由、权限及授权关系仍存在，说明删表必须与调用链重构和数据迁移一起计划。
- `/Users/mrzater/docker/adx/adx-sso-backend/src/auth/auth.service.ts`：当前密码校验仍使用 Argon2，且登录上下文依赖角色。
- `/Users/mrzater/docker/adx/adx-admin-backend/src/gateway/forward-context.service.ts` 与 `/Users/mrzater/docker/adx/adx-bff-backend/src/session/**`：ForwardContext 和 Session 仍承载现有身份与授权字段，不能仅删除 Admin 页面。
- `/Users/mrzater/docker/adx/adx-bff-backend/src/admin/**`：网关治理入口仍有大量角色与租户依赖，需要按账户权威字段收口。

## 发现与处置

| 编号 | 优先级 | 发现 | 影响文档 | 处置 | 状态 |
|---|---|---|---|---|---|
| RR-01 | P2 | `adx-bff-frontend` 范围仍以“若后端不再返回角色”表述，与已经确认的彻底删角色决策不一致。 | `change-scope.md` | 改为确定性范围：后端删除角色返回后，前端改用账户权威字段。 | resolved |
| RR-02 | P2 | 测试策略包含一律禁止物理删除的检查，但本轮已批准删除废弃治理表，命令与需求互相冲突。 | `requirements.md`、`test-strategy.md` | 明确账户记录继续软删除，物理删除仅限获批废弃治理表；用迁移 SQL 定向复核替代该通用禁止检查。 | resolved |
| RR-03 | P2 | 账户表单缺少既定的即时校验、必填星号和标签冒号约束，验收无法覆盖交互一致性。 | `requirements.md`、`change-scope.md`、`acceptance.md`、`test-cases.md` | 补充输入与失焦校验、保留必填星号、关闭标签冒号，并纳入 TC-03。 | resolved |
| RR-04 | P2 | AC-05 同时覆盖改密与旧账户恢复，跟踪表却只映射 TC-09，遗漏 TC-08。 | `traceability.md` | 将该项映射修正为 TC-08、TC-09。 | resolved |

## 完整性结论

- 需求、范围、决策、验收、测试与追踪已覆盖五个产品仓库以及只读参考仓库。
- Q1 至 Q13 均已解决，`unresolved_count` 为 0；没有仍需用户选择的设计树分支。
- P0: 0；P1: 0；P2-open: 0。
- 残余风险：48 字符随机盐 MD5 相比现有 Argon2 属于明确的安全降级；该风险已由 D-05、D-10 记录并由验收覆盖，不在评审中隐去。
- 本评审只证明需求输入完整且可进入审批，不等于需求审批，不授权计划阶段、产品代码修改、数据库迁移、提交或推送。
