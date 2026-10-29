<!-- design-interview-policy: design-tree-v1 -->
# 设计访谈

本文件持久保存需求和计划阶段的设计树访谈。事实由 Agent 使用只读源码、文档或 MCP 查询；用户只决定方案。历史尝试不得删除，输入摘要变化后把旧尝试标记为 `superseded` 并追加新尝试。

复杂度字段只使用 `yes`、`no` 或 `unknown`。任一字段为 `yes` 或 `unknown` 时按 `non-trivial`；只有全部为 `no` 才允许把访谈标为 `skipped`。

## requirements/R-001

- status: superseded
- provider: grill-me
- provider_version: 2026-10-26-local
- input_digest: f82bbff7b56c70194d29109d2ae9755e8a4268a4b7fefc8a6e6557135d4dd6cb
- started_at: 2026-10-26T14:25:27+08:00
- completed_at: 2026-10-26T14:49:15+08:00
- classification: non-trivial
- classification_reason: 涉及五个产品仓库、身份权限、密码安全降级、接口与数据库删除及既有账号失效恢复。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: yes
- complexity.permission_or_security: yes
- complexity.concurrency: no
- complexity.performance: no
- complexity.multiple_repositories: yes
- complexity.external_service: no
- complexity.deployment: unknown
- complexity.destructive_operation: yes
- complexity.uncertain: yes

### 问答

| 问题 | 推荐答案 | 用户选择 | 状态 |
|---|---|---|---|
| Q1 账户单一化的删除深度 | 彻底移除非账户治理模型，但保留并重构登录和 ForwardContext 所需内部合约；Portal 动态授权的替代行为在下一轮问题中细化。 | A：采用推荐方案。 | resolved |
| Q2 密码存库与旧账号过渡 | 新设/改密采用参考项目的 48 字符随机盐 MD5；不复制 RSA 传输层。 | 不兼容现有 Argon2，允许旧密码失效并通过重新设密恢复。 | resolved |
| Q3 审计删除边界 | 删除账号治理审计页面、查询 RPC、Dashboard 计数和已无意义的治理写入；保留 BFF 登录/代理及网关请求日志，不在本轮删除全部安全审计。 | 采用推荐方案。 | resolved |
| Q4 密码长度 | 前后端统一最少 8 位，不沿用 Admin 现有 6 位下限。 | 采用推荐方案。 | resolved |
| Q5 Portal 授权接口退场方式 | 保留 Portal 登录与账户信息合约；删除动态路由/权限计算，原授权结果返回稳定空集合，避免调用方直接 500，Portal 页面路由改由其自身静态维护。 | 采用推荐方案。 | resolved |
| Q6 账户关系字段 | 删除 `parentId`、`creatorAccountId`、`creatorRoleId` 等层级/创建者关系及关系图；账户仅保留自身属性、`yn` 和普通时间戳，不再用账户关系表达授权。 | 采用推荐方案。 | resolved |
| Q7 48 字符密码盐生成 | 保持参考项目可互认的 16 位数字盐与 32 位 MD5 交织格式，但使用 Node `crypto` 的安全随机数生成盐，不复刻 `java.util.Random` 的弱随机性。 | 采用推荐方案。 | resolved |
| Q8 旧密码全部失效后的首个入口 | 部署时只通过环境变量或一次性运维参数为超级管理员重新设密，其他账户由超级管理员在账户页重设；任何初始密码不得硬编码或写入仓库。 | 采用推荐方案。 | resolved |
| Q9 账户类型与入口门禁 | 只保留 `SUPER_ADMIN`、`PLATFORM_STAFF`；现有 `TENANT_ADMIN`、`TENANT_STAFF` 迁为 `PLATFORM_STAFF` 并删除 `tenantId`。仅 `SUPER_ADMIN` 可进入 Admin 账户管理和 BFF 网关管理，`PLATFORM_STAFF` 只保留 Portal 登录与普通代理会话。 | 采用推荐方案。 | resolved |
| Q10 软删除后的用户名 | 账号继续以 `yn` 软删除；已删除账号的用户名永久保留、不可重新注册，避免历史身份、日志和 Session 归属混淆；本轮不新增恢复页面。 | 采用推荐方案。 | resolved |
| Q11 超级管理员生命周期 | 允许存在多个 `SUPER_ADMIN`，但只有 `SUPER_ADMIN` 能创建两类账户；`accountType` 创建后不可修改；禁止自禁用/自删除，并保证至少保留一个启用的超级管理员。 | 采用推荐方案。 | resolved |
| Q12 Session 失效边界 | 管理员重设密码、账号禁用或软删除后立即吊销目标账号全部 Session；本次身份模型和密码格式迁移上线时统一吊销全部旧 Session，用户重新登录。 | 采用推荐方案。 | resolved |
| Q13 账户页面最终字段与操作 | 列表展示账号、昵称、账户类型、状态、创建/更新时间和操作；按账号/昵称关键词、类型、状态筛选。新增包含账号、密码与确认密码、昵称、类型、状态；编辑时账号和类型只读，仅改昵称/状态；重设密码使用独立弹窗；操作保留编辑、启停、重设密码和软删除。 | 采用推荐方案。 | resolved |

