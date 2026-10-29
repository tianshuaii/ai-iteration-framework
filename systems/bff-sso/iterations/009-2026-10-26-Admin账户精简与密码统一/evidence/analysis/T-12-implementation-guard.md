# T-12 Implementation Guard

> 门禁纠错（2026-10-26T18:07:33+08:00）：本记录建立在未确认的 Q23 和无效计划审批之上，状态已改为 `superseded`。文件基线事实仍保留，不能作为继续实施的门禁证据。

- 时间：2026-10-26T17:53:00+08:00
- 任务：修复账户单一化迁移的依赖删除顺序。
- 仓库：`/Users/mrzater/docker/adx/adx-admin-backend`
- 分支与 HEAD：`master@f519c0f39f6df73f8e1943036f5e8475c703f8b0`
- 隔离方式：共享检出；与当前计划和 `workspace.md` 一致。
- 输入摘要：`3e39a216a3be0e8cc4437d04ccfedef0df4189f003464f8e8d10cbeffe0cb74c`。

## 文件与资源边界

- 只接管本轮已存在但尚未跟踪的 `prisma/migrations/20261026170000_account_only_governance/migration.sql`。
- 只调整账户外键/索引删除与废弃主体表删除的相对顺序；不修改历史迁移、Schema、业务代码或删除白名单。
- 专用数据库 `mergex_manager_iter009_20261026` 当前保留 5 条 `iter009-*` 合成账户、旧治理表和旧账户字段；上次失败已由单事务回滚。
- 不使用 `CASCADE`，不触碰共享数据库，不启动或停止既有端口上的进程。

## 判定

- P0：0。
- P1：0。
- P2-open：0。
- 历史结论已失效；Q23 确认、计划重新评审并审批后，必须重新执行实施守卫。
