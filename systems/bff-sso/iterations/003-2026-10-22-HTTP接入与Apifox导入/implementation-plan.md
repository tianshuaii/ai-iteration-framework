# 实现计划

数据先加列，行为只在现有入口上分支。产品代码还没改。

## 做法

账号后端做迁移，BFF 只把 Prisma 模型同步成一样，不在 BFF 里生成迁移。

接口项目表增加：

- `interface_kind`：`http` 或 `grpc`。库默认和已有行都是 `grpc`。
- `source_apifox_project_id`：可空。HTTP 才有值，gRPC 写成 `null`，不用空字符串。

接入服务的 `transport_type` 增加 `http`。列默认仍是 `grpc`，已有行不改。新建页面默认 HTTP 只写在表单上。

保存接口项目集中在 `project.service.ts`。HTTP 必须有 `sourceApifoxProjectId`，这次保存不调用 Apifox。gRPC 把这个字段写成 `null`，Proto 地址仍按现在的方式：填了就创建前解析，地址不入库。更新时如果 `interfaceKind` 和库里的不一样，直接拒绝。只改名称或来源 ID 也不调用 Apifox。

拉取集中在新的 `import-apifox.service.ts`。「原接口文档」和「项目分支」都调这一个接口。它先用 `ApifoxClient` 上新增的导出，地址和令牌跟现有的 `importOpenApi` 同一套配置，路径是现有导入地址旁边的导出 OpenAPI。导出失败就返回，不写工作区。导出成功后走现在的 `importOpenApiJson`，再走 `UpstreamReconcileService.buildPreview`。改造和整合仍要等人确认，不在导入里直接改。gRPC 项目走这个新接口要拒绝；HTTP 项目走「导入 Proto」也要拒绝。

转发只改 `proxy.service.ts` 这一处。`transportType` 是 `http` 时按方法和路径打 HTTP，不读 Proto，不拼 `grpc://`。直连把 `directAddress` 拼成 `http://ip:端口`。Nacos 只用实例 metadata 的 `httpPort`，没有就失败。正在使用的接口包如果是另一种文档，这次转发失败。`grpc` 仍走现在的方法名，不接受 method。

连通测试跟转发用同一套地址规则，放在 `sub-service-connectivity.service.ts`，不要在弹窗里再算一遍端口。

接入服务保存仍在 `admin.service.ts`。只接受 `transportType`。请求里若带了 `sourceApifoxProjectId`，拒绝保存。`apifoxPushProjectId` 的推送逻辑不改。

页面放在接口和保存都定下来之后。接口项目新建默认 HTTP；接入服务新建默认 HTTP。平台内建服务整单不可编辑，不只锁通信方式。

## 为什么这样切

导入按钮有两个页面，拉取和差异只写在一个服务里，页面只换按钮文案。转发的调用方很多，分支只留在 `proxy.service.ts`，账号页和其他业务不用各判一次。

## 怎样避开「不做」

- 不读、不写接入服务上的原接口项目 ID。推送运行包的 `runtime-apifox-target.service.ts` 不改。
- 创建和普通保存不调用 Apifox 导出。
- 不改接口类型。
- 不改 SSO，不改账号管理页，不在 BFF 执行迁移。

## 字段变化

| 字段或路径 | 谁在用 | 变化 |
|---|---|---|
| `interfaceKind` / `interface_kind` | 接口项目创建、编辑、导入按钮 | 新建表单默认 `http`。库默认 `grpc`，已有项目不变。创建后不能改 |
| `sourceApifoxProjectId` / `source_apifox_project_id` | 接口项目。HTTP 的「导入接口」只读这一列 | 可空。gRPC 写成 `null`。接入服务请求里带这个字段会被拒绝 |
| `transportType` / `transport_type` | 接入服务保存、转发、连通测试 | 增加取值 `http`。新建默认 `http`。已有行仍是 `grpc`。Nacos 的 HTTP 地址只用 `httpPort` |
| `POST /api/admin/interface-branches/:id/import-apifox` | 原接口文档、项目分支的「导入接口」 | 新接口。请求体只有 `projectId`，不收地址 |
| `apifoxPushProjectId` | 推送正在使用的运行包 | 含义不变，仍可空 |
