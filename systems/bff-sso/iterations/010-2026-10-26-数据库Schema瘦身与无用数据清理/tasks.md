# 任务清单

- [x] T-01 在 `adx-admin-backend` 建立唯一前向 Prisma 迁移：实现目标 Schema、保留集预检、显式依赖顺序清理、无引用 Blob 清理和历史表/字段删除，并更新模型注释。依赖：无。文件：`prisma/schema.prisma`、`prisma/scripts/public-management-comment-manifest.ts`、`prisma/migrations/<本轮迁移>/migration.sql`。检查：`pnpm prisma:comments:check && pnpm prisma:generate && git diff --check`。
- [x] T-02 同步 `adx-admin-backend`、`adx-bff-backend` 与 `adx-sso-backend` 的 `public_management` Prisma 模型，移除已不存在及本轮删除的声明，并补齐最小受影响读取/认证回归。依赖：T-01 的最终保留 Schema。文件：三个仓库的 `prisma/schema.prisma`、实际受影响的最小 `src/**` 与对应 `*.spec.ts`。检查：三个仓库分别执行 `pnpm prisma:generate`、受影响 Jest 与 `git diff --check`。
- [x] T-03 编写运行包、接口项目和 Blob 的保留集不变量检查及其定向回归，形成不执行真实写入的备份/恢复/迁移操作工件。依赖：T-01、T-02。文件：`adx-admin-backend/prisma/migrations/<本轮迁移>/migration.sql`、`adx-bff-backend/src/**` 的最小测试、`evidence/analysis/`、`test-log.md`。检查：迁移 SQL 定向静态检查、active/previous 清单检查、AC-01 至 AC-07 与 TC-01 至 TC-08 对照。

任务的“检查”在首次实现完成后统一去重执行；验收返工时只执行风险策略判定受影响的必跑项。单条任务完成代码与必要测试实现后即可勾选，不机械重复完整检查或 code review。
