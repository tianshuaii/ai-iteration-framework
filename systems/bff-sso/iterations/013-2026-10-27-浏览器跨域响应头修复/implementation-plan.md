# 实现计划

## 做法

1. 在 `src/proxy/` 新增一个小型 raw response 响应头合并函数，输入上游端到端响应头和当前 `FastifyReply`。
2. 合并时先放上游响应头，再放 `reply.getHeaders()`；这样保留上游 `Content-Type` 等端到端信息，同时确保 BFF 已按当前 Origin 生成的 CORS 头具有最终优先级。
3. 普通 HTTP 直通继续使用 `Readable.fromWeb(...)` 与 `pipeline(...)`，只把 `writeHead` 的 headers 参数替换为合并结果。
4. 平台登录 `code != 200` 分支继续复制非 hop-by-hop 上游响应头和原始字节，只在最终 `writeHead` 前合并 BFF 响应头。
5. 为合并函数补独立单测，并在两个既有 service spec 的 reply mock 中提供 `getHeaders()`，覆盖普通流式响应和平台登录失败/成功相邻路径。

不增加配置、数据库字段、依赖或运行时缓冲。

## 为什么这样切

- 两个故障分支使用相同的原生响应写出边界，集中一个纯函数可以固定“BFF 同名头优先”的规则，避免以后两处分叉。
- 辅助文件保持很小，避免让已经接近 500 行的 `http-passthrough.service.ts` 越过后端文件规模边界。
- 只调整 response headers，不触碰请求鉴权、平台身份头、Session 或上游正文处理。

## 怎样避开「不做」

- 不修改 `main.ts` 的全局 CORS 配置，也不写死 Origin。
- 不修改前端、Nacos、Prisma、数据库或 Redis。
- 不启动本地服务；用定向单测和构建完成当前授权范围内的验证。
- 不提交、推送、合并、拉取或部署。

## 字段变化

| 字段或路径 | 谁在用 | 变化 |
|---|---|---|
| HTTP 响应头 | 浏览器、Fastify raw response | 尚未改代码；计划保留 `reply.getHeaders()` 并让 BFF 同名头优先。 |
| HTTP 响应正文 | 普通代理、平台登录失败 | 尚未改代码；保持现有流式或原始字节逻辑。 |
| 数据库、Session、API 请求字段 | BFF 与管理端 | 无变化。 |
