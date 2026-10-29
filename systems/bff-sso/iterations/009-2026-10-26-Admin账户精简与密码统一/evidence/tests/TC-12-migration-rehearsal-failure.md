# TC-12 隔离库迁移演练失败证据

- 时间：2026-10-26T17:49:00+08:00
- 数据库：本机专用数据库 `mergex_manager_iter009_20261026`。
- 数据来源：使用 `HEAD` 中的迁移前 Prisma Schema 建立结构，只写入 `iter009-*` 合成账户；没有读取或修改真实账号数据。
- 事务边界：本轮迁移使用 `psql -1 -v ON_ERROR_STOP=1` 在单事务内执行；失败后全部回滚。

## 已通过步骤

1. 空库历史迁移回放在既有迁移 `20260831140000_interface_version_cutover` 因历史链依赖迁移外切换步骤失败；该问题早于本轮且不作为本轮缺陷。
2. 改用 `HEAD` 的迁移前 Prisma Schema 建立隔离的前置结构，确认包含 `account_type`、账户关系字段及旧治理表。
3. 写入活动账户与同用户名软删除历史账户后，本轮迁移按预期报错 `duplicate sys_account.username values must be resolved before migration`，重复用户名预检通过。
4. 将软删除测试夹具改为唯一用户名后生成迁移前自定义格式备份。

## 本轮失败

执行命令：

```text
psql -1 -d mergex_manager_iter009_20261026 -v ON_ERROR_STOP=1 \
  -f prisma/migrations/20261026170000_account_only_governance/migration.sql
```

- 退出码：3。
- PostgreSQL 错误码：`2BP01`（依赖对象仍存在）。
- 失败对象：删除 `public_management.sys_tenant` 时，`sys_account_tenant_id_fkey` 仍引用该表。
- 根因：迁移 SQL 先删除 `sys_tenant`，后删除 `sys_account_tenant_id_fkey`；依赖删除顺序相反。
- 数据状态：单事务回滚，旧治理表、账户字段和 5 条合成账户均保留，不存在半迁移结果。

## 影响与返工边界

- 影响 AC-07、TC-12，并阻止五服务在最终结构上启动联调。
- 修复只需调整本轮迁移 SQL：在删除 `sys_tenant` 前先删除账户外键；不得扩大到历史迁移或产品业务逻辑。
- 修复后必须重跑重复用户名阻断、迁移成功、结构/数据核对、备份恢复和二次迁移。
