# 跟踪表

| 需求要点 | 验收 | 用例 | 主要文件 |
|---|---|---|---|
| Admin 只保留账户页面 | AC-01 | TC-01、TC-02 | `adx-admin-frontend/src/app/router.tsx`、`src/components/layout/AdminLayout.tsx` |
| 账户列表、筛选与操作脱离角色等模型 | AC-02 | TC-03、TC-04 | 前端账户资源文件、`adx-admin-backend/src/governance/governance-account.service.ts` |
| 删除非账户治理与治理审计查询 | AC-03 | TC-05、TC-06 | Admin/BFF governance proto、controller、service、生成 SDK |
| 密码存库规则统一 | AC-04 | TC-07、TC-08 | `adx-sso-backend/src/auth/**`、Admin seed/注释 |
| 既有密码失效、重设与恢复 | AC-05 | TC-08、TC-09 | SSO 密码校验与管理员重设路径 |
| 登录、Portal 空授权、会话和管理门禁去角色依赖 | AC-06 | TC-10、TC-11 | SSO 登录、Admin ForwardContext、BFF Portal 与 gateway admin |
| 数据模型和迁移收口 | AC-07 | TC-12 | `adx-admin-backend/prisma/**` |
| 自动检查与代码审核 | AC-08 | TC-13 | 五个产品仓库的本轮改动与测试 |
| 账户单一化直接浅回归 | AC-01 至 AC-06 | SR-01 | Admin 账户页面、账户服务、SSO 密码、BFF Session 与两个管理端门禁 |
| BFF 保留能力相邻浅回归 | AC-08 | SR-02 | BFF 普通代理、接口编辑、请求查询与实时日志 |
