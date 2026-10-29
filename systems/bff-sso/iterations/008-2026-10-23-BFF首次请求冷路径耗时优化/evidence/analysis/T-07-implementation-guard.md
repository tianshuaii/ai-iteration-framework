# T-07 实施守卫

- task: T-07
- status: passed
- provider: manual-implementation-guard
- provider_version: capability-gates-v1
- input_digest: 41c7341fb9f8e1f27a1ce46b3cd13acce6c3f07ad335ffa4ead822faf5e571c7
- previous_input_digest: 583637edd9434ba31ac6f1f860fb4fa55fb413c552ca019f0feab5052fa92c69
- revalidated_at: 2026-10-23T20:42:00+08:00
- started_at: 2026-10-23T20:22:00+08:00
- completed_at: 2026-10-23T20:22:00+08:00

## 检查结论

- 授权：用户已明确要求“开始处理，完成所有的任务”和“你自己处理”；需求与计划审批仍有效。T-07 是 AC-03 / TC-04 未通过后的既定范围内代码返工。
- 范围：只修改任务登记的 resolver、inventory、passthrough 三个实现文件及对应三个 spec；不改协议、鉴权、页面、其他服务或数据。
- 依赖：T-04、T-05、T-06 均已定向复验并完成评审；首轮优化后四路各 30 个正式样本已保留，失败原因可复核。
- 隔离：使用框架登记的独立 worktree `codex/008-bff-cold-path`，HEAD `ee616bcb333f9d27769d2d0604116907b64c8325`；六个目标文件只有本轮 T-04/T-05 的未提交改动，原仓库 dirty 不会被覆盖。
- 资源：实现与单元测试不启停服务；正式复测沿用已获准的独占 `本机 BFF :3000`、测试服务直连和动态固定替身端口，并在同轮恢复。
- 方案边界：健康就绪前等待 active 上下文和直通路由预热；预热失败不阻断启动，后续请求仍按原安全路径重试。route 快照必须校验方法/路径，旧包没有 route 项时回退 doc。

## 发现项

- P0: 0
- P1: 0
- P2-open: 0

## 当前计划重审批复核

用户已明确批准包含 T-07 的当前计划。复核确认六个目标文件均在原改动范围内，预热失败仍可请求期重试，route 损坏保持拒绝，且没有新增外部接口、迁移或持久化字段。
