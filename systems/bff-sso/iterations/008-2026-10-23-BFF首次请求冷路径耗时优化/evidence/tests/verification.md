# 第 008 轮测试验证

- provider: iteration-test-verification
- provider_version: capability-gates-v1
- status: passed
- verified_at: 2026-10-23T20:41:00+08:00
- product_worktree: `codex/008-bff-cold-path`
- base_head: `ee616bcb333f9d27769d2d0604116907b64c8325`
- worktree_state: 已提交且干净；成果提交 `c57b594194cdfd40f3d24e6d7836ebc0b0e453da`

## 自动检查

- 7 个定向 suite：退出码 0，71/71 tests 通过。
- `pnpm build`：退出码 0。
- 9 个生产文件 ESLint：退出码 0。
- 7 个 spec 严格 ESLint：退出码 1，31 errors；HEAD 基线为 33 个同类既有 mock 类型错误，本轮无新增，按 P3 保留。
- `git diff --check`：退出码 0。
- 额外全量 Jest 的历史结果为 138 suites 通过、2 跳过、10 个范围外/环境 suite 失败；它不是本轮测试策略门禁，失败详情保留在 `test-log.md`，未宣称全仓通过。

## 冷路径

| 路径 | 优化前 P95 | T-07 后 P95 | 阈值 | 有效主组 | 刷新组 | 结果 |
|---|---:|---:|---:|---:|---:|---|
| 白名单直通 | 1181 ms | 183 ms | 200 ms | 30 | 0 | 通过 |
| 需登录直通 | 1108 ms | 242 ms | 350 ms | 30 | 1 | 通过 |
| 单发 | 1091 ms | 249 ms | 350 ms | 30 | 1 | 通过 |
| 单子请求批量 | 698 ms | 279 ms | 350 ms | 30 | 2 | 通过 |

原始脱敏样本为 `baseline-samples.jsonl` 与 `optimized-v2-samples.jsonl`；后者 124 行、权限 `0600`，字段白名单和敏感字面量检查通过。

## 热路径

同环境固定替身、每路预热后 60 次；原实现→本轮实现 P95 为 87→70、159→104、290→114、315→103 ms，八组成功率均为 60/60。四路均无 P95 或成功率回退。

## AC/TC 映射

- AC-01 / TC-01、TC-02：通过。
- AC-02 / TC-03：通过。
- AC-03 / TC-04：通过。
- AC-04 / TC-05、TC-06：通过。
- AC-05 / TC-07：通过。
- AC-06 / TC-08：通过。

## 计划重审批后复核

- 当前计划已于 2026-10-23T20:39:54+08:00 重新审批，摘要与现有计划一致。
- 重审批不改变产品工作区、测试命令、样本或 AC/TC 结果；复核时 `git diff --check` 再次通过，16 个产品文件仍为同一未提交改动集。

## Git 成果状态

- 16 个产品文件已提交到 `codex/008-bff-cold-path`，提交为 `c57b594194cdfd40f3d24e6d7836ebc0b0e453da`。
- 远端 `main` 由 `ee616bc` 快进到 `c57b594`，`git ls-remote` 已确认远端分支指向该提交。
- 真实仓库 `main` 仍停留在 `ee616bc`，并保留两处接管前未提交修改；未取得拉取及 dirty 处理授权，不在本步骤改动真实仓库。

## 同步与恢复复核

- 用户授权后，原仓库两处 dirty 已先保存到命名 stash；受控同步脚本将真实仓库 `main` 快进到 `c57b594` 并验证包含 worktree 最终 HEAD，清理脚本随后删除 worktree 并恢复产品检出路径。
- 原 dirty 已应用到更新后的 `main`；一处内容冲突按“保留冷路径优化 + 恢复已解析 JSON 正文转发”解决，仍保持未暂存、未提交、未推送。
- 恢复后 `http-passthrough.service.spec.ts` 13/13、构建、生产文件 ESLint 和 `git diff --check` 通过；临时 stash 已在确认恢复后删除。
