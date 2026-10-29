<!-- shallow-regression-policy: bounded-v1 -->
<!-- risk-based-testing-policy: adaptive-v1 -->
# 测试策略

## 任务风险分级

| 任务 | 档位 | 分级理由 | 影响仓库/模块 | 必须执行 | 可复用证据 | 升级条件 |
|---|---|---|---|---|---|---|
| T-01 | T3 | 修改代理层共享响应边界，影响普通流式直通和平台登录失败原样返回，但不改接口字段、权限或数据。 | `adx-bff-backend/src/proxy` | 两个定向 spec、BFF build、差异 code review、框架定向校验。 | 012 的平台登录成功单测可作为未改契约的历史参考，但本轮仍跑受影响 spec。 | 若需改全局 CORS 配置、请求头白名单、数据库或 Session，则回规格并升级范围。 |

## 自动

| 项目 | 命令 | 要挡住的错误 |
|---|---|---|
| `adx-bff-backend` | `pnpm test -- --runInBand src/proxy/http-passthrough.service.spec.ts src/proxy/platform-login-response.service.spec.ts` | raw response 丢失已有 CORS 头、上游覆盖 BFF CORS、状态/正文/登录成功回归。 |
| `adx-bff-backend` | `pnpm build` | TypeScript 类型、Nest 构建和产物生成错误。 |
| 迭代框架 | `ruby scripts/validate-framework.rb --iteration systems/bff-sso/iterations/013-2026-10-27-浏览器跨域响应头修复` | 需求、任务、评审、验收和状态门禁不一致。 |

## 手工

按 [test-cases](./test-cases.md) 执行，结果写入 [test-log](./test-log.md)。本次授权不包含本地服务启停，因此默认以可复现的单测模拟跨域响应头；若后续取得服务启停授权，再补浏览器或带 `Origin` 的 HTTP 运行态复验。

## 回归

- 平台登录 `code == 200` 仍按 `data.userId` 查绑定并创建 BFF Session。
- 普通代理保持上游状态、`Content-Type` 与零缓冲流式正文。
- 平台登录 `code != 200` 仍原样返回上游状态、端到端响应头和原始正文。

## 受控浅功能回归

| 编号 | 类型 | 功能或路径 | 纳入理由 | 停止边界 |
|---|---|---|---|---|
| SR-01 | 直接 | 普通 `/proxy/...` 流式响应包含 BFF CORS 头。 | 截图直接命中的故障路径。 | 不启动真实上游，不扩展到所有 HTTP 方法和文件下载。 |
| SR-02 | 相邻 | 平台登录业务失败原样响应与登录成功标准响应。 | 共用 raw response 边界，且失败分支存在同类缺陷。 | 不重测数据库绑定并发、密钥加密和管理页面。 |
