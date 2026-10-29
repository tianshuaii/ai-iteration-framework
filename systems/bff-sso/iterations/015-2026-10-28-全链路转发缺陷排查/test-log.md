# 测试记录

## 自动

| 编号 | 关联 | 仓库/模块 | 命令与结果 | 基线 | 结果 | 说明 |
|---|---|---|---|---|---|---|
| AUTO-01 | T-01～T-03 / verify | `adx-bff-backend` proxy 定向 | `pnpm test -- --runInBand src/proxy/http-passthrough.service.spec.ts src/proxy/platform-request-context.service.spec.ts src/proxy/platform-login-response.service.spec.ts`，exit 0，3 suites / 22 tests | `main@04334264b59ec98a864a4ffb461081356394a6c4`，工作区仅接管前 `?? CODE_REVIEW.md`，2026-10-28T11:53:49+08:00 | 通过 | 覆盖白名单不注头、非白名单注入两头、登录路由免 Session、平台上下文失效拒绝 |
| AUTO-02 | T-01～T-03 | 本轮证据文件检查 | `test -f evidence/analysis/forward-audit.md && test -f evidence/analysis/defect-list.md && rg -q '责任侧' evidence/analysis/defect-list.md && rg -q 'bff-sso 缺陷：无' evidence/analysis/defect-list.md && test -f evidence/analysis/mergex-manager-handoff.md`，exit 0 | 本轮文档，2026-10-28T11:53:49+08:00 | 通过 | 任务检查命令 |

## 手工 / 验收用例

| 编号 | 时间 | 结果 | 证据 |
|---|---|---|---|
| TC-01 | 2026-10-28 | 通过 | 源码 `upstreamHeaders` + AUTO-01 白名单用例：上游无两头 |
| TC-02 | 2026-10-28 | 通过 | 源码非白名单先 `sessionGuard`；缺令牌不进入带身份发送 |
| TC-03 | 2026-10-28 | 通过 | 登录路由免 Session、不注头；成功走 `PlatformLoginResponseService`；失败原样返回 |
| TC-04 | 2026-10-28 | 通过 | AUTO-01 非白名单断言只注入服务端两头；Headers 新建不复制 Authorization |
| TC-05 | 2026-10-28 | 通过 | Session 失效抛错在注入前；`requireForwardIdentity` 失效路径不解密 |
| TC-06 | 2026-10-28 | 通过 | `defect-list.md` 写明 bff-sso/MergeX 代码缺陷均为无；handoff 写明不新建对端轮 |
| SR-01 | 2026-10-28 | 通过 | 未启服务；以 AUTO-01 覆盖四段主路径等价断言，停止边界同测试策略 |
| SR-02 | 2026-10-28 | 通过 | 本轮未改 Auth/Session 产品代码；定向单测含登录接管与 Session 上下文，未扩到 gRPC |

未启动前后端服务；未写库；未提交推送。
