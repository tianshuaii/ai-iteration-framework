<!-- shallow-regression-policy: bounded-v1 -->
<!-- risk-based-testing-policy: adaptive-v1 -->
# 测试策略

## 任务风险分级

| 任务 | 档位 | 分级理由 | 影响仓库/模块 | 必须执行 | 可复用证据 | 升级条件 |
|---|---|---|---|---|---|---|
| T-01 | T3 | 新列与保存契约 | mergex-manager dsp_place | 迁移脚本存在；实体/VO 含 appStd；相关编译 | 无 | 若接引擎标准化升 T4 |
| T-02 | T2 | 表单开关与回显 | EditSource BaseInfoForm | 源码有开关默认关；字段映射 | 无 | 若改列表列展示升 T3 |
| T-03 | T3 | 保存语义写死 | 利润策略保存 | 保存路径固定 bidFilterType=1 | 无 | 若批量刷库升 T4 |
| T-04 | T2 | 去掉 UI | UpdateLinkConfig | 连接利润表单无价格过滤 | 无 | 若误改其他表单升 T3 |
| T-05 | T3 | 范围补齐到全部 type + AB | batchUpdatePrice、ConfigABTest | 无 type 分支限制；AB 无 BidFilterStrategyV4 | T-03/T-04 源码证据部分复用 | 若再扩到 Mediatom 旧弹窗升 T4 |

## 自动

| 项目 | 命令 | 要挡住的错误 |
|---|---|---|
| 利润保存写死 | 管理端针对性单测或服务层断言 `bidFilterType==1` | 仍写入前端传来的 2 |
| 广告源字段 | 编译 + 保存 VO 含 appStd 的最小检查 | 字段没接到实体 |

## 手工

按 [test-cases](./test-cases.md) 执行。

## 受控浅功能回归

| 编号 | 类型 | 功能或路径 | 纳入理由 | 停止边界 |
|---|---|---|---|---|
| SR-01 | 直接 | 编辑广告源其他基本信息仍可保存 | 基本信息表单同页改动 | 不测 QPS/频控后续步骤 |
| SR-02 | 相邻 | 利润策略里平台底价策略仍可保存 | 去掉价格过滤后邻区不能坏 | 不测 AB 实验整页 |
