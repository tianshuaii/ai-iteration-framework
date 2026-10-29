# 测试记录

自动测试：T-01、T-02 定向测试和构建已跑；整套回归留待 verify。执行后记录目标仓库、命令、时间、退出码、所测 HEAD 或工作区基线；有 CI/PR 时附链接。返工前的失败记录写在“返工历史”中，不覆盖事实。

## 实现阶段定向检查

- 2026-10-23T19:10:15+08:00，`adx-bff-backend` 独立 worktree `codex/008-bff-cold-path`，HEAD `ee616bcb333f9d27769d2d0604116907b64c8325`，T-01 三文件有本轮未提交改动：`pnpm exec jest --runInBand --runTestsByPath src/proxy/http-passthrough.service.spec.ts src/runtime-interface/services/runtime-package-inventory.service.spec.ts`，退出码 0，2 suites / 14 tests 通过（评审修复后复验）。
- 同一工作区：`pnpm build`，退出码 0；`git diff --check`，退出码 0。
- 同一工作区：`pnpm exec tsc --noEmit -p tsconfig.json`，退出码 2；错误位于本轮任务范围外的既有脚本与测试文件，当前 T-01 三文件未出现在错误列表。未以此宣称全仓类型检查通过。
- 2026-10-23T19:14:20+08:00，同一 worktree 与 HEAD，T-01、T-02 共十一文件为本轮未提交改动：`pnpm exec jest --runInBand --runTestsByPath src/proxy/proxy.service.spec.ts src/common/guards/session.guard.spec.ts src/session/session.service.spec.ts`，退出码 0，3 suites / 31 tests 通过（评审修复后复验）；`pnpm build` 和 `git diff --check` 退出码均为 0。
- 2026-10-23T19:20:19+08:00，第 008 轮脚本工作区：`node --test iterations/008-2026-10-23-BFF首次请求冷路径耗时优化/scripts/cold-first-request.test.mjs`，退出码 0，4/4 自检通过（评审修复后复验）；`node --check` 退出码 0。脚本未执行正式采样，四路有效独立重启样本数仍为 0；T-03 未勾选，TC-01 仍为未测。
- 2026-10-23T19:45:54+08:00，T-03 最终复验：采样器 `node --check` 通过，`node --test` 9/9 通过；脱敏样本文件权限为 `0600`，125 行无额外字段、URL、Bearer、密码或 Token 字面量。本机固定替身、独立 BFF 重启、`/health` 后首条业务请求口径下，优化前主组：白名单直通 30/33（3 个早期诊断探索样本），P50/P95/最小/最大为 754/1181/486/1867 ms；需登录直通 30/30，为 772/1108/487/1177 ms；单发 30/31（1 个 Session 刷新组），为 706/1091/542/2249 ms；单子请求批量 30/31（1 个 Session 刷新组），为 592/698/476/743 ms。原 BFF 已从原仓库恢复且 `/health` 200，测试服务原直连已读回，替身已停止。
- 2026-10-23T19:49:20+08:00，同一 worktree 与 HEAD，T-04 复验：两套定向 spec 2 suites / 16 tests 通过，`pnpm build` 与 `git diff --check` 通过。审查中 1 个 P1、1 个 P2 及 1 个旧夹具失败均已修复，未处置发现为 0。
- 2026-10-23T19:51:49+08:00，同一 worktree 与 HEAD，T-05 复验：resolver/cache-sync 两套 spec 2 suites / 19 tests 通过，`pnpm build` 与 `git diff --check` 通过。审查补齐 Pub/Sub 清理、版本读取失败和显式 packageId 隔离，未处置发现为 0。
- 2026-10-23T19:56:40+08:00，T-06 复验：7 suites / 66 tests、`pnpm build`、9 个生产代码文件 ESLint 与 `git diff --check` 退出码 0。7 个 spec 严格 ESLint 退出码 1、31 errors；同一 HEAD 原版逐文件 `eslint --stdin` 合计 33 个同类语义错误，故本轮未新增并减少 2 个，作为 P3 基线债务保留，不宣称 spec ESLint 通过。
- 2026-10-23T20:35:00+08:00，T-07 最终复验：T-07 三套 spec 3 suites / 36 tests 通过；本轮整套定向 7 suites / 71 tests 通过；`pnpm build`、9 个生产文件 ESLint 与 `git diff --check` 退出码 0。7 个 spec 严格 ESLint仍为 31 errors，相对 HEAD 33 个既有错误无新增。
- 同一时间，优化后二次正式冷样本保存在 `evidence/tests/optimized-v2-samples.jsonl`，权限 `0600`，124 行无额外字段、URL、Bearer、密码或 Token 字面量。主组 P50/P95/最小/最大：白名单直通 30/30 为 123/183/98/187 ms；需登录直通 30/31 为 180/242/156/252 ms，另 1 个刷新组；单发 30/31 为 174/249/135/301 ms，另 1 个刷新组；单子请求批量 30/32 为 180/279/151/279 ms，另 2 个刷新组。四路均达到 AC-03。
- 热路径同环境固定替身、每路预热后 60 次对照，原实现→本轮实现 P95：白名单 87→70 ms、需登录直通 159→104 ms、单发 290→114 ms、批量 315→103 ms；八组成功率均为 60/60。原 BFF 最终从原仓库恢复且 `/health` 200，测试服务原直连已在页面读回，替身端口已停止；SSO/Admin 未重启，未清 Redis、未切运行包。

