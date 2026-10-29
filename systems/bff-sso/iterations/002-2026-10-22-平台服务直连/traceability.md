# 跟踪表

| 需求要点 | 验收 | 用例 | 主要文件 |
|---|---|---|---|
| 不写接入方式时踢登录仍走 Nacos | AC-01 | TC-01 | `src/clients/bff.client.ts` |
| 直连网关仍调用 `RevokeByAccount`，不查 Nacos | AC-02 | TC-02 | `src/clients/bff.client.ts`、`src/nacos/nacos-subscription.registry.ts` |
| 直连资料不全就失败，不退回 Nacos | AC-03 | TC-03 | `src/clients/bff.client.ts` |
| 删除账号、停用或删除角色也踢登录 | AC-04 | TC-04 | `src/governance/governance-account.service.ts`、`src/governance/governance-role.service.ts` |
| 直连登录服务仍调用 `SetPassword` | AC-05 | TC-05 | `src/clients/sso.client.ts` |
| 网关和登录服务可以各选一种方式 | AC-06 | TC-06 | `src/config/app.config.ts` |
