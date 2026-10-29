# 测试记录

自动测试：未跑。执行后记录目标仓库、命令、时间、退出码、所测 HEAD 或工作区基线；有 CI/PR 时附链接。返工前的失败记录写在“返工历史”中，不覆盖事实。

## 自动检查与复用记录

相同代码、依赖、配置和生成物输入下，已通过的检查可以复用；引用原记录并写清输入基线和未失效原因。任一输入变化时只让受影响记录失效，不机械重跑其他仓库或模块。

| 记录 | 任务/阶段 | 仓库/范围 | 命令或证据 | 输入基线 | 结果 | 复用说明 |
|---|---|---|---|---|---|---|
| AUTO-01 | implement / T-01、T-03 | `adx-admin-backend` 静态迁移工件 | `node prisma/scripts/check-public-management-schema-slim-migration.mjs` | 20261027090000 迁移与静态检查脚本 | 通过 | 不连接数据库；验证保留集、清理顺序、审计保留和无可执行 CASCADE。 |
| AUTO-02 | implement / T-01、T-03 | `adx-admin-backend` Prisma | `pnpm prisma:comments:check && pnpm prisma:generate` | 当前 Admin 工作区（含既有 009 dirty） | 通过 | 注释清单 389 行；Client 生成成功。 |
| AUTO-03 | implement / T-02 | `adx-bff-backend`、`adx-sso-backend` Prisma | 各执行 `pnpm prisma:generate` | 当前 BFF/SSO 工作区（含既有 009 dirty） | 通过 | BFF 模型无需字段删除；SSO 模型已同步最终 SubService。 |
| AUTO-04 | implement / T-03 | `adx-bff-backend` 定向回归 | `pnpm test -- --runInBand src/runtime-interface/utils/runtime-package-inventory.util.spec.ts src/runtime-interface/services/runtime-package-inventory.service.spec.ts src/interface-version/services/project.service.spec.ts` | 当前 BFF 工作区 | 通过 | 3 suite、22 tests 通过；覆盖运行包清单和接口项目读取链。 |

## 返工历史

- 无。失败时追加日期、命令或 TC、现象、受影响的 AC/TC、返工任务；当前结果仍在下表维护。

| 用例 | 日期 | 结果 | 现象 |
|---|---|---|---|
| TC-01 | 2026-10-27 | 通过 | 隔离恢复演练和线上测试库均成功执行第 010 轮唯一待应用迁移；仅影响 `public_management`。 |
| TC-02 | 2026-10-27 | 通过 | 源码、Prisma、外键与运行引用盘点已纳入删除/保留顺序；目标库迁移后保留 34 张表。 |
| TC-03 | 2026-10-27 | 通过 | 线上测试库 23 张废弃表均不存在；除审计日志外全部含 `yn` 表的 `yn=0` 合计为 0。 |
| TC-04 | 2026-10-27 | 通过 | 线上测试库 active/previous 运行包的服务编码、环境归属与有效状态均一致，孤儿运行包数为 0。 |
| TC-05 | 2026-10-27 | 通过 | 线上测试库运行包保留集真实核验通过；不存在已激活或前版本引用的缺失、软删或错归属包。 |
| TC-06 | 2026-10-27 | 通过 | BFF 接口项目相关 3 个 suite/22 tests 通过；线上测试库保留 4 个有效接口项目和 39 条提交历史。 |
| TC-07 | 2026-10-27 | 通过 | 三仓 Prisma Client 生成通过；线上测试库已无 `sys_sub_service.service_kind` 列。 |
| TC-08 | 2026-10-27 | 通过 | 已建立可校验迁移前备份，完整恢复演练通过；隔离库已删除，备份仍保留。 |
| TC-09 | 2026-10-27 | 通过 | BFF、SSO、Admin 后端健康检查均通过；Admin 登录经 SSO 建立会话，当前账号和账户列表查询成功；4 个有效服务读取且连通探测均为 UP；有效 GET 白名单经 `/proxy/mergex/user/code` 成功转发。 |

## 受控浅功能回归

按 `test-strategy.md` 的 `SR-xx` 逐条记录。每条保留日期、结果和可复核现象；范围不得临时扩展到未登记的全系统回归。

| 用例 | 日期 | 结果 | 现象 |
|---|---|---|---|
| SR-01 | 2026-10-27 | 通过 | 运行包和接口项目定向单测 22 项通过；线上测试库 active/previous 不变量为 0 异常；4 个有效服务连通探测为 UP，活动 HTTP 包的白名单 GET 成功转发。停止边界：未导入、切换或回滚任何运行包。 |
| SR-02 | 2026-10-27 | 通过 | SSO `auth.service` 7 项定向测试通过；真实 Admin 登录、会话、当前账号和账户列表查询成功；对不存在账号的重置请求返回“账号不存在”，未修改账号或密码。停止边界：未创建账号、未修改口令。 |

结果通常使用“未测”“通过”或“未通过”。只有用户明确确认时才可写“豁免”，并在现象列同时写明“用户确认”和“残余风险”；缺少任一项都不能进入 `done`。
