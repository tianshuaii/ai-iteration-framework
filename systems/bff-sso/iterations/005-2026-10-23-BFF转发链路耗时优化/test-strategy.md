# 测试策略

## 自动

| 项目 | 命令 | 要挡住的错误 |
|---|---|---|
| `adx-bff-backend` | `pnpm test -- src/proxy/http-passthrough.service.spec.ts src/request-logs/request-log-hooks.spec.ts src/request-logs/request-log-list-item.spec.ts src/request-logs/redis-log-store.spec.ts` | 分段计时边界、原始流响应完整性判定、直通鉴权/流式行为、列表与详情口径、采集失败不影响转发。实际改动后按受影响文件补充测试。 |
| `adx-bff-frontend` | `pnpm test -- src/features/request-logs/request-log-timeline.util.spec.ts` | 时间轴在同毫秒事件、缺失事件和历史日志下不误报阶段。 |

## 手工

按 [test-cases](./test-cases.md) 执行，结果写入 [test-log](./test-log.md)。

性能基线先在同一部署版本、同一接口与环境采集足够多的冷/热样本，记录请求方法、请求体大小、目标发现模式、负载、时间窗口、Trace ID、样本量、P50/P95 及上游时间。先排除真正缺失事件的日志，再分析分段；与浏览器 Network 或独立客户端时间交叉核对。优化后保持这些条件相同再复测。用户确认的热路径达标线为“预热后 BFF 入站至上游请求前 P95 ≤ 100 ms”；冷路径单独报告。样本量与执行环境在计划阶段固定，当前验收结果仍为未测。

## 回归

不能被改坏的老路径：

- HTTP 直通：白名单免登录、非白名单登录、接口匹配、唯一生效包、GET/POST/PUT/DELETE、流式传输及上游失败响应。
- `POST /proxy/one` 与 `POST /proxy/batch`：登录、请求/响应格式、错误与超时。
- 运行包启停或切换后，直通应使用当前环境生效包；权限/会话变化不能因缓存而失效延迟超出已约定行为。
- 请求日志脱敏、采集失败隔离及旧日志详情展示。
