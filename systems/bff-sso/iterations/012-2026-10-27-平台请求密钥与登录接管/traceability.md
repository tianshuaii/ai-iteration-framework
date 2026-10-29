# 跟踪表

| 需求要点 | 验收 | 用例 | 主要文件 |
|---|---|---|---|
| 平台请求密钥必填、存储、脱敏和编辑 | AC-01 | TC-01、TC-02 | Admin/BFF `prisma/schema.prisma`、platform DTO/service、`AccessPlatformEditorModal.tsx` |
| 登录接口唯一映射平台 | AC-02 | TC-03 | BFF `access-platform.service.ts`、`http-passthrough.service.ts` |
| 上游登录失败原样返回 | AC-03 | TC-04、TC-05 | BFF `http-passthrough.service.ts` |
| 成功响应解析和当前平台绑定 | AC-04 | TC-06、TC-07 | BFF proxy、binding/Auth 服务 |
| 创建平台 Portal Session 并返回统一 Token | AC-05 | TC-08 | BFF Auth、Session、response interceptor |
| 非白名单注入可信身份头、白名单不注入 | AC-06 | TC-09、TC-10 | BFF HTTP passthrough、Session Guard |
| 密钥轮换及平台/绑定/账号/Session 失效 | AC-07 | TC-11 | BFF platform、binding、session、proxy |
| 原登录与普通直通兼容 | AC-08 | TC-12、SR-01、SR-02 | BFF Auth/Session/proxy 与 Admin 前端平台页 |
