<!-- design-interview-policy: design-tree-v1 -->
# 设计访谈

本文件持久保存需求和计划阶段的设计树访谈。事实由 Agent 使用只读源码、文档或 MCP 查询；用户只决定方案。历史尝试不得删除，输入摘要变化后把旧尝试标记为 `superseded` 并追加新尝试。

## requirements/R-001

- status: completed
- provider: grill-me
- provider_version: local-skill
- question_protocol: inline-confirmation-v1
- input_digest: 67ddb28488cd524d5d6d5a67d01e7c86c19325f3a6e17cd16a2f123ac64379a0
- started_at: 2026-10-27T11:35:45+08:00
- completed_at: 2026-10-27T11:48:52+08:00
- classification: non-trivial
- classification_reason: 涉及产品代码、接口与 Schema、数据库迁移、账号权限和多仓联动。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: yes
- complexity.permission_or_security: yes
- complexity.concurrency: yes
- complexity.performance: no
- complexity.multiple_repositories: yes
- complexity.external_service: no
- complexity.deployment: no
- complexity.destructive_operation: no
- complexity.uncertain: no

### 问答

| 问题 | 推荐答案 | 用户选择 | 状态 | 确认依据 |
|---|---|---|---|---|
| Q1 运行时边界：本轮是只保存平台、登录接口和账号绑定配置，还是要让 BFF 实际调用所选登录接口？ | 本轮只完成配置与绑定；实际登录调用另立需求，因为尚缺凭据、入参映射、Token 提取和失效策略。 | 按推荐做 | resolved | 用户原话：`Q1-Q6 都按推荐做` |
| Q2 平台生命周期：接入平台是只能创建，还是支持编辑和删除？ | 支持列表、新建、编辑和软删除；存在有效账号绑定时禁止删除。 | 按推荐做 | resolved | 用户原话：`Q1-Q6 都按推荐做` |
| Q3 绑定生命周期：绑定后是否可修改平台账号 ID 和解除绑定？ | 可修改 ID 和软删除解绑；不允许一条记录直接更换 BFF 账号或平台。 | 按推荐做 | resolved | 用户原话：`Q1-Q6 都按推荐做` |
| Q4 权限边界：谁可以使用新页面和接口？ | 仅启用的 `SUPER_ADMIN` 可访问和操作，沿用现有 Admin 管理端边界。 | 按推荐做 | resolved | 用户原话：`Q1-Q6 都按推荐做` |
| Q5 失效配置：登录子服务或接口后续被删除、停用或替换时如何处理？ | 保留配置并显示“登录配置已失效”，禁止新增绑定；不自动删除平台或旧绑定。 | 按推荐做 | resolved | 用户原话：`Q1-Q6 都按推荐做` |
| Q6 改名范围：“账号”改为“BFF 账号”是否只改用户可见名称？ | 只改菜单、页标题、说明和相关提示；现有账号字段、登录、启停、设密和软删除行为不变。 | 按推荐做 | resolved | 用户原话：`Q1-Q6 都按推荐做` |
| Q7 BFF 账号生命周期：已绑定的 BFF 账号后续被禁用或软删除时，绑定如何处理？ | 保留旧绑定并显示“BFF 账号已失效”，禁止为失效账号新建绑定；不阻止原有禁用/软删除操作，不自动解绑。禁用账号重新启用后，旧绑定自动恢复为有效。 | 按推荐做 | resolved | 用户原话：`Q7 按推荐做` |

### 假设与风险

- 现有接口清单来自子服务已生效运行包；更换运行包后原接口可能消失。
- 绑定唯一性需要 partial unique 索引或等价并发安全约束，不能只用先查后写。
- 平台账号 ID 在不同平台可能是数字或字符串，应按非空字符串保存。
- 实际调用登录接口会扩展为凭据保管和 Token 生命周期问题，未获 Q1 确认前不写成已定范围。
- BFF 账号禁用或软删除后保留旧绑定并展示失效状态，不阻止原账号操作；仅禁用账号重新启用后，旧绑定自动恢复有效。

## plan/P-001

- status: completed
- provider: grill-me
- provider_version: local-skill
- question_protocol: inline-confirmation-v1
- input_digest: 7d5967be49d3d8dc9514aabb548d24502c1533fb6e7dffbc4d7937928dfceff8
- started_at: 2026-10-27T11:53:00+08:00
- completed_at: 2026-10-27T12:00:51+08:00
- classification: non-trivial
- classification_reason: 计划涉及三仓、数据库迁移、接口/Schema、权限、事务与并发唯一性，必须按 strict 档位完成计划设计树检查。
- unresolved_count: 0
- complexity.product_code: yes
- complexity.interface_or_schema: yes
- complexity.database_or_migration: yes
- complexity.permission_or_security: yes
- complexity.concurrency: yes
- complexity.performance: no
- complexity.multiple_repositories: yes
- complexity.external_service: no
- complexity.deployment: no
- complexity.destructive_operation: no
- complexity.uncertain: no

### 问答

| 问题 | 推荐答案 | 用户选择 | 状态 | 确认依据 |
|---|---|---|---|---|
| Q8 登录接口身份与模块边界：没有独立 endpoint 表时，平台应如何持久化所选 HTTP/gRPC 登录接口，并把新 CRUD 放在哪一层？ | Admin 后端只迁移三张治理表；BFF 用 HTTP 的规范化 `METHOD + path` 或 gRPC 的 `grpcFullMethod` 生成稳定键，并保存接口显示快照，在独立平台/绑定模块中集中做事务、权限、唯一性和实时失效校验；Admin 前端只负责选择与展示。本轮仍不实际调用登录接口。 | 按推荐做 | resolved | 用户原话：`Q8 按推荐做` |

### 假设与风险

- 需求 Q1-Q7 已锁定运行时边界、生命周期、权限、失效行为和改名范围，没有在计划阶段重复打开已确认分支。
- Q8 已确认 HTTP 使用规范化 method/path、gRPC 使用 full method 的稳定键与显示快照，并由 BFF 独立模块集中处理业务校验。
- 当前只有本轮处于活动状态，三个目标仓库使用真实目录共享检出，不创建 worktree。
- `adx-bff-backend/CODE_REVIEW.md` 是接管前未跟踪文件，实施时必须排除。
- 数据库迁移、服务启动、验收夹具、提交、推送和部署仍需分别授权。
- Q8 已由用户原话确认，计划设计树无未决分支。
