<!-- design-interview-policy: design-tree-v1 -->
# 设计访谈

本文件持久保存需求和计划阶段的设计树访谈。事实由 Agent 使用只读源码、文档或 MCP 查询；用户只决定方案。历史尝试不得删除，输入摘要变化后把旧尝试标记为 `superseded` 并追加新尝试。

复杂度字段只使用 `yes`、`no` 或 `unknown`。任一字段为 `yes` 或 `unknown` 时按 `non-trivial`。`lite` 只有全部为 `no` 才能跳过两阶段访谈；`standard` 的非简单需求必须访谈，计划阶段可用计划评审代替第二次访谈；`strict` 的非简单需求和计划都必须访谈。

## requirements/R-001

- status: pending
- provider: skill/grill-me
- provider_version: local-2026-10-29
- question_protocol: inline-confirmation-v1
- input_digest: 6dcb2cca4cff75090dae90ece1834781c6de0cccc30b82ff0b693d45078a1afe
- started_at: 2026-10-29T11:32:11+08:00
- completed_at: 无
- classification: non-trivial
- classification_reason: 涉及登录接口、数据库可空迁移、身份与权限、不对称加密、防重放及五仓契约同步。
- unresolved_count: 3
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: yes
- complexity.permission_or_security: yes
- complexity.concurrency: yes
- complexity.performance: no
- complexity.multiple_repositories: yes
- complexity.external_service: yes
- complexity.deployment: no
- complexity.destructive_operation: no
- complexity.uncertain: yes

### 问答

| 问题 | 推荐答案 | 用户选择 | 状态 | 确认依据 |
|---|---|---|---|---|
| Q1 平台登录配置与渠道字段 | 登录配置成组为空；渠道字段用 `accessPlatformId`；已有自有登录接口的平台拒绝 BFF 原生登录 | 按推荐做 | resolved | 用户原话：`Q1-Q5 都按推荐做` |
| Q2 无登录接口平台的 Session 与账号绑定 | Session 只保存 `accessPlatformId`，不保存 `platformAccountId`，不要求平台账号绑定 | 按推荐做 | resolved | 用户原话：`Q1-Q5 都按推荐做` |
| Q3 加密登录覆盖范围与兼容策略 | 两个 BFF 登录接口和两个管理端前端同步硬切密文协议，不保留明文兼容 | 按推荐做 | resolved | 用户原话：`Q1-Q5 都按推荐做` |
| Q4 私钥归属与算法 | 私钥仅在 SSO；BFF 透传；使用 `RSA-OAEP-256` | 按推荐做 | resolved | 用户原话：`Q1-Q5 都按推荐做` |
| Q5 防重放、密钥保存与轮换 | 载荷带时间戳和 nonce；2 分钟窗口、Redis 单次 nonce；Nacos/进程密钥环按 keyId 轮换，旧钥匙宽限 10 分钟 | 按推荐做 | resolved | 用户原话：`Q1-Q5 都按推荐做` |
| Q6 加密信封与长度边界 | `encryptedPassword` 使用版本化混合加密信封：RSA-OAEP-256 包装随机 AES-256 密钥，AES-GCM 加密载荷 | 待确认 | pending | 无 |
| Q7 Redis 故障与多实例一致性 | nonce 使用 Redis `SET NX EX` 原子占位；Redis 不可用时登录失败关闭；所有 SSO 实例共享密钥环和 nonce 命名空间 | 待确认 | pending | 无 |
| Q8 公钥获取、缓存与重试 | BFF 暴露统一匿名公钥接口并从 SSO 获取；响应 `no-store`；前端每次提交前获取，密钥过期只自动刷新并重试一次 | 待确认 | pending | 无 |

### 假设与风险

- 单纯 RSA 加密不提供防重放能力；若不加入 nonce 与时效，截获的密文可以重复提交。
- 不对称加密不能替代 HTTPS，仍需 TLS 防止公钥替换、接口元数据篡改和流量观察。
- 若保留明文兼容字段，攻击者可主动降级，因此推荐硬切新协议。
- 私钥若放在 BFF，会让 BFF 和 SSO 两个进程都接触明文密码；推荐只在 SSO 解密。
- Q1～Q5 已由用户原话 `Q1-Q5 都按推荐做` 确认。
- 纯 RSA-OAEP 对载荷长度有限制；版本化混合加密信封可避免密码长度和后续字段扩展受密钥位数限制。
- Redis 防重放若故障时放行，会让安全保证静默失效；推荐失败关闭。

## plan/P-001

- status: pending
- provider: 无
- provider_version: 无
- question_protocol: inline-confirmation-v1
- input_digest: 无
- started_at: 无
- completed_at: 无
- classification: pending
- classification_reason: 需求访谈尚未完成。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: yes
- complexity.permission_or_security: yes
- complexity.concurrency: yes
- complexity.performance: no
- complexity.multiple_repositories: yes
- complexity.external_service: yes
- complexity.deployment: no
- complexity.destructive_operation: no
- complexity.uncertain: yes

### 问答

| 问题 | 推荐答案 | 用户选择 | 状态 | 确认依据 |
|---|---|---|---|---|

### 假设与风险

- 等需求确认后再展开计划阶段设计树。
