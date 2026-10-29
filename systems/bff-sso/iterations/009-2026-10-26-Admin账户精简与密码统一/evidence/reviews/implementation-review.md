# 迭代级统一代码审核

- 阶段：`implement`
- 任务：`无`（T-01 至 T-10 汇总审核）
- provider：`code-review-skill`
- input digest：`02750c68ffa5b714b8345abac13e793cba491a45c3925f3ed73952f6fa3eaa5b`
- 审核时间：2026-10-26T17:05:00+08:00 ～ 2026-10-26T17:22:00+08:00
- 结论：通过；P0=0、P1=0、P2-open=0。

## 审核范围

- `adx-sso-backend`：48 字符随机数字盐 MD5 编解码、登录/改密/代设密、超管恢复 CLI、最终账户模型与 gRPC 合约。
- `adx-admin-backend`：账户单一治理服务、Portal 空授权与账户目录、ForwardContext、唯一迁移、seed、Prisma 与废弃治理代码删除。
- `adx-bff-backend`：账户 REST/gRPC 转发、管理端门禁、Session 身份版本、可信上下文、Portal 空授权、最终 Prisma 与 OpenAPI 文档。
- `adx-admin-frontend`：账户单页、筛选和新增/编辑/重设密码/启停/软删除交互，以及旧页面、生成 SDK 和审计入口删除。
- `adx-bff-frontend`：只以 `accountType === SUPER_ADMIN` 判定网关管理端权限。
- 明确排除 BFF 接管前 dirty：`src/proxy/http-passthrough.service.ts`、`src/proxy/http-passthrough.service.spec.ts`、`CODE_REVIEW.md`。

## 已发现并修复

| 等级 | 发现 | 修复与复验 |
|---|---|---|
| P1 | BFF 账户更新与独立重设密码控制器一度互换 DTO，可能让资料更新接受密码或让设密请求被错误拒绝。 | 恢复 `UpdateAccountDto` 与 `ResetAccountPasswordDto` 的严格边界；BFF 30 项定向测试与构建通过。 |
| P1 | BFF 账户治理入口删除后，DTO、OpenAPI tag 和示例仍暴露角色、租户、路由、权限及非空动态授权。 | 删除废弃治理 DTO/tag，Portal 授权示例固定为空集合，素材示例去除租户文案；构建和核心生产代码 ESLint 通过。 |
| P1 | Admin 迁移若直接把 Argon2 列缩到 48 字符会失败，并且旧的活动账号部分唯一索引会与最终全历史唯一语义并存。 | 迁移先把旧哈希统一改为不可登录标记，删除活动部分唯一索引，建立全历史用户名唯一索引，并刷新账户类型、密码列注释。迁移 SQL 未执行。 |
| P1 | 管理员重设密码原顺序是“先设密、后吊销 Session”；吊销失败时旧 Session 可能继续可用。 | 改成先吊销旧 Session、再设密，并增加调用顺序断言；账户服务 11 项测试和构建通过。 |
| P2 | Admin 前端 Modal/Switch 使用未消费的 `mutateAsync` Promise，失败时可能形成未处理拒绝。 | Switch 改用 `mutate`，Modal 显式吸收已由表单/Mutation 展示的拒绝；全量前端 ESLint、5 项定向测试和构建通过。 |
| P2 | BFF 网关超管校验使用 `ResourceStatus` 比较账户状态，语义类型错误。 | 改用 `AccountStatus`；BFF 构建与核心生产代码 ESLint 通过。 |
| P2 | BFF 前端门禁纯函数与 React 组件同文件，触发 Fast Refresh 门禁告警。 | 拆到 `admin-gate.ts`；目标 ESLint 与 4 项定向测试通过。 |

## P2 明确处置

