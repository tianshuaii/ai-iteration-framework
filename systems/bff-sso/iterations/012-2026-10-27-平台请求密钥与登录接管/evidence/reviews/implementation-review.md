# 迭代 012 统一代码审核

- capability: `code-review`
- provider: `code-review-skill`
- provider_version: `local-skill`
- phase: `implement`
- task: `无`
- status: `passed`
- input_digest: `fc789ded42f57e85cf3de37a1e61479104f3bd0b4d723b65ce65ba33bd0ef5ce`
- started_at: `2026-10-27T15:19:00+08:00`
- completed_at: `2026-10-27T15:21:00+08:00`
- findings: `P0=0, P1=0, P2-open=0`

## 审核范围

- Admin 后端：本轮密钥密文字段、注释、可空兼容和有效登录接口 partial unique migration。
- BFF 后端：配置校验、AES-256-GCM 信封、平台 CRUD 脱敏、登录接管、Session 平台上下文、绑定实时校验与可信头覆盖。
- Admin 前端：新建必填、编辑留空保持/输入替换、密钥配置状态和请求归一化。
- 特别保护：第 011 轮既有 dirty 文件及 BFF 仓库用户文件 `CODE_REVIEW.md` 未覆盖、未清理。

## 已发现并修复

### P1：平台 Session 可跨越平台所选子服务发送身份头

- 原因：首次实现只校验 Session、当前平台绑定、BFF 账号和平台密钥，没有把正在访问的子服务与平台有效多选关系再次关联。
- 风险：持有某个平台 Session 的调用方可能向未被该平台选择的非白名单子服务发送该平台身份头。
- 修复：`PlatformRequestContextService.requireForwardIdentity` 增加目标子服务参数，并在每次请求中校验有效 `AccessPlatformSubServiceLink`；缺失时返回 `40301`。
- 复验：新增越权拒绝和有效关系通过测试，BFF 定向 53 项测试与构建通过。

### P2：平台密钥在登录响应绑定查询时缺少第二次有效性收窄

- 原因：请求转发前已经检查密钥配置，但成功响应到达后的绑定查询只检查平台有效状态。
- 风险：极小竞态窗口内平台密钥被清空时仍可能创建新 Session。
- 修复：登录成功绑定查询同时要求当前平台密文字段非空；登录路由查询也要求登录子服务仍属于平台有效子服务集合。
- 复验：登录接管、无绑定、响应越界和会话创建测试通过。

## 安全与兼容结论

- 未发现明文密钥进入 API 响应、列表、日志、审计或 Redis Session；客户端同名身份头不会被信任或复制。
- 只有平台登录接口缓冲响应且受必填大小配置限制，普通 HTTP 响应继续流式转发。
- 上游业务失败保持状态、端到端响应头和正文；成功只接受有限数字或非空字符串 `data.userId`。
- 普通 Portal/Admin Session 无平台上下文时不能访问非白名单 HTTP 直通；白名单和平台登录均不注入身份头。
- 所有源文件维持前端 300 行、后端 500 行上限；未引入新依赖或硬编码生产密钥。

## 统一检查

- Admin 后端：`pnpm prisma:comments:check` 通过（424 行），`pnpm prisma:generate` 通过，migration 静态核对通过，未执行迁移。
- BFF 后端：10 个定向测试套件共 53 项通过，`pnpm build` 通过，`git diff --check` 通过。
- Admin 前端：`pnpm lint:ci`、`pnpm typecheck` 通过；Vitest 5 个文件共 21 项通过；`git diff --check` 通过。

## 残余边界

- 数据库 migration、测试库老数据/唯一索引实跑、三端运行态、模拟上游与验收夹具仍未执行，因为当前授权不包含这些外部状态变更。
- 原样响应基于当前 `fetch` 响应对象复写；实际代理链中的压缩与多值响应头需在获准的运行态验收中确认。