### 假设与风险

- 参考密码格式是快速 MD5 且盐由 `java.util.Random` 生成，安全性弱于现有 Argon2。
- 当前角色、租户、路由和权限仍被 SSO、BFF、ForwardContext 与 Portal Authz 使用，直接删表会使登录或授权链路中断。
- Q1 已确认会物理删除非账户治理表；迁移必须先备份并提供可验证回滚边界，规格确认不等于授权执行迁移。
- Q5 已确认保留 Portal 通道，但动态授权结果固定为空；Q9 继续收敛 Portal 与两个管理端的账户入口边界。
- Q6 已确认删除账户关系和操作者关系字段；`yn` 是账户自身的软删除标记，按项目数据约束保留。
- Q8 只定义恢复入口，不保存、展示或记录实际密码、盐与哈希。
- 当前 `AccountType` 有四类，且 Admin ForwardContext 允许 `SUPER_ADMIN` 与 `PLATFORM_STAFF`；BFF 网关管理的关键操作仍单独校验 `SUPER_ADMIN` 角色，Q9 必须在删角色前替换这一差异。
- Q9 已确认两个管理端只认 `SUPER_ADMIN`，不再保留原 `PLATFORM_STAFF` 的 Admin 登录能力。
- Q10 已确认用户名跨软删除记录永久唯一；迁移前需先审计历史重复值，不能直接添加唯一约束后赌数据干净。
- Q11 已确认允许多个超级管理员；创建后不允许变更账户类型，且任何操作都不能使启用的超级管理员数量降为零。
- Q12 已确认状态、密码和身份模型变更都要同步处理 Session，不能只改数据库而继续接受旧会话。
- Q13 已确认账户页最终字段和操作，需求设计树已无未决分支。

## requirements/R-002

- status: completed
- provider: grill-me
- provider_version: 2026-10-26-local
- input_digest: 26831b0a6aaac27222b24ea337ecd471b7a6a988db4f04a15fa3f4871f4a3c62
- started_at: 2026-10-26T17:29:00+08:00
- completed_at: 2026-10-26T17:32:15+08:00
- classification: non-trivial
- classification_reason: 验收返工需要把直接功能与相邻功能的浅回归范围、运行授权和停止边界写成受保护规格；不改变既定产品需求。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: yes
- complexity.permission_or_security: yes
- complexity.concurrency: no
- complexity.performance: no
- complexity.multiple_repositories: yes
- complexity.external_service: no
- complexity.deployment: yes
- complexity.destructive_operation: yes
- complexity.uncertain: no

### 问答

| 问题 | 推荐答案 | 用户选择 | 状态 |
|---|---|---|---|
| Q20 受控浅功能回归范围 | 直接范围覆盖 Admin 账户、密码、Session 和两个管理端门禁；相邻范围覆盖 BFF 普通代理、接口编辑、请求查询与实时日志；不扩展到其他业务模块，服务启动和隔离库迁移仍单独授权。 | 按推荐做。 | resolved |

### 假设与风险

- SR-01 与 SR-02 只补齐验收协议，不新增产品行为，不扩大 T-01 至 T-11 的源码改动范围。
- 本机服务、隔离数据库、测试账号和迁移回滚仍是运行态资源；Q20 不构成这些资源的执行授权。
- BFF 两仓已登记的范围外全量基线保留为 TC-13 失败证据，不能因本次规格补充自动豁免。
- 设计树已无未决分支，可以重新执行需求评审并等待需求审批。

## plan/P-001

- status: superseded
- provider: grill-me
- provider_version: 2026-10-26-local
- input_digest: 12798aaf1c99b70d1cdfbd5436a51f01dfb3e80e34ef454233f72e63e4166076
- started_at: 2026-10-26T14:51:19+08:00
- completed_at: 2026-10-26T15:02:45+08:00
- classification: non-trivial
- classification_reason: 计划跨五个仓库，包含破坏性数据库迁移、密码安全降级、权限模型切换、多服务契约切换与发布顺序。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: yes
- complexity.permission_or_security: yes
- complexity.concurrency: yes
- complexity.performance: no
- complexity.multiple_repositories: yes
- complexity.external_service: no
- complexity.deployment: yes
- complexity.destructive_operation: yes
- complexity.uncertain: yes