## 返工历史

- 2026-10-23T20:21:00+08:00，AC-03 / TC-04 首轮优化后正式冷样本未通过：相同本机固定上游、每次独立重启、`/health` 就绪后立即发首条业务请求的主组中，四路各 30 个有效样本；白名单直通 P50/P95/最小/最大为 542/757/364/1408 ms（目标 P95≤200 ms），需登录直通为 654/1222/538/3109 ms（目标≤350 ms，另有 1 个探索样本），单发为 615/847/427/2435 ms（目标≤350 ms，另有 1 个授权上下文刷新样本），单子请求批量为 603/759/500/1181 ms（目标≤350 ms）。分段显示直通 `inventory.upstream.read` P95 为 542/668 ms，单发/批量 `forward.runtime.resolve` P95 为 680/604 ms；健康就绪时异步运行包预热仍可能未完成，首请求承担大对象加载。样本保存在 `evidence/tests/optimized-samples.jsonl`，权限 `0600`，122 行无额外字段、URL、Bearer、密码或 Token 字面量。原 BFF 已恢复且 `/health` 200，测试服务原直连已读回，替身端口已停止。按返工规则新增 T-07，当前 AC-03 / TC-04 重置为未测，旧失败保留在此。

- 2026-10-23T19:52:45+08:00，验收阶段额外全量 `pnpm exec jest --runInBand`：退出码 1，148/150 suites 中 138 通过、2 跳过、10 失败，686/713 tests 通过、10 跳过、17 失败。失败文件均不在本轮 diff：7 个 suite 因隔离 worktree 没有相邻 `mergex-proto-server` / `mergex-page-delivery` 资源；`admin.service.spec.ts`、`interface-version.dto.spec.ts` 为当前基线断言失败；`app.controller.spec.ts` 为本机 Nacos 环境组合校验失败。测试策略未把全量 Jest 列为门禁，但此结果保留，不能宣称全仓回归通过；本轮定向门禁继续单独执行。
- 2026-10-23T19:53:24+08:00，验收阶段测试策略门禁：7 suites / 66 tests 与 `pnpm build` 通过；改动文件 `pnpm exec eslint ...` 退出码 1，共 215 errors / 1 warning，其中 179 个可由格式化修复，其余含测试替身类型规则。按 verify 返工流程新增 T-06，不能把本次 lint 写成通过。
- 2026-10-23T19:47:40+08:00，T-04 首次定向检查 15/16：并发冷请求测试仍返回旧版 `{ upstream }` 结构，新入口实际返回数组；仅测试夹具受影响。修复夹具后 16/16 通过。
- 2026-10-23T19:48:40+08:00，审查优化后首次复验 15/16：Prisma mock 不会执行 `startsWith` 关系过滤，暴露服务缺少防御性过滤；补回进程内过滤后 16/16 通过。
- 2026-10-23T19:50:55+08:00，T-05 首次定向检查 16/17：测试误期望首次版本缺失时读取 Redis 大正文，实际安全路径直接查 DB 并补齐版本；修正断言后通过。

| 用例 | 日期 | 结果 | 现象 |
|---|---|---|---|
| TC-01 | 2026-10-23 | 通过 | 优化前四路各 30 个有效独立重启样本；预热状态、刷新组、分段与统计口径完整。 |
| TC-02 | 2026-10-23 | 通过 | 主组均为健康就绪后的首条业务请求；刷新与探索样本未混入，热路径单独采样。 |
| TC-03 | 2026-10-23 | 通过 | 直通定位到 package/doc 读取，单发/批量定位到 runtime resolve；T-07 后首请求不再承担这些预热段。 |
| TC-04 | 2026-10-23 | 通过 | 旧失败保留在返工历史；T-07 后 P95 为 183/242/249/279 ms，均达到阈值。 |
| TC-05 | 2026-10-23 | 通过 | 定向测试覆盖白名单/登录、未知接口拒绝、单发/批量响应与失败隔离，固定替身请求成功。 |
| TC-06 | 2026-10-23 | 通过 | 定向测试覆盖失败重试、切包清理、跨实例事件、缓存缺失/失败和显式 packageId 隔离。 |
| TC-07 | 2026-10-23 | 通过 | 每路 60 次热样本，原实现→本轮 P95 为 87→70、159→104、290→114、315→103 ms；均 100% 成功。 |
| TC-08 | 2026-10-23 | 通过 | 原 BFF 与直连地址已恢复，替身已停止；未重启其他服务、未清 Redis、未切包；样本脱敏自检通过。 |

结果通常使用“未测”“通过”或“未通过”。只有用户明确确认时才可写“豁免”，并在现象列同时写明“用户确认”和“残余风险”；缺少任一项都不能进入 `done`。
