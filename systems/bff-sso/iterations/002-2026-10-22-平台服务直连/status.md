# 状态

- phase: done
- current_task: 无
- work_state: done
- updated_at: 2026-10-22T21:33:53+08:00
- checkpoint: 用户确认直接收口。AC-01 到 AC-06 均为通过，无豁免。角色页环境报错已消失，接入服务列表的绑定环境用户确认为正确。残余风险：停用角色时状态保存失败是原有问题，本轮未改；后加的内建同步、禁止编辑和运行包环境没有单独验收编号，随本次收口一并结束。
- next_action: 无

`phase` 只能是 `specify`、`plan`、`implement`、`verify`、`done` 其中一个。只有 `implement` 使用 `T-xx` 格式的 `current_task`，其他阶段写 `无`。

活动阶段的 `work_state` 只能是 `ready`、`in_progress` 或 `blocked`，`done` 阶段固定写 `done`。`updated_at` 使用带时区的 ISO 8601 时间。`checkpoint` 只记录已经验证的事实，`next_action` 写恢复后要做的第一件具体事情。

阶段允许的读写范围只看 `prompts/` 中与 `phase` 对应的入口，不在本文件重复维护。
