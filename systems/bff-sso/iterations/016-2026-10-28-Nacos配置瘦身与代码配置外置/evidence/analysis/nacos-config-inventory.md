# Nacos 配置只读盘点与目标分类

本文件只记录键名、计数、摘要、布尔比较、分类和处理结论，不保存任何配置值。下表已于 2026-10-28 以只读方式重新拉取六个 Data ID；后续发布前仍须重新核对摘要，避免覆盖并发修改。

## 当前规模

| 服务 | dev | test | 已知差异风险 |
|---|---:|---:|---|
| BFF | 60 | 53 | test 当前缺少平台主密钥和登录响应大小限制，不能直接复制 dev 删键结果 |
| Admin | 31 | 24 | dev 比 test 多直连/注册覆盖项，需先确认默认回退是否等价 |
| SSO | 21 | 20 | dev 比 test 多注册开关，需核对 test 是否依赖代码默认 |

## 只读基线

| 服务 | 环境 | Data ID | SHA-256 | 键数 |
|---|---|---|---|---:|
| BFF | dev | `mergex-bff-ai.yml` | `0568bbc2eabdfb4711aa580ab9c845ccaaf3c11487c6725fcc942151de25e623` | 60 |
| BFF | test | `mergex-bff-ai.yml` | `bd4792dd598e9c5d36194ba3b454390ad45793ebea7f58d4d32a5d25446f8d1c` | 53 |
| Admin | dev | `mergex-admin-backend-ai.yml` | `9fe91f478d87f115103c744f08f9989f8884c4d32aab2b9cf8853e368b919d54` | 31 |
| Admin | test | `mergex-admin-backend-ai.yml` | `3a17fd54b22e127930a75dbedc45479ae32d9d7a4f019a5f71db1d7558c2d3d0` | 24 |
| SSO | dev | `mergex-sso-ai.yml` | `fb2725c89e003cdbd7123ff2025e216548e194d4bcb94b5521bb6f2b783a44e9` | 21 |
| SSO | test | `mergex-sso-ai.yml` | `431af342fdac46fa40e45da61b312f64652654b028eed4e6aaba98de89f8ea99` | 20 |

六份配置中的 `NACOS_CONFIG_GROUP`、`NACOS_CONFIG_TIMEOUT_MS`、`NACOS_CLIENT_TRANSPORT`、`NACOS_GROUP`、`NACOS_CLUSTER_NAME`、`NACOS_WEIGHT`、`NACOS_EPHEMERAL`、`NACOS_FAIL_FAST`、`NACOS_METADATA_JSON`、`HTTP_MAX_PARAM_LENGTH` 和 `LOG_LEVEL` 均与当前强类型代码默认值相同。三个 dev 的 `NACOS_REGISTER_ENABLED` 均不等于默认值，因此保留；三个 test 未配置该键，继续使用代码默认值。所有 `NACOS_APP_NAME` 均等于本服务的 `NACOS_SERVICE_NAME`；Admin、SSO 的 `SERVICE_NAME` 也等于 `NACOS_SERVICE_NAME`，BFF 两者不等，体现 HTTP 身份与注册身份的既有差异。

## 逐键去留和消费者映射

“删除”表示从 dev/test 远端和受版本控制模板中移除；bootstrap 参数仍保留在部署环境示例中。“保留”表示继续由 Nacos 管理。“新增”表示仅在 BFF 中增加强类型键并保持现有行为默认值。

