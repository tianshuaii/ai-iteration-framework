# 测试记录

自动测试：源码断言已跑。未编译启动服务，未连库，未跑正式库迁移。用户 2026-10-27 原话：「已看过代码了，开始验收」。

## 自动检查与复用记录

| 记录 | 任务/阶段 | 仓库/范围 | 命令或证据 | 输入基线 | 结果 | 复用说明 |
|---|---|---|---|---|---|---|
| AUTO-01 | verify | mergex-manager / app_std | `rg appStd|app_std` + `setAppStd(0)`；脚本 `sql/dsp_place_app_std.sql` | manager HEAD `ed5ccad3` + 本轮工作区 | 通过 | 2026-10-27T19:45 复验仍通过 |
| AUTO-02 | verify | mergex-manager / 利润保存 | 初版断言 type 1/3；已被 T-05 扩到全部 type，见 AUTO-04 | manager 工作区 | 失效 | 范围纠正后失效 |
| AUTO-03 | verify | mediatom-web / 开关与去 UI | 初版含「AB 仍保留」；已被 T-05 改掉，见 AUTO-04 | web 工作区 | 失效 | 范围纠正后失效 |
| AUTO-04 | T-05 / verify | 全位置补齐 | `batchUpdatePrice` 无 type 限制强制 `MEDIA_FLOOR`；`viewsForManage` 无 `BidFilterStrategyV4`；`appStd` 默认 0 | 纠正后工作区 | 通过 | 2026-10-27T19:45 复验仍通过 |

## 返工历史

- 无。

| 用例 | 日期 | 结果 | 现象 |
|---|---|---|---|
| TC-01 | 2026-10-27 | 通过 | 代码审阅：`BaseInfoForm` 有 `appStd` 开关，`data.js` 默认 0（AUTO-01/04） |
| TC-02 | 2026-10-27 | 豁免 | 用户确认：已看过代码了，开始验收。残余风险：测试库未跑 `dsp_place_app_std.sql`，未实际保存/回显 |
| TC-03 | 2026-10-27 | 通过 | 代码审阅：`UpdateLinkConfig` 与 `ConfigABTest` 均无 `BidFilterStrategyV4`（AUTO-04） |
| TC-04 | 2026-10-27 | 通过 | 代码审阅：`batchUpdatePrice` 对所有 type 强制媒体底价 1（AUTO-04） |

## 受控浅功能回归

| 用例 | 日期 | 结果 | 现象 |
|---|---|---|---|
| SR-01 | 2026-10-27 | 豁免 | 用户确认：已看过代码了，开始验收。残余风险：未开页面改其他基本信息保存 |
| SR-02 | 2026-10-27 | 豁免 | 用户确认：已看过代码了，开始验收。残余风险：未开页面改平台底价策略区保存 |

结果通常使用“未测”“通过”或“未通过”。只有用户明确确认时才可写“豁免”，并在现象列同时写明“用户确认”和“残余风险”；缺少任一项都不能进入 `done`。
