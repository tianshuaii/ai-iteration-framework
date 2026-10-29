# 实现计划

## 总体做法

本轮按“治理字段与数据库约束 → BFF 密钥、登录接管和平台 Session → Admin 密钥表单”的顺序实施。三个任务完成后统一执行去重检查和整轮 code review，修复并复验后再进入 `verify`，不在每条任务后机械重复完整检查。

三个目标仓库沿用 `overview.md` 登记的真实目录和第 011 轮尚未提交的产品改动。当前没有其他 `implement` 或 `verify` 轮次占用这些仓库，因此不创建 worktree；实现前必须逐文件登记并保护第 011 轮 dirty 基线，尤其不得覆盖 `adx-bff-backend/CODE_REVIEW.md`。

## 1. 治理 Schema 与约束

- 只在 `adx-admin-backend` 新增 migration：为 `sys_access_platform` 增加可空的加密密文字段，不给旧平台伪造默认密钥。
- 字段使用可容纳版本、IV、认证标签和任意字符串密文的文本类型；数据库、Prisma 和字段注释只表达“加密请求密钥”，不记录或输出明文。
- 对有效 HTTP 平台建立“登录子服务 + 登录接口稳定键”的 partial unique 索引；BFF Prisma 只同步字段，不创建第二份 migration。
- 已有平台保持可查询；密文字段为空时，BFF 禁止登录接管和非白名单身份头注入。

## 2. BFF 平台密钥管理

- 创建平台时要求请求密钥是字符串且不等于空字符串，不 trim、不限制字符格式；空白字符串也按用户“无格式要求”原样加密保存。
- 更新平台时，缺少或空字符串表示保持原密钥，非空字符串表示加密替换；列表和详情只返回 `requestSecretConfigured`，不返回密文或明文。
- 使用职责单一的密钥组件完成加解密和脱敏边界，平台 CRUD 只编排业务语义。算法固定为 AES-256-GCM；必填配置 `ACCESS_PLATFORM_SECRET_MASTER_KEY` 提供严格 32 字节 Base64 主密钥，不允许代码默认值。
- 密文使用带版本的信封保存 IV、认证标签和密文。本轮不实现在线主密钥轮换；变更主密钥前必须通过另行授权的维护流程重加密，密钥不匹配时失败关闭。
- 平台登录接口唯一冲突由数据库 partial unique 与服务端可读错误共同保证，避免并发先查后写绕过。

## 3. 登录响应接管与 Session

- HTTP 直通先解析当前生效包和接口，再判断该接口是否是唯一有效平台的登录接口；普通白名单和普通非白名单继续走原流式路径。
- 平台登录接口作为动态免 Session 入口，仍按原方法、查询、正文和目标地址转发；客户端同名平台身份头在发送前移除。
- 只对平台登录响应做有界缓冲：必填配置 `PLATFORM_LOGIN_RESPONSE_MAX_BYTES` 决定上限，验收配置为 1048576（1 MiB）；超限返回 `50201` 且不创建 Session。业务 `code != 200` 时原样写回 HTTP 状态、响应头和原始响应体；业务 `code == 200` 时解析 `data.userId`，不再返回原成功体。
- `userId` 只接受非空字符串或有限数字并统一转成字符串；结构异常返回 `50201`，当前平台无有效绑定或 BFF 账号失效返回 `40401`“该账户不存在”。
- 抽取可复用的 Portal Session 创建方法，让原账号密码登录与平台登录共用 ForwardContext、Redis Session、TTL、Token 数据和审计逻辑，避免复制认证实现。
- Session 增加可选的 `accessPlatformId` 与 `platformAccountId`，保持旧 Portal/Admin Session 可被原能力读取；非白名单 HTTP 直通额外要求两项平台上下文。

## 4. 非白名单可信头注入

- 通过 Session 校验后，用 Session 平台 ID 重新读取当前有效平台和最新密钥，校验绑定、BFF 账号及平台仍有效。
- 在发送上游请求前覆盖写入 `X-BFF-Secret` 和 `X-BFF-User-Id`；请求头匹配大小写不敏感，浏览器值永远不作为可信来源。
- 白名单和平台登录请求不注入身份头；旧 Portal/Admin Token 调用非白名单 HTTP 直通时明确拒绝，不猜平台。
- 密钥解密失败、平台缺密钥或任何关联失效时都在转发前失败关闭，不向上游发送部分身份。

## 5. Admin 前端

- 接入平台新建弹窗增加带必填星的密码型“请求密钥”，落实 `colon={false}` 与 `validateTrigger={['onChange', 'onBlur']}`。
- 编辑弹窗不回显真实值，显示“已配置/未配置”；留空不传替换值，输入非空字符串才替换。
- 请求模型区分“新建必填”和“编辑可省略”，不把掩码或空字符串误传为新密钥；列表不增加密钥明文列。
- 继续按功能文件拆分，新增或修改的前端源码不超过 300 行；后端源码接近 500 行时拆成职责单一服务。

## 6. 检查、审核与验收边界

- T-01 完成后只保留必要生成物；T-02、T-03 完成后统一执行 `tasks.md` 中去重后的 Prisma、定向测试、构建、Lint 和类型检查。
- 对三个仓库本轮整体差异统一执行一次 code review，修复全部发现并按影响范围复验；通过后才进入 `verify`。
- `verify` 覆盖 TC-01 至 TC-12、SR-01 和 SR-02。数据库迁移、测试库、Redis、模拟上游、服务启停和验收夹具仍需分别取得明确授权。

## 为什么这样切

- Admin 后端继续是治理 Schema 唯一迁移源，BFF 只同步模型，避免 migration 漂移。
- 登录成功接管和普通流式直通分开，限制响应缓冲只影响登录接口。
- Session 只保存平台身份而不保存平台密钥，使平台密钥替换能立即生效，也缩小 Redis 敏感面。
- 可信头在服务端根据 Session 和当前数据库配置生成，客户端无法伪造或保留旧值。

## 怎样避开“不做”

- 不修改 `adx-sso-backend`、`adx-bff-frontend` 或外部平台服务。
- 不改变上游登录请求参数、凭据验证或 `code != 200` 响应。
- 不把请求密钥写入日志、API 响应、Session、前端状态持久化或代码常量。
- 计划和实现阶段不自动执行数据库迁移、启动服务、提交、推送、合并、拉取或部署。

## 字段与接口变化

当前尚未修改本轮产品代码；下表是计划目标。

| 字段或路径 | 谁在用 | 计划变化 |
|---|---|---|
| `sys_access_platform.request_secret_ciphertext` | BFF 平台 CRUD、登录接管和上游头注入 | 新增加密密文字段；旧数据为空，API 不返回字段内容。 |
| `POST /api/admin/access-platforms` | Admin 接入平台新建 | 新增必填字符串 `requestSecret`。 |
| `PUT /api/admin/access-platforms/:id` | Admin 接入平台编辑 | 新增可选字符串 `requestSecret`；缺少或空字符串表示保持，非空表示替换。 |
| 平台列表/详情响应 | Admin 前端 | 新增布尔值 `requestSecretConfigured`，不返回密钥。 |
| `SessionRecord` | Auth、Session Guard、HTTP 直通 | 新增可选 `accessPlatformId`、`platformAccountId`。 |
| 平台登录接口原路径 | 外部平台前端 | 失败继续返回上游原响应；成功改为 BFF Portal Token 信封。 |
| 非白名单 HTTP 直通 | 外部平台服务 | 服务端覆盖注入 `X-BFF-Secret`、`X-BFF-User-Id`。 |
