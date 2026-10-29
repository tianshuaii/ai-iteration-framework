# 整轮实现审核

- reviewer: `code-review-skill`
- provider_version: `local-skill-2026-10-28`
- task: `无`
- input_digest: `b44f2e132a010df404d9dc0d5b79b069e177255e077ade040d90573d4d865764`
- product_diff_digest:
  - BFF: `dc61972c61b276df0227b7f0ca2f0bb6c7d969a493937588d564451e2e02b819`
  - Admin: `fe2844d7c5db9d6bcd0b291454997a4bf236c6f1dc27513bb694d9cdd5d7d7e3`
  - SSO: `a40db49c63b7bd1175378cf8e1e5f5a7b02b89a7950be1ea31364d3b034bbd1c`
  - Nacos 发布脚本: `304c1c6d6c67c28085190df6b86cae945ca041637fb947f7ab880520ac157e03`
- started_at: `2026-10-28T16:05:50+08:00`
- completed_at: `2026-10-28T16:08:08+08:00`
- result: `passed`
- findings: `P0=0, P1=0, P2-open=0`

## 审核范围

- 三仓 bootstrap/runtime 配置边界、服务身份派生和六份版本化模板。
- BFF 登录限流、Session/运行时接口参数、Admin proto origin 强类型收口。
- 新增配置辅助模块、配置契约测试、登录限流行为测试和 T-04 Nacos 发布脚本。
- Nacos 发布顺序、漂移保护、敏感值处理、权威读回、客户端缓存收敛和失败回滚。
- 用户既有未跟踪文件 `adx-bff-backend/CODE_REVIEW.md` 未读取、未修改、未纳入差异摘要。

## 已发现并修复

1. **P1：版本化 Nacos 模板包含真实形态的数据库、JWT、Apifox、Redis 和内部令牌值。** 已替换为不可路由示例地址或明确占位值；远端发布采用键级补丁，未用脱敏模板覆盖真实值。
2. **P1：`ADMIN_BACKEND_HTTP_ORIGIN` 的通用 URL 校验会接受非 HTTP scheme。** 已增加 `http/https` 白名单校验，并以 `ftp://` 非法值测试保护。
3. **P1：发布响应丢失时，服务端可能已落库但目标尚未登记进回滚集合；回滚只读 Client API 也可能把旧缓存误判为成功。** 已改为请求前登记回滚项；回滚同时校验 Admin 权威存储和 Client 缓存。
4. **P2：BFF 主配置文件职责集中。** 已把通用解析、服务身份和 bootstrap Data ID 派生拆入两个有注释的辅助模块，主文件只保留 Schema 和结构化映射。
5. **P2：登录限流 mock 的无等待 async 函数触发 lint。** 已改为显式 `Promise.resolve`，受影响文件 ESLint 通过。

## 验证证据

- BFF：6 suites / 29 tests 通过；目标 TypeScript 文件 ESLint 通过；`pnpm build` 通过。
- Admin：3 suites / 12 tests 通过；`pnpm build` 通过。
- SSO：3 suites / 12 tests 通过；`pnpm build` 通过。
- 六份版本化模板和六份发布后的远端配置均通过对应强类型 Schema。
- dev/test 六个 Data ID 均完成 Admin 权威读回和 Client 运行时读回；发布前后摘要记录在 `evidence/delivery/nacos-publish-preflight.md`。
- `node --check` 通过发布脚本语法检查；三仓 `git diff --check` 通过。
- 目标轮次框架局部校验通过。

## 结论与残余边界

结论为 **Approve**，没有开放的 P0/P1/P2 代码发现。prod 配置未写入；本轮没有启动本地三端服务，因此真实进程启动、平台密钥解密既有 test 数据和主要业务浅回归仍属于 verify 阶段待验事项。随机生成的新 test 主密钥不会与历史未知密钥兼容；若 test 数据库已有用其他主密钥加密的平台密钥，需要重新保存这些平台配置。
