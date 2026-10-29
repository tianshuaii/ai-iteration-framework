# 改动范围

系统：`mergex-manager`。

## 仓库

| 仓库 | 绝对路径 | 这一轮 |
|---|---|---|
| `mediatom-web` | `/Users/mrzater/project/mediatom-web` | 改 ADX、鲲鹏的流量广告位筛选；删多曝光页面和只给它用的前端代码 |
| `mergex-manager` | `/Users/mrzater/java/mergex-manager` | 新增搜索接口；放宽 ADX 报表的 ID 解析；鲲鹏不再因该条件返回空；删多曝光查询和下载；停用菜单 |
| `mergex-datasyn` | `/Users/mrzater/java/mergex-datasyn` | 不动 |

React 前端不在这套系统里，不动。Mediatom 页面不动。

## 页面位置

| 位置 | 现在 | 改完 |
|---|---|---|
| ADX 报表筛选「流量广告位」 | 打开就拉列表。展示 ID，同一个 ID 可重复。选中值是「广告位 ID_流量广告位 ID」。搜索提示是「请输入流量广告位名称/ID」 | 输入关键字或更换供应商后再查。只显示去重后的流量广告位 ID。选中值就是这个 ID。搜索提示只提 ID |
| ADX 报表其余筛选项、维度、表格、导出按钮 | 保持原样 | 不改文案和布局。导出跟着新的 ID 数组走 |
| 鲲鹏报表筛选「流量广告位」 | 和 ADX 一样拼接待选值 | 搜索方式和 ADX 相同。选中后表格数字不随这个 ID 变化 |
| 鲲鹏报表其余筛选和表格 | 选了流量广告位后整表为空 | 取消这个空表。其余条件照常出数 |
| 数据报表菜单「多曝光报表」 | 能进入 `FunlinkAnalyse` | 菜单不再出现。页面代码不在 |
| 映射管理里的流量广告位 | 用老接口维护映射 | 不改 |
| 聚合配置里的 funlink 编辑限制 | 编辑广告源时锁字段 | 不改 |

## 可以改的文件

`mediatom-web`：

- 改：`src/viewsForManage/reportdatas/SynthReport/SynthSearch/index.vue`
- 改：`src/viewsForManage/reportdatas/KunpengReport/SynthSearch/index.vue`
- 改：`src/mixins/getListForManage.js`。两张报表改走新搜索。旧的拼接方法如果没有调用方，删掉
- 改：`src/apiForManage/common.js`。增加新接口方法
- 改：`src/router/generator-routers-manage.js`。去掉 `FunlinkAnalyse`
- 改：`src/utils/localDataNameForManage.js`。去掉只给多曝光用的列缓存名
- 改：`src/locales/lang/zh-CN/menu.js`、`src/locales/lang/en-US/menu.js`、`src/locales/lang/zh-CN/mediatomReport.js`、`src/locales/lang/en-US/mediatomReport.js`、`src/locales/lang/zh-CN/report.js`、`src/locales/lang/en-US/report.js`、`src/locales/lang/zh-CN/common.js`、`src/locales/lang/en-US/common.js`。只改流量广告位搜索提示，并删掉没有引用的多曝光文案。中英文成对
- 删：`src/viewsForManage/reportdatas/FunlinkAnalyse/`
- 删：`src/apiForManage/report/flanalyse.js`

`mergex-manager`：

- 改：`src/main/java/com/ydmob/mergex/managerserver/controller/traffic/TrafficPlaceController.java`。保留 `getTrafficPlace`，新增搜索
- 改：`src/main/java/com/ydmob/mergex/managerserver/service/traffic/TrafficPlaceService.java`
- 改：`src/main/java/com/ydmob/mergex/managerserver/service/traffic/impl/TrafficPlaceServiceImpl.java`
- 新增：查询 `publisher_traffic_place_link` 的 Mapper 接口和 XML。放在管理端现有 mapper 目录，不从定时任务仓库搬
- 改：`src/main/java/com/ydmob/mergex/managerserver/service/report/impl/ReportServiceImpl.java`。放宽流量广告位 ID 解析；删多曝光查询和下载方法
- 改：`src/main/java/com/ydmob/mergex/managerserver/service/report/ReportService.java`
- 改：`src/main/java/com/ydmob/mergex/managerserver/controller/report/ReportController.java`。去掉多曝光查询和下载
- 改：`src/main/java/com/ydmob/mergex/managerserver/service/report/kunpeng/impl/ReportKunpengServiceImpl.java`。`trafficPlaceIdList` 不再算不支持条件
- 改：`src/main/java/com/ydmob/mergex/managerserver/service/download/impl/ReportDownloadExportHandler.java`。去掉 `downloadMultiImpressReport` 分支
- 改：`src/main/java/com/ydmob/mergex/managerserver/common/utils/ReportProjectionUtil.java`。只删多曝光投影，文件里别的报表投影留下
- 改：`src/main/java/com/ydmob/mergex/managerserver/mapper/report/ClickhouseReportNewMapper.java` 和 `src/main/resources/mapper/ClickhouseReportNewMapper.xml`。只删多曝光 SQL，别的报表 SQL 留下
- 删：`src/main/java/com/ydmob/mergex/managerserver/service/report/support/MultiImpressReportAssembler.java`
- 删：`src/main/java/com/ydmob/mergex/managerserver/model/vo/report/response/MultiImpressReportVo.java`。先确认没有多曝光以外的引用
- 新增：`sql/` 下一条停用菜单的 SQL。只把组件名 `FunlinkAnalyse` 那条路由的 `status` 改为 `D`
- 补测试：`src/test/java/com/ydmob/mergex/managerserver/service/traffic/PublisherTrafficPlaceSearchTest.java`
- 补测试：`src/test/java/com/ydmob/mergex/managerserver/service/report/impl/ReportTrafficPlaceIdNormalizeTest.java`
- 补测试：在现有鲲鹏服务测试旁新增或补一条，证明只带 `trafficPlaceIdList` 时不再被当成不支持条件。若还没有鲲鹏服务测试文件，新增 `src/test/java/com/ydmob/mergex/managerserver/service/report/kunpeng/impl/ReportKunpengServiceImplTest.java`

做的时候如果必须再碰一个文件，先把路径补进这份文档，再改那个文件。

## 明确不动

- `mergex-datasyn` 全部文件，含 `PublisherTrafficPlaceSyncService` 和它的 Mapper。
- `POST /trafficPlace/getTrafficPlace` 的原有行为。
- 映射管理、小时报表、预警、华为、消耗、熔断、填充分析的页面。
- 聚合配置里带 funlink 的编辑限制。
- `report_kunpeng` 的表结构和查询列。
- React 前端和 Mediatom 页面。
