# 任务清单

- [x] T-01 修复普通代理与平台登录失败 raw response 的响应头合并，并补定向回归测试。依赖：无。文件：`src/proxy/raw-response-headers.ts`、`src/proxy/raw-response-headers.spec.ts`、`src/proxy/http-passthrough.service.ts`、`src/proxy/http-passthrough.service.spec.ts`、`src/proxy/platform-login-response.service.ts`、`src/proxy/platform-login-response.service.spec.ts`。检查：`pnpm test -- --runInBand src/proxy/raw-response-headers.spec.ts src/proxy/http-passthrough.service.spec.ts src/proxy/platform-login-response.service.spec.ts && pnpm build`

任务的检查在首次实现完成后统一执行；本轮只有一条任务，随后仍单独执行迭代级统一 code review 和按风险验收。
