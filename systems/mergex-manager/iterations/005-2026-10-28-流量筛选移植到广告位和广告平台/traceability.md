# 跟踪表

| 需求要点 | 验收 | 用例 | 主要文件 |
|---|---|---|---|
| 广告平台账号新增/编辑接入完整流量筛选 | AC-01 | TC-01 | `mediatom-web/src/viewsForManage/Budget/EditPlatAccount/index.vue`、`data.js` |
| 权限 code 只替换为 `platform:` 前缀 | AC-02 | TC-02 | `EditPlatAccount/index.vue`、`TrafficDirectionV4/` |
| 新老新增、更新和详情接口均真实保存、回显和生效 | AC-03 | TC-03 | 广告平台 VO、`PlatAccountServiceImpl`、前端目标页 |
| 广告平台账号策略主记录、挂载字段和关联数据隔离 | AC-04 | TC-04 | `PolicyServiceImpl`、`PolicyManage`、`PolicyQuery`、`PolicyManage.xml`、`PlatAccountServiceImpl` |
| 不启用时原保存行为不变 | AC-05 | TC-05 | 广告平台目标页和新老新增/更新接口 |
| 广告平台账号使用专用 `policy_manage` 维度和 `plat_account_id`，迁移不操作表索引 | AC-06 | TC-06 | `PolicyConstant`、`PolicyManage`、`PolicyQuery`、`PolicyServiceImpl`、`PolicyManage.xml`、`mergex-manager/sql/` |
| 广告位不在本轮产品改动范围 | AC-07 | TC-07 | 产品差异边界检查 |
