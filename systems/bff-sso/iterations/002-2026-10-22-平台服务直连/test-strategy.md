# 测试策略

## 自动

| 项目 | 命令 | 要挡住的错误 |
|---|---|---|
| `adx-admin-backend` | `pnpm test -- src/clients/bff.client.spec.ts src/clients/sso.client.spec.ts src/nacos/nacos-subscription.registry.spec.ts` | 直连仍去查 Nacos、直连失败后又改去查 Nacos、缺地址仍调用成功、不写接入方式时不再走 Nacos、直连时仍订阅网关 |

## 手工

按 [test-cases](./test-cases.md) 执行，结果写入 [test-log](./test-log.md)。

手工只在自动测试通过后抽一条：把网关配成直连，停用一个测试账号，确认登录被踢掉。不把真实地址写进记录。

## 回归

不能被改坏的老路径：

- 不写 `BFF_ACCESS_TYPE`、`SSO_ACCESS_TYPE` 时，踢登录和设密码仍走 Nacos。
- 网关按接入服务记录转发的行为不改。那是 001 的范围。
- 从 Nacos 拉自己的配置、把自己注册到 Nacos，这两件不改。
