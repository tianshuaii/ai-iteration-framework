# 整轮实现审核

- reviewer: code-review-skill
- reviewed_at: 2026-10-28T19:29:49+08:00
- input_digest: 1cf0067247e5bf9e6271af203f30f3957f5cf1c4f2f3c41e12e6e77254adbda1
- task: 无
- result: passed

对照了修订后需求、决策、T-01 及两仓完整差异。管理端新增 `level=9 + type=1 + plat_account_id` 独立挂载，新老 add/update/getById 和 delete 共用精确查询；页面复用 `TrafficDirectionV4`、`platform:` 权限前缀和 dimension 9。未改广告位、Mediatom 页面、React 或 datasyn，未执行数据库迁移。

## 检查结果

| 范围 | 命令/证据 | 结果 |
|---|---|---|
| 后端编译+定向测试 | Surefire 3.5.4 实跑 3 个类 | 9 条通过 |
| 前端定向测试 | `trafficTargeting.spec.js` | 3 条通过 |
| 前端机械检查 | EditPlatAccount eslint + `check:imports:mergex` | 通过 |
| Mapper/差异边界 | `xmllint`、`git diff --check`、排除文件扫描 | 通过 |

## 发现与处置

| 编号 | 级别 | 发现 | 处置 |
|---|---|---|---|
| R-01 | P1 | 开关打开但所有字段为“不限”时没有 rule link，若仅按规则体判断会错误回显为关闭 | 已修复。回显开关改为按独立 `policy_manage` 记录判断，并补回归用例 |
| R-02 | P1 | delete 新增策略清理后仍非事务，中途失败可造成账号和策略状态不一致 | 已修复。公开 delete 方法增加回滚事务 |
| R-03 | P2 | 并发首次保存可能为同一账号创建重复策略 | 已处置。迁移索引改为 `(level,type,plat_account_id)` 唯一索引 |
| R-04 | P2 | 既有 `SysUserPlatformValidatorTest` 仍断言请求地址必填，与验证器已取消该校验的真实契约相反 | 已修复测试基线，未改业务校验行为 |
| R-05 | P2 | `EditPlatAccount/index.vue` 和两个后端 Service 是接管前已超单文件行数限制的存量文件 | 明确处置：新默认值拆到 99 行 `data.js`，Service 只局部接入；整体拆分会扩大验收面，不在当前功能轮次处理 |

没有未关闭的 P0、P1 或 P2。本审核不代替真实页面/数据库验收，也不授权执行 SQL、启动服务、提交、推送、合并或部署。

## 2026-10-29 无索引返工增量审核

- reviewer: code-review-skill
- reviewed_at: 2026-10-29T11:04:01+08:00
- input_digest: 7a755024d13b1a4d3caee5d7825e9546b49949bdf3800dddf75def6d0a20e65a
- task: T-01
- result: passed_with_accepted_risk

本次只审核返工守卫之后的 `sql/policy_manage_plat_account_id.sql`。迁移脚本已删除索引说明和 `ADD UNIQUE INDEX`，保留带注释的 `plat_account_id BIGINT NULL` 字段 DDL，语法终止符正确；无索引扫描和 `diff --check` 均通过。测试库未执行任何 DDL。

### 检查结果

| 范围 | 命令/证据 | 结果 |
|---|---|---|
| 无索引边界 | `! rg -n -i 'index|unique|key' sql/policy_manage_plat_account_id.sql` | 通过；无匹配 |
| 机械格式 | `git diff --check -- sql/policy_manage_plat_account_id.sql` | 通过 |
| SQL 完整性 | 人工核对完整文件 | 通过；仅一条 `ADD COLUMN`，以分号结束 |
| 未变化范围 | AUTO-06～AUTO-09、AUTO-12 | 复用；后端、前端、依赖、配置和生成物未因本次 SQL 返工变化 |

### 发现与处置

| 编号 | 级别 | 发现 | 处置 |
|---|---|---|---|
| R-06 | P2 | 取消 `(level,type,plat_account_id)` 唯一索引后，`PolicyServiceImpl#createOrGetPolicyManage` 仍是“先查再插入”；同一账号并发首次保存时可能创建重复 `policy_manage`。原 R-03 的数据库约束处置不再成立。 | 用户明确接受。原话：“接受并发首次保存可能产生重复策略记录的残余风险，保持无索引并继续”。保持无索引，不扩展 Service；残余风险为同一账号并发首次保存可能产生重复主记录。 |

当前没有未处置的 P0、P1 或 P2；R-06 已由用户明确接受并保留残余风险。增量审核通过，可以进入 verify；本审核不授权开始验收、执行数据库 DDL、提交或推送。
