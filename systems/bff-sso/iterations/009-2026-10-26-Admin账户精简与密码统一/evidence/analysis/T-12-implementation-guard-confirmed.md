# T-12 Implementation Guard（Q23 确认后）

- 执行时间：2026-10-26T18:16:00+08:00
- 用户授权：`Q23 按推荐做；开始处理，计划审批通过，并执行当前任务 T-12`
- 需求审批：有效。
- 计划审批：已由框架脚本记录，摘要为 `3e39a216a3be0e8cc4437d04ccfedef0df4189f003464f8e8d10cbeffe0cb74c`。
- 当前任务：T-12。
- 产品写入范围：仅 `/Users/mrzater/docker/adx/adx-admin-backend/prisma/migrations/20261026170000_account_only_governance/migration.sql`。
- 依赖：T-06 已完成。
- 仓库：共享检出 `master@f519c0f39f6df73f8e1943036f5e8475c703f8b0`；当前只有本轮 009 处于产品实现/验收阶段，无同仓并行冲突。
- 接管前状态：迁移目录为本轮 T-06/T-12 未提交成果；仓库其他 dirty 均为本轮 T-01 至 T-11 已登记成果，不覆盖或回退。
- 运行资源：隔离数据库 `mergex_manager_iter009_20261026`、迁移前备份 `/tmp/bff-sso-009.AGRmvr/pre-account-only.dump`；用户已授权隔离库迁移与回滚演练。
- 边界：显式删除账户侧外键/索引后再删主体表；禁止 `CASCADE`，不修改历史迁移、删除白名单、最终 Prisma 模型或业务代码。
- 门禁结论：P0=0、P1=0、P2-open=0，允许执行 T-12。