- `adx-bff-backend/src/admin/admin.service.ts`、`src/admin/dto/admin.dto.ts`、`src/common/openapi/response-docs.ts` 仍分别为 750、585、733 行，超过当前后端 500 行约束。三者均是接管前已经超限的综合文件，本轮已经通过删除治理逻辑显著缩小；继续拆分会进入接入服务、接口编辑和全局 OpenAPI 基础设施，超出本轮账户精简范围。处置为：本轮不扩大重构，记录为既有结构债；本轮新增前端文件均不超过 300 行，新增/主改 Admin 后端账户服务和 gRPC 文件均不超过 500 行。该项不作为开放审核问题。
- BFF 候选文件的宽范围 ESLint 会命中既有 DTO 边界 `String(unknown)`、旧测试 mock 的 `any` 和相邻运行模块格式债。审核已修复本轮引入的格式、未使用变量和门禁问题，并对本轮核心生产文件单独执行 `--max-warnings 0` 通过；剩余命中未扩大修改。该项不作为开放审核问题。
- 48 字符随机盐 MD5 是用户确认的兼容格式，安全性弱于 Argon2；数字盐改用 Node `crypto.randomInt` 且摘要用恒定时间比较，但不能消除 MD5 本身的离线破解风险。该风险属于已批准方案，不是未修复代码问题。

## 统一检查结果

| 仓库 | 命令摘要 | 结果 |
|---|---|---|
| SSO | Prisma generate；3 套件 18 项；Nest build | 通过 |
| Admin 后端 | Prisma generate；数据库注释检查；seed 密码自检；6 套件 34 项；Nest build；无物理删除检查 | 通过 |
| BFF 后端 | Prisma generate；数据库注释检查；9 套件 30 项；Nest build；核心生产代码 ESLint；无物理删除检查 | 通过 |
| Admin 前端 | ESLint 全量；2 文件 5 项；TypeScript/Vite build | 通过；仅 Vite 既有大 chunk 提示，不影响退出码 |
| BFF 前端 | 本轮文件 ESLint；2 文件 4 项 | 通过 |
| 五仓 | `git diff --check` | 全部通过 |

## 审核决定

批准进入 `verify`。正式验收仍需按 TC-01 至 TC-13 执行；数据库迁移、服务启动、本机联调、提交与推送不由本次代码授权自动获得。
# T-11 增量复核（2026-10-26T17:28:00+08:00）

- verify 首轮发现的三份本轮相关 BFF 测试已纳入 T-11，并按实际差异完成独立 code review。
- 增量复核确认治理库存只描述账户 CRUD，Portal 文档测试只读取 Admin 后端 Proto，且没有扩大到生产源码或接管前 dirty。
- 定向 Jest、ESLint、BFF build 与 diff check 均通过；修复后的最终结论仍为 P0=0、P1=0、P2-open=0。

# 当前计划摘要统一复核（2026-10-26T17:42:36+08:00）

- input digest：`7272252e3ecdb92f415bc8391fed104e1dc8bb82b49333666a742fc7c849a14a`。
- 审核对象：当前五仓 HEAD 上 T-01 至 T-11 的全部受控差异；受控未跟踪文件也逐文件纳入，BFF 三处接管前 dirty 继续排除。
- 审核重点：密码格式与敏感信息边界、迁移可执行性、账户生命周期与 Session 吊销顺序、超管授权、旧治理入口删除、前端账户交互和回归测试边界。
- 结果：未发现新的 P0、P1 或开放 P2；此前已修复问题没有回归。既有超长综合文件和兼容 MD5 风险沿用上文已批准处置，不扩展本轮范围。
- 复验：五仓差异检查通过；SSO 18 项、Admin 后端 34 项、Admin 前端 5 项、BFF 后端 24 项、BFF 前端 4 项定向自动测试通过。
- 基线声明：BFF 前端全量命令仍会因仓库外 traffic-package fixture 缺失失败；该范围外基线未获豁免，不影响当前差异审核结论，但继续阻塞 TC-13 的最终通过。
- 最终结论：P0=0、P1=0、P2-open=0；批准从 `implement` 进入 `verify`。

# T-12 后当前计划摘要统一复核（2026-10-26T18:02:00+08:00）

> 门禁纠错（2026-10-26T18:07:33+08:00）：本节对应的 C-038 建立在未确认 Q23 和无效计划审批之上，已改为 `superseded`；以下技术事实保留，但“批准进入 verify”不再有效。

