# 测试策略

## 自动

管理端 `mergex-manager`，在仓库根目录执行：

`mvn -Dtest=PublisherTrafficPlaceSearchTest,ReportTrafficPlaceIdNormalizeTest,ReportKunpengServiceImplTest test`

要挡住这些错误：

- 纯流量广告位 ID 被丢掉
- 「广告位 ID_流量广告位 ID」没有取下划线后面的整段
- 同一个 ID 返回多行
- 没选供应商且没有关键字时仍去查全表
- 选了供应商、关键字为空时没有按这些供应商查
- 鲲鹏请求只带 `trafficPlaceIdList` 时仍被当成不支持条件

前端 `mediatom-web`，在仓库根目录执行：

`pnpm check:imports:mergex`

要挡住删掉多曝光页面后，还有文件引用它。

## 手工

按 [test-cases](./test-cases.md) 走。前置：管理端和 MergeX 页面用当前代码；`publisher_traffic_place_link` 里已有测试供应商的流量广告位。只动测试数据。菜单 SQL 只有在拿到执行授权后才跑，没跑之前 TC-07 的菜单项记未测，不把没跑写成通过。

## 回归

不能改坏：

- 映射管理仍走 `POST /trafficPlace/getTrafficPlace`
- 小时报表在不传流量广告位时仍能出数
- 鲲鹏报表不选流量广告位时，原有日期和供应商筛选仍出数

## 受控浅功能回归

| 编号 | 覆盖 | 纳入理由 | 停止边界 |
|---|---|---|---|
| SR-01 | ADX 报表不选流量广告位，按日期查出数 | 本轮直接改了这张报表的筛选和 ID 解析 | 不改维度、不导出全量、不测其他筛选项的组合 |
| SR-02 | 小时报表打开并按日期查出数 | 和 ADX 共用流量广告位 ID 解析，解析放宽后可能误伤 | 不测小时报表的流量广告位筛选，页面上本来没有这项。不测预警、华为、消耗、熔断、填充 |
