# 测试记录

自动测试：T-01 至 T-13 定向检查、实现阶段统一复验、隔离库迁移演练及 T-13 影响路径运行态复验已通过；BFF 两仓范围外全量基线按用户确认的受控豁免保留。剩余运行态验收已执行，其中 TC-10 暴露错误码映射缺陷并进入 T-14 返工。

## 实现阶段定向检查

| 任务 | 仓库与基线 | 时间 | 命令 | 退出码 | 结果 |
|---|---|---|---|---:|---|
| T-01 | `adx-sso-backend` `master@6437527b4eab8f86b0b697b88d81bbdbf310d1c0` + T-01 工作区 | 2026-10-26T15:20:00+08:00 | `pnpm test -- --runInBand src/auth/password-codec.spec.ts src/auth/auth.service.spec.ts src/auth/super-admin-recovery.spec.ts` | 0 | 3 套件、19 用例通过。 |
| T-01 | 同上 | 2026-10-26T15:20:00+08:00 | `pnpm build` | 0 | Nest/TypeScript 构建通过。 |
| T-01 | 同上 | 2026-10-26T15:20:00+08:00 | `git diff --check` | 0 | 无空白错误或冲突标记。 |
| T-02 | `adx-admin-backend` `master@f519c0f39f6df73f8e1943036f5e8475c703f8b0` + T-02 工作区 | 2026-10-26T15:32:00+08:00 | `pnpm exec ts-node --compiler-options '{"module":"CommonJS"}' prisma/seed-password.self-check.ts` | 0 | Java 互认 golden vector、随机数字盐、错误密码、畸形值及环境变量边界自检通过；输出不含密码、盐或哈希。 |
| T-02 | 同上 | 2026-10-26T15:32:00+08:00 | `pnpm build` | 0 | Nest/TypeScript 构建通过。 |
| T-02 | 同上 | 2026-10-26T15:32:00+08:00 | `git diff --check` | 0 | 无空白错误或冲突标记。 |
| T-03 | `adx-admin-backend` `master@f519c0f39f6df73f8e1943036f5e8475c703f8b0` + T-02/T-03 工作区 | 2026-10-26T15:45:00+08:00 | `pnpm test -- --runInBand src/governance/governance-account.service.spec.ts src/clients/sso.client.spec.ts src/clients/bff.client.spec.ts` | 0 | 3 套件、21 用例通过；覆盖两类账户、历史用户名、设密补偿、自禁用/删除、最后启用超管、独立重设密码与 Session 吊销。 |
| T-03 | 同上 | 2026-10-26T15:45:00+08:00 | `pnpm build` | 0 | Nest/TypeScript 构建通过。 |
| T-03 | 同上 | 2026-10-26T15:45:00+08:00 | `node -e "require('@grpc/proto-loader').loadSync(...)"` | 0 | `admin.proto` 及其依赖动态加载通过，reserved 编号合法。 |
| T-03 | 同上 | 2026-10-26T15:45:00+08:00 | `git diff --check` | 0 | 无空白错误或冲突标记。 |
| T-11 | `adx-bff-backend` `main@c57b594194cdfd40f3d24e6d7836ebc0b0e453da` + 本轮工作区 | 2026-10-26T17:27:00+08:00 | `pnpm exec jest --runInBand src/runtime-interface/utils/governance-inventory.util.spec.ts src/openapi/portal-authz-proto-document.spec.ts src/openapi/portal-catalog-proto-document.spec.ts` | 0 | 3 套件、7 用例通过；账户 CRUD 库存与 Admin Proto 唯一来源断言通过。 |
| T-11 | 同上 | 2026-10-26T17:27:00+08:00 | `pnpm exec eslint <T-11 三份测试>` | 0 | 定向 lint 通过；已修复不安全 matcher 类型。 |
| T-11 | 同上 | 2026-10-26T17:27:00+08:00 | `pnpm build && git diff --check` | 0 | BFF 构建及工作区差异检查通过。 |
| T-12 | `adx-admin-backend` `master@f519c0f39f6df73f8e1943036f5e8475c703f8b0` + 本轮工作区 | 2026-10-26T18:00:00+08:00 | 迁移前备份恢复、单事务执行、结构/数据断言、恢复后二次迁移 | 0 | 5 个合成账户保留；批准治理表与关系字段删除；两类唯一索引、48 字符密码列和旧密码失效标记符合最终模型。 |
| T-12 | 同上 | 2026-10-26T18:00:00+08:00 | `prisma migrate diff --from-url <隔离库> --to-schema-datamodel prisma/schema.prisma --exit-code` | 0 | 输出 `No difference detected.`；已修复 code review 检出的 `user_uid` 唯一索引漂移。 |
| T-12 | 同上 | 2026-10-26T18:00:00+08:00 | `pnpm prisma:generate && pnpm check:db-comments && pnpm build`；3 个定向 Jest 套件 | 0 | Prisma 生成、389 行注释清单、构建通过；3 套件、21 用例通过。 |
| T-12 | `adx-admin-backend` `master@f519c0f39f6df73f8e1943036f5e8475c703f8b0` + 本轮工作区 | 2026-10-26T18:20:00+08:00 | Q23 确认后从备份执行迁移、恢复、二次迁移、结构/数据断言与 Prisma schema diff | 0 | 两次迁移均成功；5 个账户、类型转换、旧密码失效、唯一索引、删除边界与最终 schema 全部符合目标。 |
| T-12 | 同上 | 2026-10-26T18:20:00+08:00 | `pnpm prisma:generate && pnpm check:db-comments && pnpm build`；3 个定向 Jest 套件；`git diff --check` | 0 | Prisma 生成、389 行注释校验、构建通过；3 套件 21 用例通过；差异格式检查通过。 |
| 统一复核 | 五仓当前工作区 | 2026-10-26T18:28:00+08:00 | 当前摘要定向 Prisma、Jest/Vitest、seed 自检、lint/typecheck、build、数据库注释与五仓差异检查 | 0 | SSO 18 项、Admin 后端修复后 36 项、BFF 后端 28 项、Admin 前端 5 项、BFF 前端 4 项通过；五仓构建及适用静态检查通过。 |
| 统一复核 | `adx-admin-backend` | 2026-10-26T18:28:00+08:00 | `pnpm exec eslint src/grpc/governance-grpc.server.ts src/grpc/governance-grpc.server.spec.ts --max-warnings 0` | 2 | 仓库没有 `eslint.config.*`，ESLint 9 无法启动；用 Jest、Nest build、注释检查和 `git diff --check` 完成替代复验，不属于产品失败。 |
| T-14 | `adx-bff-backend` `main@c57b594194cdfd40f3d24e6d7836ebc0b0e453da` + 本轮工作区 | 2026-10-26T19:42:00+08:00 | `pnpm exec jest --runInBand src/auth/auth.service.spec.ts` | 0 | 1 套件、8 用例通过；覆盖 Admin 40302 映射、Portal 原错误传递、未知错误传递和两个成功路径。 |
| T-14 | 同上 | 2026-10-26T19:42:00+08:00 | `pnpm build`、`pnpm exec eslint src/auth/auth.service.ts src/auth/auth.service.spec.ts --max-warnings 0`、`git diff --check` | 0 | BFF 构建、目标 lint 和差异格式检查通过。code-review-skill 发现并修复 1 项 Portal 端别 P1，复验全部通过。 |

