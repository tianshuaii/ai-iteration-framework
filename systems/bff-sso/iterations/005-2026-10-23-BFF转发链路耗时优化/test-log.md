# 测试记录

自动测试：验收时按测试策略又跑了一遍，见「验收自动测试」。

## 验收自动测试

- 时间：2026-10-23T15:31:18+08:00
- 后端：`/Users/mrzater/docker/adx/adx-bff-backend`，`pnpm test -- src/proxy/http-passthrough.service.spec.ts src/request-logs/request-log-hooks.spec.ts src/request-logs/request-log-list-item.spec.ts src/request-logs/redis-log-store.spec.ts --no-coverage`，退出码 0。4 个文件，22 条通过，6 条因没配测试 Redis 跳过。分支 `main`，HEAD `53ca7113dca4ecc21752361b2edcba025c3e5374`，改动未提交。
- 前端：`/Users/mrzater/docker/adx/adx-bff-frontend`，`pnpm exec vitest run src/features/request-logs/request-log-timeline.util.spec.ts`，退出码 0，4 条通过。分支 `main`，HEAD `0695d75f5ec93b16b530454b12f0a49f54c56a5f`，改动未提交。

## TC-01 / TC-03 耗时实测

- 时间：2026-10-23T15:31 到 15:36
- 环境：本机网关，按原来的 `pnpm start` 重启后才带上这次的代码。接口是白名单 GET `/proxy/mergex/user/code`，不带登录。直连，没有改用户现有的包。
- 优化前：原来 4 条 Trace，打上游前大约 574、653、702、792 毫秒。那不是 200 次样本。
- 冷启动：重启后的第一次，打上游前 1416 毫秒，整条 1584 毫秒，记录完整。
- 热路径：预热 10 次后，等日志队列清空，再连续 200 次，并发 1。200 次都返回成功，200 条日志都完整，都有打上游前的耗时。采集期间丢弃数没有增加。
- 打上游前：P50 61 毫秒，P95 87 毫秒，最小 49，最大 143。达到 100 毫秒这条线。
- 同一批：子请求 P50 16 / P95 24 毫秒；整条请求 P50 78 / P95 107 毫秒。浏览器侧自己计的整段 P50 79.6 / P95 109.0 毫秒，只作对照。
- 时间主要在查生效包（热路径里大约几十毫秒）和查接入服务（大约十几毫秒）。匹配、白名单、解析地址接近 0。
- 连着打、不等日志写完时，日志队列会堆满并丢事件，业务请求仍然成功。那一批没有拿来当基线。
- 没另测 Nacos，也没另测带正文的请求。

## T-01

- 仓库：`/Users/mrzater/docker/adx/adx-bff-backend`
- 命令：`pnpm test -- src/proxy/http-passthrough.service.spec.ts src/request-logs/request-log-hooks.spec.ts src/request-logs/trace-context.spec.ts --no-coverage`
- 时间：2026-10-23T15:22:00+08:00（review 后复验）
- 退出码：0
- 结果：3 个测试文件、14 条都通过
- 基线：分支 `main`，HEAD `53ca7113dca4ecc21752361b2edcba025c3e5374`，改动还在工作区，未提交
- code review：打上游前那条如果只记「上一段」会接近 0 毫秒，已改成从入站算起的耗时，并复验通过

## T-02

- 仓库：`/Users/mrzater/docker/adx/adx-bff-backend`
- 命令：`pnpm test -- src/proxy/http-passthrough.service.spec.ts --no-coverage`
- 时间：2026-10-23T15:26:00+08:00
- 退出码：0
- 结果：10 条通过。覆盖同一包只读一次接口清单、两条冷请求共用一次加载、切包重读、白名单每次现查、加载失败不留空名单
- 基线：优化前仍是原来 4 条 Trace（574～792 毫秒）。新分段还没进正在跑的网关，这次不把 100 毫秒目标当成已达成
- code review：缓存键只用运行包主键，失败会删掉这次加载；没有再改代码

