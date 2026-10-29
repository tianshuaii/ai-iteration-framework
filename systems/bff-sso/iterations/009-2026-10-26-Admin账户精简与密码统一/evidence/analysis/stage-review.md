# 阶段评审

## Plan Review：T-13 本人改密 Session 吊销返工

- provider: `iteration-plan-review`
- provider_version: `2026-10-26-local`
- input_digest: `17da42b810c11cde5c69bbbcc5a38342a66182c152b417366d42bf06e8ecbb12`
- started_at: `2026-10-26T18:36:00+08:00`
- completed_at: `2026-10-26T18:38:00+08:00`
- result: `passed`
- findings: `P0=0, P1=0, P2-open=0`

### 规格与设计树

- 需求审批仍有效；T-13 修复 TC-08 已批准行为的实现缺陷，不改变账户单一化、密码格式或治理删除范围。
- Q24 已由用户原话“Q24 按推荐做”确认：Portal 与 Admin 都提供受各自 Session Guard 保护的本人改密接口；请求体不能指定账号；不新增前端页面。
- 安全顺序沿用管理员重设密码：先吊销该账户全部 Session，再调用 SSO 改密。SSO 失败时密码不变、Session 已失效，用户重新登录后重试，不恢复旧 Session。

### 任务、依赖与文件范围

- T-13 仅依赖已完成的 T-01、T-05；不重复实现 T-01 至 T-12。
- 允许文件为 `adx-bff-backend/src/auth/**` 及对应 spec，与 `change-scope.md` 的 BFF 认证范围相交；不改 SSO、Admin、两个前端、Proto、Prisma 或迁移。
- 明确排除接管前 dirty：`src/proxy/http-passthrough.service.ts`、`src/proxy/http-passthrough.service.spec.ts`、`CODE_REVIEW.md`。
- 实现前按当前 T-13 摘要执行 implementation guard；完成任务后重新执行当前摘要的迭代级统一 code review，再进入 verify。

### 检查与验收

- 定向自动化覆盖 Portal/Admin 两类入口、当前 Session 身份不可伪造、吊销先于 SSO、失败传播及成功后同账户全部 Session 失效。
- 实现检查为本人改密、账户门禁与 Session 定向 Jest、BFF build、目标文件 ESLint、`git diff --check`；可在统一检查中去重执行。
- 修复后重跑 TC-08、TC-11、TC-13 与直接浅回归 SR-01。SR-02 的代理、接口编辑、请求查询和实时日志不经过本人改密编排，经影响分析不要求机械重跑；原停止边界和已确认的范围外基线豁免不变。

### 检出、资源与回退

- 系统内没有其他 `implement` 或 `verify` 轮次占用 `adx-bff-backend`，继续使用真实仓库共享检出 `main@c57b594194cdfd40f3d24e6d7836ebc0b0e453da`，不创建 worktree。
- 隔离五服务当前全部停止；实现阶段不启动。用户先前已授权本轮使用隔离五服务、专用数据库和 Redis DB14，复验时只恢复这些独占资源并在结束前关闭。
- T-13 不含数据库变化。未提交状态可通过撤销 T-13 精确文件回退；禁止 reset/checkout 覆盖其他本轮成果或接管前 dirty。

### 结论

计划没有未解决的范围、依赖、检查、回退、检出或独占资源冲突，可以等待计划重新审批。该结论不代替用户审批，也不授权修改产品源码、提交、推送或部署。
