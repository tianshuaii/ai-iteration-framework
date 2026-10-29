# SR-02 自动化相邻浅回归

- 时间：2026-10-26T17:43:40+08:00 ～ 2026-10-26T17:43:42+08:00
- 环境：本机源码与测试替身；未启动服务、未连接业务数据库、未执行迁移。
- 产品基线：`adx-bff-backend main@c57b594194cdfd40f3d24e6d7836ebc0b0e453da`、`adx-bff-frontend main@a91961d050eaf28199481f37ab6d283ff0145ea8` 加当前工作区。

## 后端相邻主路径

命令：

```text
pnpm exec jest --runInBand \
  src/proxy/proxy.service.spec.ts \
  src/runtime-interface/utils/operation-supports-batch.util.spec.ts \
  src/proxy/http-passthrough.service.spec.ts \
  src/runtime-interface/services/runtime-interface-resolver.service.spec.ts \
  src/request-logs/request-log.controller.spec.ts \
  src/request-logs/request-log.service.spec.ts \
  src/console-logs/console-log.controller.spec.ts \
  src/console-logs/console-log.service.spec.ts
```

- 退出码：0。
- 结果：8 套件、64 项通过。
- 覆盖：普通代理、批量能力判定、HTTP 直通、接口运行时解析、请求查询和实时日志服务/控制器。
- 边界：`http-passthrough.service.ts` 与其测试存在接管前 dirty，本轮只运行既有测试，不修改、不纳入当前差异审核。

## 前端相邻主路径

命令：

```text
pnpm exec vitest run \
  src/lib/request-logs-api.test.ts \
  src/lib/console-logs-api.test.ts \
  src/features/request-logs/request-log-timeline.util.spec.ts \
  src/features/request-logs/protocol-context.test.ts \
  src/features/openapi/utils/composite-upstream-mapping-indicator.util.spec.ts \
  src/features/openapi/utils/composite-step-id.util.test.ts \
  src/features/openapi/utils/composite-bind-source.util.test.ts \
  src/features/openapi/utils/composite-folder.util.test.ts \
  src/features/openapi/utils/user-scenario.spec.ts
```

- 退出码：0。
- 结果：9 文件、44 项通过。
- 覆盖：请求查询/实时日志 API 与展示数据、接口编辑的上游映射、步骤、绑定、目录和场景主路径。

## 判定

SR-02 的安全自动化部分通过，共 17 套件/文件、108 项，没有发现账户单一化引起的相邻回归。按批准测试策略，运行态请求查询和实时日志可见结果仍需本机服务授权，因此 SR-02 总结果保持“未测”，不能提前写为通过或豁免。
