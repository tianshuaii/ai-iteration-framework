# 改动范围

系统：`bff-sso`。仓库绝对路径只看系统 [overview](../../overview.md)。以下是定位阶段的初始范围；实测后若需要增加文件，先更新本文件。

## 要改的项目

| 项目 | 这一轮它负责什么 |
|---|---|
| `adx-bff-backend` | 分段测量 BFF 直通请求，依据证据优化实际瓶颈，保留转发与鉴权语义。 |
| `adx-bff-frontend` | 请求查询的耗时口径、时间轴标签与不完整记录提示。 |

## 页面上要改的位置

页面的筛选项、其他列、抽屉参数快照和菜单本轮不变。

| 位置 | 现在 | 改完 |
|---|---|---|
| 请求查询列表“耗时”表头 | 显示子请求条目耗时，但未标明口径。 | 明确是子请求耗时；历史或无条目数据说明采用的口径。 |
| 请求日志详情“耗时” | 显示整条 BFF 请求耗时。 | 明确是 BFF 整条请求耗时，与列表区分。 |
| 请求周期时间轴与事件名称 | 相邻事件差可能被展示成“读取请求体”耗时。 | 阶段文字符合实际边界；缺失事件时不作确定性归因。 |
| 详情“不完整”提示 | 只提示可能丢弃或写入失败。 | 保持可见，并说明该次阶段耗时不能当作可靠基线。 |

## 大致文件

### `adx-bff-backend`

- `src/proxy/http-passthrough.service.ts`：直通请求的分段测量与经证据确认的热路径优化。
- `src/runtime-interface/services/runtime-package-inventory.service.ts`：核对直通请求是否不必要地反复读取或解析完整运行包；仅当测量确认瓶颈在此时优化。
- `src/request-logs/request-log-hooks.ts`、`src/request-logs/trace-context.ts`：调整阶段采集边界和计时数据，使日志本身的开销可区分且不改变转发结果。
- `src/request-logs/request-log-list-item.ts`：仅在耗时口径需要明确字段时修改；历史记录需兼容。
- `src/request-logs/redis-log-store.ts`：核实并修正原始流响应的完整性判定，不能掩盖真实丢失事件。

### `adx-bff-frontend`

- `src/features/request-logs/RequestQueryPage.tsx`：详情耗时与不完整样本的说明。
- `src/features/request-logs/request-logs-table.util.tsx`：列表耗时口径的表头或提示。
- `src/features/request-logs/request-log-timeline.util.ts`、`src/features/request-logs/RequestLogLifecycleTimeline.tsx`：时间轴名称和区间显示。
- `src/lib/request-logs-api.ts`：仅在后端日志响应字段随测量调整时同步类型。

### 补测试

- `adx-bff-backend/src/proxy/http-passthrough.service.spec.ts`、`src/request-logs/request-log-hooks.spec.ts`、`src/request-logs/request-log-list-item.spec.ts`、`src/request-logs/redis-log-store.spec.ts`：覆盖分段口径、完整性判定、匹配/鉴权/流式转发及优化后的正确性。
- `adx-bff-frontend/src/features/request-logs/request-log-timeline.util.spec.ts`：覆盖时间轴阶段名称、区间和不完整数据。

## 明确不动

| 项目 | 为什么不动 |
|---|---|
| `adx-sso-backend` | 截图与当前链路未指向 SSO 的业务处理。 |
| `adx-admin-backend` | 本轮不改账号业务和治理表，不做迁移。 |
| `adx-admin-frontend` | 本轮优化 BFF 转发与网关请求查询。 |

`adx-bff-backend` 的 Nacos、会话与单发/批量实现先只读检查和回归；若成为实测瓶颈，按待确认事项扩围。所有产品文件在 `specify` 阶段均不修改。
