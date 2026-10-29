# 实现计划

## 顺序

1. **T-01** 管理端：`dsp_place.app_std` 迁移脚本 + 实体/VO/保存回显
2. **T-02** 页面：广告源基本信息加「应用名称标准化」开关（默认可关）
3. **T-03** 管理端：利润策略保存时 `bidFilterType` 写死为媒体底价 `1`（初版曾只覆盖供应商 type，已由 T-05 补齐）
4. **T-04** 页面：连接管理利润策略表单去掉价格过滤 UI
5. **T-05** 返工：后端对所有 type 强制媒体底价；AB 实验页去掉价格过滤

T-01 与 T-03 可并行；T-02 依赖 T-01 字段约定；T-04 可与 T-03 并行；T-05 在用户纠正范围后执行。

## 做法要点

- 迁移 SQL 只放 `mergex-manager/sql/`，本轮不代跑正式库。
- `app_std` / `appStd`：0 关 1 开；未传按 0。
- 利润保存：`batchUpdatePrice` 忽略 type，一律固定 `bidFilterType=1`。
- 连接 `UpdateLinkConfig` 与 AB `ConfigABTest` 都去掉 `BidFilterStrategyV4`，提交不再依赖用户选择。

## 检查

见 [tasks](./tasks.md)。管理端优先编译 + 针对性单测；页面用 lint/源码检查确认开关与去掉价格过滤。
