# 代码审核报告

- 范围：本轮全部未提交改动。管理端仓库 `/Users/mrzater/java/mergex-manager`，页面仓库 `/Users/mrzater/project/mediatom-web`。对比基准都是接管时的 HEAD，工作区有未提交改动。
- 时间：2026-10-26T17:29:05+08:00
- 决策：Approve

## 摘要

ADX 和鲲鹏的流量广告位改成按供应商搜索，只显示 ID。旧的拼接值还能拿去查报表。鲲鹏选了这个 ID 不再变成空表。多曝光页面和接口删掉了，菜单停用 SQL 只写了文件，没有执行。

## 检查命令

管理端默认把测试写死跳过，任务里的 `mvn -Dtest=... test` 会显示成功但实际不跑。编译已经通过。测试改用本机已有的 JUnit 启动器实跑。不改构建文件，也不改已批准的任务正文。

| 仓库 | 命令 | 时间 | 退出码 | 结果 |
|---|---|---|---|---|
| mergex-manager | `mvn -Dtest=PublisherTrafficPlaceSearchTest,ReportTrafficPlaceIdNormalizeTest,ReportKunpengServiceImplTest test` | 2026-10-26T17:24:42+08:00 | 0 | 编译通过。测试被构建配置跳过 |
| mergex-manager | JUnit 控制台执行上面三个测试类 | 2026-10-26T17:25:20+08:00 | 0 | 10 条全过 |
| mergex-manager | `mvn -DskipTests test-compile` 已包含在上面的编译里；再用 ruby 扫 `multiImpressReport`、`downloadMultiImpressReport`、`MultiImpressReport` | 2026-10-26T17:24:56+08:00 | 0 | 主代码里没有这三个名字 |
| mergex-manager | 任务 T-01 的 ruby 检查菜单 SQL | 2026-10-26T17:23:00+08:00 | 0 | `sql ok` |
| mediatom-web | `pnpm check:imports:mergex` | 2026-10-26T17:23:00+08:00 | 0 | mergex 引用检查通过 |
| mediatom-web | 任务 T-07 的 ruby 检查页面、接口和路由 | 2026-10-26T17:23:00+08:00 | 0 | 页面目录、接口文件和路由引用都没了 |
| mediatom-web | 任务 T-06 的 ruby 检查两张搜索页 | 修复后 2026-10-26T17:28:40+08:00 | 0 | `pages ok` |

所测版本：管理端 `adde6027`，页面 `b6c14103d`。两边都还有本轮未提交改动。

## 发现

- [P2] 套用模板后，已选的流量广告位不会回到下拉里 — `KunpengReport/SynthSearch/index.vue` 的 `changeQuery`；`SynthReport/SynthSearch/index.vue` 的 `syncLinkageByQuery`
  说明：鲲鹏套模板时只刷新了包名。ADX 只在供应商变了时查，而且把搜索框里的字丢掉。已选 ID 就不在列表里。
  处置：已修。两页都改成读当前搜索框，供应商或已选 ID 变了再查。鲲鹏套模板后也会再查一次。修复后重跑了页面检查。

无未关闭的 P0、P1、P2。

## 测试缺口 / 残余风险

- 页面还没打开看过。正式验收和浅回归还没做。
- 菜单 SQL 没执行，菜单项现在还在。
- 没选供应商时，关键字会搜到关联表里任意供应商的 ID。这是已定的搜索范围。报表仍按原来的供应商权限出数。
- 选了供应商且搜索框为空时，一次返回这些供应商的全部 ID，没有条数上限。
- 鲲鹏选了流量广告位，表格数字不随这个 ID 变化。表里没有这一列。

## 做得好的地方

- 老的下拉接口还在，映射管理不用改。
- 关键字拆分、去重和“要不要查”都有不连库的测试。
- 多曝光只删了自己的查询、下载和页面，共用的分组条件留着。
