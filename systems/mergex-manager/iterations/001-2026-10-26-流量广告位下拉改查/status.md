# 状态

- workflow_profile: strict
- phase: done
- current_task: 无
- work_state: done
- updated_at: 2026-10-27T14:45:38+08:00
- checkpoint: 用户确认不需要页面测试验证。简单单测 8 条通过。AC-01 至 AC-09、TC-01 至 TC-09、SR-01、SR-02 记为豁免。残余风险：没在页面上再点供应商和 lenovo_store3；旧拼接按整段查；多曝光菜单还在而页面已删；有的日期仍可能因 login_num 报错。未提交、未推送。
- next_action: 无

`workflow_profile` 只能是 `lite`、`standard`、`strict`。新轮默认 `standard`；规格阶段按 `capabilities.yml` 的风险条件调整为最低安全档位，高风险或不确定项必须使用 `strict`。

`phase` 只能是 `specify`、`plan`、`implement`、`verify`、`done` 其中一个。`implement` 实现任务时使用 `T-xx`；全部任务已经写完、正在做统一检查与审核时使用 `无`。其他阶段固定写 `无`。

活动阶段的 `work_state` 只能是 `ready`、`in_progress` 或 `blocked`，`done` 阶段固定写 `done`。`updated_at` 使用带时区的 ISO 8601 时间。只在阶段切换、任务切换、阻塞、恢复或回合交接时更新 `checkpoint` 和 `next_action`；普通只读命令和同一连续步骤不制造微小状态写入。

阶段允许的读写范围只看 `prompts/` 中与 `phase` 对应的入口，不在本文件重复维护。