## Verify 自动化与静态验收

| 项目 | 时间 | 命令 | 退出码 | 结果 |
|---|---|---|---:|---|
| `adx-admin-backend` | 2026-10-26T17:20:00+08:00 | `pnpm exec jest --runInBand`、`pnpm build`、`pnpm check:db-comments` | 0 | 23 套件、96 用例、构建和数据库注释检查通过。 |
| `adx-sso-backend` | 2026-10-26T17:20:00+08:00 | `pnpm exec jest --runInBand`、`pnpm build` | 0 | 15 套件、60 用例和构建通过。 |
| `adx-admin-frontend` | 2026-10-26T17:20:00+08:00 | `pnpm test -- --run`、`pnpm typecheck`、`pnpm lint:ci`、`pnpm build` | 0 | 3 文件、14 用例、类型检查、lint 和构建通过；仅有 Vite 既有大包提示。 |
| `adx-bff-backend` | 2026-10-26T17:26:00+08:00 | `pnpm exec jest --runInBand` | 1 | T-11 修复后 137 套件通过、2 跳过、6 失败；670 用例通过、10 跳过、11 失败。本轮相关失败为 0，剩余均为已登记范围外基线。 |
| `adx-bff-backend` | 2026-10-26T17:27:00+08:00 | 本轮 10 个关联套件定向 Jest | 0 | 10 套件、31 用例通过，覆盖登录、Session、Portal 空授权、账户门禁、可信上下文、治理库存和 Portal Proto 文档。 |
| `adx-bff-backend` | 2026-10-26T17:27:00+08:00 | `pnpm build` | 0 | BFF 后端构建通过。 |
| `adx-bff-frontend` | 2026-10-26T17:20:00+08:00 | `pnpm test -- --run` | 1 | 20 文件、142 用例通过，3 文件、3 用例因仓库外 traffic-package fixture 缺失失败。 |
| `adx-bff-frontend` | 2026-10-26T17:27:00+08:00 | `pnpm exec vitest run src/stores/auth.store.spec.ts src/components/auth/RequireRole.spec.tsx` | 0 | 2 文件、4 个账户类型门禁用例通过。 |
| `adx-bff-frontend` | 2026-10-26T17:26:00+08:00 | `pnpm typecheck`、`pnpm lint:ci`、`pnpm build` | 2 / 1 / 2 | 被本轮明确不动的接口编辑模块既有类型错误和 1 条 Fast Refresh warning 阻断；账户门禁定向 lint 已在实现阶段通过。 |
| 五仓 | 2026-10-26T17:28:00+08:00 | `git diff --check` | 0 | 五个产品仓库均无空白错误或冲突标记。 |
| 静态边界 | 2026-10-26T17:28:00+08:00 | Admin 路由/feature 清单、Admin/BFF RPC 目录、Prisma 与迁移 SQL 定向 `rg` | 0 | Admin 前端只保留账户和登录/禁止页；治理 RPC 只保留账户；迁移包含重复用户名预检、账户类型折叠、批准表清理、永久用户名唯一和旧密码失效标记。 |
| 当前摘要定向复验 | 2026-10-26T17:42:36+08:00 | 五仓 T-01 至 T-11 定向 Jest/Vitest、seed 密码自检与 `git diff --check HEAD` | 0 | SSO 18 项、Admin 后端 34 项、Admin 前端 5 项、BFF 后端 24 项、BFF 前端 4 项全部通过；五仓差异检查通过。 |
| BFF 前端范围外基线 | 2026-10-26T17:41:46+08:00 | `pnpm test -- --run <目标文件>`（命令未按预期过滤） | 1 | 误触发全量 Vitest；142 项通过，3 项因仓库外 traffic-package fixture 缺失失败。随后用 `pnpm exec vitest run <目标文件>` 精确定向复验通过，既有全量失败仍保留且未豁免。 |
| T-13 运行态复验 | 2026-10-26T19:08:28+08:00 | 本机隔离五服务、隔离 PostgreSQL、Redis DB14；Portal/Admin 登录、本人改密、Session 吊销、ForwardContext 刷新与 `/proxy/one` | 0 | 两个渠道本人改密均为 `200`；同账号全部旧 Session 为 `40102`；旧密码 `40103`、新密码登录 `200`；48 位交织格式、Session 强制刷新、Portal 代理主路径和测试夹具软删除通过。证据见 `evidence/tests/T-13-runtime-retest.md`。 |
| T-14 运行态门禁复验 | 2026-10-26T19:44:56+08:00 | 本机隔 SSO/Admin/BFF 三后端、隔离 PostgreSQL、Redis DB14；超管 Admin、员工 Admin、员工 Portal 登录 | 0 | 超管 Admin=`200`；员工 Admin=`40302` 且无 Session；员工 Portal=`200`。夹具已软删除，Redis DB14 已清空，本轮启动的六个端口已停止。证据见 `evidence/tests/T-14-runtime-gate-retest.md`。 |

