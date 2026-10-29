# 测试用例

前置：账号后端能启动。示例地址只用文档地址，例如网关 `192.0.2.10:5003`，登录服务 `192.0.2.10:5001`。不把真实内网地址写进记录。

## TC-01 不写接入方式仍走 Nacos

1. 配置里不写 `BFF_ACCESS_TYPE`。
2. 停用一个账号。

期望：

- 仍向 Nacos 要网关实例。
- 调用的方法是 `RevokeByAccount`。

## TC-02 直连网关踢登录

1. `BFF_ACCESS_TYPE=direct`。
2. `BFF_GRPC_URL` 和 `BFF_SESSION_PROTO_PATH` 都有值。
3. 停用一个账号。

期望：

- 调用打到 `BFF_GRPC_URL`。
- 方法仍是 `RevokeByAccount`，仍带原来的内部令牌。
- 这次不查询网关的 Nacos 服务名，启动时也不订阅它。

## TC-03 直连资料不全

1. `BFF_ACCESS_TYPE=direct`。
2. 去掉地址，再去掉接口文件路径，各试一次停用账号。

期望：

- 两次都失败。
- 不改去问 Nacos。

## TC-04 其他踢登录操作

1. 网关保持直连，地址和接口文件路径齐全。
2. 分别删除账号、停用角色、删除角色。

期望：

- 三次都调用 `RevokeByAccount`。
- 角色上绑了哪个账号，就踢哪个账号。和现在一样。

## TC-05 直连登录服务设密码

1. `SSO_ACCESS_TYPE=direct`，`SSO_GRPC_URL` 和 `SSO_PROTO_PATH` 有值。
2. 做一次现在会调用 `SetPassword` 的操作。

期望：

- 调用打到 `SSO_GRPC_URL`。
- 不查询登录服务的 Nacos 服务名。

## TC-06 两个目标各走各的

1. `BFF_ACCESS_TYPE=direct`，地址和接口文件路径齐全。
2. 不写 `SSO_ACCESS_TYPE`。
3. 停用账号，并做一次设密码。

期望：

- 踢登录走固定地址。
- 设密码仍走 Nacos。
