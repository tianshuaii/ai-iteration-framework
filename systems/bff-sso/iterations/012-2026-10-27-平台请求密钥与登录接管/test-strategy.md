<!-- shallow-regression-policy: bounded-v1 -->
<!-- risk-based-testing-policy: adaptive-v1 -->
# 测试策略

## 任务风险分级

| 任务 | 档位 | 分级理由 | 影响仓库/模块 | 必须执行 | 可复用证据 | 升级条件 |
|---|---|---|---|---|---|---|
| T-01 | T4 | 新增平台密钥字段并涉及敏感值存储、老数据和 migration。 | `adx-admin-backend` Schema/迁移、BFF Prisma | 注释检查、Prisma 生成、迁移前后结构与老数据验证、密钥不泄露检查。 | 可复用 011 三张平台/绑定表结构基线；不能复用新字段结果。 | 加密方案或唯一约束改变时扩展迁移与轮换测试。 |
| T-02 | T4 | 登录接管、Session 身份、可信头覆盖和账号绑定属于认证安全边界。 | `adx-bff-backend` proxy/auth/session/admin | 定向单测、流式/缓冲分支、真实 HTTP、权限、失效态、并发和敏感日志检查。 | 可复用 011 平台/绑定 CRUD与权限证据；请求链和 Session 输入变化后不得复用相关结果。 | 改动共享 Guard、Session 版本或普通转发时扩大到登录与代理浅回归。 |
| T-03 | T3 | 密钥表单和请求模型改变平台创建/编辑契约。 | `adx-admin-frontend` 平台页/API | ESLint、类型检查、定向组件/模型测试、浏览器必填与编辑回显验收。 | 可复用 011 平台三级联动测试中未受影响部分。 | 修改公共请求封装或全局表单时扩大前端回归。 |

## 自动

| 项目 | 命令 | 要挡住的错误 |
|---|---|---|
| `adx-admin-backend` | `pnpm prisma:comments:check && pnpm prisma:generate` 加本轮 migration 定向检查 | 密钥列、注释、唯一约束或老数据迁移错误。 |
| `adx-bff-backend` | `pnpm prisma:generate`、平台/代理/Auth/Session 定向测试与 `pnpm build` | 错平台登录、错误成功接管、Session 串平台、头伪造、普通流式直通回归。 |
| `adx-admin-frontend` | `pnpm lint:ci && pnpm typecheck` 加接入平台定向测试 | 密钥漏传、明文回显、编辑误清和必填校验失效。 |

## 手工

按 [test-cases](./test-cases.md) 执行，结果写入 [test-log](./test-log.md)。数据库迁移、服务启停、真实 Redis Session 和外部/模拟上游写入仍需对应授权。

## 回归

- Admin 接入平台新建、编辑、失效配置和平台账号绑定。
- BFF API 路径 /api/portal/auth/login、/api/admin/auth/login、Session 续期与退出。
- HTTP 直通查询参数、JSON/字符串/流式正文、上游状态/内容类型原样返回。
- 白名单免登录与非白名单 Session 校验。

## 受控浅功能回归

| 编号 | 类型 | 功能或路径 | 纳入理由 | 停止边界 |
|---|---|---|---|---|
| SR-01 | 直接 | 平台创建、平台登录接管、Token 后非白名单请求 | 本轮完整用户主路径。 | 一个 HTTP 平台、一个登录接口、一个绑定账号和一个非白名单接口，不穷举全部上游。 |
| SR-02 | 相邻 | 原 BFF/Admin 登录、白名单和普通 HTTP 流式直通 | 共享 Auth、Session、Guard 与直通发送/响应代码。 | 不改密码、不扩展到 gRPC 路径 /proxy/one/batch 的业务接口穷举。 |
