# 第 012 轮需求设计访谈

- capability: `design-interview`
- provider: `grill-me`
- phase: `specify`
- attempt: `requirements/R-001`
- status: `passed`
- input_digest: `2b205ea4b620899b89cc66c8dff4e22e7501ee8715f45d59e89db2a3d8c234a1`
- started_at: `2026-10-27T14:47:30+08:00`
- completed_at: `2026-10-27T14:52:17+08:00`

## 已核实事实

- HTTP 直通入口目前只能从 `publicPath + HTTP 方法 + 原路径`识别生效包和接口，入站没有平台 ID。
- 当前 `SessionRecord` 只有 BFF 账号、渠道、账号类型和 ForwardContext，没有接入平台或平台账号上下文。
- 同一个 BFF 账号允许跨多个平台各绑定一个账号 ID，因此不能只凭 BFF 账号反推本次平台。
- 现有 HTTP 直通对普通响应使用流式管道；只在平台登录成功分支解析 JSON 才能避免普通大响应退化。
- 现有 Portal 登录成功数据是 `accessToken`、`expiresIn`、`tokenType`，再由统一响应层包装为 `{ code, data, msg }`。

## 访谈结论

- Q1-Q5 均由用户原话“`Q1-Q5 都按推荐做`”确认。
- 有效平台的登录接口稳定键唯一；请求密钥加密保存且永不明文回显；已有平台补录前不能登录接管或注入身份头。
- 平台登录接口作为动态登录例外；异常成功体返回 `50201`，无绑定或账号失效返回 `40401`。
- 非白名单 HTTP 直通只接受平台登录生成并携带平台上下文的 Portal Session。
- 需求设计树无未决分支。
