# 任务清单

- [x] T-01 为 applistForD 增加可选账户和状态，不传时保持现有结果。依赖：无。文件：`mediatom-manager` 的 `AppController.java`、`AppService.java`、`AppServiceImpl.java`、`AppMapper.java`、`AppMapper.xml`。检查：`mvn -DskipTests test-compile`
- [x] T-02 综合报表和小时报表都把应用状态放在应用前面，并只通过 applistForD 按状态和账户刷新应用下拉。依赖：T-01。文件：`mediatom-web` 的 `SynthReport/SynthSearch/index.vue`、`HoursReport/HoursSearch/index.vue`、`shared/reportSearchLoader.js`、`src/api/media.js`。检查：`pnpm check:imports:mediatom`

任务的“检查”在首次实现完成后统一去重执行；验收返工时只执行风险策略判定受影响的必跑项。单条任务完成代码与必要测试实现后即可勾选，不机械重复完整检查或 code review。