| 键 | 服务 | 消费者/语义 | 结论 |
|---|---|---|---|
| `ACCESS_PLATFORM_SECRET_MASTER_KEY` | BFF | 平台请求密钥加解密 | 保留；敏感必填，test 发布前必须补齐而非复制 dev 值 |
| `ACCOUNT_TREE_MAX_DEPTH` | BFF | 账号树策略 | 保留；业务策略允许运维覆盖 |
| `ADMIN_DIRECT_ADDRESS` | BFF | Admin 直连降级 | 保留；环境地址 |
| `ADMIN_DIRECT_SERVICE_CODES` | BFF | Admin 直连服务范围 | 保留；环境路由策略 |
| `ALLOW_CHILD_ACCOUNT_CREATE_CHILDREN` | BFF | 子账号策略 | 保留；业务开关 |
| `APIFOX_ACCESS_TOKEN` | BFF | Apifox 同步认证 | 保留；敏感且环境相关 |
| `APIFOX_API_VERSION` | BFF | Apifox 客户端协议版本 | 保留；本轮不改变外部 API 契约 |
| `APIFOX_BASE_URL` | BFF | Apifox 上游地址 | 保留；外部地址可能按环境变化 |
| `APIFOX_ENABLED` | BFF | Apifox 功能开关 | 保留 |
| `APIFOX_GATEWAY_PROJECT_ID` | BFF | Apifox 项目标识 | 保留；环境相关 |
| `APIFOX_PORTAL_BUSINESS_PROJECT_ID` | BFF | Apifox 项目标识 | 保留；环境相关 |
| `APIFOX_PORTAL_PROJECT_ID` | BFF | Apifox 项目标识 | 保留；环境相关 |
| `APIFOX_REQUEST_TIMEOUT_MS` | BFF | 外部请求超时 | 保留；运维参数 |
| `BATCH_ITEM_TIMEOUT_MS` | BFF | 批处理单项超时 | 保留；运行策略 |
| `BATCH_MAX_REQUESTS` | BFF | 批处理数量上限 | 保留；安全边界 |
| `BATCH_SERVICE_CONCURRENCY` | BFF | 批处理并发 | 保留；容量参数 |
| `BATCH_TOTAL_TIMEOUT_MS` | BFF | 批处理总超时 | 保留；安全边界 |
| `BFF_ACCESS_TYPE` | Admin | BFF 调用模式 | 保留；dev/test 存在差异 |
| `BFF_GRPC_URL` | Admin | BFF 直连地址 | 保留；环境地址 |
| `BFF_SESSION_PROTO_PATH` | Admin | BFF proto 入口 | 保留；现有部署仍显式覆盖，本轮不迁移协议资产 |
| `CONSOLE_LOG_BOOTSTRAP_LIMIT` | BFF | 控制台日志启动回放量 | 保留；容量参数 |
| `CONSOLE_LOG_ENABLED` | BFF | 控制台日志开关 | 保留 |
| `CONSOLE_LOG_REDIS_URL` | BFF | 控制台日志专用 Redis | 保留；环境连接，虽有回退但不能凭名称判等 |
| `CONSOLE_LOG_RETENTION_MINUTES` | BFF | 控制台日志保留周期 | 保留；运维策略 |
| `DATABASE_URL` | BFF/Admin/SSO | 数据库连接 | 保留；敏感环境配置 |
| `DEPLOYMENT_ENVIRONMENT_CODE` | BFF | 部署环境编码 | 保留；业务路由语义 |
| `GRPC_PORT` | BFF/Admin/SSO | gRPC 监听端口 | 保留；部署参数 |
| `HTTP_MAX_PARAM_LENGTH` | BFF/Admin/SSO | HTTP 参数长度上限 | 删除；六份均等于受 Schema 保护的默认值 |
| `INTERNAL_SERVICE_TOKEN` | BFF/Admin/SSO | 内部服务认证 | 保留；敏感必填 |
| `JWT_ACCESS_TOKEN_TTL` | BFF | Portal token 周期 | 保留；认证策略 |
| `JWT_ADMIN_ACCESS_TOKEN_TTL` | BFF | Admin token 周期 | 保留；认证策略 |
| `JWT_ADMIN_AUDIENCE` | BFF | Admin token audience | 保留；认证契约 |
| `JWT_ISSUER` | BFF | token issuer | 保留；认证契约 |
| `JWT_PORTAL_AUDIENCE` | BFF | Portal token audience | 保留；认证契约 |
| `JWT_SECRET` | BFF | JWT 签名密钥 | 保留；敏感必填 |
| `JWT_SESSION_ABSOLUTE_TTL` | BFF | Session 绝对周期 | 保留；认证策略 |
| `JWT_SESSION_TOUCH_MIN_INTERVAL_SECONDS` | BFF | Session touch 周期 | 保留；运行策略 |
| `LOG_LEVEL` | BFF/Admin/SSO | 日志级别 | 删除；六份均等于代码默认，仍可由 bootstrap 环境临时覆盖 |
| `NACOS_APP_NAME` | BFF/Admin/SSO | Nacos 客户端 appName | 删除；六份均与 `NACOS_SERVICE_NAME` 重复，由代码派生 |
| `NACOS_BFF_GROUP` | Admin | BFF 发现目标 group | 保留；跨服务目标，不与本服务 group 合并 |
| `NACOS_BFF_SERVICE_NAME` | Admin | BFF 发现目标名 | 保留；跨服务目标 |
| `NACOS_CLIENT_TRANSPORT` | BFF/Admin/SSO | Nacos 传输协议 | 删除；Schema 仅允许固定 `grpc` |
| `NACOS_CLUSTER_NAME` | BFF/Admin/SSO | 注册集群 | 删除；六份均为代码默认 |
| `NACOS_CONFIG_GROUP` | BFF/Admin/SSO | 首次配置拉取 group | 删除远端；保留在 bootstrap `.env`，远端值无法控制首次拉取 |
| `NACOS_CONFIG_TIMEOUT_MS` | BFF/Admin/SSO | 首次配置拉取超时 | 删除远端；保留在 bootstrap `.env` |
| `NACOS_EPHEMERAL` | BFF/Admin/SSO | 临时实例标记 | 删除；六份均为代码默认 |
| `NACOS_FAIL_FAST` | BFF/Admin/SSO | Nacos 失败策略 | 删除；六份均为代码默认 |
| `NACOS_GROUP` | BFF/Admin/SSO | 本服务注册 group | 删除；六份均为代码默认，跨服务目标 group 单独保留 |
| `NACOS_METADATA_JSON` | BFF/Admin/SSO | 注册 metadata | 删除；六份均为空默认对象 |
| `NACOS_REGISTER_ENABLED` | BFF/Admin/SSO | 服务注册开关 | dev 保留；其值明确覆盖默认。test 继续缺省使用默认 |
| `NACOS_SERVICE_NAME` | BFF | BFF 注册名 | 保留；与 `SERVICE_NAME` 不同，不能机械合并 |
| `NACOS_SERVICE_NAME` | Admin/SSO | 本服务注册名 | 删除；与 `SERVICE_NAME` 重复并已有代码回退 |
| `NACOS_SSO_GROUP` | BFF/Admin | SSO 发现目标 group | 保留；跨服务目标 |
| `NACOS_SSO_SERVICE_NAME` | BFF/Admin | SSO 发现目标名 | 保留；跨服务目标 |
| `NACOS_SSO_STRICT` | BFF | SSO 发现严格模式 | 保留；运行策略 |
| `NACOS_SUBSCRIBE_TARGETS` | SSO | 订阅目标集合 | 保留；跨服务环境拓扑 |
| `NACOS_WEIGHT` | BFF/Admin/SSO | 注册权重 | 删除；六份均为代码默认 |
| `NODE_ENV` | BFF/Admin/SSO | 进程启动环境 | 删除远端；必须在 Nacos 加载前由部署环境确定 |
| `PLATFORM_LOGIN_RESPONSE_MAX_BYTES` | BFF | 平台登录响应上限 | 保留；安全边界，test 发布前补齐 |
| `PORT` | BFF/Admin/SSO | HTTP 监听端口 | 保留；部署参数 |
| `REDIS_URL` | BFF/Admin | Redis 连接 | 保留；敏感环境配置 |
| `REQUEST_LOG_ENABLED` | BFF | 请求日志开关 | 保留 |
| `REQUEST_LOG_REDIS_URL` | BFF | 请求日志专用 Redis | 保留；环境连接 |
| `REQUEST_LOG_RETENTION_HOURS` | BFF | 请求日志保留周期 | 保留；运维策略 |
| `SERVICE_NAME` | BFF/Admin/SSO | HTTP/日志服务身份 | 保留；作为本服务身份唯一显式来源 |
| `SSO_ACCESS_TYPE` | Admin | SSO 调用模式 | 保留；dev/test 存在差异 |
| `SSO_DIRECT_ADDRESS` | BFF | SSO 直连降级 | 保留；环境地址 |
| `SSO_GRPC_URL` | Admin | SSO 直连地址 | 保留；环境地址 |
| `SSO_PROTO_PATH` | Admin | SSO proto 入口 | 保留；现有部署仍显式覆盖 |
| `SYNC_DIRECT_ADDRESS` | BFF | 同步服务直连地址 | 保留；环境地址 |
| `LOGIN_RATE_LIMIT_FAIL_WINDOW_SECONDS` | BFF | 登录失败统计窗口 | 新增；默认保持 900 秒 |
| `LOGIN_RATE_LIMIT_FAIL_THRESHOLD` | BFF | 登录失败阈值 | 新增；默认保持 5 次 |
| `LOGIN_RATE_LIMIT_BACKOFF_BASE_SECONDS` | BFF | 首次锁定周期 | 新增；默认保持 30 秒 |
| `LOGIN_RATE_LIMIT_BACKOFF_MAX_SECONDS` | BFF | 最大锁定周期 | 新增；默认保持 900 秒，且不得小于基础周期 |
| `SESSION_AUTHORIZED_TENANT_REFRESH_INTERVAL_SECONDS` | BFF | 授权租户刷新周期 | 新增；默认保持 120 秒 |
| `RUNTIME_INTERFACE_CACHE_MAX_ENTRIES` | BFF | 运行时接口缓存容量 | 新增；默认保持 200 项 |
| `RUNTIME_INTERFACE_RECONCILE_INTERVAL_SECONDS` | BFF | 运行时接口对账周期 | 新增；默认保持 120 秒 |
| `RUNTIME_INTERFACE_CACHE_PUBLISH_TIMEOUT_MS` | BFF | 缓存发布超时 | 新增；默认保持 500 毫秒 |
| `ADMIN_BACKEND_HTTP_ORIGIN` | BFF | Admin HTTP origin 的兼容覆盖 | 不新增远端键；纳入强类型可选配置，当前六份均不存在，保留既有空值回退 |

