# 改动范围

仓库绝对路径写在这套系统的 `overview.md`。写规格时，管理端在 `feat-zhoutao`（`c0e44cb5`），页面在 `feat-20261027-bff`（`0c25c1aa7`，比远程超前 1 个提交）。系统名：mergex-manager。

002 还停在验收，并且登记过这两个仓库。进入实现前再核对能不能共用检出。

## 要改的项目

| 项目 | 这一轮它负责什么 |
|---|---|
| mergex-manager | 新下拉按当前用户能看的供应商收口；请求对象挪到 VO；鲲鹏带了流量广告位就返回空 |
| mediatom-web | 只改鲲鹏报表筛选：藏起流量广告位，查询不再带这个条件 |

## 页面上要改的位置

| 位置 | 现在 | 改完 |
|---|---|---|
| 鲲鹏报表筛选区的流量广告位 | `cur` 为 0 时显示，可选、可搜 | 不再显示。查询、趋势、导出都不带 `trafficPlaceIdList` |
| 鲲鹏报表的空结果 | 选了流量广告位仍可能看到全量 | 页面不再发出这个条件。若请求里仍带着，后端返回空 |
| 综合报表、小时报表的流量广告位 | 仍可搜索和筛选 | 不改显示。搜索结果改为只含当前用户能看的供应商 |

## 大致文件

### mergex-manager

- `src/main/java/com/ydmob/mergex/managerserver/service/traffic/impl/TrafficPlaceServiceImpl.java`：查询前收口供应商范围
- `src/main/java/com/ydmob/mergex/managerserver/service/traffic/TrafficPlaceService.java`：去掉内部类，方法改用新的请求对象
- `src/main/java/com/ydmob/mergex/managerserver/controller/traffic/TrafficPlaceController.java`：入参改为新的请求对象
- `src/main/java/com/ydmob/mergex/managerserver/model/vo/traffic/PublisherTrafficPlaceSearchReqVo.java`：新增。字段仍是 `publisherIdList`、`searchKey`、`trafficPlaceIdList`
- `src/main/resources/mapper/PublisherTrafficPlaceLinkMapper.xml`：供应商条件保持现有的 `IN`。范围在进 SQL 前已经收好，不另写一套过滤
- `src/main/java/com/ydmob/mergex/managerserver/service/report/kunpeng/impl/ReportKunpengServiceImpl.java`：非空 `trafficPlaceIdList` 重新算作不支持，返回空
- `src/test/java/com/ydmob/mergex/managerserver/service/report/kunpeng/impl/ReportKunpengServiceImplTest.java`：只带流量广告位时期望返回空，用例名不再写成已经支持
- 给供应商收口补一条不连库就能失败的检查。现有 `PublisherTrafficPlaceSearchTest` 只测关键字拆分，可在旁边加范围判断

### mediatom-web

- `src/viewsForManage/reportdatas/KunpengReport/SynthSearch/index.vue`：去掉流量广告位筛选项，搜索参数里不再带 `trafficPlaceIdList`。文件已超过 300 行，这轮不拆

### 补测试

- 管理端用现有单测方式跑鲲鹏「只带流量广告位则算不支持」和供应商范围判断。页面是否藏起筛选项按用例看，这轮不新造页面测试框架。

## 明确不动

| 项目 | 为什么不动 |
|---|---|
| mergex-datasyn | 不改同步，不建表 |
| Mediatom 页面 | 只动 MergeX 的鲲鹏筛选 |
| 老接口 `getTrafficPlace` | 用户只要求收口新下拉 |
| 综合报表、小时报表页面 | 筛选项继续可用 |
| `/report/fullReport` 的 `loginNum`、`payNum` | 用户此前明确不改 |
| 本地环境文件 | `application.yml`、`build/env/development/adx.js` 不纳入这轮 |
