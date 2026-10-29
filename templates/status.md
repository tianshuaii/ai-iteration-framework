# 状态

- workflow_profile: standard
- phase: specify
- current_task: 无
- work_state: ready
- updated_at: YYYY-MM-DDTHH:MM:SS+08:00
- checkpoint: 迭代已创建，规格尚未编写。
- next_action: 按 specify 阶段补齐规格文档。

`workflow_profile` 只能是 `lite`、`standard`、`strict`。新轮默认 `standard`；规格阶段按 `capabilities.yml` 的风险条件调整为最低安全档位，高风险或不确定项必须使用 `strict`。

`phase` 只能是 `specify`、`plan`、`implement`、`verify`、`done` 其中一个。`implement` 实现任务时使用 `T-xx`；首次统一审核或返工增量审核窗口使用 `无`。其他阶段固定写 `无`。

活动阶段的 `work_state` 只能是 `ready`、`in_progress` 或 `blocked`，`done` 阶段固定写 `done`。`updated_at` 使用带时区的 ISO 8601 时间。只在阶段切换、任务切换、阻塞、恢复或回合交接时更新 `checkpoint` 和 `next_action`；普通只读命令和同一连续步骤不制造微小状态写入。

实现和统一审核完成后使用 `verify / blocked` 等待验收授权；验收通过后继续使用 `verify / blocked` 等待收口授权。只有当前原话明确联合授权对应步骤时才可连续推进，不把“完成所有任务”自动解释为验收或收口。

等待设计问题时，`next_action` 必须同屏写出每个 `Qxx` 的问题全文、推荐方案和可直接复制的推荐回复，不能只写问题编号。用户明确回答前，访谈行保持 `待确认 / pending / 无`，不得提前标成 `resolved`。

阶段允许的读写范围只看 `prompts/` 中与 `phase` 对应的入口，不在本文件重复维护。
