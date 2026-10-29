# 实现计划

## 总体做法

本轮按“密码单一写入规则 → 账户单一治理合约 → 调用链去角色/租户 → 数据模型收口 → 两个前端收口”的顺序实施。每个任务完成后先执行定向检查，再做 code review、修复和复验；跨仓库全量构建、手工用例和迁移演练留到 `verify`。

五个仓库均使用 `overview.md` 登记的真实检出。当前没有其他 `implement` 或 `verify` 轮次占用同一仓库，不创建 worktree。`adx-bff-backend` 现有 `src/proxy/http-passthrough.service.ts`、对应 spec 和 `CODE_REVIEW.md` 属于接管前修改，本轮不得覆盖或纳入成果。

## 1. 密码与首个超级管理员恢复

- SSO 新增独立密码编解码器，严格兼容 `mergex-manager` 的 48 字符格式：16 位数字盐、32 位 MD5 摘要、按参考算法交织。
- 盐只用 Node `crypto` 的安全随机源生成；登录、本人改密、管理员设密统一调用该编解码器，删除 Argon2 双格式兼容。
- 使用固定密码/固定盐的 golden vectors 锁定与 Java 参考实现的互认结果；日志和测试证据不得输出真实密码、盐或哈希。
- Admin 新建账户继续以占位值落库，再通过 SSO `SetPassword` 完成最终写入，避免普通业务路径复制散落的哈希逻辑。
- 新库 seed 使用同格式且有 golden vectors 保护的编解码器；SSO 提供一次性超管恢复 CLI，只接受用户名参数与环境变量中的新密码，不开放 HTTP 接口，也不把密码放进命令行、仓库或普通日志。

## 2. Admin 账户单一治理合约

`GovernanceService` 最终只保留以下账户能力：

- `GetCurrentAccount`
- `ListAccounts`
- `CreateAccount`
- `UpdateAccount`
- `ResetAccountPassword`（新增独立 RPC）
- `DeleteAccount`

`CreateAccount` 只接收 `username`、`password`、`nickname`、`accountType`、`status`；`UpdateAccount` 只允许 `nickname`、`status`，不再接受密码、账号或账户类型。重设密码走独立 RPC，不和普通编辑混用。

账户服务只认 `SUPER_ADMIN`、`PLATFORM_STAFF`。所有写操作校验操作者为启用的 `SUPER_ADMIN`；账户类型创建后不可改；用户名对包含软删除记录的全表永久唯一；删除只更新 `yn`。自禁用、自删除以及让启用超级管理员数量变成零都在数据库事务内加锁校验，避免并发绕过。

禁用、软删除和管理员重设密码成功后调用现有 BFF `RevokeByAccount`；失败补偿必须保证不会留下可登录但密码未完成写入的半成品账户。

## 3. 删除非账户治理与重构仍需链路

- 删除 Dashboard、治理审计查询 RPC，以及角色、租户、页面路由、权限、全部授权关系的 proto、DTO、服务、工具和测试。
- 删除 `src/main.ts` 中随服务启动执行的旧路由绑定清理与授权缓存刷新，并删除仅服务于该旧逻辑的 `scripts/run-route-binding-cleanup.ts`，避免废弃治理表删除后启动或构建失败。
- 删除只服务于废弃关联表的 `src/common/link.util*`、会重新生成旧治理服务的拆分脚本，以及两份已失效的 Portal 租户/角色/路由/权限选项说明，避免残留代码或文档重新引入退场模型。
- `GetCurrentAccount` 只返回账户自身字段与 `accountType`，不再返回 `roles`、`tenantId`、创建者等历史治理字段。
- Admin `ForwardContextService` 直接从账户构建上下文：`SUPER_ADMIN` 可进入 Admin，`PLATFORM_STAFF` 仅允许 Portal；不再查询角色、租户或授权表。
- Portal 保留 `GetBootstrap`、`GetMe`、`GetAuthorization` 和仅依赖账户表的账号/员工选项；账号/员工选项只返回未软删除、状态启用的 `PLATFORM_STAFF`，不暴露超级管理员、禁用或已删除账号。动态路由和权限始终返回稳定空集合。租户、角色、路由、权限目录 RPC 删除，不能因删表抛 500。
- `sys_audit_log` 继续承载 BFF 登录、退出、代理和请求运行日志，不随治理审计页面与查询接口一起删除；只移除已无意义的治理写入与查询面。
- 接入服务、接口编辑、运行包、OpenAPI、组合接口和请求/实时日志代码保持不动。

