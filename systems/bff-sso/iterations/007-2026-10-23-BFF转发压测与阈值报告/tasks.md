# 任务清单

每条任务做完要有检查结果。整份报告的最终验收在 `verify`，不在这里提前写成通过。产品仓库不在本轮改动范围内，任务不得改它们。

- [x] T-01 准备只返回固定内容的假上游，并经白名单直通试打一次。依赖：无。文件：`scripts/fake-upstream.mjs`、`scripts/load-once.mjs`。检查：`node scripts/load-once.mjs`。
- [x] T-02 对白名单直通、要登录的直通、单发、批量做阶梯加压，并把每一档原始数字存下来。依赖：T-01。文件：`scripts/run-load.mjs`。检查：`node scripts/run-load.mjs`。
- [x] T-03 根据原始数字写阈值报告和处理建议，并核对五个产品仓库没有这一轮的改动。依赖：T-02。文件：`report.md`、`scripts/check-report.mjs`。检查：`node scripts/check-report.mjs`。
