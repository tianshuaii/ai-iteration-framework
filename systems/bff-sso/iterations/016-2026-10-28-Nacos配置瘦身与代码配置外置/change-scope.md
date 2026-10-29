# 改动范围

系统名：`bff-sso`

## 要改的项目

| 项目 | 这一轮它负责什么 |
|---|---|
| `adx-bff-backend` | 精简 BFF Nacos 契约、收口强类型配置、补启动与默认值测试 |
| `adx-admin-backend` | 精简 Admin Nacos 契约及重复服务注册参数、补配置测试 |
| `adx-sso-backend` | 精简 SSO Nacos 契约及重复服务注册参数、补配置测试 |

## 页面上要改的位置

本轮没有页面改动。

## 大致文件

### 三个后端共同范围

- `src/config/app.config.ts`：配置 Schema、默认值和 bootstrap/runtime 边界。
- `src/config/*.spec.ts`：精简配置与默认行为测试。
- `nacos-config.dev.yml`、`nacos-config.test.yml`：本地可审计模板同步。
- `.env.example`：最小 Nacos bootstrap 说明；不写真实凭证。

### `adx-bff-backend`

- `src/auth/login-rate-limit.service.ts`：候选安全参数改为强类型配置。
- `src/request-logs/**`、`src/console-logs/**`：只收口已经存在的裸环境读取；是否增加新外置项以访谈结论为准。
- `src/runtime-interface/**`、`src/session/**`：候选缓存与刷新参数的消费点。

### 补测试

- 三仓配置校验测试：删除稳定默认键后仍解析出相同行为；必填密钥/连接缺失仍失败。
- BFF 定向测试：登录退避、Session/运行包缓存参数保持原默认行为并可覆盖。

### 迭代证据

- `evidence/analysis/nacos-config-inventory.md`：只保存键名、分类、消费者和去留理由，不保存敏感值。
- `evidence/analysis/stage-review.md`：需求与计划阶段评审。
- `evidence/delivery/`：获授权后的发布前摘要、读回校验和回滚结果；未获外部写入授权时不得伪造发布证据。

## 明确不动

| 项目 | 为什么不动 |
|---|---|
| `adx-bff-frontend` | 无配置中心读取和页面需求 |
| `adx-admin-frontend` | 无配置中心读取和页面需求 |
| 数据库 Schema/迁移 | 本轮不改变数据模型 |
| 接口协议与 Proto | 本轮不改变对外或内部契约 |