## T-03

- 仓库：`/Users/mrzater/docker/adx/adx-bff-backend`
- 命令：`pnpm test -- src/request-logs/redis-log-store.spec.ts`
- 时间：2026-10-23T15:27:00+08:00（review 后复验）
- 退出码：0
- 结果：6 条完整性用例通过。另外 6 条要连测试 Redis，这次没配地址，跳过了
- 基线：分支 `main`，HEAD `53ca7113dca4ecc21752361b2edcba025c3e5374`。这两个文件动手前是干净的
- code review：结束钩子没走到时，直通要看到 `passthrough.response` 才算完整。只有 `forward.response`、序号断了、或摘要上已有丢弃标记，仍然不完整。普通 `/proxy/one` 仍要求 `http.response`

## T-04

- 仓库：`/Users/mrzater/docker/adx/adx-bff-frontend`
- 命令：`pnpm exec vitest run src/features/request-logs/request-log-timeline.util.spec.ts`
- 时间：2026-10-23T15:28:03+08:00
- 退出码：0
- 结果：4 条通过。整套 `pnpm test` 里还有 3 条失败，都是找不到流量包夹具文件，和这次改的请求查询无关
- 基线：分支 `main`，HEAD `0695d75f5ec93b16b530454b12f0a49f54c56a5f`。这 5 个文件动手前是干净的
- code review：空档不再沿用起点的阶段名。只有 Span 自己带了结束耗时才保留阶段名。不完整提示写明不能当性能基线

## 返工历史

- 无。失败时追加日期、命令或 TC、现象、受影响的 AC/TC、返工任务；当前结果仍在下表维护。

| 用例 | 日期 | 结果 | 现象 |
|---|---|---|---|
| TC-01 | 2026-10-23 | 通过 | 白名单 GET 200 条完整记录能分开看到打上游前、上游处理和整条耗时。Nacos 和带正文没有另测。 |
| TC-02 | 2026-10-23 | 通过 | 请求查询页列表是「子请求耗时」，详情是「BFF 整条请求耗时」。同一条直通列表 19 毫秒、详情 77 毫秒。空档写成「待归因区间」，没有把那段说成读取请求体。旧的 `/proxy/one` 日志能打开。缺了事件的记录有「不能当作性能基线」。 |
| TC-03 | 2026-10-23 | 通过 | 预热后打上游前 P95 87 毫秒，P50 61 毫秒，200 条。冷启动 1416 毫秒。优化前 4 条是 574～792 毫秒。 |
| TC-04 | 2026-10-23 | 通过 | 白名单 GET 不带登录返回 200，响应是分块传输，正文是上游自己的 JSON。直通代码没有另设超时。没有另搭一个慢慢吐分段的上游。 |
| TC-05 | 2026-10-23 | 通过 | 非白名单不带登录是 40101。带登录后请求到了上游，上游自己说登录失效。不存在的路径是 40001。假的唯一路径返回「没有唯一的生效运行包」。没有改用户正在用的包，所以没有人为造出两份生效包；没有和两份走的是同一处判断。 |
| TC-06 | 2026-10-23 | 通过 | 单发和批量不带登录是 40101。成功时外层是 code、msg、data。1 毫秒超时会中止。批量按 requestId 各自返回。不存在的路径在单发和批量里都是内层 500，批量该项仍标成功，这是原来的返回方式。 |
| TC-07 | 2026-10-23 | 通过 | 同时打 120 次，全部 200。日志丢弃数从 848 增到 1253，队列曾堆到 967。抽到的记录标了不完整。队列随后回到 0。这批没有拿来当耗时基线。 |

结果通常使用“未测”“通过”或“未通过”。只有用户明确确认时才可写“豁免”，并在现象列同时写明“用户确认”和“残余风险”；缺少任一项都不能进入 `done`。
