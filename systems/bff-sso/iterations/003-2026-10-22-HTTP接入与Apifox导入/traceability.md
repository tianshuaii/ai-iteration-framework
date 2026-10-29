# 跟踪表

| 需求要点 | 验收 | 用例 | 主要文件 |
|---|---|---|---|
| 新建接口项目默认 HTTP，只保存来源 ID | AC-01 | TC-01 | `src/features/interface-version/InterfaceProjectPage.tsx`、`src/interface-version/services/project.service.ts` |
| gRPC 项目仍导入 Proto，不要求来源 ID | AC-02 | TC-02 | `src/features/openapi/OpenapiUpstreamPage.tsx`、`src/interface-version/services/import-proto.service.ts` |
| 导入接口拉全量并先给出差异 | AC-03 | TC-03 | `src/interface-version/services/import-apifox.service.ts`、`src/features/interface-version/InterfaceBranchPage.tsx` |
| 拉取失败或只改项目资料时不写新接口 | AC-04 | TC-04 | `src/apifox/apifox.client.ts`、`src/interface-version/services/import-apifox.service.ts` |
| 老项目保持 gRPC，类型不能改 | AC-05 | TC-05 | `prisma/schema.prisma`、`src/interface-version/dto/interface-version.dto.ts` |
| 新建接入服务默认 HTTP，不出现来源 ID | AC-06 | TC-06 | `src/features/resources/ResourcePage.tsx`、`src/admin/admin.service.ts` |
| HTTP 转发和连通测试不用 gRPC 端口 | AC-07 | TC-07 | `src/proxy/proxy.service.ts`、`src/nacos/nacos-host.util.ts`、`src/admin/sub-service-connectivity.service.ts` |
| gRPC 转发不变，内建 SSO 不能改通信方式 | AC-08 | TC-08 | `src/proxy/proxy.service.ts`、`src/features/resources/ResourcePage.tsx` |
| 推送运行包仍用接入服务上的项目 ID | AC-09 | TC-09 | `src/runtime-interface/services/runtime-apifox-target.service.ts` |
