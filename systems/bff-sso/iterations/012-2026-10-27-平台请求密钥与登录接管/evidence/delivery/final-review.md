# 第 012 轮验收与交付复核

## 测试验证

- capability: `test-verification`
- provider: `manual-execution + local-framework-validator`
- phase: `verify`
- task: `无`
- result: `passed`
- completed_at: `2026-10-27T15:38:00+08:00`

- AC-01 至 AC-08、TC-01 至 TC-12、SR-01 和 SR-02 全部通过，没有豁免或未验证项。
- 测试库验证覆盖 migration 落地、密钥保留/替换、响应脱敏和登录稳定键 partial unique。
- 真实 HTTP 覆盖登录失败原样返回、成功响应校验、当前平台绑定、BFF Session 接管、可信头覆盖和普通流式直通。
- 失效态覆盖密钥轮换、平台/绑定/临时账号失效和 Session 失效，均已证明在转发前拒绝。
- 前端密钥表单行为由 21 项组件/路由测试和真实平台 API 交互共同验证；未使用或暴露既有账号密码。

## 交付复核

- capability: `delivery-review`
- provider: `manual-delivery-review`
- phase: `verify`
- task: `无`
- result: `passed`
- completed_at: `2026-10-27T15:38:00+08:00`

- 需求和计划审批有效；T-01 至 T-03、整轮统一 code review、修复和复验均有独立证据，未遗留 P0/P1/P2。
- 产品差异仍限于 Admin Schema/migration、BFF 平台密钥/登录接管/Session/代理，以及 Admin 前端平台表单；SSO 无本轮修改。
- 验收脚本仅位于本轮 `scripts/`，已复核只读取权限收紧的临时状态，不输出 Token 或密钥，只操作本轮命名夹具。
- 活动夹具计数为 0，一次性会话与临时文件已删除，本轮启动端口已释放，共享 SSO 与 BFF 前端保持运行。
- 本轮没有 worktree、提交、推送、合并、拉取或部署；测试库保留已通过验收的 migration，无豁免和残余风险。

## Nacos 配置漏项补充复核

- completed_at: `2026-10-27T15:49:00+08:00`
- 用户反馈日常 `npm run start` 缺少 `ACCESS_PLATFORM_SECRET_MASTER_KEY` 和 `PLATFORM_LOGIN_RESPONSE_MAX_BYTES`；根因是首次验收仅使用进程级临时配置，未完成运行配置交付。
- 修复仅变更 `mergex-dev` 的 BFF Nacos 配置，没有改动产品源码、本地 `.env`、数据库、其他 Data ID 或其他 namespace。
- 发布前确认测试库无有效平台密文，并确认目标字段原先不存在；新主密钥可作为首次稳定配置，不需要重加密存量数据。
- 配置发布、读后校验、BFF 无额外环境变量启动、健康/就绪探针和进程回收全部通过；未显示或写入仓库主密钥。
- 配置变更仅增加两个必填键，审核未发现 P0/P1/P2；不需要重跑未受影响的业务单测和三端全量验收。
