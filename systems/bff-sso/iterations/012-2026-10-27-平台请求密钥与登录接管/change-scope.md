# 改动范围

仓库绝对路径写在这套系统的 `overview.md`。默认按那个路径打开原仓库；未提交修改不改变路径。只有另一 `implement` 或 `verify` 轮次使用同一仓库时，才按本轮 `workspace.md` 中由脚本登记的 `.worktrees/` 临时检出打开。系统名：`bff-sso`

## 要改的项目

| 项目 | 这一轮它负责什么 |
|---|---|
| `adx-admin-backend` | 作为治理 Schema 唯一迁移源，为接入平台增加请求密钥存储字段及字段注释。 |
| `adx-bff-backend` | 同步 Prisma 模型；扩展平台 CRUD、平台登录识别、响应接管、绑定查找、Portal Session 平台上下文和非白名单身份头注入。 |
| `adx-admin-frontend` | 在接入平台新建/编辑弹窗增加安全的请求密钥录入与替换交互。 |

## 页面上要改的位置

| 位置 | 现在 | 改完 |
|---|---|---|
| 接入平台新建弹窗 | 名称、所属子服务、登录子服务、登录接口四项。 | 增加必填“请求密钥”，使用密码型输入，不展示真实值；保留必填星与 `onChange/onBlur` 校验。 |
| 接入平台编辑弹窗 | 回显全部非敏感平台配置。 | 不回显密钥明文；留空保持原密钥，输入新值替换。 |
| 接入平台列表 | 显示名称、子服务、登录接口和状态。 | 不增加密钥明文列；如需状态提示，只显示“已配置/未配置”。 |
| 平台保存错误 | 只覆盖名称、子服务和登录接口错误。 | 增加密钥缺失、平台登录接口冲突和密钥加解密配置错误的可读提示，不泄露密钥。 |

## 大致文件

### `adx-admin-backend`

- `prisma/schema.prisma`：为 `AccessPlatform` 增加请求密钥存储字段。
- `prisma/migrations/<本轮迁移>/migration.sql`：只迁移平台密钥字段及必要约束，不修改绑定基数。
- `prisma/scripts/public-management-comment-manifest.ts`：同步字段注释。

### `adx-bff-backend`

- `prisma/schema.prisma`：同步平台密钥字段，不创建 BFF migration。
- `src/admin/dto/access-platform.dto.ts`：扩展创建/编辑密钥契约。
- `src/admin/access-platform.service.ts`：保存、替换、隐藏密钥并校验登录接口唯一性。
- `src/admin/access-platform.controller.ts`：保持超管守卫并暴露新契约。
- `src/proxy/http-passthrough.service.ts`：识别平台登录、按分支处理上游响应，并在非白名单转发中注入可信身份头。
- `src/session/session.types.ts`、`src/session/session.service.ts`：保存和校验平台 Session 上下文；必要时升级 Session 身份模型版本。
- `src/auth/auth.service.ts` 或新增职责单一的服务：复用 Portal Session 创建、ForwardContext、审计和响应组装逻辑，避免复制登录实现。
- `src/common/responses/api-codes.ts`：仅在现有码无法表达已确认错误时增加稳定业务码。
- `src/config/app.config.ts`：声明无代码兜底的密钥加密主密钥配置。

### `adx-admin-frontend`

- `src/features/access-platforms/AccessPlatformEditorModal.tsx`：增加请求密钥输入、编辑保持/替换语义和校验。
- `src/features/access-platforms/access-platform-model.ts`：归一化平台密钥请求。
- `src/features/access-platforms/access-platform-model.spec.ts`：覆盖新建必填与编辑不误清密钥。
- `src/lib/admin-api.ts`：同步平台密钥请求与脱敏响应类型。

### 补测试

- BFF：平台登录识别、上游失败原样返回、成功响应解析、绑定与账号状态、Session 平台上下文、头覆盖/缺失、白名单不注入、普通流式转发不回归。
- Admin 后端：Prisma 生成、迁移字段和注释检查。
- Admin 前端：密钥必填、失焦校验、编辑保持/替换且不回显。

## 明确不动

| 项目 | 为什么不动 |
|---|---|
| `adx-sso-backend` | 平台登录仍由原上游验证，BFF 不调用 SSO 校验该平台凭据；共享 Schema 若构建确有要求再同步模型，但不迁移。 |
| `adx-bff-frontend` | 本轮不改网关管理页，也不新增平台登录 UI；上游业务前端继续调用原登录 URL。 |
| 外部平台服务 | BFF 适配既有 `{ code, data.userId }` 响应并注入请求头，不修改外部平台代码。 |
