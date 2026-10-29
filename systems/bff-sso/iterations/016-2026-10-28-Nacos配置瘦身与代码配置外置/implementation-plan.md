# 实现计划

## 做法

### 1. 先冻结配置事实

- 重新只读取得 BFF、Admin、SSO 在 dev/test 的六份键名、revision 和脱敏摘要，与需求阶段计数对账。
- 用代码消费者、Schema 默认值和跨环境差异给每个键落下“保留、移出远端、依赖默认删除、从代码外置新增、暂缓”结论。
- 实施中发现远端 revision 变化时重新盘点，不沿用过期删键清单。

### 2. 收口三仓配置契约

- `.env.example` 只描述首次拉取所需的 Nacos bootstrap 参数；远端 `nacos-config.dev.yml` / `nacos-config.test.yml` 只保留运行期配置。
- 对 transport、cluster、weight、ephemeral、fail-fast 等稳定默认使用 Zod 强类型默认值，并补“最小远端配置仍可解析”测试。
- 服务身份按语义处理：本服务的业务应用名和 Nacos 注册名真实不同则分别保留；只有同义且同值的 `NACOS_APP_NAME` 等展示别名才派生，不能为了少一个键改变注册名。
- Admin、SSO 没有独立 `app.config.spec.ts`，在现有 config 测试体系内新增最小配置契约测试，不建立第二套配置加载器。

### 3. BFF 高价值参数外置

- 在 `app.config.ts` 增加登录限流四个强类型参数：失败窗口、失败阈值、基础锁定秒数、最大锁定秒数。
- `login-rate-limit.service.ts` 只读取统一配置对象，默认仍为 15 分钟、5 次、30 秒、15 分钟；同时校验最大锁定不小于基础锁定。
- 已存在 Schema 但未进入模板的 Session 授权刷新周期、运行时接口缓存容量/对账周期/发布超时加入可审计模板，默认保持 120 秒、200 项、120 秒、500 毫秒。
- `ADMIN_BACKEND_HTTP_ORIGIN` 先核对消费者和服务发现回退；仍是环境入口时纳入强类型配置，已被服务发现替代时删除裸读取，不新增无消费者配置。
- Proto 方法、服务编码、Redis channel/key 版本、日志内部队列和重试细节继续留在代码。

### 4. 分环境发布

- 代码、模板和自动测试全部通过后，等待单独的 Nacos 外部写入授权。
- 发布前保存每个 Data ID 的 revision、键名和受控回滚正文；正文不进入迭代 Markdown 或普通命令输出。
- 固定批次是 test 按 SSO→Admin→BFF 发布并完成三端真实启动与链路验证，再进入 dev 按 SSO→Admin→BFF 发布、读回和配置解析；服务启停仍需另行授权。
- 任一读回或运行验证异常，停止后续批次并回滚当前 Data ID；不读写 prod。
- 未取得 Nacos 外部写入授权时，T-01～T-03 可以完成，但 T-04 与整轮保持阻塞，不把代码可发布误写成迭代完成。

## 为什么这样切

- 配置键是否多余必须同时由远端事实、代码消费者和默认值证明，不能只看模板或名称。
- 强类型入口统一放在各仓 `app.config.ts`，避免业务服务继续散落读取 `process.env`。
- BFF 安全与性能参数单独成任务，便于使用 T4 测试深度；Admin/SSO 的模板瘦身不被迫扩大到业务模块。
- 远端发布与代码实现分开，确保删键之前已有可运行默认和回滚证据。

## 怎样避开「不做」

- 不改两个前端、数据库 Schema、Prisma 模型、接口路径、响应结构或 Proto 契约。
- 不把所有常量迁入 Nacos，也不新增 Secret Manager。
- 不修改或读取生产 Nacos；生产只交付脱敏迁移清单。
- 不启动本地三端服务，除非用户另行授权；实现阶段优先使用不启动监听端口的配置单测和 build。
- 不提交、推送、合并或拉取代码，除非用户分别授权。

## 字段变化

开发结束后再把“计划”改为实际结果；开始时均为尚未改代码。

| 字段或路径 | 谁在用 | 计划变化 |
|---|---|---|
| `LOGIN_RATE_LIMIT_FAIL_WINDOW_SECONDS` | BFF 登录限流 | 新增强类型可覆盖项，默认 900 秒 |
| `LOGIN_RATE_LIMIT_FAIL_THRESHOLD` | BFF 登录限流 | 新增强类型可覆盖项，默认 5 |
| `LOGIN_RATE_LIMIT_BACKOFF_BASE_SECONDS` | BFF 登录限流 | 新增强类型可覆盖项，默认 30 秒 |
| `LOGIN_RATE_LIMIT_BACKOFF_MAX_SECONDS` | BFF 登录限流 | 新增强类型可覆盖项，默认 900 秒 |
| `SESSION_AUTHORIZED_TENANT_REFRESH_INTERVAL_SECONDS` | BFF Session | 已有 Schema；补进可审计配置模板，默认 120 秒 |
| `RUNTIME_INTERFACE_CACHE_MAX_ENTRIES` | BFF 运行时接口缓存 | 已有 Schema；补进模板，默认 200 |
| `RUNTIME_INTERFACE_RECONCILE_INTERVAL_SECONDS` | BFF 运行时接口缓存 | 已有 Schema；补进模板，默认 120 秒 |
| `RUNTIME_INTERFACE_CACHE_PUBLISH_TIMEOUT_MS` | BFF 运行时接口缓存 | 已有 Schema；补进模板，默认 500 毫秒 |
| `ADMIN_BACKEND_HTTP_ORIGIN` | BFF Admin 转发客户端 | 经消费者核实后收口到强类型配置或删除裸读取，不预设一定新增 |
| 三仓 `nacos-config.*.yml` | 本地模板与远端发布正文 | 删除已证明冗余的 bootstrap、同义展示和稳定默认键 |

