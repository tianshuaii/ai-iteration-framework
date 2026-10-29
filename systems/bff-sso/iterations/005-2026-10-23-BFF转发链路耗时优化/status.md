# 状态

- phase: done
- current_task: 无
- work_state: done
- updated_at: 2026-10-23T15:46:00+08:00
- checkpoint: 七条验收都通过。热路径 200 条，打上游前 P50 61 毫秒、P95 87 毫秒；冷启动 1416 毫秒。页面口径、白名单免登录、非白名单要登录、单发批量和日志队列丢弃都核对过。没有改用户正在用的包。Nacos、带正文、以及人为造两份生效包没有另做。
- next_action: 无

`phase` 只能是 `specify`、`plan`、`implement`、`verify`、`done` 其中一个。只有 `implement` 使用 `T-xx` 格式的 `current_task`，其他阶段写 `无`。

活动阶段的 `work_state` 只能是 `ready`、`in_progress` 或 `blocked`，`done` 阶段固定写 `done`。`updated_at` 使用带时区的 ISO 8601 时间。`checkpoint` 只记录已经验证的事实，`next_action` 写恢复后要做的第一件具体事情。

阶段允许的读写范围只看 `prompts/` 中与 `phase` 对应的入口，不在本文件重复维护。
