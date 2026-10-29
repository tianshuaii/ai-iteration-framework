# T-12 Code Review（Q23 确认后）

- 时间：2026-10-26T18:20:00+08:00
- 范围：`adx-admin-backend/prisma/migrations/20261026170000_account_only_governance/migration.sql`
- 方法：按正确性、数据完整性、安全边界、可回滚性和最终 Prisma 模型一致性审核实际 SQL，并在隔离数据库执行两轮恢复迁移。

## 审核结论

1. 账户对租户、父账户和创建者的外键在删除主体表前显式移除；迁移语句未使用 `CASCADE`，不会隐藏或扩大批准的删除边界。
2. `username` 和非空 `user_uid` 都在迁移前检查重复值；两列在最终模型中均为非空并建立全局唯一索引，软删除账号不能复用身份。
3. 迁移只删除批准的治理关联表、角色/租户/页面授权主体表及四个账户关系字段；审计、运行时、接口编辑和接入服务表继续保留。
4. 旧密码统一替换为非 48 字符登录编码，再把列收窄为 `VARCHAR(48)`，保证历史 Argon2 值不能被新编解码器误认。
5. 迁移后 `sys_account` 不再保留外键；Prisma schema diff 返回 `No difference detected.`。

## 复验

- 从迁移前备份创建隔离库并完成第一次单事务迁移：5 个账户保留，4 个历史租户账号转为 `PLATFORM_STAFF`，1 个 `SUPER_ADMIN` 保持不变。
- 恢复同一备份后完成第二次单事务迁移：`username` 与 `user_uid` 重复数均为 0；迁移成功。
- 两轮均验证旧密码全部失效、密码列长度 48、批准退场表与关系字段数量为 0、账户唯一索引数量为 2。
- `pnpm prisma migrate diff --from-url <隔离库> --to-schema-datamodel prisma/schema.prisma --exit-code` 返回 0。
- `pnpm prisma:generate && pnpm check:db-comments && pnpm build` 返回 0；3 个定向 Jest 套件共 21 项通过；`git diff --check` 返回 0。

## 发现

- P0：0
- P1：0
- P2-open：0

T-12 审核通过，无需追加修复。
