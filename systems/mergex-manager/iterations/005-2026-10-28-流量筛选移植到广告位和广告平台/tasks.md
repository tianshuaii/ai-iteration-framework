# 任务清单

- [x] T-01 验收返工广告平台账号流量筛选迁移：保留已经完成的广告平台页面、新老 add/update/getById、专用维度、`plat_account_id` 与独立 `type=1` 策略实现，只从迁移文件移除 `ADD UNIQUE INDEX`，确保该 SQL 只新增字段且不操作任何表索引；不删除测试库已有索引，不改广告位。依赖：无。文件：`mergex-manager/sql/policy_manage_plat_account_id.sql`。检查：`! rg -n -i 'index|unique|key' sql/policy_manage_plat_account_id.sql`；`git diff --check -- sql/policy_manage_plat_account_id.sql`；复用未受影响的后端 9/9、前端 3/3、ESLint、导入边界及广告位排除证据。

任务的“检查”在首次实现完成后统一去重执行；本次验收返工仅使迁移结构与 TC/AC-06 证据失效，后端业务代码、前端、依赖、配置和生成物未变化时复用既有通过证据。T-01 完成后执行一次增量 code review 和迁移结构复验，不机械重复全部测试。
