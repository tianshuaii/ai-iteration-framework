# 改动范围

仓库绝对路径写在这套系统的 `overview.md`。默认按那个路径打开原仓库；并发隔离时按本轮 `workspace.md` 中由脚本登记的 `.worktrees/` 临时检出打开。系统名：`bff-sso`。

## 要改的项目

| 项目 | 这一轮它负责什么 |
|---|---|
| `adx-bff-backend` | 经重复冷样本证明瓶颈后，限定范围内优化首次转发和运行时解析并补定向测试。当前 `specify` 阶段不改产品仓库。 |

## 页面上要改的位置

同一页上相关的说明、筛选、表格、弹窗都要写。不要只写用户圈出的那一块。

| 位置 | 现在 | 改完 |
|---|---|---|
| 请求查询页页头、筛选、结果表与空状态 | 展示已有请求记录。 | 不变。 |
| 请求日志详情的总耗时、请求周期、时间轴和提示 | 展示现有计时事件与待归因区间。 | 不变；定位证据放本轮测试记录，不暗改页面口径。 |
| 运行包、白名单、接入服务的新增/编辑与连通测试弹窗 | 按原流程配置、保存与提示。 | 不变。 |

## 大致文件

### `adx-bff-backend`

- `src/proxy/http-passthrough.service.ts`：直通的生效包查询、首次接口清单匹配入口；证实瓶颈后才改。
- `src/runtime-interface/services/runtime-package-inventory.service.ts`：直通冷载入接口清单的直接调用处；证实瓶颈后才改。
- `src/proxy/proxy.service.ts`：单发及批量共用的单项转发入口；证实瓶颈后才改。
- `src/runtime-interface/services/runtime-interface-resolver.service.ts`：单发/批量的运行包解析和缓存冷加载；证实瓶颈后才改。
- `src/runtime-interface/services/runtime-interface-cache-sync.service.ts`：仅当需要调整缓存命中或失效时才改，保留跨实例一致性。
- `src/request-logs/trace-context.ts`：如计时边界不足，仅补必要分段，不改变对外日志字段契约。
- `src/proxy/proxy.controller.ts`：仅当批量外层计时确需补充时改，不改批量协议和并发语义。
- `src/common/guards/session.guard.ts`、`src/session/session.service.ts`、`src/clients/admin-forward-context.client.ts`：仅在守卫前置间隔继续无法归因时补必要计时或安全等价的冷路径优化；不跳过账号状态、Session 续期或授权上下文刷新。

### 补测试

- `src/proxy/http-passthrough.service.spec.ts`：直通冷/热路径、失败重试与切包匹配。
- `src/proxy/proxy.service.spec.ts`：单发、批量共用转发及安全回归。
- `src/runtime-interface/services/runtime-package-inventory.service.spec.ts`：若改清单加载，覆盖冷载入与失败路径。
- `src/runtime-interface/services/runtime-interface-resolver.service.spec.ts`：若改解析缓存，覆盖并发合并、激活、回滚、归档与显式 `packageId`。
- `src/proxy/proxy.controller.spec.ts`：若调整批量外层计时或聚合，再增加定向测试。
- `src/common/guards/session.guard.spec.ts`、`src/session/session.service.spec.ts`：若改相应鉴权链路，扩充失效会话、刷新到期、账号状态及错误回退；若改账号上下文客户端，新增 `src/clients/admin-forward-context.client.spec.ts` 定向测试。
- 本轮 `scripts/`：后续经计划阶段确定的脱敏冷路径采样脚本和结果；`specify` 阶段不写脚本。

## 明确不动

| 项目 | 为什么不动 |
|---|---|
| `adx-bff-frontend` | 本轮不改页面和日志展示口径；如需 UI 改动先回 `specify` 扩围。 |
| `adx-sso-backend` | 无已证实的鉴权服务瓶颈，本轮不改。 |
| `adx-admin-backend` | 不改账号权限与治理表；无迁移。 |
| `adx-admin-frontend` | 不改账号管理页。 |
| 产品仓库中其余文件 | 不在本轮范围；若证据要求改动，先更新范围及 AC/TC。 |

## 接管提醒

只读盘点时，`adx-bff-backend` 的 `src/proxy/http-passthrough.service.ts` 和同名 `.spec.ts` 已有未提交改动，归属未核实。后续先预留隔离检出及运行资源，实施前逐文件记录分支、HEAD 和 dirty 状态，不覆盖既有改动。