## 返工历史

- 2026-10-26：剩余运行态验收中，`PLATFORM_STAFF` 使用正确口令登录 Admin 时，Admin gRPC 正确返回 `PERMISSION_DENIED: 管理端仅允许超级管理员登录`，但 BFF 最终返回 `50001`，没有按已定义合约映射为 `AUTH_ADMIN_ROLE_DENIED=40302`。权限边界未被绕过，但 TC-10/AC-06 未通过；失败证据见 `evidence/tests/remaining-runtime-acceptance.md`，追加 T-14 并将当前结果重置为未测。
- 2026-10-26：T-13 已在 BFF 认证编排层完成：Portal/Admin 增加受各自 Session Guard 保护的本人改密入口，请求体严格拒绝目标账号字段，并按“吊销全部 Session → SSO 改密”顺序执行。定向 Jest 3 套件/12 项、BFF 构建、目标 ESLint 和 `git diff --check` 通过；运行态 TC-08、TC-11、TC-13 与 SR-01 留待 verify 重验。
- 2026-10-26：T-13 修复后在隔离五服务重跑影响路径，Portal/Admin 本人改密、多 Session 吊销、旧/新密码、ForwardContext 强制刷新和 Portal 单发代理均通过。启动期间的 proto cwd 与默认直连端口问题均被确认是隔离测试编排偏差，修正后未再复现；完整证据见 `evidence/tests/T-13-runtime-retest.md`。
- 2026-10-26：隔离五服务正式补测发现本人改密经 SSO 成功后，改密前的 Portal Session 调用 `/api/portal/account/me` 仍返回业务码 `200`；管理员重设密码、禁用和删除的按账号吊销路径正常。保留失败证据并追加 T-13，TC-08、TC-11、TC-13 与 SR-01 需在修复后重跑。
- 2026-10-26：用户明确授权本机五服务、隔离测试库迁移/回滚/联调，并对 BFF 两仓范围外全量基线作受控豁免；残余风险保留为仓库外 fixture 缺失和接口编辑域既有类型/lint/build 错误。
- 2026-10-26：TC-12 在专用数据库中验证重复用户名预检通过；正式迁移因先删 `sys_tenant`、后删引用它的账户外键而失败，事务回滚。该缺陷位于本轮迁移文件，追加 T-12，不修改历史迁移。
- 2026-10-26：五仓全量自动化中，Admin 后端 23 套件/96 用例、SSO 15 套件/60 用例、Admin 前端 3 文件/14 用例及其类型检查、lint、构建均通过。
- 2026-10-26：BFF 后端全量 Jest 为 134 套件通过、2 套件跳过、9 套件失败；其中 `governance-inventory.util.spec.ts` 仍断言已删除的路由 CRUD，`portal-authz-proto-document.spec.ts` 与 `portal-catalog-proto-document.spec.ts` 仍指向已删除的 BFF 本地 Proto 根目录，属于本轮回归，影响 TC-05、TC-06、TC-13，追加 T-11。
- 2026-10-26：BFF 后端其余全量失败来自接管前环境或本轮范围外基线：Redis loopback 防护、PublisherService 测试替身、外部 DSP fixture、外部 `mergex-proto-server` 及 interface-version DTO；不把这些失败记为本轮通过或豁免。
- 2026-10-26：BFF 前端全量 Vitest 为 20 文件/142 用例通过、3 文件/3 用例失败，失败原因是仓库外 `mergex-page-delivery` traffic-package fixture 缺失；后续仍单独执行类型检查、lint 与构建并记录结果。
- 2026-10-26：计划中的 Jest 命令 `pnpm test -- --runInBand ...` 在当前 package script 下把 `--runInBand` 误传为测试路径，首次返回“未找到测试”；已改用 `pnpm exec jest --runInBand ...`，该命令调用错误不作为产品失败。
- 2026-10-26：Vitest 的 `pnpm test -- --run <files>` 同样未按预期过滤 BFF 前端文件，因而暴露范围外 fixture 基线；已改用 `pnpm exec vitest run <files>`，本轮门禁 2 文件、4 用例通过，原全量失败仍保留记录。

