# 跟踪表

| 需求要点 | 验收 | 用例 | 主要文件 |
|---|---|---|---|
| 广告源基本信息加标准化开关，默认关 | AC-01 | TC-01 | `EditSource/BaseInfoForm` |
| `app_std` 落库与回显 | AC-02 | TC-02 | `DspPlace`、保存/详情 VO、迁移 SQL |
| 利润策略表单去掉价格过滤 | AC-03 | TC-03 | `BidFilterStrategyV4`、`ProfitInfoForm` |
| 保存时 `bidFilterType` 固定媒体底价 1 | AC-04 | TC-04 | 利润策略保存服务 |
| 广告源其他字段仍可保存 | 浅回归 | SR-01 | `EditSource` |
| 平台底价策略区仍可保存 | 浅回归 | SR-02 | `ProfitInfoForm` |
