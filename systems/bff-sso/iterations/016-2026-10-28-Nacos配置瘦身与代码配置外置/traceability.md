# 跟踪表

| 需求要点 | 验收 | 用例 | 主要文件 |
|---|---|---|---|
| 六份配置逐键脱敏分类 | AC-01 | TC-01 | `evidence/analysis/nacos-config-inventory.md` |
| 稳定默认移回代码且模板可解析 | AC-02 | TC-02、TC-09、SR-01 | 三仓 `src/config/app.config.ts`、`nacos-config.*.yml`、配置测试 |
| bootstrap/runtime 正确分层 | AC-03 | TC-03 | 三仓 `.env.example`、`src/config/prepare-process-env.ts`、远端模板 |
| 本服务身份唯一来源 | AC-04 | TC-04、SR-01 | 三仓 `src/config/app.config.ts`、Nacos 注册配置消费点 |
| BFF 高价值参数进入强类型配置 | AC-05 | TC-05、TC-09、SR-02 | BFF `src/config`、`src/auth`、`src/session`、`src/runtime-interface` |
| 敏感必填项没有不安全兜底 | AC-06 | TC-06 | 三仓配置 Schema 与定向测试 |
| dev/test 分环境发布、读回和回滚 | AC-07 | TC-07 | 六个 Data ID、`evidence/delivery/` |
| prod 只给迁移清单 | AC-08 | TC-08 | `evidence/analysis/nacos-config-inventory.md` |
| 相邻配置消费者行为不变 | AC-09 | TC-09、SR-01、SR-02 | 三仓配置和 BFF auth/session/runtime-interface |
