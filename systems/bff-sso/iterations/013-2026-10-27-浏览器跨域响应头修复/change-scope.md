# 改动范围

仓库绝对路径写在这套系统的 `overview.md`。本轮系统名：`bff-sso`。

## 要改的项目

| 项目 | 这一轮它负责什么 |
|---|---|
| `adx-bff-backend` | 保留原生代理响应中的 Fastify/BFF 响应头，并补充定向回归测试。 |

## 页面上要改的位置

| 位置 | 现在 | 改完 |
|---|---|---|
| 浏览器调用普通 `/proxy/...` 接口 | 上游返回 200，但响应缺少 BFF CORS 头，Axios 报 `Network Error`。 | 响应保留 BFF CORS 头，浏览器可以读取状态、响应头和正文。 |
| 浏览器调用已登记的平台登录接口且上游 `code != 200` | 上游错误被原样写到 raw response，但同样可能丢失 BFF CORS 头。 | 继续原样返回上游错误，同时保留 BFF CORS 头。 |

## 大致文件

### `adx-bff-backend`

- `src/proxy/http-passthrough.service.ts`：普通流式代理响应写出时保留 Fastify 已生成的响应头。
- `src/proxy/platform-login-response.service.ts`：平台登录失败原样返回时保留 BFF 响应头，并确保 BFF 同名头优先。
- 如两个分支需要共享且职责清晰，可在 `src/proxy/` 下新增一个小型响应头辅助模块。

### 补测试

- `src/proxy/http-passthrough.service.spec.ts`：断言普通流式代理写出的 raw headers 包含已有 CORS 头，且正文和状态不变。
- `src/proxy/platform-login-response.service.spec.ts`：断言上游业务失败保留上游头、原始正文与 BFF CORS 头，并验证上游不能覆盖 BFF CORS。

## 明确不动

| 项目 | 为什么不动 |
|---|---|
| `adx-bff-frontend` | 管理页与本次浏览器代理响应无关。 |
| `adx-sso-backend` | 不涉及密码校验和 SSO。 |
| `adx-admin-backend` | 不涉及账号、治理表或数据库。 |
| `adx-admin-frontend` | 不涉及账号权限页面。 |
| MergeX 页面源码 | 现有请求方式正确，不能通过前端规避 BFF 响应头缺陷。 |
| Nacos 与数据库 | 现有 CORS 配置有效，不新增运行配置或数据迁移。 |
