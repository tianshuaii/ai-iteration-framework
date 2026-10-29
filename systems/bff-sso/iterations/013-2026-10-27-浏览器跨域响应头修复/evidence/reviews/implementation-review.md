# 迭代级统一代码审核

- reviewer: `code-review-skill`
- provider_version: `local-skill`
- input_digest: `27c959c77b076aba106ee8b11ca84cd837430b3a01c7098a3abecbf75e50ef8f`
- started_at: `2026-10-27T16:25:34+08:00`
- completed_at: `2026-10-27T16:27:36+08:00`
- result: `approved`
- findings: `P0=0, P1=0, P2-open=0`

## 审核范围

- `src/proxy/raw-response-headers.ts`
- `src/proxy/raw-response-headers.spec.ts`
- `src/proxy/http-passthrough.service.ts` 的 raw response 写出调用点
- `src/proxy/http-passthrough.service.spec.ts` 的 CORS 响应头断言
- `src/proxy/platform-login-response.service.ts` 的业务失败原样返回调用点
- `src/proxy/platform-login-response.service.spec.ts` 的上游/BFF 同名头优先级断言

接管前 011/012 的其余 dirty 只作为调用链背景，不计入本轮差异，也未被回退或重排。

## 发现与修复

### P1-01 Fastify 数值响应头与 Node writeHead 类型不兼容（已修复）

- 首次 `pnpm build` 在 `raw-response-headers.ts` 报 TS2322：Fastify 允许 number 头值，而 Node 的已知 header 类型不接受部分 number 值。
- 修复为在 raw 边界把有限的 number 头值转换为字符串，字符串与多值数组保持原样，undefined 不写出。
- 新增 `content-length: 42 -> "42"` 回归断言；修复后定向测试与 build 通过。

## 逐项结论

- 正确性：上游头先合并、BFF/Fastify 头后合并，动态 Origin、credentials、Vary 与链路头可以进入最终 raw response；同名上游 CORS 不能覆盖 BFF。
- 安全：未硬编码 `*`，未扩大允许方法或请求头；浏览器边界仍由现有全局 CORS 配置决定。
- 性能：普通代理仍使用 `pipeline(Readable.fromWeb(...), reply.raw)`，没有新增响应体缓冲。
- 兼容：平台登录失败继续保持上游状态、端到端头和原始字节；登录成功仍走 BFF Session 信封。
- 范围：没有修改前端、`main.ts`、Nacos、数据库、Prisma、Session 或其他仓库。
- 文件规模：新增 helper 36 行、helper spec 78 行；生产 service 分别 482/159 行，未越过后端 500 行门禁。

## 检查记录

| 检查 | 结果 |
|---|---|
| 首次三个定向 spec | 3 suites / 20 tests 通过 |
| 首次 `pnpm build` | 失败，发现并修复 P1-01 |
| 修复后三个定向 spec | 3 suites / 21 tests 通过 |
| 修复后 `pnpm build` | 通过 |
| 新 helper 与两个生产 service 的 ESLint | 通过，0 error / 0 warning |
| `git diff --check` | 通过 |

补充：把两个接管前已经 dirty 的历史 spec 整文件纳入 ESLint 会报告 17 errors / 1 warning，位置均来自 011/012 既有测试写法；本轮新增 helper、生产实现和新增断言未引入新的 ESLint 诊断。本轮未扩大范围重写历史测试基线。

## 结论

Approve。P0、P1、P2-open 均为 0，可以进入按风险验收。
