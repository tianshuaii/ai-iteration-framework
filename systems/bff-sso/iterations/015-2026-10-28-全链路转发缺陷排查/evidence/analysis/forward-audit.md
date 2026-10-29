# 全链路转发审计（只读）

- 对照契约：`mergex-manager` 002「BFF密钥和用户编号登录」
- 对照实现：`adx-bff-backend` `main@04334264b59ec98a864a4ffb461081356394a6c4`
- 主链路：调用方 → BFF HTTP 直通 → MergeX 管理端
- 审计时间：2026-10-28T11:52:35+08:00
- 方式：源码与定向单测只读核对；未启动服务；无单独故障单优先案

## 契约摘要（不含密钥明文）

| 侧 | 约定 |
|---|---|
| BFF → 上游（登录后非白名单） | 只注入 `X-BFF-Secret`、`X-BFF-User-Id`；不转发调用方 Authorization |
| MergeX 管理端 | 两头齐全且密钥正确、用户编号为整数且用户可用时按用户放行，不再校验 token；两头都无时走原 token；只带一个头或密钥/编号无效则拒绝，不退回 token |

## 四段状态

### 登录前 · 白名单

- 代码：`HttpPassthroughService.forward` 在 `allowed` 为真时不调用 `sessionGuard`，也不取 `forwardIdentity`。
- `upstreamHeaders` 只可能写 `content-type`；没有身份时不加两个平台头。
- 客户端自带的 Authorization / `X-BFF-*` 不会被复制进上游 Headers。
- 单测：`skips login for a whitelist operation...` 断言上游没有 `x-bff-secret` / `x-bff-user-id`。
- 结论：与契约一致，未见 BFF 缺陷。

### 登录前 · 需登录接口

- 代码：非白名单且非登录路由时先 `sessionGuard.canActivate`；缺 Bearer 会抛缺令牌/失效类业务异常，不会进入带身份的上游发送。
- 结论：未登录不会误注入密钥和用户编号。未见 BFF 缺陷。

### 登录时 · 平台登录

- 代码：匹配到平台登录路由且已配置密钥时，跳过 Session；`pipeUpstream` 不传 `forwardIdentity`；登录成功由 `PlatformLoginResponseService` 接管并创建带平台上下文的 Portal Session。
- 上游登录请求本身不带两个身份头（单测已断言）。
- 结论：与 012 / 002 登录分工一致。未见 BFF 缺陷。

### 登录后 · 非白名单

- 代码：Session 通过后 `requireForwardIdentity` 重读 Session、绑定、平台密钥和子服务关系，再写入两个身份头。
- `upstreamHeaders` 新建 `Headers`，只设 content-type 与两个身份头；注释写明客户端伪造头永不复制。
- 单测：非白名单路径断言上游收到服务端密钥与平台账号 ID。
- 结论：与 002「BFF 调用不带 token、只带两头」一致。未见 BFF 缺陷。

### 登录失效

- 代码：`ProxySessionGuard` / `SessionAudienceGuard` 在 Session 不存在或续期失败时抛「登录已失效」；只有守卫通过后才调用 `requireForwardIdentity`。
- `requireForwardIdentity` 对无平台上下文、绑定/密钥失效、无权子服务再次拒绝，且拒绝路径不解密密钥。
- 结论：失效 Session 不会继续用旧上下文注入上游身份。未见 BFF 缺陷。

## MergeX 管理端只读对照

- `ViewInterceptor.tryBffLogin` + `TokenUtil.decideBffHeaders` / `decideBffUser` 实现与 002 需求一致：头齐且密钥正确才放行；头不齐拒绝；都没有才走 token。
- 用户编号解析要求纯数字整数；BFF 侧绑定值来自上游 `data.userId` 规范化字符串，MergeX 登录返回的是数字编号时两边对齐。
- 管理端密钥在常量类；BFF 密钥在接入平台配置。两边必须由运维配成同一串，本轮文档不写明文。

## 范围外

- gRPC `/proxy/one`、账号权限后台未扩查；本轮主链路未证明断点在那里。
