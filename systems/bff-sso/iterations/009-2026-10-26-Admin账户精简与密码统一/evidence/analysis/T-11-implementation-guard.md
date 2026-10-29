# T-11 Implementation Guard

- 时间：2026-10-26T17:24:01+08:00
- 任务：修复账户单一化后的 BFF 治理库存与 Portal Proto 文档测试。
- 仓库：`/Users/mrzater/docker/adx/adx-bff-backend`
- 分支与 HEAD：`main@c57b594194cdfd40f3d24e6d7836ebc0b0e453da`
- 隔离方式：共享检出；与 `workspace.md` 已审批方案一致。
- 输入摘要：沿用已审批计划摘要 `02750c68ffa5b714b8345abac13e793cba491a45c3925f3ed73952f6fa3eaa5b`；T-11 是 verify 对 T-05 对应测试发现的定向返工，不改变产品需求、数据模型或运行资源。

## 文件边界

- 接管 `src/runtime-interface/utils/governance-inventory.util.spec.ts`。
- 接管 `src/openapi/portal-authz-proto-document.spec.ts`。
- 接管 `src/openapi/portal-catalog-proto-document.spec.ts`。
- 不修改任何生产源码、数据库、服务配置或仓库外 fixture。
- 明确排除接管前 dirty：`src/proxy/http-passthrough.service.ts`、`src/proxy/http-passthrough.service.spec.ts`、`CODE_REVIEW.md`。

## 判定

- P0：0。
- P1：0。
- P2-open：0。
- 结论：门禁通过，可以进入 T-11 实现。
