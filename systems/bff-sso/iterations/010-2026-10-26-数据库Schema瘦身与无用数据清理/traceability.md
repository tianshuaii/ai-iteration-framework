# 跟踪表

| 需求要点 | 验收 | 用例 | 主要文件 |
|---|---|---|---|
| 仅清理线上测试 `public_management`、保留迁移元数据和删除无引用历史表 | AC-01 | TC-01、TC-02 | `adx-admin-backend/prisma/migrations/<本轮迁移>/migration.sql`、`prisma/schema.prisma` |
| 物理删除所有 `yn=0` 数据并保持引用一致 | AC-02 | TC-03 | `adx-admin-backend/prisma/migrations/<本轮迁移>/migration.sql` |
| 删除失效服务、activation、运行包及其依赖 | AC-03 | TC-04 | `adx-admin-backend/prisma/migrations/<本轮迁移>/migration.sql`、`adx-bff-backend/prisma/schema.prisma` |
| 有效服务只保留 active/previous 包 | AC-04 | TC-05 | `adx-admin-backend/prisma/migrations/<本轮迁移>/migration.sql`、`adx-bff-backend/src/runtime-interface/**` |
| 删除项目及依赖、保留有效项目完整历史 | AC-05 | TC-06 | `adx-admin-backend/prisma/migrations/<本轮迁移>/migration.sql`、`adx-bff-backend/src/interface-version/**` |
| 删除无用字段并同步三个 Prisma 模型 | AC-06 | TC-07 | 三个后端的 `prisma/schema.prisma` |
| 备份、清单与恢复演练 | AC-07 | TC-08 | 本轮 `scripts/`、`evidence/analysis/` |
| 有效运行链路不回归 | AC-08 | TC-09、SR-01、SR-02 | `adx-bff-backend/src/**`、`adx-sso-backend/src/**`、`adx-admin-backend/src/**` |
