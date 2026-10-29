# 测试策略

<!-- shallow-regression-policy: bounded-v1 -->

## 自动

| 项目 | 命令 | 要挡住的错误 |
|---|---|---|
| `adx-admin-frontend` | `pnpm test -- --run`、`pnpm typecheck`、`pnpm lint:ci`、`pnpm build` | 删除后仍有旧路由/资源引用，账户页字段或类型失配。 |
| `adx-admin-backend` | 定向 Jest、`pnpm test -- --runInBand`、`pnpm build`、`pnpm check:db-comments`，并定向复核迁移 SQL | 账户 CRUD、RPC、Prisma 模型和迁移不一致；误删账户记录，或删表范围超出已批准的废弃治理表。 |
| `adx-sso-backend` | 定向 Jest、`pnpm test -- --runInBand`、`pnpm build` | 48 字符格式、安全数字盐、旧密码失效与重设、改密和身份判断回退。 |
| `adx-bff-backend` | 定向 Jest、`pnpm test -- --runInBand`、`pnpm build` | 管理转发入口残留、Portal 空授权合约、登录/Session/超管门禁及会话吊销失效。 |
| `adx-bff-frontend` | `pnpm test -- --run`、`pnpm typecheck`、`pnpm lint:ci`、`pnpm build` | 角色字段删除后网关管理端无法进入或类型残留。 |

最终定向测试文件和可接受的仓库既有失败基线在计划阶段写明；不能用全量失败掩盖本轮新增失败。

本轮已批准物理删除废弃的非账户治理表，因此不把会一律禁止物理删除的 `pnpm check:no-physical-delete` 作为迁移验收命令；计划阶段必须改用迁移 SQL 定向复核，确认账户业务记录仍只允许软删除，删表对象严格等于已批准范围。

## 手工

按 [test-cases](./test-cases.md) 执行，结果写入 [test-log](./test-log.md)。

涉及数据库内容的核对只记录格式和计数，不记录密码、哈希、盐、密钥或连接串。

## 回归

不能被改坏的老路径：

- Admin 正确密码登录、错误密码拒绝、退出与 Session 失效。
- BFF 网关管理端超管访问接入服务与接口编辑。
- `/proxy/one`、`/proxy/batch` 和 HTTP 直通不因治理接口删除而改变。
- 网关请求查询和实时日志继续可用。

## 受控浅功能回归

| 编号 | 类型 | 范围 | 检查方式 | 停止边界 |
|---|---|---|---|---|
| SR-01 | 直接 | Admin 账户页面、账户 CRUD、密码设置/登录、Session 吊销以及 Admin/BFF 两个管理端门禁。 | 复用 TC-01 至 TC-11 的定向自动化；在获授权的本机栈与隔离库中只走账户主路径和关键错误路径。 | 不读取或修改真实账号数据；不在未授权时启动服务、执行迁移或创建测试数据。 |
| SR-02 | 相邻 | BFF 普通代理、接口编辑、请求查询和实时日志，确认账户治理删除没有干扰保留模块。 | 运行现有定向测试；在本机栈中各检查一个可复核主路径及关键可见结果。 | 不扩展到其他业务模块、全量接口或性能压测；遇到范围外基线只记录，不借验收顺手修复。 |
