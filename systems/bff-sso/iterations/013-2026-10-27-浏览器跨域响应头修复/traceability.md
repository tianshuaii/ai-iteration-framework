# 跟踪表

| 需求要点 | 验收 | 用例 | 主要文件 |
|---|---|---|---|
| 普通流式代理保留 Fastify/BFF 响应头 | AC-01、AC-05 | TC-01、TC-05、SR-01 | `src/proxy/http-passthrough.service.ts`、对应 spec |
| 平台登录业务失败同时保留上游响应和 BFF CORS | AC-02 | TC-02、SR-02 | `src/proxy/platform-login-response.service.ts`、对应 spec |
| BFF 同名 CORS 头优先于上游 | AC-03 | TC-03 | `src/proxy/platform-login-response.service.ts`、对应 spec |
| 平台登录成功 Session 逻辑不变 | AC-04 | TC-04、SR-02 | `src/proxy/platform-login-response.service.ts`、对应 spec |
