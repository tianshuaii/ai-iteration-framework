<!-- design-interview-policy: design-tree-v1 -->
# 设计访谈

本文件持久保存需求和计划阶段的设计树访谈。事实由 Agent 使用只读源码、文档或 MCP 查询；用户只决定方案。历史尝试不得删除，输入摘要变化后把旧尝试标记为 `superseded` 并追加新尝试。

## requirements/R-001

- status: completed
- provider: grill-me
- provider_version: local-skill
- question_protocol: inline-confirmation-v1
- input_digest: 2b205ea4b620899b89cc66c8dff4e22e7501ee8715f45d59e89db2a3d8c234a1
- started_at: 2026-10-27T14:47:30+08:00
- completed_at: 2026-10-27T14:52:17+08:00
- classification: non-trivial
- classification_reason: 登录接管同时改变接口、数据库密钥、Session、安全头与多仓契约，属于认证安全和迁移高风险需求。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: yes
- complexity.permission_or_security: yes
- complexity.concurrency: yes
- complexity.performance: yes
- complexity.multiple_repositories: yes
- complexity.external_service: yes
- complexity.deployment: yes
- complexity.destructive_operation: no
- complexity.uncertain: yes

### 问答

| 问题 | 推荐答案 | 用户选择 | 状态 | 确认依据 |
|---|---|---|---|---|
| Q1 平台登录接口唯一识别：当前入站只有 publicPath、HTTP 方法和路径，没有平台 ID；若两个有效平台选同一登录接口，BFF 应怎样决定平台？ | 对有效平台增加“登录子服务 + 登录接口稳定键”唯一约束；创建/编辑冲突直接拒绝，不在请求时猜第一条。 | 按推荐做 | resolved | 用户原话：`Q1-Q5 都按推荐做` |
| Q2 请求密钥保存与编辑：密钥必须能被 BFF 取出转发，如何兼顾安全和已有平台？ | 使用独立主密钥加密后入库；新建非空必填且保持原字符串，API/列表/日志永不返回明文；编辑留空表示保持，输入新值表示替换；已有平台保持可查询但补录前不能登录接管或发送身份头。 | 按推荐做 | resolved | 用户原话：`Q1-Q5 都按推荐做` |
| Q3 登录接口免会话：平台登录调用发生在 BFF Session 之前，是否自动视为登录例外？ | 已配置的平台登录接口独立于普通白名单免 BFF Session，但仍必须属于当前生效 HTTP 包；普通白名单规则不被改写。 | 按推荐做 | resolved | 用户原话：`Q1-Q5 都按推荐做` |
| Q4 上游成功体与账号不存在：`code=200` 但 `data.userId` 异常、无绑定或 BFF 账号失效时怎样返回？ | `userId` 接受非空 string 或有限 number 并转字符串；缺失/非法结构返回 `50201`“上游登录响应缺少有效 userId”；无绑定或绑定账号失效统一返回 `40401`“该账户不存在”，都不创建 Session。 | 按推荐做 | resolved | 用户原话：`Q1-Q5 都按推荐做` |
| Q5 旧 Session 兼容：现有 BFF Portal/Admin Session 没有平台上下文，无法提供两项平台身份头，应怎样处理非白名单 HTTP 直通？ | 非白名单 HTTP 直通只接受平台登录生成的 Portal Session；原 API 路径 /api/portal/auth/login 和 Admin 登录继续服务其他现有接口，但其 Token 调用该直通路径时明确拒绝，避免猜平台或漏发身份头。 | 按推荐做 | resolved | 用户原话：`Q1-Q5 都按推荐做` |

### 假设与风险

- 平台识别不唯一会导致密钥和账号跨平台，必须在实现前确定唯一性策略。
- 密钥若明文回显或进入 Session/日志会扩大泄露面；若加密主密钥缺失则服务应启动或保存失败，不得代码兜底。
- 登录成功分支需要解析响应体；普通转发必须保持流式，避免大文件和慢响应内存回归。
- Session 身份模型变化会使旧 Session 不具备平台上下文，兼容策略直接影响现有 Portal/Admin 用户。
- Q1-Q5 已由用户原话确认，需求设计树无未决分支。

## plan/P-001

- status: completed
- provider: grill-me
- provider_version: local-skill
- question_protocol: inline-confirmation-v1
- input_digest: fc789ded42f57e85cf3de37a1e61479104f3bd0b4d723b65ce65ba33bd0ef5ce
- started_at: 2026-10-27T15:00:00+08:00
- completed_at: 2026-10-27T15:05:29+08:00
- classification: non-trivial
- classification_reason: 计划涉及加密主密钥、响应缓冲边界、认证 Session、数据库约束和三仓 dirty 基线，必须锁定部署与资源上限。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: yes
- complexity.permission_or_security: yes
- complexity.concurrency: yes
- complexity.performance: yes
- complexity.multiple_repositories: yes
- complexity.external_service: yes
- complexity.deployment: yes
- complexity.destructive_operation: no
- complexity.uncertain: yes

### 问答

| 问题 | 推荐答案 | 用户选择 | 状态 | 确认依据 |
|---|---|---|---|---|
| Q6 密钥加密配置与主密钥轮换边界：请求密钥已确定加密入库，本轮应怎样定义加密算法、主密钥格式和主密钥变更行为？ | 使用 AES-256-GCM；部署必须提供严格 32 字节 Base64 主密钥且不允许代码默认值；密文使用带版本的信封保存 IV、认证标签和密文。本轮不做在线主密钥轮换，变更主密钥前必须先以单独授权的维护流程重加密；密钥不匹配时失败关闭。 | 按推荐做 | resolved | 用户原话：`Q6-Q7 都按推荐做` |
| Q7 登录响应缓冲上限：只有平台登录成功分支需要读取 JSON，本轮怎样限制响应体，避免大响应拖垮 BFF？ | 新增必填配置 `PLATFORM_LOGIN_RESPONSE_MAX_BYTES`，所有实例显式配置，建议验收值 1048576（1 MiB）；仅平台登录响应受限，超过上限返回稳定 `50201` 且不创建 Session，普通接口继续流式转发。 | 按推荐做 | resolved | 用户原话：`Q6-Q7 都按推荐做` |

### 假设与风险

- 加密主密钥没有安全格式和认证加密会让密文可篡改，错误轮换会使所有平台密钥不可读。
- 登录响应无界缓冲会把单个异常上游响应放大为 BFF 内存风险；全局缓冲则会破坏普通下载和流式接口。
- 三个真实仓库保留第 011 轮未提交改动，本轮必须以它们为接管前基线追加，不能覆盖或误回退。
- Q6-Q7 已由用户原话确认，计划设计树无未决分支。
