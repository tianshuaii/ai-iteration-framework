# 测试策略

## 自动

| 项目 | 命令 | 要挡住的错误 |
|---|---|---|
| `adx-bff-backend` | `pnpm exec jest --runInBand --runTestsByPath src/proxy/http-passthrough.service.spec.ts src/proxy/proxy.service.spec.ts src/runtime-interface/services/runtime-package-inventory.service.spec.ts src/runtime-interface/services/runtime-interface-resolver.service.spec.ts`；若改鉴权链路，增跑对应 `session.guard.spec.ts`、`session.service.spec.ts` 及新建的账号上下文客户端测试 | 改动的冷载入、失败重试、切包失效、会话刷新、单发/批量转发分支至少有一条退化会失败的检查；仅执行存在且本轮实际改到的测试。 |
| `adx-bff-backend` | `pnpm build` | 类型、编译与模块接线错误。 |
| `adx-bff-backend` | `pnpm exec eslint` 加本轮实际改动的产品文件路径 | 只读检查候选修改文件的 lint，不使用会写文件的 `pnpm lint`。 |

## 手工

按 [test-cases](./test-cases.md) 在获准的受控环境执行，结果写入 [test-log](./test-log.md)，附环境、BFF 分支/HEAD 或工作区基线、包版本、冷触发方式、异步预热与 CORS 预检状态、Session 刷新条件、脱敏原始样本和计时口径。用户已授权短时重启本机 BFF 及临时改测试服务直连并同轮恢复；清 Redis、切包不在授权内。规格阶段的 3×4 个重启后首条业务请求只记入需求背景，不把探索样本或历史截图填成用例“通过”。

## 回归

不能被改坏的老路径：白名单免登录与非白名单登录校验；未知原接口拒绝；`GET /user/code` 和 `GET /abTestExperiment/getVersionNameList` 直通；`POST /proxy/one` 响应信封；`POST /proxy/batch` 多子请求的顺序、`requestId` 和单项错误隔离；默认生效包与显式 `packageId`；包激活、回滚、归档和跨实例缓存失效；第 005 轮已优化的预热后热路径。

首次请求主组只统计独立重启、`/health` 就绪后的第一条业务请求，授权上下文到期刷新另列并报告原因；切包、缓存未命中或长时间空闲在获准后另列，不混算。先比对入站→发上游，后比对整体耗时；上游固定响应的采样只代表 BFF 侧，不推出真实服务容量。用户已确认主组四路暂定 P95 目标和每路至少 30 个有效样本，见 AC-03；当前每路 3 个探索样本仍不能判定达标。
