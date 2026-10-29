# 测试记录

验收时间：`2026-10-28T16:09:57+08:00` 至 `2026-10-28T16:10:27+08:00`。本轮按 T3/T4 风险执行三仓定向测试、构建、真实 Nacos dev/test 发布与强类型解析；未启动本地服务，未访问 prod。

## 自动检查与复用记录

| 记录 | 任务/阶段 | 仓库/范围 | 命令或证据 | 输入基线 | 结果 | 复用说明 |
|---|---|---|---|---|---|---|
| AUTO-01 | T-02/T-03/verify | `adx-bff-backend` | `pnpm test -- --runInBand src/config/app.config.spec.ts src/config/nacos-config.loader.spec.ts src/config/nacos-config.merge.spec.ts src/auth/login-rate-limit.service.spec.ts src/session/session.service.spec.ts src/runtime-interface/services/runtime-interface-cache-sync.service.spec.ts && pnpm build` | HEAD `04334264b59ec98a864a4ffb461081356394a6c4` + 工作区差异摘要 `dc61972...` | 通过，exit 0；6 suites / 29 tests；build 通过 | verify 阶段现场重跑，不复用旧输出 |
| AUTO-02 | T-02/verify | `adx-admin-backend` | `pnpm test -- --runInBand src/config/app.config.spec.ts src/config/nacos-config.loader.spec.ts src/config/nacos-config.merge.spec.ts && pnpm build` | HEAD `cb3f12621b6ca4b7658b9978db301ac0620166da` + 工作区差异摘要 `fe2844d7...` | 通过，exit 0；3 suites / 12 tests；build 通过 | verify 阶段现场重跑，不复用旧输出 |
| AUTO-03 | T-02/verify | `adx-sso-backend` | `pnpm test -- --runInBand src/config/app.config.spec.ts src/config/nacos-config.loader.spec.ts src/config/nacos-config.merge.spec.ts && pnpm build` | HEAD `a3134f52ea2e9d5f3970268440fdee3c998cc09f` + 工作区差异摘要 `a40db49c...` | 通过，exit 0；3 suites / 12 tests；build 通过 | verify 阶段现场重跑，不复用旧输出 |
| AUTO-04 | T-04/verify | 六个 dev/test Data ID | `evidence/tests/remote-config-validation.md` | 发布后摘要见交付证据 | 通过；六份均 `schema ok` | 复用同回合发布后现场解析结果；此后远端正文未再次写入 |
| AUTO-05 | verify | 框架轮次 | `ruby scripts/validate-framework.rb --iteration systems/bff-sso/iterations/016-2026-10-28-Nacos配置瘦身与代码配置外置` | 当前轮次文件 | 通过，exit 0 | 统一审核后现场执行 |

## 返工历史

- T-04 前两次发布尝试遇到 Nacos Client API 旧缓存；每次只触及 test SSO，均自动恢复发布前 SHA-256，未继续后续 Data ID。修复为 Admin 权威读回与 Client 缓存轮询后，第三次六份全部通过。
- 统一代码审核发现发布响应不确定时的回滚遗漏风险、以及回滚缓存误判风险；已在发布脚本修复并通过 `node --check`。该修复不改变已发布正文，三仓产品检查无需因脚本变化重复失效。

| 用例 | 日期 | 结果 | 现象 |
|---|---|---|---|
| TC-01 | 2026-10-28 | 通过 | 六份 dev/test 键集合、消费者、默认值、环境差异和去留结论已逐项记录；证据不保存远端敏感正文 |
| TC-02 | 2026-10-28 | 通过 | 六份精简模板通过 Schema；默认与显式覆盖由 53 项定向测试保护 |
| TC-03 | 2026-10-28 | 通过 | `.env.example` 仅保留 bootstrap；loader 测试证明远端 bootstrap 键不会反向覆盖本地连接参数 |
| TC-04 | 2026-10-28 | 通过 | 三仓服务身份派生测试通过，BFF 保留独立注册名，Admin/SSO 从 `SERVICE_NAME` 派生 |
| TC-05 | 2026-10-28 | 通过 | BFF 八个参数进入强类型配置；默认、覆盖和非法边界测试通过 |
| TC-06 | 2026-10-28 | 通过 | 数据库、内部令牌、JWT 与平台主密钥缺失继续由 Schema 拒绝，无固定生产默认 |
| TC-07 | 2026-10-28 | 通过 | 六个 Data ID 按 test→dev 发布并由 Admin/Client 双读回；两次真实异常均停止并精确回滚 |
| TC-08 | 2026-10-28 | 通过 | 仅保留脱敏 prod 迁移边界；操作记录没有 prod 读取、发布、删除或启动 |
| TC-09 | 2026-10-28 | 通过 | 三仓 53 项定向测试及 build 全部通过；目标新增配置无重复裸 `process.env` 消费 |

## 受控浅功能回归

| 用例 | 日期 | 结果 | 现象 |
|---|---|---|---|
| SR-01 | 2026-10-28 | 通过 | 六份真实远端配置完成加载与 Schema 解析；服务身份、group、cluster 与端口组装由三仓配置测试覆盖。停止于配置/注册参数，不扩展业务接口 |
| SR-02 | 2026-10-28 | 通过 | 登录失败退避、Session 授权刷新、运行时缓存默认与覆盖路径由 BFF 定向测试通过。停止于一层消费者，不执行全量认证或性能压测 |

## 残余风险

- test BFF 使用本轮随机生成的新主密钥。若 test 数据库已有用其他未知主密钥加密的平台密钥，旧密文无法被新密钥解密，需要在 test 重新保存平台配置。
- 未启动本地三端服务；真实进程监听与业务数据库路径不在本轮已授权资源范围。配置中心真实读取、合并和 Schema 解析已完成，未把此边界伪装成服务启动证据。
