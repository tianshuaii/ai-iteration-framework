# 迭代 011 统一代码审核

- capability: code-review
- provider: code-review-skill
- provider_version: local-skill
- phase: implement
- task: 无
- input_digest: 7d5967be49d3d8dc9514aabb548d24502c1533fb6e7dffbc4d7937928dfceff8
- started_at: 2026-10-27T12:13:09+08:00
- completed_at: 2026-10-27T12:15:02+08:00
- result: passed
- decision: Approve

## 审核范围

- Admin 后端：三张治理表的 Prisma 模型、迁移、partial unique、外键与注释清单。
- BFF 后端：Admin 守卫下的平台/绑定 CRUD、DTO、稳定键、事务、软删除、实时失效与测试。
- Admin 前端：BFF 账号文案、超管路由/菜单、平台与绑定页面、联动表单、API 类型与测试。
- 明确排除：BFF 接管前未跟踪的 `CODE_REVIEW.md`，本轮未读取、覆盖或纳入成果。

## 已修复发现

1. 绑定请求最初使用内部 bigint，而既有账号列表公开 `userUid`；已统一使用 `userUid` 作为页面与 API 外部身份，内部查询再解析为 bigint。
2. 唯一性最初只依赖数据库并发约束；已补平台名称及两条绑定规则的服务端主动预检，并保留 P2002 转换处理竞态。
3. 旧绑定最初未实时反映平台登录接口漂移；已按平台去重检查当前接口目录，显示“登录配置已失效”并阻止新绑定。
4. 更新绑定 DTO 最初可能静默忽略伪造主体字段；已使用 strict DTO 明确拒绝更换 BFF 账号或平台。

## 复核结论

- 鉴权：所有新 BFF 路由均使用 `AdminSessionGuard`，前端三页均在 `RequireSuperAdmin` 下。
- 一致性：平台字段和多选关联在事务中更新；软删除与有效行唯一索引语义一致。
- 安全：DTO 有长度、格式及未知字段校验；Prisma 参数化查询，无凭据、Token 或外部登录调用。
- React：Query key 含依赖，写后失效对应列表；联动选择会清空下游字段；表单有标签、必填星和输入/失焦校验。
- 规模：新增后端源码均小于 500 行，新增前端源码均小于 300 行。
- 未完成发现：P0=0，P1=0，P2-open=0。

## 验证命令

- Admin 后端：`pnpm prisma:comments:check`、带占位本地 URL 的 `pnpm prisma:generate`、迁移索引/注释静态检索。
- BFF 后端：`pnpm prisma:generate && pnpm test -- --runInBand src/admin/login-interface-identity.util.spec.ts src/admin/access-platform.service.spec.ts src/admin/platform-account-binding.service.spec.ts && pnpm build`；11/11 通过。
- Admin 前端：`pnpm lint:ci && pnpm typecheck && pnpm test -- --run src/app src/features/accounts src/features/access-platforms src/features/platform-account-bindings`；19/19 通过。

## 残余风险

- 尚未获得数据库迁移执行、测试夹具写入或本地服务启动授权，因此真实 PostgreSQL partial unique 并发、HTTP CRUD、页面交互和受控浅功能回归仍待 verify 阶段执行。
