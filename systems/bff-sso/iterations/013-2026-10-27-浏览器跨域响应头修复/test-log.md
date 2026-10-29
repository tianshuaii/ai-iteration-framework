# 测试记录

测试目标：`/Users/mrzater/docker/adx/adx-bff-backend`，分支 `main`，接管 HEAD `da98f0c40bab372e247c39a6541e02a6eec281a9`，工作区包含已登记的 011/012 dirty 与本轮 T-01 增量。未启动服务、未访问真实上游、未写数据库、Redis 或 Nacos。

## 自动检查与复用记录

| 记录 | 任务/阶段 | 仓库/范围 | 命令或证据 | 输入基线 | 结果 | 复用说明 |
|---|---|---|---|---|---|---|
| AUTO-01 | T-01 / verify | `adx-bff-backend` 三个 proxy spec | `pnpm test -- --runInBand src/proxy/raw-response-headers.spec.ts src/proxy/http-passthrough.service.spec.ts src/proxy/platform-login-response.service.spec.ts` | 2026-10-27 16:26，最终 T-01 工作区 | 通过：exit 0，3 suites / 21 tests | code review 修复数值头后已重跑；验收期间代码、依赖和配置未再变化，直接复用。 |
| AUTO-02 | T-01 / verify | `adx-bff-backend` build | `pnpm build` | 2026-10-27 16:26，最终 T-01 工作区 | 通过：exit 0 | 修复 TS2322 后重跑；验收期间输入未变化，直接复用。 |
| AUTO-03 | code review | 新 helper 与两个生产 service | `pnpm exec eslint src/proxy/raw-response-headers.ts src/proxy/raw-response-headers.spec.ts src/proxy/http-passthrough.service.ts src/proxy/platform-login-response.service.ts --max-warnings=0` | 2026-10-27 16:27，最终 T-01 工作区 | 通过：exit 0，0 error / 0 warning | 输入未变化，直接复用。两个接管前历史 spec 的整文件 lint 基线问题不属于本轮新增诊断。 |
| AUTO-04 | code review | 本轮工作区 | `git diff --check` | 2026-10-27 16:27，最终 T-01 工作区 | 通过：exit 0 | 输入未变化，直接复用。 |

## 返工历史

- 2026-10-27 16:25：首次三个定向 spec 通过（3 suites / 20 tests），随后 `pnpm build` 失败，`raw-response-headers.ts` 报 TS2322。统一 code review 认定为 P1-01；在 raw 边界把 Fastify number 头转换为字符串并补测试后，AUTO-01/AUTO-02 均通过。受影响 AC-01、AC-02、AC-03、AC-05 已按最终代码重新验证。

## 正式用例

| 用例 | 日期 | 结果 | 现象 |
|---|---|---|---|
| TC-01 | 2026-10-27 | 通过 | 普通代理 spec 的 raw `writeHead` 同时包含 `content-type: text/plain` 和 `access-control-allow-origin: http://frontend.test`；内存 Fastify+CORS 注入也返回动态 Origin、credentials、正文 `ok`。 |
| TC-02 | 2026-10-27 | 通过 | 平台登录 `code=401` / HTTP 422 保持 `x-upstream`、JSON 原始正文和 BFF Origin，不创建 Session。 |
| TC-03 | 2026-10-27 | 通过 | 上游提供 `http://upstream.invalid` 时，最终 Origin 为 BFF 的 `http://frontend.test`；helper 单测同时验证 credentials、Vary 与数值头转换。 |
| TC-04 | 2026-10-27 | 通过 | 既有成功用例继续按 `data.userId` 找绑定、创建平台 Portal Session 并发送标准 BFF 登录信封。 |
| TC-05 | 2026-10-27 | 通过 | 静态检查确认 `pipeline(Readable.fromWeb(...), reply.raw)` 保持不变，`src/main.ts` 未修改，build 通过。 |

## 受控浅功能回归

| 用例 | 日期 | 结果 | 现象 |
|---|---|---|---|
| SR-01 | 2026-10-27 | 通过 | 直接路径覆盖普通 `/proxy/...` 200 流式响应；状态、Content-Type、正文与 BFF CORS 头同时保留。停止在内存 Fastify 注入和 service spec，未启动真实服务或扩展到下载接口。 |
| SR-02 | 2026-10-27 | 通过 | 相邻路径覆盖平台登录失败原样返回和成功创建 Session；两条语义均保持。未扩展到数据库绑定并发、密钥加密和管理页面。 |

没有豁免。服务级浏览器运行态未在本轮启动，因为用户授权明确不包含服务启停；本轮用内存 Fastify+CORS 生命周期测试复现并验证相同响应头边界。
