# TC-08 本人改密 Session 吊销失败

- 时间：2026-10-26T18:31:00+08:00
- 环境：本轮隔离五服务端口、专用数据库 `mergex_manager_iter009_20261026`、独占 Redis DB14。
- 基线：`adx-sso-backend` `master@6437527b4eab8f86b0b697b88d81bbdbf310d1c0` 与 `adx-bff-backend` `main@c57b594194cdfd40f3d24e6d7836ebc0b0e453da` 加本轮工作区；BFF 接管前 HTTP 直通 dirty 未参与。
- 操作：创建隔离平台员工，取得 Portal Session，经 SSO `ChangePassword` 执行本人改密，再使用改密前 Session 调用 `/api/portal/account/me`；最后软删除夹具。
- 结果：命令退出码 `0`，本人改密成功，但旧 Session 请求返回 HTTP `200`、业务码 `200`，`oldSessionInvalidated=false`，不符合 TC-08“目标账户全部旧 Session 立即失效”。
- 对照：同环境下管理员重设密码后旧 Session 返回业务码 `40102`，禁用/软删除路径也会按账户吊销，缺陷收窄到本人改密编排未调用 BFF Session 吊销。
- 安全：证据只记录状态码和布尔结果，不保存测试密码、Token、盐或哈希；测试账户已软删除。
- 影响：TC-08、TC-11、TC-13、SR-01；追加 T-13 在现有认证范围内修复并重验。