## 明确移出远端的类别

| 类别 | 代表键 | 去向 | 理由 |
|---|---|---|---|
| 首次拉取参数 | `NACOS_CONFIG_GROUP`、`NACOS_CONFIG_TIMEOUT_MS` | `.env` bootstrap | 远端 YAML 在首次拉取后才加载，不能控制本次拉取 |
| 进程启动环境 | `NODE_ENV` | 进程环境/部署层 | 应在加载 Nacos 前确定，不能由业务运行配置反向决定 |
| 重复本服务身份 | `NACOS_APP_NAME`、Admin/SSO 的 `NACOS_SERVICE_NAME` | 从唯一 `SERVICE_NAME` 派生 | BFF 的两个 service name 不同，继续保留；跨服务目标名不在此列 |
| 固定客户端默认 | `NACOS_CLIENT_TRANSPORT`、`NACOS_CLUSTER_NAME`、`NACOS_WEIGHT`、`NACOS_EPHEMERAL`、`NACOS_FAIL_FAST` | 强类型代码默认 | dev/test 相同且已有稳定默认；transport 当前只有 `grpc` 合法 |
| 无差异空 metadata | `NACOS_METADATA_JSON` | 代码默认空对象 | 空配置没有环境信息，保留只增加噪声；非空环境必须重新分类 |

