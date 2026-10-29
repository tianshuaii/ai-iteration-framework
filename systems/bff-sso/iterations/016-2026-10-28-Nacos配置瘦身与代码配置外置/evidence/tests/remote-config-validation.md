# 远端配置解析与发布验证

- executed_at: `2026-10-28T16:04:00+08:00`
- environment: Nacos `mergex-test` 与 `mergex-dev`
- authorization: 用户已授权迭代 016 的 dev/test 配置写入与回滚，并授权随机生成 test 平台主密钥
- service_start_stop: 未执行
- prod_access: 未执行

## 执行方式

每个仓库分别使用自己的 `.env.test` 或 `.env` 作为 bootstrap，只加载 Nacos 首次连接所需字段；随后调用仓内 `loadNacosConfig` 取得目标 Data ID，并将合并后的环境传入 `validateEnv`。输出只保留服务、环境和 `schema ok`，不输出远端正文或敏感值。

## 结果

| 环境 | BFF | Admin | SSO |
|---|---|---|---|
| test | schema ok | schema ok | schema ok |
| dev | schema ok | schema ok | schema ok |

六份配置均通过强类型解析。发布过程的前后 SHA-256、键数、Admin/Client 精确读回及两次实际回滚记录见 `evidence/delivery/nacos-publish-preflight.md`。

## 停止边界

本验证覆盖配置中心真实读取、合并和 Schema 解析，不启动监听端口，不连接业务数据库验证平台密钥历史密文，也不执行全系统接口回归。
