# 风险与回退

| 风险 | 影响 | 怎样避免 | 怎样退回 |
|---|---|---|---|
| 迁移把已有接入服务或接口项目改成 HTTP | 老的 gRPC 转发和「导入 Proto」突然对不上 | 列默认和已有行都写成 `grpc`，来源 ID 留空。新建默认 HTTP 只在页面上 | 在 `adx-admin-backend` 回滚这份迁移。BFF 没有自己的迁移可回滚 |
| HTTP 打到 gRPC 端口 | 调用失败，或打进错误的服务 | Nacos 只认 metadata 的 `httpPort`，没有就失败。直连只用这条记录上的 `directAddress` | 把该接入服务的 `transportType` 改回 `grpc` |
| Apifox 导出到一半就写入工作区 | 原接口变成残缺的一版，改造对不上 | 导出完整成功之后才调用 `importOpenApiJson`。失败直接返回 | 用现有的工作区撤销，回到上一次推送 |
| 原始接口项目 ID 被拿去推送运行包 | 改造过的包推进子服务自己的原始文档项目 | 新列叫 `sourceApifoxProjectId`。不改 `runtime-apifox-target.service.ts`，推送仍先用接入服务上的 `apifoxPushProjectId` | 不需要数据回滚。若页面填错列，改回接口项目上的来源 ID 即可 |
| 新建或改名称时就去拉 Apifox | 还没准备好的差异进了工作区 | 创建和普通保存不调用导出。只有「导入接口」才拉 | 同上，撤销工作区 |
