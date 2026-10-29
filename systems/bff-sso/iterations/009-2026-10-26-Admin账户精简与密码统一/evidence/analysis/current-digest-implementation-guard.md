# 当前计划摘要实施守卫

- 时间：2026-10-26T17:42:36+08:00
- 阶段：`implement`
- 任务窗口：`无`（T-01 至 T-11 完成后的补偿性当前摘要审计）
- 计划摘要：`7272252e3ecdb92f415bc8391fed104e1dc8bb82b49333666a742fc7c849a14a`
- 结论：通过；P0=0、P1=0、P2-open=0。

## 基线与隔离

| 仓库 | 分支与 HEAD | 隔离方式 | 当前受控差异 SHA-256 |
|---|---|---|---|
| `adx-admin-backend` | `master@f519c0f39f6df73f8e1943036f5e8475c703f8b0` | 共享检出 | `62237a9332316623b833107c87566608b1262b8da1a541da0c8b501bb3d583e7` |
| `adx-admin-frontend` | `main@345226fbcc8a8477b77cce103444c8576e3ff85c` | 共享检出 | `d31e332a177fe9637a972d3d5b5b3ca30b91b3b3bc8ffa703bc35d869771c322` |
| `adx-sso-backend` | `master@6437527b4eab8f86b0b697b88d81bbdbf310d1c0` | 共享检出 | `e2c83efbbaae06783a08ea544c182cb299b2e1c08100c53163ce43832d27ff10` |
| `adx-bff-backend` | `main@c57b594194cdfd40f3d24e6d7836ebc0b0e453da` | 共享检出 | `220a0d505b69a42e5548e6c646a6ca919dcc9caed1baedcc64aa98babc569a0c` |
| `adx-bff-frontend` | `main@a91961d050eaf28199481f37ab6d283ff0145ea8` | 共享检出 | `d0f0d8ec5757aaab6fee639386947cb456bf19c786575bb0419cf951e8385086` |

- 受控未跟踪文件逐文件计算 SHA-256 后的排序聚合值为 `34228865b173a013a46a223cdc4e2ddd63359bf678d49d6c458173cf359516d6`。
- BFF 后端哈希明确排除接管前 dirty：`src/proxy/http-passthrough.service.ts`、`src/proxy/http-passthrough.service.spec.ts`、`CODE_REVIEW.md`。
- 五仓 HEAD、分支和检出路径与 `workspace.md` 一致；没有执行拉取、提交、推送、服务启动或数据库迁移。

## T-01 至 T-11 范围复核

| 任务 | 当前摘要复核结果 |
|---|---|
| T-01 | SSO 48 字符密码编解码、登录/改密/代设密和一次性超管恢复入口仍在批准文件边界内。 |
| T-02 | Admin seed 使用同格式与环境变量，不存在默认密码或生产固定盐。 |
| T-03 | Admin 治理合约与服务只保留账户 CRUD、独立设密、最后启用超管保护及按账号吊销 Session。 |
| T-04 | 非账户治理、动态 Portal 授权、旧清理脚本和失效说明的删除与批准清单一致。 |
| T-05 | BFF 账户入口、门禁、Portal 空授权、Session 身份版本与可信上下文均不依赖角色；HTTP 直通 dirty 未接管。 |
| T-06 | 唯一治理迁移只位于 Admin 后端，含重复用户名预检、账户类型折叠、废弃表清理、全历史用户名唯一和旧密码失效。 |
| T-07 | SSO Prisma、gRPC 与身份输出同步到账户两类型，不建立治理迁移。 |
| T-08 | BFF Prisma 保留运行与接口编辑模型，删除旧关系工具和治理 seed，不建立治理迁移。 |
| T-09 | Admin 前端只保留账户页及登录/无权限壳层；账户页覆盖筛选、新增、编辑、设密、启停和软删除。 |
| T-10 | BFF 前端仅以 `accountType === SUPER_ADMIN` 允许管理端访问，没有角色兼容回退。 |
| T-11 | 治理库存只断言账户 CRUD，两份 Portal 文档测试只读取 Admin 后端唯一 Proto 根目录。 |

## 静态与定向证据

- 五仓 `git diff --check HEAD` 均通过。
- Admin 前端生产源码未检出治理审计、角色、租户或关系页面路由残留。
- 管理端门禁相关生产源码未检出 `roleCode`、`roles`、`TENANT_ADMIN` 或 `TENANT_STAFF` 回退。
- 三套 SSO 定向测试 18 项、Admin 后端六套件 34 项、Admin 前端两文件 5 项、BFF 后端八套件 24 项、BFF 前端两文件 4 项全部通过。
- BFF 前端误触发的全量 Vitest 仍有仓库外 traffic-package fixture 缺失的 3 个既有失败；精确定向命令通过，未将范围外失败记为豁免。

## 判定

当前工作区与当前计划摘要的任务、仓库、文件和运行资源边界一致。T-01 至 T-11 的补偿性实施守卫全部通过，可执行迭代级统一代码审核并进入验证阶段。
