# T-05 实施守卫

- task: T-05
- status: passed
- provider: manual-implementation-guard
- provider_version: capability-gates-v1
- input_digest: 41c7341fb9f8e1f27a1ce46b3cd13acce6c3f07ad335ffa4ead822faf5e571c7
- previous_input_digest: 583637edd9434ba31ac6f1f860fb4fa55fb413c552ca019f0feab5052fa92c69
- revalidated_at: 2026-10-23T20:42:00+08:00
- input_digest: 583637edd9434ba31ac6f1f860fb4fa55fb413c552ca019f0feab5052fa92c69
- started_at: 2026-10-23T19:50:02+08:00
- completed_at: 2026-10-23T19:50:02+08:00

## 检查结论

- 授权：沿用本轮“开始处理，完成所有的任务”和“你自己处理”；不包含提交、推送、部署或迁移。
- 证据：T-02 分段与 T-03 基线已确认默认单发/批量在首次请求读取完整 Redis 正文或 DB blob；任务只优化默认 active 上下文。
- 方案：Redis active 正文旁新增轻量版本键；进程内只复用默认 active 上下文，每次请求先读小版本。版本命中才复用，缺失、失败或不一致均回退现有正文/DB 路径。
- 跨实例：activate/archive 事件清理本机 active 上下文；即使漏收事件，版本不一致也不复用旧上下文。
- 串包边界：manifest pin 与显式数据库 `packageId` 保持原路径，不读取或写入默认 active 进程缓存。
- 隔离：独立 worktree `codex/008-bff-cold-path`，HEAD `ee616bcb333f9d27769d2d0604116907b64c8325`；三份 T-05 产品文件接管前均干净。
- 专用能力：本机没有 `iteration-implementation-guard` skill，继续使用人工确定性回退并如实记录 provider。

## 发现项

- P0: 0
- P1: 0
- P2-open: 0

## 准入条件

必须覆盖版本命中、跨实例版本变化、版本缺失/读取失败、activate/archive 清理及显式 `packageId` 不串用默认缓存；定向测试后执行代码审查、修复与复验。

## 当前计划重审批复核

新摘要未改变 T-05 的缓存权威和安全回退约束。默认 active、显式 manifest/database packageId、跨实例失效仍隔离；现有测试继续覆盖版本缺失、读取失败和事件清理，无新增发现。
