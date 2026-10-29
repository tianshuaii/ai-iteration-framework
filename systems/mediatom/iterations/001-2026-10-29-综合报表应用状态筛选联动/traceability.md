# 跟踪表

| 需求要点 | 验收 | 用例 | 主要文件 |
|---|---|---|---|
| 应用状态放在应用前面 | AC-01、AC-08 | TC-01、TC-08 | SynthSearch/index.vue、HoursSearch/index.vue |
| 默认启用中和暂停中，下拉只含这两种 | AC-02 | TC-02 | SynthSearch/index.vue、appStsFilterConfig.js |
| 多选状态按并集过滤应用 | AC-03 | TC-03 | SynthSearch/index.vue、AppMapper.xml |
| 选中已删除时账户路径也能返回已删除 | AC-04 | TC-04 | AppController.java、AppMapper.xml |
| 仍在下拉中的已选应用保留，其余取消并级联刷新 | AC-05 | TC-05 | SynthSearch/index.vue |
| 一个状态都没选时应用下拉为空且不请求 | AC-06 | TC-06 | SynthSearch/index.vue |
| 选中账户也只请求 applistForD，并保留类型图标和云图标 | AC-07 | TC-07 | media.js、reportSearchLoader.js、AppMapper.xml |
| 无参数 applistForD 仍可供动态包回填名称 | 无单独验收，见 SR-02 | SR-02 | media.js、AppMapper.xml |
| 小时报表与综合报表同一套状态联动和请求 | AC-08 | TC-08、SR-03 | HoursSearch/index.vue、reportSearchLoader.js |
