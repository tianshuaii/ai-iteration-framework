# 跟踪表

| 需求要点 | 验收 | 用例 | 主要文件 |
|---|---|---|---|
| “账号”用户可见名称改为“BFF 账号”，行为不变 | AC-01 | TC-01 | `adx-admin-frontend/src/features/accounts/**`、`src/components/layout/AdminLayout.tsx` |
| 接入平台列表、新建、编辑与归属校验 | AC-02 | TC-02、TC-03 | `adx-admin-frontend/src/features/access-platforms/**`、`adx-bff-backend/src/admin/**` |
| 接入平台软删除与有效绑定阻断 | AC-03 | TC-04 | `adx-bff-backend/src/admin/**`、`adx-admin-backend/prisma/schema.prisma` |
| 平台账号绑定新建、修改 ID、解绑与主体不可换 | AC-04 | TC-05、TC-06 | `adx-admin-frontend/src/features/platform-account-bindings/**`、`adx-bff-backend/src/admin/**` |
| BFF-平台及平台-账号双唯一约束 | AC-05 | TC-07 | `adx-admin-backend/prisma/migrations/<本轮迁移>/migration.sql`、`adx-bff-backend/src/admin/**` |
| 登录子服务/接口失效保留旧数据并阻断新绑定；BFF 账号失效保留旧绑定、展示状态并阻断新绑定 | AC-06 | TC-08 | `adx-bff-backend/src/openapi/service-openapi-sync.service.ts`、`src/admin/**`、`adx-admin-frontend/src/features/platform-account-bindings/**` |
| 仅启用超管可访问新能力 | AC-07 | TC-09 | `adx-bff-backend/src/admin/**`、`adx-admin-frontend/src/app/router.tsx` |
| 新表命名、注释、软删除和迁移仓库边界；老功能不回归 | AC-08 | TC-10、SR-01、SR-02 | `adx-admin-backend/prisma/**`、`adx-bff-backend/prisma/schema.prisma`、`adx-admin-frontend/src/**` |