### 问答

| 问题 | 推荐答案 | 用户选择 | 状态 |
|---|---|---|---|
| Q14 Portal 目录退场边界 | 保留 `GetBootstrap`、`GetMe`、`GetAuthorization`，其中动态路由/权限返回空集合；保留仅由账户表可支持的账号/员工选项，删除租户、角色、路由、权限目录 RPC，避免为兼容目录继续保留废弃表。 | 采用推荐方案。 | resolved |
| Q15 首个超级管理员恢复入口 | 在 SSO 提供一次性 CLI，只接受用户名参数与环境变量中的新密码，直接复用 SSO 密码编解码器；不开放 HTTP 接口、不把密码放入命令行或日志。新库 seed 使用同格式 golden-tested codec。 | 采用推荐方案。 | resolved |
| Q16 全部旧 Session 吊销实现 | 为 BFF Session 增加固定身份模型版本；缺失或版本不符的旧 Session 在读取时立即拒绝并删除，从行为上统一失效。重设、禁用和软删除继续调用现有 `RevokeByAccount`。 | 采用推荐方案。 | resolved |
| Q17 协调发布与迁移顺序 | 使用维护窗口：冻结账户写入并记录备份 → SSO → BFF 后端 → Admin 后端 → 获授权后执行迁移与核对 → 两个前端 → 登录/门禁/代理验收。迁移前可代码回滚，迁移后必须先恢复备份再整体回滚。 | 采用推荐方案。 | resolved |

### 假设与风险

- 当前没有其他 `implement` 或 `verify` 轮次占用五个仓库，计划使用真实仓库共享检出，不创建 worktree。
- `adx-bff-backend` 有三处与本轮无关的既有 dirty，实施时必须逐文件登记并排除。
- `sys_audit_log` 同时承载 BFF 登录/退出等运行日志，本轮只删除治理查询面，不能删表。
- 迁移是破坏性的；实施阶段只生成 SQL，任何数据库执行仍需单独授权和备份证据。
- Q14 至 Q17 均已采用推荐方案，计划设计树无未决分支。

## plan/P-002

- status: superseded
- provider: scope-amendment-review
- provider_version: 2026-10-26-local
- input_digest: e9159b5b488e38ad090fd3384910070abfa466aede3d8ba902e2dbe79d0003dd
- started_at: 2026-10-26T16:12:19+08:00
- completed_at: 2026-10-26T16:12:19+08:00
- classification: non-trivial
- classification_reason: 原计划遗漏两个直接引用废弃治理启动逻辑的文件；补充范围是完成既定删除目标和恢复构建的必要条件，不改变需求、接口或迁移边界。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: yes
- complexity.permission_or_security: yes
- complexity.concurrency: yes
- complexity.performance: no
- complexity.multiple_repositories: yes
- complexity.external_service: no
- complexity.deployment: yes
- complexity.destructive_operation: yes
- complexity.uncertain: no

### 问答

| 问题 | 推荐答案 | 用户选择 | 状态 |
|---|---|---|---|
| Q18 T-04 遗漏启动入口的处理 | 把 `adx-admin-backend/src/main.ts` 与 `scripts/run-route-binding-cleanup.ts` 补入 T-04，删除已退场的路由绑定启动清理和独立脚本；保持其他范围、测试和迁移执行边界不变。 | 明确允许补入 T-04，并重新批准计划、授权继续执行 T-04。 | resolved |

### 假设与风险

- 两个新增文件只承载已删除治理模型的清理入口，不被账户单一模型替代。
- 删除启动清理后不会再访问未来将由 T-06 删除的治理表；数据库连接、HTTP/gRPC 启动顺序和 Nacos 注册保持不变。
- 调整不授权启动服务、执行数据库迁移、提交、推送或部署。

## plan/P-003

- status: superseded
- provider: cross-task-scope-review
- provider_version: 2026-10-26-local
- input_digest: 02750c68ffa5b714b8345abac13e793cba491a45c3925f3ed73952f6fa3eaa5b
- started_at: 2026-10-26T16:23:24+08:00
- completed_at: 2026-10-26T16:28:57+08:00
- classification: non-trivial
- classification_reason: T-04 代码审查发现旧治理代码和最终模型消费者分散在原精确清单之外；若不一次性补入 T-04 至 T-08，删表后会造成构建、seed 或登录失败。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: yes
- complexity.permission_or_security: yes
- complexity.concurrency: no
- complexity.performance: no
- complexity.multiple_repositories: yes
- complexity.external_service: no
- complexity.deployment: yes
- complexity.destructive_operation: yes
- complexity.uncertain: no

