<!-- design-interview-policy: design-tree-v1 -->
# 设计访谈

本文件持久保存需求和计划阶段的设计树访谈。事实由 Agent 使用只读源码、文档或 MCP 查询；用户只决定方案。历史尝试不得删除，输入摘要变化后把旧尝试标记为 `superseded` 并追加新尝试。

复杂度字段只使用 `yes`、`no` 或 `unknown`。任一字段为 `yes` 或 `unknown` 时按 `non-trivial`。`lite` 只有全部为 `no` 才能跳过两阶段访谈；`standard` 的非简单需求必须访谈，计划阶段可用计划评审代替第二次访谈；`strict` 的非简单需求和计划都必须访谈。

## requirements/R-001

- status: completed
- provider: grill-me
- provider_version: local-skill
- question_protocol: inline-confirmation-v1
- input_digest: cefa6a8fa3cfb9058bba85920ace075948f8fa2d3dfd7530f431711e1ba9208d
- started_at: 2026-10-28T11:36:00+08:00
- completed_at: 2026-10-28T11:43:00+08:00
- classification: non-trivial
- classification_reason: 要排查并可能修复鉴权转发，涉及安全权限、外部上游、多仓责任分界和不确定缺陷面，按严格档。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: unknown
- complexity.database_or_migration: no
- complexity.permission_or_security: yes
- complexity.concurrency: no
- complexity.performance: no
- complexity.multiple_repositories: yes
- complexity.external_service: yes
- complexity.deployment: no
- complexity.destructive_operation: no
- complexity.uncertain: yes

### 问答

| 问题 | 推荐答案 | 用户选择 | 状态 | 确认依据 |
|---|---|---|---|---|
| Q1 本轮排查的主链路要包到哪一段？ | 以「调用方 → BFF HTTP 直通 → MergeX 管理端」为主。必须覆盖四种状态：登录前、登录时、登录后、登录失效。每种都看实际发出去的头和正文。先不扩到 gRPC `/proxy/one` 和账号权限后台，除非断点在那里。 | 主链路按推荐，并必须覆盖登录前、登录时、登录后、登录失效四种转发 | resolved | 用户原话：要考虑登陆前，登录时，登录后，登录失效这些情况下的转发 |
| Q2 发现 `mergex-manager` 侧缺陷时怎么处理？ | 本轮只记清单，不改那边代码；责任侧确认后马上在 `mergex-manager` 系统新开一轮承接，不必等本轮全部查完。 | 按推荐做 | resolved | 用户原话：Q2 按推荐做。Q3 按推荐做 |
| Q3 本轮从哪里起查？ | 先对照 002 契约，按登录前 / 登录时 / 登录后 / 登录失效四段做只读审计；有具体失败请求就优先当第一案。没有故障单也不挡审计。 | 按推荐做 | resolved | 用户原话：Q2 按推荐做。Q3 按推荐做 |

### 假设与风险

- 已核对：BFF HTTP 直通非白名单只注入平台密钥和用户编号，不转发调用方 token；这与 002「BFF 调用不带 token」一致。
- 已核对：`mergex-manager` 002 已 `done`，密钥在管理端常量类；两边密钥不一致会表现为管理端拒识，需归类后分仓处理。
- 设计树已收敛：主链路四段状态、分仓节奏、起查方式都已确认。没有开放分支。

## plan/P-001

- status: completed
- provider: grill-me
- provider_version: local-skill
- question_protocol: inline-confirmation-v1
- input_digest: 96b1e18cc4cfb4acda7fa9a11cc051601b0080b84a3966307f945f3ec5894806
- started_at: 2026-10-28T11:42:00+08:00
- completed_at: 2026-10-28T11:47:33+08:00
- classification: non-trivial
- classification_reason: 严格档计划必须访谈。实现会碰鉴权转发，审计后才知道具体改点。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: unknown
- complexity.database_or_migration: no
- complexity.permission_or_security: yes
- complexity.concurrency: no
- complexity.performance: no
- complexity.multiple_repositories: yes
- complexity.external_service: yes
- complexity.deployment: no
- complexity.destructive_operation: no
- complexity.uncertain: yes

### 问答

| 问题 | 推荐答案 | 用户选择 | 状态 | 确认依据 |
|---|---|---|---|---|
| Q1 是不是先只读审计出缺陷清单，再改代码？ | 是。T-01 只写审计和清单，不改产品文件；T-02 再按清单修 `bff-sso`。 | 按推荐做 | resolved | 用户原话：Q1 按推荐做。Q2 按推荐做。Q3 按推荐做 |
| Q2 如果审计后没有 `bff-sso` 缺陷，本轮怎么收？ | T-02 只留下“确认无 BFF 缺陷”的证据，不空改代码；有 MergeX 缺陷仍走 T-03 开对端轮。本轮可以在分仓和证据齐全后收口。 | 按推荐做 | resolved | 用户原话：Q1 按推荐做。Q2 按推荐做。Q3 按推荐做 |
| Q3 计划默认只预留 `adx-bff-backend` 共享检出，够不够？ | 够。先只预留这个仓。审计证明断点在别的 bff-sso 仓时，再补计划预留并重批计划。 | 按推荐做 | resolved | 用户原话：Q1 按推荐做。Q2 按推荐做。Q3 按推荐做 |

### 假设与风险

- 001～014 都已 done，没有别的实现/验收轮占用 `adx-bff-backend`。
- 真实目录当前是 `main`，工作区仅有未跟踪的 `CODE_REVIEW.md`，不挡共享检出。
- 设计树已收敛：先审计后修复、无 BFF 缺陷时只留确认证据、默认只预留 `adx-bff-backend`。没有开放分支。
