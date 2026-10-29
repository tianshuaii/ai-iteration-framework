# 测试记录

自动测试与 Live 验收均已完成；运行态命令、现象、回收和授权原话见 `evidence/tests/runtime-acceptance.md`。

## 自动检查与复用记录

相同代码、依赖、配置和生成物输入下，已通过的检查可以复用；引用原记录并写清输入基线和未失效原因。任一输入变化时只让受影响记录失效，不机械重跑其他仓库或模块。

| 记录 | 任务/阶段 | 仓库/范围 | 命令或证据 | 输入基线 | 结果 | 复用说明 |
|---|---|---|---|---|---|---|
| AUTO-01 | T-01 / verify | `adx-admin-backend` Schema、注释、生成物 | `pnpm prisma:comments:check && pnpm prisma:generate`，退出码 0；migration 定向静态核对列可空、字段注释和 `WHERE yn=1` partial unique | `master@303b62bf52b08f2c770393d122bb9097dbf72b1a` + 第 011 轮 dirty + 本轮 T-01 工作区，2026-10-27 15:18+08:00 | 通过 | 未执行数据库迁移；只证明静态契约和 Prisma 生成。 |
| AUTO-02 | T-02 / unified review | `adx-bff-backend` 平台 DTO/Admin/Auth/Session/Proxy/配置 | `pnpm test -- --runInBand admin/dto/access-platform.dto.spec.ts admin/access-platform.service.spec.ts auth/auth.service.spec.ts session/session.service.spec.ts proxy/access-platform-secret.service.spec.ts proxy/platform-request-context.service.spec.ts proxy/platform-login-response.service.spec.ts proxy/http-passthrough.service.spec.ts common/responses/api-codes.spec.ts config/app.config.spec.ts`，10 套件 53 项通过，退出码 0 | `main@da98f0c40bab372e247c39a6541e02a6eec281a9` + 第 011 轮 dirty + 本轮 T-01/T-02 工作区，2026-10-27 15:20+08:00 | 通过 | 修复平台跨子服务越权与密钥竞态后重跑；覆盖受影响测试。 |
| AUTO-03 | T-02 / unified review | `adx-bff-backend` 编译 | `pnpm build`，退出码 0；`git diff --check`，退出码 0 | 与 AUTO-02 相同，代码、依赖与 Prisma Client 输入未再变化 | 通过 | Nest 构建覆盖产品源码；仓库历史 scripts 的独立 `tsc --noEmit` 错误不作为本轮门禁。 |
| AUTO-04 | T-03 / verify | `adx-admin-frontend` 接入平台与一层相邻模块 | `pnpm lint:ci && pnpm typecheck && pnpm test -- --run src/features/access-platforms`，退出码 0；Vitest 实际执行 5 文件 21 项通过；`git diff --check` 退出码 0 | `main@441332b9d75652a02469c802e7dd656223c5ee54` + 第 011 轮 dirty + 本轮 T-03 工作区，2026-10-27 15:20+08:00 | 通过 | 覆盖密钥归一化、新建/编辑模型及现有功能测试；未启动浏览器。 |
| LIVE-05 | verify / 配置补验 | Nacos `mergex-bff-ai.yml` 与 BFF 日常启动 | Nacos 3.x Admin API 发布并读后校验；无额外环境变量执行 `npm run start`；`GET /health`、`GET /readiness` | 产品代码、依赖和数据库未变；Nacos 由 57 项增至 59 项，2026-10-27 15:49+08:00 | 通过 | 主密钥格式有效且未输出；响应上限 1 MiB；两个健康端点均 `UP`，测试进程已关闭。 |

## 返工历史

- 无。失败时追加日期、命令或 TC、现象、受影响的 AC/TC、返工任务；当前结果仍在下表维护。

| 用例 | 日期 | 结果 | 现象 |
|---|---|---|---|
| TC-01 | 2026-10-27 | 通过 | 组件测试覆盖必填、`onChange/onBlur` 和提交；真实 API 不传/传空均 `40001`，非空字符串保存成功。 |
| TC-02 | 2026-10-27 | 通过 | 真实列表/更新仅返回已配置布尔值；留空保持、新值轮换立即生效，Session 和验收输出无密钥。 |
| TC-03 | 2026-10-27 | 通过 | 测试库 partial unique 对同一登录稳定键重复写入返回 `P2002`，服务层定向测试也通过。 |
| TC-04 | 2026-10-27 | 通过 | 模拟上游返回 HTTP 422 + `code=401`，BFF 保留状态、自定义头和完整 JSON 正文；无 Session 产生。 |
| TC-05 | 2026-10-27 | 通过 | 普通业务 JSON 和两段文本流 `chunk-1|chunk-2` 原样直通，未进入登录缓冲分支。 |
| TC-06 | 2026-10-27 | 通过 | Live 覆盖 string、number 和缺失 userId；单测补足空值、对象、非 JSON 和响应上限。 |
| TC-07 | 2026-10-27 | 通过 | 无绑定、临时账号禁用和当前平台条件均通过；禁用账号登录返回 `40401`。 |
| TC-08 | 2026-10-27 | 通过 | 成功响应只包含 BFF Token 信封；Redis Session 是 Portal audience，且平台/平台账号上下文匹配。 |
| TC-09 | 2026-10-27 | 通过 | Live 上游确认客户端伪造头被覆盖，收到当前密钥和 Session 平台账号 ID；轮换后下次请求即使用新值。 |
| TC-10 | 2026-10-27 | 通过 | 无 Session 调用白名单与动态登录例外成功；上游确认两项可信头均不存在。 |
| TC-11 | 2026-10-27 | 通过 | 密钥轮换、平台/绑定/临时 BFF 账号失效和 Session 删除均实测；失效请求未到达上游。 |
| TC-12 | 2026-10-27 | 通过 | Auth/Session/登录/续期/退出自动回归、三端健康检查、白名单、JSON 正文和普通流式直通共同通过；非平台 Token 被明确拒绝。 |

## 受控浅功能回归

按 `test-strategy.md` 的 `SR-xx` 逐条记录。每条保留日期、结果和可复核现象；范围不得临时扩展到未登记的全系统回归。

| 用例 | 日期 | 结果 | 现象 |
|---|---|---|---|
| SR-01 | 2026-10-27 | 通过 | 一个 HTTP 平台从上游登录、BFF 建 Session 到携带 Token 调用非白名单接口全链路通过，上游收到正确两项可信头。 |
| SR-02 | 2026-10-27 | 通过 | 三端健康检查、原 Auth/Session 定向回归、白名单和普通非登录分块直通通过；停止在一层相邻，未扩展到 gRPC 或全系统。 |

结果通常使用“未测”“通过”或“未通过”。只有用户明确确认时才可写“豁免”，并在现象列同时写明“用户确认”和“残余风险”；缺少任一项都不能进入 `done`。