| 用例 | 日期 | 结果 | 现象 |
|---|---|---|---|
| TC-01 | 2026-10-26 | 通过 | Chrome 无头真实登录后，Admin 侧栏只有账号入口，未出现租户、角色、权限、路由或审计入口。 |
| TC-02 | 2026-10-26 | 通过 | 逐个访问 12 条旧 Admin URL，均由通配路由收敛到 `/accounts`，没有重新加载旧页面。 |
| TC-03 | 2026-10-26 | 通过 | 隔离库完成账户新增、列表、三类筛选、编辑、启停、独立重设密码和软删除；表单必填星号、无冒号和失焦校验通过。 |
| TC-04 | 2026-10-26 | 通过 | 重复历史用户名 `40901`、非法输入 `40001`、自禁用/删除 `40301`；最后启用超管保护继续由定向自动化覆盖。 |
| TC-05 | 2026-10-26 | 通过 | 运行服务调用 11 个旧非账户治理 API 均返回 `40401`。 |
| TC-06 | 2026-10-26 | 通过 | 旧治理审计 API 返回 `40401`；Admin 无审计入口，保留的通用 `AuditLog` 模型未被误删。 |
| TC-07 | 2026-10-26 | 通过 | 隔离库新建账户后确认密码为 48 位小写十六进制交织格式、16 个盐位均为数字；正确密码登录 `200`，错误/旧密码 `40103`，证据未记录密码、盐或哈希。 |
| TC-08 | 2026-10-26 | 通过 | 保留旧失败证据 `evidence/tests/TC-08-self-change-session-failure.md`；T-13 修复后 Portal/Admin 本人改密均为 `200`，两个 Portal Session 及同账号跨 Admin/Portal Session 均立即变为 `40102`，旧密码 `40103`、新密码登录 `200`。 |
| TC-09 | 2026-10-26 | 通过 | 一次性超管恢复 CLI 真实执行退出码 0；旧格式标记登录 `40103`，经账户页重设后恢复登录且存库长度为 48；真实长 Argon2 值由 SSO 定向单测覆盖。 |
| TC-10 | 2026-10-26 | 通过 | T-14 后在隔离三后端重验：超管 Admin 登录 `200`；员工正确口令登录 Admin 返回 `40302` 且不创建 Session；同一员工 Portal 登录 `200`。其余两管理端、空授权、普通代理和跨端拒绝沿用输入未变的既有通过证据。 |
| TC-11 | 2026-10-26 | 通过 | 隔离五服务中 Portal `me`、空授权、强制到期后的 ForwardContext 刷新持久化，以及 `/proxy/one` 调用 `PortalAuthzService/GetMe` 均为 `200`，未出现角色依赖异常。 |
| TC-12 | 2026-10-26 | 通过 | 用户已授权隔离库演练。重复用户名预检按预期阻断；T-12 修复后从迁移前备份重建并成功执行迁移，随后完成备份恢复和恢复后二次迁移；结构、数据及 Prisma schema 均一致。初次失败证据保留在 `evidence/tests/TC-12-migration-rehearsal-failure.md`，最终审核见 `evidence/reviews/T-12.md`。 |
| TC-13 | 2026-10-26 | 通过 | T-13 定向 Jest 3 套件/12 项、BFF 构建、目标 ESLint、五仓统一检查与 `code-review-skill` 复核通过，P0/P1/P2-open 均为 0；受影响 TC-07、TC-08、TC-11 与 SR-01 运行态路径重验通过。BFF 两仓范围外全量基线继续按用户确认的受控豁免保留。 |

| 浅回归 | 日期 | 结果 | 现象 |
|---|---|---|---|
| SR-01 | 2026-10-26 | 通过 | 原直接功能主路径全部通过；T-14 返工后又完成登录 8 项定向自动化及隔离运行态门禁复验，员工 Admin=`40302`、超管 Admin=`200`、员工 Portal=`200`，没有改变 Portal 成功路径或扩大回归边界。证据见 `evidence/tests/T-14-runtime-gate-retest.md`。 |
| SR-02 | 2026-10-26 | 通过 | 本机隔离栈的单发、批量、请求日志状态与请求查询均为 `200`，查询可见单发记录；接口编辑、HTTP 直通和 SSE 由已登记定向自动化覆盖，未扩大到其他模块。证据见 `evidence/tests/SR-02-automated-adjacent-regression.md` 与 `evidence/tests/remaining-runtime-acceptance.md`。 |

结果通常使用“未测”“通过”或“未通过”。只有用户明确确认时才可写“豁免”，并在现象列同时写明“用户确认”和“残余风险”；缺少任一项都不能进入 `done`。
