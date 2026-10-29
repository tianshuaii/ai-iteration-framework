# 需求与注意事项：浏览器跨域响应头修复

范围见 [change-scope](./change-scope.md)。验收见 [acceptance](./acceptance.md)。当前进度只看 [status](./status.md)。

## 背景

浏览器通过 `http://127.0.0.1:3000/proxy/...` 调用 BFF 的 HTTP 直通接口时，上游实际返回 `200 OK`，但 Axios 报 `Network Error`。同一请求在 Apifox 可以正常读取。

BFF 已全局启用按请求 Origin 返回的 CORS，并允许携带凭据；问题发生在代理响应直接调用 `reply.raw.writeHead()` 时，没有把 Fastify 已生成的响应头写入原生响应。浏览器因此看不到 `Access-Control-Allow-Origin`，而 Apifox 不受浏览器同源策略限制。

## 本次要做

### 页面

- 不修改前端页面、Axios 配置或开发代理。
- 修复后浏览器继续使用现有 BFF 地址，请求成功时可以正常读取响应，不再显示由该缺陷触发的 `Network Error`。

### 接口与转发

1. 普通 HTTP 直通响应继续保持上游 HTTP 状态、正文流和现有 `Content-Type`，同时保留 Fastify/Nest 已为当前请求生成的响应头，包括 CORS 与请求链路相关响应头。
2. 平台登录接口在上游 `code != 200` 时继续原样返回上游状态、端到端响应头和原始字节，同时保留 BFF 自己生成的 CORS 响应头。
3. BFF 生成的响应头是浏览器边界的最终策略；上游同名 CORS 头不得覆盖 BFF 根据当前 Origin 计算出的值。
4. 平台登录 `code == 200` 后创建 BFF Session 的标准响应逻辑不变。
5. 不将 CORS Origin 硬编码为 `*`；继续使用现有 `origin: true` 与 `credentials: true` 配置。

### 数据

- 不修改数据库、Prisma Schema、Redis Session、Nacos 配置或验收数据。

## 默认与老数据

| 场景 | 行为 |
|---|---|
| 跨域普通代理请求 | 按现有 CORS 配置回显允许的 Origin，浏览器可读取上游响应。 |
| 同源或没有 Origin 的调用 | 保持现有代理响应，不人为补固定 Origin。 |
| 平台登录上游业务失败 | 保持上游状态、正文和端到端响应头，同时返回 BFF CORS 头。 |
| 平台登录成功 | 继续返回 BFF 登录信封与 Token，不返回原上游成功响应。 |
| 已有平台、账号与 Session | 数据和兼容行为全部不变。 |

## 不做

- 不修改前端绕过浏览器安全策略。
- 不使用 `Access-Control-Allow-Origin: *`，也不关闭凭据模式。
- 不扩大允许的请求头、请求方法或可暴露响应头清单。
- 不改写上游响应正文，不把普通代理改成全量缓冲。
- 不启动或停止本地服务；服务级浏览器复验需要单独授权。

## 注意事项

- 本轮只恢复全局 CORS 配置在原生流式响应分支中的既有语义，不引入新的外部接口字段或数据库契约。
- 普通代理必须继续零缓冲流式转发，不能为修 CORS 读取完整响应体。
- 具体文件范围见 [change-scope](./change-scope.md)。
