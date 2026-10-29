# 验收标准

| 编号 | 对应测试 | 标准 | 结果 |
|---|---|---|---|
| AC-01 | TC-01 | 不写接入方式时，停用账号仍通过 Nacos 找到网关，并调用 `RevokeByAccount` | 通过 |
| AC-02 | TC-02 | `BFF_ACCESS_TYPE=direct` 且地址、接口文件路径都有时，停用账号打到 `BFF_GRPC_URL`，不查询、不订阅网关的 Nacos 服务名 | 通过 |
| AC-03 | TC-03 | 直连网关时地址或接口文件路径为空，踢登录失败，不改去问 Nacos | 通过 |
| AC-04 | TC-04 | 删除账号、停用角色、删除角色在直连时也调用同一个 `RevokeByAccount` | 通过 |
| AC-05 | TC-05 | `SSO_ACCESS_TYPE=direct` 时，设密码打到 `SSO_GRPC_URL`，不查询登录服务的 Nacos 服务名 | 通过 |
| AC-06 | TC-06 | 网关用直连、登录服务不写接入方式时，设密码仍走 Nacos，踢登录走固定地址 | 通过 |
