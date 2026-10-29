# 任务清单

范围以 [改动范围](./change-scope.md) 为准。未勾选前不要把迭代标成已验收。检查命令在 `adx-admin-backend` 目录执行。命令没过、或 code review 还有问题，不能勾选。

- [x] T-01 读入两个接入方式，缺省为 `nacos`。直连网关时用 `BFF_GRPC_URL` 和 `BFF_SESSION_PROTO_PATH` 调用 `RevokeByAccount`；缺一就失败，不查 Nacos。`nacos` 时仍查实例并下载接口文件。依赖：无。文件：`src/config/app.config.ts`、`src/clients/bff.client.ts`、`src/clients/platform-proto.resolver.ts`、`src/clients/bff.client.spec.ts`。检查：`pnpm test -- src/clients/bff.client.spec.ts`
- [x] T-02 直连登录服务时用 `SSO_GRPC_URL` 和 `SSO_PROTO_PATH` 调用 `SetPassword`；缺一就失败，不查 Nacos。`nacos` 时保持现在的发现。依赖：T-01。文件：`src/clients/sso.client.ts`、`src/clients/sso.client.spec.ts`。检查：`pnpm test -- src/clients/sso.client.spec.ts`
- [x] T-03 网关接入方式是 `direct` 时启动不订阅网关；是 `nacos` 时仍订阅。依赖：T-01。文件：`src/nacos/nacos-subscription.registry.ts`、`src/nacos/nacos-subscription.registry.spec.ts`。检查：`pnpm test -- src/nacos/nacos-subscription.registry.spec.ts`
- [x] T-04 在两份 Nacos 示例配置里写上两个接入方式，值为 `nacos`，不写真实地址。依赖：T-01。文件：`nacos-config.dev.yml`、`nacos-config.test.yml`。检查：`rg -n "BFF_ACCESS_TYPE: nacos" nacos-config.dev.yml nacos-config.test.yml`

T-02 和 T-03 都要等 T-01 的字段名定下来。T-03 和 T-04 可以同时做。

- [x] T-05 网关启动后同步登录服务和账号后端。没有记录才新建直连并写入 Nacos 地址。已有记录不新建。`SYNC_DIRECT_ADDRESS` 不写或为 `false` 时不改已有地址；为 `true` 时更新地址并写成直连。地址为空则跳过，不用代码里的默认地址。依赖：无。文件：`adx-bff-backend/src/platform/platform-sso-sub-service.bootstrap.ts`、`adx-bff-backend/src/config/app.config.ts` 及对应测试。检查：`pnpm test -- src/platform/platform-sso-sub-service.bootstrap.spec.ts`
- [x] T-06 同步用的配置改叫地址，不再使用带 grpc 的名字。账号后端可以写多条服务编码，开关为 true 时这几条已有记录都更新地址。列表把完整地址显示出来。依赖：T-05。文件：`adx-bff-backend/src/config/app.config.ts`、`adx-bff-backend/src/platform/platform-sso-sub-service.bootstrap.ts`、`adx-bff-frontend/src/features/resources/ResourcePage.tsx` 及对应测试。检查：`pnpm test -- src/platform/platform-sso-sub-service.bootstrap.spec.ts`
- [x] T-07 两条账号后端也标成平台内建，不能删除。编辑时如果账号后端没有运行包，改用本地或账号后端 HTTP 上的 proto 组装登录上下文。依赖：T-06。文件：`adx-bff-backend/src/admin/admin.service.ts`、`adx-bff-backend/src/platform/platform-service.constants.ts`、`adx-bff-backend/src/clients/admin-forward-context.client.ts`、`adx-bff-frontend/src/lib/platform-service-row.ts`。检查：`pnpm test -- src/admin/admin.service.spec.ts src/platform/platform-service.constants.spec.ts`
- [x] T-08 内建服务的修改接口直接拒绝，不改页面。依赖：T-07。文件：`adx-bff-backend/src/admin/admin.service.ts`、`adx-bff-backend/src/admin/admin.service.spec.ts`。检查：`pnpm test -- src/admin/admin.service.spec.ts`

整套自动回归、手工用例和验收结果属于 `verify`，不再拆成实现任务。
