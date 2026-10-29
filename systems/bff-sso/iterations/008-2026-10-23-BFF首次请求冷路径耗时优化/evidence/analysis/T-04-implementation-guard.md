# T-04 实施守卫

- task: T-04
- status: passed
- provider: manual-implementation-guard
- provider_version: capability-gates-v1
- input_digest: 41c7341fb9f8e1f27a1ce46b3cd13acce6c3f07ad335ffa4ead822faf5e571c7
- previous_input_digest: 583637edd9434ba31ac6f1f860fb4fa55fb413c552ca019f0feab5052fa92c69
- revalidated_at: 2026-10-23T20:42:00+08:00
- input_digest: 583637edd9434ba31ac6f1f860fb4fa55fb413c552ca019f0feab5052fa92c69
- started_at: 2026-10-23T19:46:49+08:00
- completed_at: 2026-10-23T19:46:49+08:00

## 检查结论

- 授权：沿用用户“开始处理，完成所有的任务”和“你自己处理”的当前轮授权；不包含提交、推送、部署或数据迁移。
- 依赖：T-01、T-03 已完成。四路正式基线均已达到 30 个主组样本，直通日志重复显示完整清单读取是冷路径大头。
- 范围：仅修改任务列出的两个服务文件与两个对应 spec；完整管理端 inventory 行为保持不变，只增加直通路由专用的最小读取入口。
- 隔离：独立 worktree 分支 `codex/008-bff-cold-path`，HEAD `ee616bcb333f9d27769d2d0604116907b64c8325`；原仓库不修改。
- dirty 基线：`http-passthrough.service.ts`、`http-passthrough.service.spec.ts`、`runtime-package-inventory.service.ts` 已含 T-01 计时改动；`runtime-package-inventory.service.spec.ts` 当前干净。T-04 必须保留前三者的既有改动。
- 运行资源：本任务只改代码并运行 Jest/构建，不启停现有 BFF；正式复测留到后续受控采样窗口。
- 专用能力：本机没有安装 `iteration-implementation-guard` skill，继续使用与 T-03 相同的人工确定性回退并如实标记 provider。

## 发现项

- P0: 0
- P1: 0
- P2-open: 0

## 准入条件

必须保留运行包归属校验、加载失败删除 Promise 以便重试、切包清理旧 route set；完成定向测试后执行 `code-review-skill`，修复并复验才可勾选。

## 当前计划重审批复核

T-07 仍复用 T-04 登记的 resolver、inventory、passthrough 范围，没有新增协议或权限行为；归属校验、失败重试和切包清理均仍存在，当前守卫无新增发现。