## 4. BFF 会话、转发和管理门禁

- BFF 治理 REST/gRPC 映射只保留账户接口，物理删除 `/dashboard/summary`、`/audit-logs`、角色、租户、路由、权限和授权入口。
- Admin 与网关管理门禁统一使用 `accountType === SUPER_ADMIN`；不再从 `roles` 推导超管身份。
- Portal 登录和账户信息保持；动态授权返回空集合；普通代理链路继续使用账户身份，不携带已删除租户/角色字段。
- BFF 的 Session、当前账户装饰器、SSO 登录映射、ForwardContext 解析和 manager 可信上下文编码统一删除租户、租户管理员与授权租户集合字段；诊断脚本同步最终协议，不保留伪兼容字段。
- Session 增加命名的身份模型版本常量；缺失或版本不符的旧 Session 在读取时立即拒绝并删除。日常重设密码、禁用和软删除继续复用现有按账号吊销 RPC。
- 保留 `sys_audit_log` 的登录/退出/代理安全记录以及请求查询、实时日志页面。

## 5. 数据迁移与回退边界

迁移只在 `adx-admin-backend/prisma/migrations/**` 建立；BFF 和 SSO 只同步最终 Prisma 模型，不创建治理迁移。

迁移按下列顺序设计：

1. 预检全部账户用户名重复值；存在重复时立即阻断，不自动改名。
2. 要求记录可恢复的数据库备份/快照标识；没有备份证据不执行迁移。
3. 把 `TENANT_ADMIN`、`TENANT_STAFF` 更新为 `PLATFORM_STAFF`。
4. 清除账户的 `tenant_id`、`parent_id`、`creator_account_id`、`updated_account_id` 等废弃关系并移除约束、索引和列。
5. 为 `sys_account.username` 建立覆盖全部历史行的唯一约束；保留 `yn`，账户仍然软删除。
6. 按外键依赖从关联表到主体表删除角色、租户、路由、权限和授权表及废弃枚举；保留 `sys_account`、`sys_audit_log`、运行包、接入服务和接口编辑相关表。
7. 迁移后核对账户数量、两类账户分布、重复用户名、保留表清单和已删除表清单。

最终模型生成前同时清理所有静态消费者：Admin seed 只创建/恢复账户，不再创建角色或关系；旧角色/租户回填脚本物理删除；Admin 与 BFF 的数据库注释清单同步最终表和 48 字符密码格式。BFF 不再承担治理库超管 seed，删除其 seed、凭据解析器、命令和仅由旧 seed/治理代码使用的 Argon2 依赖。SSO 登录和 gRPC 合约改为直接返回 `accountType`，并删除角色/租户身份推导与无用 Argon2 依赖。

这是破坏性迁移，不提供伪造的 down migration。迁移前可回退应用代码；迁移后若必须回退，使用已记录的数据库备份恢复，并按已确认的协调顺序回滚五个服务/前端。

实施任务只生成和静态复核迁移，不执行本机、测试或生产数据库迁移；任何实际迁移仍需单独授权。

## 6. Admin 页面

- 路由和侧栏只保留登录、账户列表、必要壳层和无权限页；默认路由跳转 `/accounts`。
- 删除 Dashboard、租户、角色、账户关系图、路由、权限、全部授权页、治理审计页及其懒加载、资源配置和 SDK 调用。
- 账户列表显示账号、昵称、账户类型、状态、创建时间、更新时间和操作；筛选只有账号/昵称关键词、类型、状态。
- 新增弹窗包含账号、双次密码、昵称、类型、状态；编辑时账号和类型只读，只改昵称/状态；重设密码独立弹窗。
- 所有新增、编辑和重设密码表单使用 `validateTrigger={['onChange', 'onBlur']}`、`colon={false}`，有 label 的必填项保留必填星号。

