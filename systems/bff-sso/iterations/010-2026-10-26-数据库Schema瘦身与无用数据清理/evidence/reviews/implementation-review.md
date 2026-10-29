# 第 010 轮统一代码审查

- capability: `code-review`
- provider: `code-review-skill + manual-review`
- provider_version: `2026-10-27`
- task: `无`
- result: `passed`
- reviewed_at: `2026-10-27T10:45:00+08:00`
- findings: `P0=0, P1-fixed=1, P2-open=0`

## 审查范围

- Admin：`20261027090000_public_management_schema_slim` 迁移和只读静态检查脚本。
- SSO：`SubService` Prisma 模型与枚举同步。
- BFF：运行包和接口项目读取链的既有定向回归。
- 不把 009 已存在的 dirty 基线纳入本轮差异，也不执行数据库写入或服务操作。

## 发现与修复

| 级别 | 发现 | 修复与复验 |
|---|---|---|
| P1（已修复） | 有效标记 activation 若仍指向已软删服务，原清理会删除服务和包却留下无外键保护的 activation。 | 迁移先删除无有效服务/环境归属的 activation，保留集按服务编码和环境匹配，并校验 active/previous 包归属；静态检查、Prisma 生成与 BFF 回归均通过。 |

## 结论

- 无可执行 `CASCADE`，无法识别的外键依赖会使迁移失败并回滚。
- 审计表被通用 `yn=0` 删除循环明确排除，符合 D-08。
- SSO 已无数据库不存在的旧 OpenAPI/Proto 字段；BFF 合成 `serviceKind` 未被误删。
- 通过：可进入 verify 的静态/代码验收；真实备份、恢复、迁移和目标库验收仍待单独外部写入授权。

## 迁移演练返工后的增量审查

- capability: `code-review`
- provider: `code-review-skill + manual-review`
- task: `T-01`
- result: `passed`
- reviewed_at: `2026-10-27T11:05:00+08:00`
- findings: `P0=0, P1-fixed=1, P2-open=0`

### 触发原因与范围

- 首次隔离恢复演练在 `sys_form_option_group_option` 的有效子行仍引用已删除父行时安全失败；该失败仅发生在隔离库，目标测试库未被写入。
- 返工只调整迁移中废弃 Form 域与旧业务表的移除时机，并扩展动态清理对 PostgreSQL `RESTRICT` 违规的可恢复等待；未改变运行包、接口项目、审计日志或账户数据的保留边界。

### 审查结果

| 级别 | 发现 | 修复与复验 |
|---|---|---|
| P1（已修复） | 旧 Form 域在通用 `yn=0` 清理之后才删除，导致有效子行引用软删父行时，通用循环无法推进到可完成状态。 | 将 14 张 Form 表按子到父顺序、9 张旧业务表一并提前至通用清理前删除；静态检查新增顺序断言。新隔离恢复库已完整执行迁移，最终 `yn=0=0`、23 张废弃表不存在、审计行数保持 83,919。 |

### 增量结论

- 通过：迁移不包含可执行 `CASCADE`，新增删除顺序与真实外键约束一致；隔离恢复演练已覆盖本次返工路径，可继续迁移已授权的目标测试库。