## 已核实后仍保留的候选项

以下键不能只看名称删除；实现时逐项比较远端值、代码默认和环境差异：

- 批量请求数量/并发/总超时/单项超时仍是运行策略；`HTTP_MAX_PARAM_LENGTH` 已确认删除。
- Apifox API version、base URL、请求超时；token、开关和项目 ID 仍按环境保留。
- 请求日志/控制台日志 retention、bootstrap limit 和专用 Redis URL；专用 URL 与 `REDIS_URL` 相同且已有安全回退时才可删除。
- `NACOS_REGISTER_ENABLED` 在 dev 明确覆盖默认，保留；`NACOS_GROUP` 已确认删除；各跨服务目标 group 继续保留。
- JWT/Session TTL、账号树深度、子账号开关、日志级别等策略项；确需运维覆盖时保留，纯重复默认时删除。
- `BFF_ACCESS_TYPE`、`SSO_ACCESS_TYPE`、直连地址和 Proto 路径；按是否仍存在 HTTP/gRPC 环境差异逐项决定，不允许把固定协议路径误当环境参数。

## 必须保留的类别

- 数据库、Redis、JWT 密钥、内部服务令牌、平台请求密钥主密钥等敏感或必填配置。
- 各服务监听端口、环境相关直连地址、真实存在差异的项目 ID、功能开关和日志开关。
- BFF 的部署环境编码，以及真实用于服务发现的跨服务目标名/group。
- `PLATFORM_LOGIN_RESPONSE_MAX_BYTES` 等已有安全边界参数；test 缺失项需要按契约补齐或证明有安全默认，不能在瘦身中忽略。

## 从代码外置的限定清单

| 参数组 | 数量 | 默认兼容要求 |
|---|---:|---|
| 登录失败窗口、阈值、基础锁定、最大锁定 | 4 | 默认值与现有 `login-rate-limit.service.ts` 常量完全等价 |
| Session 授权租户刷新周期 | 1 | 默认保持当前 120 秒 |
| 运行时接口缓存容量、对账周期、发布超时 | 3 | 默认保持当前 200 项、120 秒、500 毫秒 |
| 仍有环境差异的 HTTP 上游 origin | 0 | 调用链仍消费，但当前六份均无此键；只收口裸读取，不无依据扩大远端配置 |

瘦身模板完成后的预期基础键数（尚未计入 BFF 新外置的 8 个运行参数）为：BFF dev 47、test 40；Admin dev 17、test 10；SSO dev 7、test 6。BFF 加入 8 个已批准运行参数后预期为 dev 55、test 48。实际 T-04 发布仍以发布前重新拉取的键集合为准。

Proto 文件名、gRPC full method、服务编码、Redis key/channel 版本和日志内部队列/重试细节不进入本清单。

## 发布边界

- 只有取得外部写入授权后才执行 test→dev 发布。
- 每个 Data ID 单独保存发布前 revision 和受控回滚正文，发布后立即读回和验证。
- 任一读回、Schema 或启动验证失败，停止后续 Data ID 并回滚当前项。
- prod 仅输出迁移清单，不读取、不发布、不删除。