### 问答

| 问题 | 推荐答案 | 用户选择 | 状态 |
|---|---|---|---|
| Q19 跨任务遗漏范围如何处理 | 一次性把 T-04 的公共关联工具/生成脚本/旧说明、T-05 的 BFF 身份与可信上下文消费者、T-06 的 Admin seed/回填/注释/依赖、T-07 的 SSO 登录合约、T-08 的 BFF seed/关系工具/注释/依赖纳入计划；保持迁移不执行、服务不启动、提交推送不授权。 | 明确允许按清单补充 T-04 至 T-08，重新批准计划并执行当前任务 T-04。 | resolved |

### 假设与风险

- 新增范围只删除或同步已经退场模型的静态消费者，不新增业务能力，也不扩大运行资源。
- Admin seed 继续保留并改为账户单一 seed；BFF 治理 seed 删除，避免两个应用分别写同一治理库。
- SSO/BFF 的最终身份只依赖 `accountType`；manager 可信上下文不再携带本轮删除的租户和授权范围字段。
- 实际迁移、服务启动、提交、推送和部署仍需各自授权。

## plan/P-004

- status: superseded
- provider: grill-me
- provider_version: 2026-10-26-local
- input_digest: 7272252e3ecdb92f415bc8391fed104e1dc8bb82b49333666a742fc7c849a14a
- started_at: 2026-10-26T17:33:44+08:00
- completed_at: 2026-10-26T17:38:16+08:00
- classification: non-trivial
- classification_reason: 验收返工追加 T-11 后计划摘要变化，需明确既有成果的证据迁移方式和范围外全量失败的收口边界。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: yes
- complexity.permission_or_security: yes
- complexity.concurrency: no
- complexity.performance: no
- complexity.multiple_repositories: yes
- complexity.external_service: no
- complexity.deployment: yes
- complexity.destructive_operation: yes
- complexity.uncertain: no

### 问答

| 问题 | 推荐答案 | 用户选择 | 状态 |
|---|---|---|---|
| Q21 计划摘要变化后怎样处理已经完成的 T-01 至 T-11 | 保留已验证的产品成果和任务完成状态，不重复实现；在重新计划审批后，对当前摘要执行一次覆盖 T-01 至 T-11 的范围/基线守卫审计，再重跑统一 code review 与受影响定向检查，生成当前摘要能力证据后回到 verify。 | 按推荐做。 | resolved |
| Q22 BFF 两仓范围外全量基线失败怎样处理 | 不把接口编辑、外部 fixture、Redis 环境和 proto-server 基线扩大进本轮产品修复；继续保留失败证据，运行态验收完成后由用户明确选择受控豁免，或另开迭代修复。本轮不得自行写豁免。 | 按推荐做。 | resolved |

### 假设与风险

- T-01 至 T-11 的产品需求和允许文件没有因 SR-01/SR-02 改变，保留完成状态的依据是当前差异与原任务映射仍一致。
- 当前摘要能力证据必须重新生成；旧摘要证据保留为历史，不能冒充当前门禁。
- 本轮范围外基线不自动豁免，用户不接受残余风险时迭代继续保持 blocked。
- 服务启动、隔离库迁移、备份回滚、提交、推送和部署仍需分别授权。

## plan/P-005

- status: superseded
- provider: iteration-design-interview
- provider_version: 2026-10-26-local
- question_protocol: inline-confirmation-v1
- input_digest: 3e39a216a3be0e8cc4437d04ccfedef0df4189f003464f8e8d10cbeffe0cb74c
- started_at: 2026-10-26T17:50:00+08:00
- completed_at: 2026-10-26T18:16:00+08:00
- classification: non-trivial
- classification_reason: 返工只改一份迁移 SQL，但仍涉及破坏性数据库迁移、依赖删除顺序和备份恢复验收。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: yes
- complexity.permission_or_security: no
- complexity.concurrency: no
- complexity.performance: no
- complexity.multiple_repositories: no
- complexity.external_service: no
- complexity.deployment: yes
- complexity.destructive_operation: yes
- complexity.uncertain: no

### 问答

