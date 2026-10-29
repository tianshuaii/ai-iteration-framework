# 跟踪表

| 需求要点 | 验收 | 用例 | 主要文件 |
|---|---|---|---|
| 只传关键字时按当前用户能看的供应商收口 | AC-01 | TC-01 | `TrafficPlaceServiceImpl.java` |
| 传入的供应商和能看的范围取交集，空交集返回空 | AC-02 | TC-02 | `TrafficPlaceServiceImpl.java` |
| 没有范围或三个条件都空时不扫整张表 | AC-03 | TC-03 | `TrafficPlaceServiceImpl.java`、`PublisherTrafficPlaceLinkMapper.xml` |
| 鲲鹏带流量广告位时返回空 | AC-04 | TC-04 | `ReportKunpengServiceImpl.java` |
| 鲲鹏页面不再显示也不再发送这个条件 | AC-05 | TC-05 | `KunpengReport/SynthSearch/index.vue` |
| 请求对象挪到 traffic 的 VO，字段不变 | AC-06 | TC-06 | `PublisherTrafficPlaceSearchReqVo.java`、`TrafficPlaceController.java` |
| 综合报表搜索仍可用且看不到别人的 ID | 无，浅回归不绑 AC | SR-01 | `TrafficPlaceServiceImpl.java` |
| 鲲鹏只选日期不会被藏筛选项带成空 | 无，浅回归不绑 AC | SR-02 | `KunpengReport/SynthSearch/index.vue` |
