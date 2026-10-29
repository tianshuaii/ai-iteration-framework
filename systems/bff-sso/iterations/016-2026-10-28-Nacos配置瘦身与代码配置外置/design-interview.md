<!-- design-interview-policy: design-tree-v1 -->
# 设计访谈

## requirements/R-001

- status: superseded
- provider: grill-me
- provider_version: local-2026-10-28
- question_protocol: inline-confirmation-v1
- input_digest: 09a24bdffc6257523d4fa015002b067d3b11050453f8442ab62b04c4596fbd32
- started_at: 2026-10-28T14:58:00+08:00
- completed_at: 2026-10-28T14:59:36+08:00
- classification: non-trivial
- classification_reason: 涉及三仓产品代码、Nacos 外部服务、安全敏感配置、部署契约和删除远端键。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: no
- complexity.database_or_migration: no
- complexity.permission_or_security: yes
- complexity.concurrency: no
- complexity.performance: yes
- complexity.multiple_repositories: yes
- complexity.external_service: yes
- complexity.deployment: yes
- complexity.destructive_operation: yes
- complexity.uncertain: yes

### 问答

| 问题 | 推荐答案 | 用户选择 | 状态 | 确认依据 |
|---|---|---|---|---|
| Q1 本轮交付深度 | 完成审计、代码/模板瘦身；远端发布另行授权 | 按推荐做 | resolved | 用户原话：Q1-Q5 都按推荐做 |
| Q2 环境范围 | dev/test 实施，prod 只给清单 | 按推荐做 | resolved | 用户原话：Q1-Q5 都按推荐做 |
| Q3 瘦身原则 | 远端只保留环境差异、敏感值和运维覆盖项 | 按推荐做 | resolved | 用户原话：Q1-Q5 都按推荐做 |
| Q4 敏感配置去向 | 本轮继续放 Nacos，不扩展 Secret Manager | 按推荐做 | resolved | 用户原话：Q1-Q5 都按推荐做 |
| Q5 代码外置边界 | 仅外置高价值安全/性能/环境参数 | 按推荐做 | resolved | 用户原话：Q1-Q5 都按推荐做 |

### 假设与风险

- dev/test 六份真实配置已只读获取键名和跨环境差异，没有保存任何敏感值。
- 删除远端键如果没有代码默认值或 bootstrap 来源会造成启动失败，必须逐键验证并分环境发布。
- test 的 BFF 配置当前缺少平台主密钥和登录响应上限，不能把 dev 启动成功推断为 test 也可启动。

## requirements/R-002

- status: completed
- provider: grill-me
- provider_version: local-2026-10-28
- question_protocol: inline-confirmation-v1
- input_digest: 33662de70dc6d1c2cb4c01c87b347faf2ed75e0203798bcd5c222bd3b0bcba59
- started_at: 2026-10-28T15:17:00+08:00
- completed_at: 2026-10-28T15:22:33+08:00
- classification: non-trivial
- classification_reason: 需求语义未改，仅将风险测试表第一列规范为框架要求的纯任务编号；受保护文档摘要仍必须重新确认。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: no
- complexity.database_or_migration: no
- complexity.permission_or_security: yes
- complexity.concurrency: no
- complexity.performance: yes
- complexity.multiple_repositories: yes
- complexity.external_service: yes
- complexity.deployment: yes
- complexity.destructive_operation: yes
- complexity.uncertain: no

### 问答

| 问题 | 推荐答案 | 用户选择 | 状态 | 确认依据 |
|---|---|---|---|---|
| Q10 风险任务编号格式修正是否保持原需求不变 | 保持不变，只把风险表第一列规范为纯 T-xx | 按推荐做 | resolved | 用户原话：Q10 按推荐做，需求审批通过 |

### 假设与风险

- 修改前后四条任务的档位、理由、影响范围、必跑项、证据复用和升级条件完全一致。
- 需求摘要从 `09a24bdffc62` 变为 `33662de70dc6`，旧审批不得继续用于跨阶段。

## plan/P-001

- status: completed
- provider: grill-me
- provider_version: local-2026-10-28
- question_protocol: inline-confirmation-v1
- input_digest: b44f2e132a010df404d9dc0d5b79b069e177255e077ade040d90573d4d865764
- started_at: 2026-10-28T15:15:50+08:00
- completed_at: 2026-10-28T15:24:22+08:00
- classification: non-trivial
- classification_reason: 涉及三仓实施顺序、认证安全参数、Nacos 外部删键、服务启停与不可事务化发布。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: no
- complexity.database_or_migration: no
- complexity.permission_or_security: yes
- complexity.concurrency: no
- complexity.performance: yes
- complexity.multiple_repositories: yes
- complexity.external_service: yes
- complexity.deployment: yes
- complexity.destructive_operation: yes
- complexity.uncertain: no

### 问答

| 问题 | 推荐答案 | 用户选择 | 状态 | 确认依据 |
|---|---|---|---|---|
| Q6 服务身份瘦身边界 | 按语义而非名称合并，只删除同义同值项 | 按推荐做 | resolved | 用户原话：Q6-Q9 都按推荐做 |
| Q7 Nacos 发布批次 | test 三端全量成功后再进入 dev，顺序 SSO→Admin→BFF | 按推荐做 | resolved | 用户原话：Q6-Q9 都按推荐做 |
| Q8 未获外部授权时的终态 | 完成 T-01～T-03 后保持阻塞，不把迭代标 done | 按推荐做 | resolved | 用户原话：Q6-Q9 都按推荐做 |
| Q9 真实运行验收深度 | test 做三端真实启动，dev 做读回与配置解析；启停另行授权 | 按推荐做 | resolved | 用户原话：Q6-Q9 都按推荐做 |

### 假设与风险

- BFF 的 `SERVICE_NAME` 与 `NACOS_SERVICE_NAME` 默认语义和值并不相同，不能机械压成一个键。
- 六个 Data ID 不能事务化同时发布，批次和停止点必须由计划明确。
- Nacos 写入与本地服务启停都需要单独授权；计划审批本身不包含这些权限。
