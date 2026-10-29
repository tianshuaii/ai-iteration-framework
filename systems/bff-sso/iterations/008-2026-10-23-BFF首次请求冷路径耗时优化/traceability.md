# 跟踪表

| 需求要点 | 验收 | 用例 | 主要文件 |
|---|---|---|---|
| 四类首次请求重复基线与口径 | AC-01 | TC-01、TC-02 | 本轮 `scripts/`；`src/proxy/http-passthrough.service.ts`、`src/proxy/proxy.service.ts` |
| 直通、单发与批量分段归因 | AC-02 | TC-03 | `src/request-logs/trace-context.ts`、`src/runtime-interface/services/runtime-package-inventory.service.ts`、`src/runtime-interface/services/runtime-interface-resolver.service.ts`、`src/common/guards/session.guard.ts`、`src/session/session.service.ts`、`src/clients/admin-forward-context.client.ts` |
| 用户确认目标后四路优化与复测 | AC-03 | TC-04 | `src/proxy/http-passthrough.service.ts`、`src/proxy/proxy.service.ts`、`src/runtime-interface/services/runtime-interface-resolver.service.ts` |
| 转发契约、安全校验与缓存生命周期不变 | AC-04 | TC-05、TC-06 | `src/proxy/http-passthrough.service.ts`、`src/proxy/proxy.controller.ts`、`src/runtime-interface/services/runtime-interface-cache-sync.service.ts` 及相关 `.spec.ts` |
| 热路径不明显回退 | AC-05 | TC-07 | 四条路径对应 `.spec.ts`；本轮 `scripts/` |
| 受控环境与脱敏边界 | AC-06 | TC-08 | 本轮 `scripts/`、`test-log.md` |
