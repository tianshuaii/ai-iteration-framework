# 状态

- phase: done
- current_task: 无
- work_state: done
- updated_at: 2026-10-23T14:08:58+08:00
- checkpoint: TC-01 到 TC-10 都已通过，验收标准与测试记录一致。没有豁免。测完已把原来的生效包切回，对照用的项目和服务已删。
- next_action: 本轮无后续动作。

`phase` 只能是 `specify`、`plan`、`implement`、`verify`、`done` 其中一个。只有 `implement` 使用 `T-xx` 格式的 `current_task`，其他阶段写 `无`。

活动阶段的 `work_state` 只能是 `ready`、`in_progress` 或 `blocked`，`done` 阶段固定写 `done`。`updated_at` 使用带时区的 ISO 8601 时间。`checkpoint` 只记录已经验证的事实，`next_action` 写恢复后要做的第一件具体事情。

阶段允许的读写范围只看 `prompts/` 中与 `phase` 对应的入口，不在本文件重复维护。
