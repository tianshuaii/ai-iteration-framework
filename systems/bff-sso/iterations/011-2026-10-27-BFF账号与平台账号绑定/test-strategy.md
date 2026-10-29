<!-- shallow-regression-policy: bounded-v1 -->
<!-- risk-based-testing-policy: adaptive-v1 -->
# 测试策略

## 任务风险分级

| 任务 | 档位 | 分级理由 | 影响仓库/模块 | 必须执行 | 可复用证据 | 升级条件 |
|---|---|---|---|---|---|---|
| T-01 | T4 | 新表、partial unique 索引、软删除和迁移影响并发数据一致性。 | `adx-admin-backend` Schema/迁移 | Prisma 注释检查、生成、迁移 SQL 定向检查、索引并发冲突用例。 | 可复用 010 对现有 Schema 的基线，不复用新表结果。 | 迁移执行、回滚或真实数据修复。 |
| T-02 | T4 | 平台/绑定 CRUD 涉及超管权限、数据事务、子服务/接口契约、BFF 账号状态和并发唯一性。 | `adx-bff-backend` Admin API/Prisma/OpenAPI 查询 | 定向单测、Controller/Service 权限测试、Prisma 生成、冲突、登录配置与 BFF 账号失效测试。 | 现有账号、子服务和接口列表定向测试在输入未变时可复用。 | 变更登录会话、代理转发或实际调用外部登录。 |
| T-03 | T3 | 两个新页、三个菜单和联动表单共享 Admin 路由、请求封装与会话守卫。 | `adx-admin-frontend` 路由/布局/表单/API | ESLint、类型检查、定向组件测试、表单联动与错误展示测试。 | 现有账号页测试在行为未变时可复用，文案断言需更新。 | 改动公共认证存储、登录页或全局请求协议。 |

## 自动

| 项目 | 命令 | 要挡住的错误 |
|---|---|---|
| `adx-admin-backend` | `pnpm prisma:comments:check && pnpm prisma:generate` 及本轮迁移定向检查 | 表/字段注释漏失、Schema 不能生成、唯一索引错误。 |
| `adx-bff-backend` | `pnpm prisma:generate` 与新增 Admin 平台/绑定定向测试 | 权限绕过、归属校验漏失、并发重复、软删除误读、失效账号被错误新增绑定。 |
| `adx-admin-frontend` | 项目现有 ESLint/类型命令与新页定向测试 | 路由漏配、表单联动错误、缺必填/失焦校验、API 入参不匹配。 |

## 手工

按 [test-cases](./test-cases.md) 执行，结果写入 [test-log](./test-log.md)。数据库迁移、启动服务和创建验收夹具均需单独授权。

## 回归

- 现有 BFF 账号列表、新建、编辑、启停、设密、软删除。
- Admin 登录、超管路由守卫和退出。
- BFF 子服务列表和已生效接口清单查询。

## 受控浅功能回归

| 编号 | 类型 | 功能或路径 | 纳入理由 | 停止边界 |
|---|---|---|---|---|
| SR-01 | 直接 | Admin 三个菜单、接入平台主路径和平台账号绑定主路径 | 是本轮用户可见改动。 | 只测一个平台、两个子服务、两个 BFF 账号的主路径与冲突，不穷举全部接口。 |
| SR-02 | 相邻 | Admin 登录、BFF 账号管理、子服务/接口列表 | 共享超管会话、Admin 路由、Prisma Schema 和接口列表数据源。 | 不改密码，不修改子服务或运行包，不扩展到代理业务接口。 |

