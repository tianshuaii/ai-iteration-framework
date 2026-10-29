# 测试策略

## 自动

| 项目 | 命令 | 要挡住的错误 |
|---|---|---|
| `adx-bff-backend` | `pnpm test -- src/interface-version/services/project.service.spec.ts src/interface-version/services/import-apifox.service.spec.ts src/proxy/proxy.service.spec.ts src/admin/sub-service-connectivity.service.spec.ts` | 新建 HTTP 项目就去拉 Apifox；gRPC 项目要求来源 ID；导入失败仍写入工作区；HTTP 转发仍走 gRPC；Nacos 没有 `httpPort` 时改用 gRPC 端口；接入服务保存了 `sourceApifoxProjectId`；gRPC 转发开始接受 method |

账号后端这一轮只加迁移。不另跑一套页面测试。迁移内容用上面的模型字段在 BFF 测试里挡住。

## 手工

按 [test-cases](./test-cases.md) 执行，结果写入 [test-log](./test-log.md)。

前置：网关管理页能打开。用一个专门给这次试的 Apifox 项目，项目 ID 不要写进迭代文档。自动测试用假的导出结果，不打真实 Apifox。

## 回归

不能被改坏的老路径：

- 已有 gRPC 接口项目仍用「导入 Proto」，Proto 地址仍不入库。
- 已有接入服务不改通信方式时，转发仍走 gRPC。
- 「推 Apifox」仍把正在使用的运行包推到接入服务上配置的另一个项目。
- 平台内建 SSO 仍不能改通信方式。
- 改造、整合、打成运行包的步骤不另做一套。
