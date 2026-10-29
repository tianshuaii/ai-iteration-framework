# Schema 只读盘点

- 盘点时间：2026-10-26T20:36:12+08:00
- 环境：线上测试库 `public_management`
- 权限：`default_transaction_read_only=on`
- 结果只用于需求规格，未执行任何数据库写入。

## 总体

- 基础表：57 张。
- 当前 BFF/Admin/SSO Prisma 模型未覆盖：25 张，其中迁移元数据表 2 张、历史业务/配置表 23 张。
- 所有含 `yn` 的表合计 `yn=0`：1,158 行。
- 当前模型化表中，数据库存在但三个后端 Prisma 均未映射的字段候选：`sys_sub_service.service_kind`；7 行现值均为 `upstream`。
- SSO 的 `SubService` Prisma 模型仍声明 9 个数据库已经不存在的旧字段，需要在本轮同步模型，不能据此恢复列。

## 服务与运行包

- `sys_sub_service`：4 行 `yn=1`、3 行 `yn=0`。
- `sys_sub_service_runtime_activation`：7 行 `yn=1`、8 行 `yn=0`。
- `sys_sub_service_runtime_package`：38 行 `yn=1`、147 行 `yn=0`。
- 147 个 `yn=0` 运行包均未被有效 activation 的 active/previous 引用。
- 另有 28 个 `yn=1` 运行包未被有效 activation 的 active/previous 引用，是否删除等待 Q3。

## 接口项目

- `sys_interface_project`：4 行 `yn=1`、30 行 `yn=0`。
- 30 个删除项目仍关联分支、提交、Tree Item、工作区与接口包记录。
- `sys_interface_package_record` 中 168 行指向 `yn=0` 项目，33 行指向有效项目，6 行没有本地项目引用。
- 有效项目的完整版本历史是否保留等待 Q4。

## `yn=0` 主要分布

- 动态表单数据：91 行。
- 接口工作区数据：864 行。
- 接口项目及白名单：45 行。
- 服务、运行激活和运行包：158 行。

## 未被当前 Prisma 模型覆盖的历史业务/配置表

`app_list`、`audit_outbox`、`crowd_packet_record`、`device_brand`、`industry`、`region_city`、`region_country`、`region_province`、`upload_record`，以及 14 张 `sys_form_*` 表。

当前五个仓库排除 migration、dist、coverage 和依赖目录后，没有发现这些表名的直接 SQL/ORM 引用。是否以此作为删除真源等待 Q2。

## 明确保留候选

- `_prisma_migrations`、`flyway_schema_history`：迁移元数据，推荐保留。
- `sys_audit_log`：82,187 行，约 57 MB；虽然审计页面/API 已删除，但登录与管理写操作仍写入该表，推荐保留。