- input digest：`3e39a216a3be0e8cc4437d04ccfedef0df4189f003464f8e8d10cbeffe0cb74c`。
- 审核对象：T-01 至 T-12 的全部受控差异；重点增量为账户单一化迁移，BFF 三处接管前 dirty 继续排除。
- 已修复发现：迁移的外键删除顺序 P1，以及 `user_uid` 唯一索引与最终 Prisma 模型不一致 P1；均已从迁移前备份重建后复验。
- 边界复核：没有修改历史迁移、最终模型、业务代码或批准删除白名单；迁移没有执行 `CASCADE`，意外依赖仍会终止事务。
- 复验：隔离库迁移/恢复/二次迁移通过，schema diff 为零；Admin Prisma 生成、注释检查、构建与 21 项定向测试通过。
- 既有受控豁免保持不变：BFF 前端外部 traffic-package fixture 缺失，以及接口编辑域既有类型/lint/build 基线不由本轮修复。
- 历史技术结论：P0=0、P1=0、P2-open=0；当前不得进入 `verify`，须等待 Q23 确认并重新走计划审批、实施守卫和统一复核。

# Q23 确认后的最终统一复核（2026-10-26T18:28:00+08:00）

- input digest：`3e39a216a3be0e8cc4437d04ccfedef0df4189f003464f8e8d10cbeffe0cb74c`。
- 审核对象：T-01 至 T-12 的五仓全部受控差异；继续排除 BFF 接管前三处 dirty。
- 审核方法：按 TypeScript、React、NestJS、SQL/Prisma、安全、权限和通用质量清单逐行复核，并重跑当前摘要定向自动检查。

## 本次发现与修复

| 等级 | 发现 | 修复与复验 |
|---|---|---|
| P1 | Admin 账户列表遗漏 Q13 明确要求的更新时间，只显示创建时间。 | 增加 `updatedAt` 列并调整横向滚动宽度；账户页保持 300 行，Admin 前端 5 项测试、lint、typecheck、build 和差异检查通过。 |
| P1 | `proto-loader` 启用 `oneofs: true` 后会为 proto3 optional 字段附加 `_status: "status"` 等 presence 标记；原归一化会把它转换为 `Status`，严格 DTO 因未知字段拒绝正常的账户新增、筛选和编辑。 | 只忽略与同层真实字段严格配对的 `_field: "field"` 标记，保留其他下划线字段的既有处理；新增顶层、嵌套和误删保护测试。Admin 后端 7 套件 36 项、构建、注释检查与差异检查通过。 |
| P2 | Admin 与 BFF 数据库注释清单把实际数字盐 MD5 交织格式误写为 `scrypt`。 | 两仓统一为“48 字符随机数字盐 MD5 交织编码；不保存明文”，两仓 389 行数据库注释检查通过。 |

## 当前摘要检查结果

- SSO：Prisma 生成、3 套件 18 项、Nest build 通过。
- Admin 后端：Prisma 生成、seed 密码自检、数据库注释检查、修复后 7 套件 36 项、Nest build 通过。
- BFF 后端：Prisma 生成、数据库注释检查、9 套件 28 项、Nest build 通过。
- Admin 前端：2 文件 5 项、全量 lint、typecheck、Vite build 通过；仅保留既有大 chunk 提示。
- BFF 前端：2 文件 4 项及本轮文件 ESLint 通过。
- 五仓：`git diff --check` 与冲突标记扫描通过。
- Admin 后端没有可用 ESLint 配置；尝试的 ESLint 9 命令因仓库缺少 `eslint.config.*` 返回 2，改用该仓既有 Jest、Nest build、数据库注释和差异检查完成复验，不把工具缺失记为产品失败。

## 审核决定

- P0：0。
- P1：0（2 项均已修复并复验）。
- P2-open：0（1 项已修复并复验）。
- 既有超长综合文件、兼容 MD5 安全风险和 BFF 范围外基线继续沿用已批准处置。
- 当前摘要统一审核通过，批准进入 `verify`。

# T-13 返工后最终统一复核（2026-10-26T18:49:24+08:00）

- input digest：`17da42b810c11cde5c69bbbcc5a38342a66182c152b417366d42bf06e8ecbb12`。
- provider：`code-review-skill`。
- 审核对象：T-01 至 T-13 的五仓全部受控差异；重点增量为 BFF Portal/Admin 本人改密入口、严格 DTO、Session 吊销与 SSO 编排。BFF 接管前的 `src/proxy/http-passthrough.service*` 和 `CODE_REVIEW.md` 继续排除。
- 审核方法：按 TypeScript、NestJS、认证授权、输入校验、异步错误、Session 一致性与通用质量清单逐项复核；确认全局 `ZodValidationPipe` 会执行严格 schema。

