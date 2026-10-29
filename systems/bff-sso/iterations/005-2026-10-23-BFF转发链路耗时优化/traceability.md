# 跟踪表

| 需求要点 | 验收 | 用例 | 主要文件 |
|---|---|---|---|
| BFF 分段采集与可靠基线 | AC-01 | TC-01 | `adx-bff-backend/src/proxy/http-passthrough.service.ts`、`src/request-logs/request-log-hooks.ts` |
| 列表、详情与时间轴的耗时口径 | AC-02 | TC-02 | `adx-bff-backend/src/request-logs/request-log-list-item.ts`、`adx-bff-frontend/src/features/request-logs/RequestQueryPage.tsx`、`request-log-timeline.util.ts` |
| 定位后优化与对照结果 | AC-03 | TC-03 | `adx-bff-backend/src/proxy/http-passthrough.service.ts`、`src/runtime-interface/services/runtime-package-inventory.service.ts`；实测后更新 |
| 白名单直通和流式响应保持原样 | AC-04 | TC-04 | `adx-bff-backend/src/proxy/http-passthrough.service.ts` |
| 非白名单和非法路径保持原样 | AC-05 | TC-05 | `adx-bff-backend/src/proxy/http-passthrough.service.ts` |
| 单发、批量兼容 | AC-06 | TC-06 | `adx-bff-backend/src/proxy/proxy.controller.ts`、`src/proxy/proxy.service.ts`（只读回归） |
| 日志采集故障隔离 | AC-07 | TC-07 | `adx-bff-backend/src/request-logs/request-log-hooks.ts`、`src/request-logs/trace-context.ts` |