| 问题 | 推荐答案 | 用户选择 | 状态 | 确认依据 |
|---|---|---|---|---|
| Q23 TC-12 外键依赖失败怎样修复 | 只把 `sys_account_tenant_id_fkey` 等账户关系约束/索引的删除提前到 `sys_tenant` 等主体表之前；不使用 `CASCADE`，不修改历史迁移、删除白名单、最终模型或业务代码。 | 按推荐做。 | resolved | 用户原话：Q23 按推荐做；开始处理，计划审批通过，并执行当前任务 T-12 |

### 假设与风险

- 单事务失败已完整回滚，隔离库仍处于迁移前状态，可以直接复验。
- `CASCADE` 会隐藏未登记依赖并扩大删除风险，因此不作为备选实现。
- 服务启动、隔离库迁移/恢复和 BFF 基线豁免已有本轮用户授权；提交、推送和部署仍未授权。

## plan/P-006

- status: superseded
- provider: grill-me
- provider_version: 2026-10-26-local
- question_protocol: inline-confirmation-v1
- input_digest: 17da42b810c11cde5c69bbbcc5a38342a66182c152b417366d42bf06e8ecbb12
- started_at: 2026-10-26T18:34:00+08:00
- completed_at: 2026-10-26T18:36:00+08:00
- classification: non-trivial
- classification_reason: TC-08 返工涉及认证入口、当前身份可信边界、改密与 Session 吊销顺序；产品范围仍限制在 BFF 已批准的 `src/auth/**`。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: no
- complexity.permission_or_security: yes
- complexity.concurrency: yes
- complexity.performance: no
- complexity.multiple_repositories: no
- complexity.external_service: no
- complexity.deployment: no
- complexity.destructive_operation: no
- complexity.uncertain: no

### 问答

| 问题 | 推荐答案 | 用户选择 | 状态 | 确认依据 |
|---|---|---|---|---|
| Q24 本人改密入口覆盖哪些登录通道 | 在 Portal 与 Admin 认证控制器都提供受各自 Session Guard 保护的 `POST /api/{channel}/auth/change-password`；请求体只接收旧密码和新密码，账号必须取当前 Session，禁止客户端指定用户名；先按账号吊销全部 Session，再调用 SSO 改密，成功后当前会话也必须重新登录。不新增前端页面。仅做 Portal 会使 Admin Session 缺少同一安全能力。 | 按推荐做。 | resolved | 用户原话：Q24 按推荐做 |

### 假设与风险

- 现有管理员重设密码已经采用“先吊销 Session，再写新密码”，T-13 沿用相同安全顺序；若 SSO 改密失败，旧密码保持不变但用户需重新登录，优先避免旧会话继续可用。
- BFF 已有可信的当前账户装饰器、`SsoClient.changePassword` 和 `SessionService.deleteSessionsByAccountId`，无需增加 SSO 到 BFF 的反向依赖。
- T-13 不新增账户页面或改动两个前端，也不接管 HTTP 直通 dirty；服务启动、提交、推送和部署授权边界不变。

## plan/P-007

- status: completed
- provider: grill-me
- provider_version: 2026-10-26-local
- question_protocol: inline-confirmation-v1
- input_digest: 75b616c365da58ae6d869ce192f5618104206c02911d4d254922ef287b3c79eb
- started_at: 2026-10-26T19:27:33+08:00
- completed_at: 2026-10-26T19:33:06+08:00
- classification: non-trivial
- classification_reason: TC-10 返工涉及认证错误边界；必须防止把非权限类 gRPC 故障误映射为身份拒绝。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: no
- complexity.database_or_migration: no
- complexity.permission_or_security: yes
- complexity.concurrency: no
- complexity.performance: no
- complexity.multiple_repositories: no
- complexity.external_service: no
- complexity.deployment: no
- complexity.destructive_operation: no
- complexity.uncertain: no

### 问答

| 问题 | 推荐答案 | 用户选择 | 状态 | 确认依据 |
|---|---|---|---|---|
| Q25 T-14 如何识别 Admin 身份拒绝 | 只按结构化 gRPC `PERMISSION_DENIED` 状态映射为 `40302`，不再依赖中文消息；其他状态和普通异常保持原错误语义。主要影响：可抵抗下游文案变化，并避免把连接失败、超时或内部错误伪装成权限拒绝。 | 按推荐做 | resolved | 用户原话：Q25 按推荐做 |

### 假设与风险

- Admin ForwardContext 是登录阶段唯一会返回该身份拒绝的调用，映射范围限制在这一层，不建立全局 gRPC 兜底转换。
- T-14 不改变权限判定主体、登录成功路径、Session TTL 或审计结构。
- 本轮服务启动授权仍可用于修复后门禁复验；提交、推送和部署仍未授权。
