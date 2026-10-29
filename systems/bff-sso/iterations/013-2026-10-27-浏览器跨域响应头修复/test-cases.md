# 测试用例

前置：使用 service spec 的 FastifyReply 模拟对象预置由全局 CORS 生成的响应头，不启动本地服务，不访问真实上游或数据库。

## TC-01 普通流式代理保留 BFF CORS 头

1. 在 reply 中预置 `access-control-allow-origin: http://localhost:8080`。
2. 模拟上游返回 `200`、JSON `Content-Type` 和流式正文。
3. 执行普通 HTTP 直通。

期望：`writeHead` 包含预置 Origin 与上游 `Content-Type`，状态为 200，正文仍通过流写出。

## TC-02 平台登录业务失败保留原样响应和 BFF CORS

1. 在 reply 中预置 BFF CORS 头。
2. 模拟上游返回 HTTP 422、`code=401`、自定义端到端响应头和原始正文。
3. 执行平台登录响应处理。

期望：HTTP 422、自定义上游头、BFF CORS 头和原始字节全部保留，不创建 Session。

## TC-03 上游 CORS 不能覆盖 BFF CORS

1. BFF reply 预置当前浏览器 Origin。
2. 上游响应提供不同的 `Access-Control-Allow-Origin`。
3. 执行平台登录失败原样返回。

期望：最终写出的同名头使用 BFF 值，不使用上游值。

## TC-04 平台登录成功路径不回归

1. 模拟 `code=200` 与有效 `data.userId`。
2. 模拟找到有效平台账号绑定。
3. 执行响应处理。

期望：创建平台 Portal Session，并发送现有标准 BFF 登录信封，不调用 raw 原样返回。

## TC-05 静态流式边界检查

1. 检查普通代理实现和本轮差异。
2. 确认普通响应仍由 `Readable.fromWeb(...)` 和 `pipeline(...)` 转发。
3. 确认未修改 `main.ts` 的全局 CORS 配置。

期望：普通代理没有新增完整响应读取或缓冲，CORS 仍按现有动态 Origin 与凭据模式处理。

## 受控浅功能回归用例

## SR-01 普通代理主路径

前置：执行普通代理定向 spec。

步骤：覆盖一次 200 流式响应并检查 raw headers、状态和输出正文。

期望：浏览器所需 CORS 头与上游响应语义同时存在。

## SR-02 平台登录相邻路径

前置：执行平台登录响应定向 spec。

步骤：分别覆盖业务失败原样返回和业务成功创建 Session。

期望：失败分支修复 CORS，成功分支保持标准 BFF 登录响应。
