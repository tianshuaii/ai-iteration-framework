# 任务清单

每条代码任务执行定向检查后都要 code review、修复并复验，完成这些步骤才勾选。产品文件先按 `workspace.md` 逐文件复核 HEAD 与接管前 dirty 状态；未得到明确“开始执行”或“开始处理”授权前不改产品源码。整套回归和最终性能验收在 `verify` 阶段记录，不在这里预先勾选。

- [x] T-01 为 HTTP 直通增加单调时钟分段事件并核对无敏感数据，明确入站至上游发起边界。依赖：无。文件：`adx-bff-backend/src/proxy/http-passthrough.service.ts`、`src/request-logs/request-log-hooks.ts`、`src/request-logs/trace-context.ts`、`src/proxy/http-passthrough.service.spec.ts`、`src/request-logs/request-log-hooks.spec.ts`。检查：`pnpm test -- src/proxy/http-passthrough.service.spec.ts src/request-logs/request-log-hooks.spec.ts src/request-logs/trace-context.spec.ts`。
- [x] T-02 仅缓存当前生效包 ID 对应的原接口集合，保留逐请求生效包、白名单和服务查询；覆盖并发冷加载、切包、白名单变化及失败关闭。依赖：T-01；在可控测试环境采集优化前基线后再改。文件：`adx-bff-backend/src/proxy/http-passthrough.service.ts`、`src/proxy/http-passthrough.service.spec.ts`。检查：`pnpm test -- src/proxy/http-passthrough.service.spec.ts`。
- [x] T-03 修正直通原始流日志的完整性判定，区分 `onSend` 不触发与真实事件缺失。依赖：T-01；与 T-02 的产品文件不重叠，可在取得代码授权后独立排期。文件：`adx-bff-backend/src/request-logs/redis-log-store.ts`、`src/request-logs/redis-log-store.spec.ts`。检查：`pnpm test -- src/request-logs/redis-log-store.spec.ts`。
- [x] T-04 明确列表、详情耗时口径及时间轴区间名称，兼容旧日志与不完整记录。依赖：T-01、T-03。文件：`adx-bff-frontend/src/features/request-logs/RequestQueryPage.tsx`、`src/features/request-logs/request-logs-table.util.tsx`、`src/features/request-logs/request-log-timeline.util.ts`、`src/features/request-logs/RequestLogLifecycleTimeline.tsx`、`src/features/request-logs/request-log-timeline.util.spec.ts`。检查：`pnpm test`。
