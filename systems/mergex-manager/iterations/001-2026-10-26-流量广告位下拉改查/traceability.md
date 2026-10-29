# 跟踪表

| 需求要点 | 验收编号 | 用例编号 | 主要文件 |
|---|---|---|---|
| ADX、鲲鹏下拉只显示去重后的流量广告位 ID，按关键字异步搜索 | AC-01 | TC-01 | `mediatom-web` 的 `SynthSearch/index.vue`、`KunpengReport/SynthSearch/index.vue`；`mergex-manager` 的 `TrafficPlaceController.java` |
| 选中供应商后，搜索框为空也只查这些供应商 | AC-02 | TC-02 | `SynthSearch/index.vue`；`TrafficPlaceServiceImpl.java` |
| 没选供应商时只按关键字查，都空则不请求 | AC-03 | TC-03 | `SynthSearch/index.vue`；`PublisherTrafficPlaceSearchTest.java` |
| ADX 查询只传流量广告位 ID，并按它出数 | AC-04 | TC-04 | `SynthSearch/index.vue`；`ReportServiceImpl.java` |
| 旧的「广告位 ID_流量广告位 ID」仍能查 | AC-05 | TC-05 | `ReportServiceImpl.java`；`ReportTrafficPlaceIdNormalizeTest.java` |
| 鲲鹏选中流量广告位后仍按其他条件出数，不再空表 | AC-06 | TC-06 | `ReportKunpengServiceImpl.java`；`ReportKunpengServiceImplTest.java` |
| 多曝光页面、查询、下载和菜单去掉 | AC-07 | TC-07 | `FunlinkAnalyse/`；`ReportController.java`；`sql/` 停用菜单脚本 |
| 老查询接口和小时报表不被删坏 | AC-08 | TC-08 | `TrafficPlaceController.java` 的 `getTrafficPlace`；`ReportServiceImpl.java` 的小时报表入口 |
| 换供应商不清空已选 ID，新结果只含新供应商 | AC-09 | TC-09 | `SynthSearch/index.vue`；`TrafficPlaceServiceImpl.java` |
| ADX 不选流量广告位仍能出数 | 无，浅回归不绑 AC | SR-01 | `SynthReport` 查询入口 |
| 小时报表按日期仍能出数 | 无，浅回归不绑 AC | SR-02 | `ReportServiceImpl.java` 的小时报表入口 |
