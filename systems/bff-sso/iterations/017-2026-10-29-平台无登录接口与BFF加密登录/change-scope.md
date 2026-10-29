# 改动范围

仓库绝对路径写在这套系统的 `overview.md`。系统名：`bff-sso`。

## 要改的项目

| 项目 | 这一轮它负责什么 |
|---|---|
| `adx-admin-backend` | 治理表字段可空迁移、Prisma 模型和接入平台保存校验 |
| `adx-admin-frontend` | 接入平台可选登录接口、列表状态展示和 Admin 登录加密 |
| `adx-bff-backend` | 登录渠道契约、无登录平台 Session、请求头注入分支、公钥接口与 SSO 密文转发 |
| `adx-bff-frontend` | BFF 管理端登录前获取公钥并加密密码 |
| `adx-sso-backend` | 登录密文协议、私钥解密、防重放、密钥配置和密码校验 |

## 页面上要改的位置

同一页上相关的说明、筛选、表格、弹窗都要写。不要只写用户圈出的那一块。

| 位置 | 现在 | 改完 |
|---|---|---|
| 账号权限管理端－接入平台－新增/编辑 | 登录子服务、登录接口均必填 | 登录接口可不选；未选择时提示“使用 BFF 登录”并成组清空登录配置 |
| 账号权限管理端－接入平台－列表 | 登录接口列只展示稳定键，无配置会被视为失效 | 无登录接口时展示“BFF 登录”，状态仍可为有效 |
| BFF 网关管理端－登录页 | 直接提交明文 `password` | 先获取公钥，以 `keyId + encryptedPassword` 提交 |
| 账号权限管理端－登录页 | 直接提交明文 `password` | 先获取公钥，以 `keyId + encryptedPassword` 提交 |

## 大致文件

### `adx-admin-backend`

- `prisma/schema.prisma` 与本轮 migration：接入平台登录配置字段和关系支持成组为空；迁移只在本仓执行。
- `src/admin/dto/access-platform.dto.ts`、`src/admin/access-platform.service.ts`：DTO、保存、唯一性、实时有效性和列表映射支持 BFF 登录模式。
- 对应 `*.spec.ts`：覆盖空登录配置、半套配置拒绝和老配置兼容。

### `adx-admin-frontend`

- `src/features/access-platforms/AccessPlatformEditorModal.tsx`、`AccessPlatformPage.tsx`、`access-platform-model.ts`：可选登录接口、联动清空、列表展示与提交归一化。
- `src/lib/admin-api.ts`、`src/features/auth/LoginPage.tsx`：同步平台类型和加密登录契约。
- 对应测试：覆盖表单归一化、加密请求和错误路径。

### `adx-bff-backend`

- `src/auth/dto/login.dto.ts`、`src/auth/auth.controller.ts`、`src/auth/auth.service.ts`：新增平台渠道并接收密文登录参数。
- `src/clients/sso.client.ts`：BFF→SSO 登录 RPC 透传密文，不接触明文。
- `src/proxy/platform-request-context.service.ts`、`src/proxy/http-passthrough.service.ts`：区分有/无平台账号 ID 的转发身份和请求头。
- `src/proxy/platform-login-response.service.ts`：保持既有平台自有登录接管行为。
- `prisma/schema.prisma`：同步治理表可空模型，不在本仓迁移。
- 公钥查询相关模块与测试：向浏览器提供当前公钥元数据，不暴露私钥。

### `adx-bff-frontend`

- `src/features/auth/LoginPage.tsx`、`src/lib/admin-api.ts`：登录前获取公钥并发送密文。
- 新增加密工具及定向测试：使用浏览器 Web Crypto，不引入私钥或固定公钥。

### `adx-sso-backend`

- `proto/sso/v1/auth.proto`、`src/grpc/auth-grpc.server.ts`：登录 RPC 接收 `keyId + encryptedPassword`。
- `src/auth/dto/auth.dto.ts`、`src/auth/auth.service.ts`：解密后执行现有密码校验。
- `src/config/app.config.ts`：强类型读取密钥环和防重放配置。
- 新增加密、防重放模块及定向测试：算法、过期、nonce 重放、轮换和日志脱敏。

### 补测试

- 五仓只运行本轮直接影响的定向单测、类型检查/构建和按风险浅回归；具体命令在计划阶段确认。

## 明确不动

| 项目 | 为什么不动 |
|---|---|
| 平台业务仓库 | 本轮只定义 BFF 原生登录契约；外部调用方升级范围等待 Q3 确认 |
| Nacos dev/test/prod 实例 | 规格阶段不写外部配置；实现/验收仍需另行授权 |
| 已有平台账号绑定数据 | 无登录平台不伪造绑定，已有平台逻辑保持 |