## 7. BFF 管理前端

- `AdminMe` 和鉴权 Store 只读取 `accountType`，删除 `roles` 兼容回退。
- `RequireSuperAdmin` 只允许 `SUPER_ADMIN`；请求查询、实时日志、接入服务和接口编辑页面均保留。

## 8. 发布顺序

发布在维护窗口内完成：冻结账户写入并取得备份 → 部署 SSO → 部署 BFF 后端 → 部署 Admin 后端 → 执行已授权迁移与核对 → 部署两个前端 → 验证首个超级管理员、Session 失效、Portal 普通代理和两套管理端门禁。

## 9. 验收返工与证据迁移

- T-01 至 T-10 的需求、产品文件和检查方式未因 SR-01/SR-02 改变，保留已完成状态，不重复实现。
- T-11 是 verify 首轮发现的规格内测试返工，产品差异仅涉及三份 BFF 测试；其定向 Jest、ESLint、构建、差异检查和 code review 已通过，同样保留完成状态。
- 重新计划审批后，先执行一次覆盖 T-01 至 T-11 的当前摘要范围/基线守卫审计，逐仓确认 HEAD、dirty 保护、改动范围、运行资源和无新增代码漂移。
- 守卫审计通过后，对最终五仓差异重新执行迭代级统一 code review，并重跑受计划摘要变化影响的定向检查；无需机械重做已经由影响分析确认不受规格补充影响的实现步骤。
- 当前摘要的实现守卫与统一审核能力证据完成后再回到 verify，执行 TC-01 至 TC-13、SR-01 和 SR-02 的剩余运行态步骤。
- 本机五服务、隔离测试库、迁移备份/回滚和测试账号仍需分别授权；计划重新审批不自动取得这些运行资源。
- BFF 两仓已登记的接口编辑、外部 fixture、Redis 环境和 proto-server 等范围外基线不纳入本轮产品修复；保留失败证据，运行态验收后只接受用户明确的受控豁免，或另开迭代修复。
- 本轮不自动写豁免，不把范围外失败改写为通过，也不因补充浅回归扩大到全系统回归。

## 10. T-12 迁移依赖顺序返工

- 隔离库实跑已经证明重复用户名预检有效，但迁移在删除 `sys_tenant` 时仍保留 `sys_account_tenant_id_fkey`，PostgreSQL 按依赖约束拒绝执行。
- T-12 只调整 `20261026170000_account_only_governance/migration.sql` 的语句顺序：先删除账户对租户、父账户和创建者的外键/索引，再删除废弃关联表与主体表，最终删列、枚举和密码格式步骤保持不变。
- 不使用 `CASCADE` 绕过依赖审计，不修改历史迁移，不改变批准的删除白名单、最终 Prisma 模型或业务代码。
- 修复后在同一专用数据库重新验证：重复用户名阻断、单事务迁移成功、账户数量与类型转换、保留/删除表清单、迁移前备份恢复、恢复后二次迁移。
- 用户已授权本机五服务和隔离测试库验收，并确认受控豁免 BFF 范围外基线；这些授权不包含提交、推送或部署。

## 11. T-13 本人改密 Session 吊销返工

- 失败边界已经由 TC-08 收窄：SSO `ChangePassword` 会正确写入 48 字符密码并拒绝旧密码，但直接调用不会触达 BFF 的账户 Session 索引，所以改密前 Session 仍可使用。
- 修复只放在 BFF 认证编排层：Portal 与 Admin 分别提供受各自 Session Guard 保护的 `POST /api/{channel}/auth/change-password`，请求体只包含旧密码和新密码；用户名和账户 ID 均来自当前 Session，客户端不能指定或覆盖目标账号。
- 沿用管理员重设密码的安全顺序：先调用 `SessionService.deleteSessionsByAccountId` 吊销该账户全部 Session，再调用已有 `SsoClient.changePassword`。若 SSO 拒绝旧密码或写入失败，密码保持不变，但旧 Session 已失效，用户需要重新登录，避免失败窗口继续信任旧会话。
- 不把吊销逻辑下沉到 SSO，避免新增 SSO → BFF 反向依赖；不改两个前端，不新增改密页面，不修改 Prisma、Proto、迁移、Admin 服务或接管前 HTTP 直通 dirty。
- 定向测试覆盖两类入口、当前 Session 身份不可伪造、吊销先于 SSO、吊销/SSO 失败传播、成功后当前及同账户其他 Session 均失效；实现后重跑 TC-08、TC-11、TC-13 与 SR-01，SR-02 经影响分析不涉及认证编排时只保留既有结果。

