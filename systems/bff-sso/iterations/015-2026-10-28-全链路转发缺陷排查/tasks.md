# 任务清单

- [x] T-01 按登录前、登录时、登录后、登录失效四段做只读审计，产出缺陷清单并标明责任侧；有现成故障单时优先复现。依赖：无。文件：本轮 `evidence/analysis/forward-audit.md`、`evidence/analysis/defect-list.md`。检查：`test -f evidence/analysis/forward-audit.md && test -f evidence/analysis/defect-list.md && rg -q '责任侧' evidence/analysis/defect-list.md`
- [x] T-02 按缺陷清单修复确认属于 `bff-sso` 的项，并补定向测试；若清单无 BFF 缺陷，只写入确认证据不改产品代码。依赖：T-01。文件：`adx-bff-backend` 中清单点名的源码与 spec（定位后写入本任务正文）。检查：在 `/Users/mrzater/docker/adx/adx-bff-backend` 运行清单对应的 `pnpm test -- --runInBand <定向 spec>`；无 BFF 缺陷时检查改为 `rg -q 'bff-sso 缺陷：无' evidence/analysis/defect-list.md`
- [x] T-03 整理 `mergex-manager` 侧缺陷开轮材料；取得创建授权后在该系统新建迭代并回写指向。依赖：T-01。文件：本轮 `evidence/analysis/mergex-manager-handoff.md`；新建的 `systems/mergex-manager/iterations/...`。检查：`test -f evidence/analysis/mergex-manager-handoff.md`；若清单无 MergeX 缺陷则文件中写明“无”，不要求已创建对端轮次

任务的检查在首次实现完成后统一执行。单条任务完成代码与必要测试实现后即可勾选；全部任务勾选后仍做整轮审核和按风险验收。