## 本次发现与修复

| 等级 | 发现 | 修复与复验 |
|---|---|---|
| P2 | 初始 Controller 测试只验证两个通道把当前 Session 账号传给服务，没有直接锁定 `POST change-password` 与通道专用 Guard 元数据，后续重构可能在单测仍绿时遗漏鉴权装饰器。 | 增加 Portal/Admin 路径、HTTP 方法与 `PortalSessionGuard`/`AdminSessionGuard` 元数据断言；修复测试中 `unbound-method` lint 写法后，3 套件/12 项、构建、目标 ESLint 与差异检查通过。 |

## 当前摘要检查结果

- BFF 后端：认证、Session、SSO 客户端、账户门禁、Portal 空授权、可信上下文和 Proto 文档共 12 套件/39 项通过；Nest build、T-13 目标 ESLint 和差异检查通过。
- SSO：Prisma 生成、3 套件/18 项、Nest build 和差异检查通过。
- Admin 后端：Prisma 生成、数据库注释、seed 密码自检、7 套件/36 项、Nest build 和差异检查通过；T-12 已通过的隔离库迁移证据未重复执行。
- Admin 前端：2 文件/5 项、全量 lint、typecheck、Vite build 和差异检查通过；仅保留既有大 chunk 提示。
- BFF 前端：2 文件/4 项、本轮文件 ESLint 和差异检查通过。
- 本次新增/主改认证文件均低于后端 500 行上限；未新增依赖、硬编码凭据或外部写入。

## 审核决定

- P0：0。
- P1：0。
- P2-open：0（1 项已修复并复验）。
- Q24 批准的失败语义已落地：先吊销账号全部 Session，再调用 SSO；吊销失败不调 SSO，SSO 失败也不恢复已吊销会话。
- 既有超长综合文件、48 字符 MD5 兼容风险和用户已确认的 BFF 范围外基线继续沿用已登记处置，未因 T-13 扩大。
- 当前计划摘要统一审核通过，批准进入 `verify`。

# T-14 返工后最终统一复核（2026-10-26T19:42:00+08:00）

- input digest：`75b616c365da58ae6d869ce192f5618104206c02911d4d254922ef287b3c79eb`。
- provider：`code-review-skill`。
- 审核对象：T-01 至 T-14 的五仓全部受控差异；以已通过的 C-046 全量复核为基线，重点逐行审核 T-14 新增的 BFF 结构化 gRPC 错误映射与登录边界测试。BFF 接管前 `src/proxy/http-passthrough.service*` 和 `CODE_REVIEW.md` 继续排除。
- 审核方法：按 TypeScript、NestJS、认证授权、异步错误传递、Portal/Admin 端别和通用质量清单复核；运行 Jest、build、目标 ESLint 与差异检查。

## 本次发现与修复

| 等级 | 发现 | 修复与复验 |
|---|---|---|
| P1 | 初始实现会将 Portal 通道的 ForwardContext `PERMISSION_DENIED` 也转为 Admin 专用 `40302`，与“不改变 Portal 登录行为”不符。 | 将映射条件收窄为 `audience === 'admin'` 且 gRPC code 严格等于 `PERMISSION_DENIED`；增加 Portal 同状态原错误传递测试。修复后 8 项定向 Jest、BFF build、目标 ESLint 和 `git diff --check` 全部通过。 |

## 当前摘要检查结果

- BFF 登录定向测试：1 套件、8 项通过，覆盖 Admin `PERMISSION_DENIED` 稳定映射、Portal 原错误传递、非权限错误传递、Portal 员工与 Admin 超管成功路径。
- BFF `pnpm build`、目标文件 ESLint `--max-warnings 0` 和 `git diff --check` 全部通过。
- 实现只引用 grpc-js 已有 `status` 常量，没有新增依赖、文案正则、凭据或外部写入。

## 审核决定

- P0：0。
- P1：0（1 项已修复并复验）。
- P2-open：0。
- 既有超长综合文件、48 字符 MD5 兼容风险和用户已确认的 BFF 范围外基线继续沿用已登记处置，未因 T-14 扩大。
- 当前计划摘要统一审核通过，批准进入 `verify` 重跑 TC-10、AC-06 与 SR-01 管理端门禁路径。