## 12. T-14 Admin 登录权限错误码返工

- 运行态已经确认权限边界没有失效：`PLATFORM_STAFF` 无法取得 Admin Session，Admin 后端以 gRPC `PERMISSION_DENIED` 拒绝构建管理端 ForwardContext。
- 缺陷只在 BFF 登录编排的错误转换：现有实现通过中文消息正则猜测身份拒绝，未匹配“超级管理员”文案，导致 gRPC 状态 7 落入通用 `50001`。
- T-14 只在 `AuthService.login` 的 Admin ForwardContext 异常分支识别结构化 gRPC `PERMISSION_DENIED`，转换为 `AUTH_ADMIN_ROLE_DENIED=40302`；不得把其他 gRPC 状态或普通内部异常误报为权限拒绝。
- 不修改 Admin/SSO、Proto、数据库、Session 模型、两个前端或 HTTP 直通 dirty；Portal 登录、超级管理员 Admin 登录和既有审计写入顺序保持不变。
- 定向测试必须构造带结构化 gRPC 状态的异常，断言员工 Admin 登录得到 `40302`，并证明未知错误仍原样传播；实现后完成 code review，再重跑 TC-10、AC-06 与 SR-01 管理端门禁路径。

## 为什么这样切

- SSO 保持普通在线密码写入的单一入口，账户服务只编排创建/重设与 Session 吊销，避免每个调用方各写一套密码逻辑。
- 先让代码停止读取旧模型，再执行删表迁移，可在迁移前保持新代码对旧数据库的向前兼容，并缩小破坏性步骤的不可用窗口。
- BFF 和 Admin 同时去掉角色依赖，避免只删页面或只删表造成隐藏入口、500 或错误放权。
- 两个前端最后切换，保证用户看到的新操作都已有后端合约承接。

## 怎样避开“不做”

- 不修改 `/Users/mrzater/java/mergex-manager`，只用其算法和 golden vectors 做只读对照。
- 不删除 BFF 请求查询、实时日志、登录/退出/代理安全日志。
- 不改接入服务、接口编辑、运行包、OpenAPI 和组合接口业务行为。
- 不执行数据库迁移、不启动服务、不提交、不推送、不部署，除非分别获得后续明确授权。

## 字段与接口变化

当前尚未改产品代码；下表是计划目标。

| 字段或路径 | 谁在用 | 计划变化 |
|---|---|---|
| `sys_account.account_type` | Admin、SSO、BFF、两个前端 | 只允许 `SUPER_ADMIN`、`PLATFORM_STAFF`。 |
| `sys_account.username` | 登录、账户列表 | 对软删除历史也永久唯一。 |
| `sys_account.tenant_id/parent_id/creator_account_id/updated_account_id` | 旧治理链路 | 删除。 |
| `GovernanceService` | BFF、Admin 前端 SDK | 只保留当前账户与账户 CRUD，新增 `ResetAccountPassword`。 |
| `UpdateAccountRequest` | Admin 账户编辑 | 只允许昵称、状态；移除密码和账户类型写入。 |
| `PortalAuthzService` | BFF Portal | 保留账户信息和账户选项；动态路由/权限返回空集合；删除租户、角色、路由、权限目录。 |
| `SessionRecord` | BFF Redis Session | 增加身份模型版本，拒绝并删除旧版本 Session。 |
| `/admin/audit-logs` 等治理路径 | Admin 前端/BFF | 删除；网关请求查询与实时日志路径保留。 |
