# Nacos 发布前预检

- checked_at: `2026-10-28T15:57:59+08:00`
- authorization: 用户原话“授权执行迭代 016 的 Nacos dev/test 配置写入与回滚”
- result: `blocked_before_write`
- remote_writes: `0`
- rollback_actions: `0`

## 六份摘要复核

| 环境 | 服务 | 发布前 SHA-256 | T-01 基线 | 结果 |
|---|---|---|---|---|
| test | BFF | `bd4792dd598e9c5d36194ba3b454390ad45793ebea7f58d4d32a5d25446f8d1c` | 同左 | 未漂移 |
| test | Admin | `3a17fd54b22e127930a75dbedc45479ae32d9d7a4f019a5f71db1d7558c2d3d0` | 同左 | 未漂移 |
| test | SSO | `431af342fdac46fa40e45da61b312f64652654b028eed4e6aaba98de89f8ea99` | 同左 | 未漂移 |
| dev | BFF | `0568bbc2eabdfb4711aa580ab9c845ccaaf3c11487c6725fcc942151de25e623` | 同左 | 未漂移 |
| dev | Admin | `9fe91f478d87f115103c744f08f9989f8884c4d32aab2b9cf8853e368b919d54` | 同左 | 未漂移 |
| dev | SSO | `fb2725c89e003cdbd7123ff2025e216548e194d4bcb94b5521bb6f2b783a44e9` | 同左 | 未漂移 |

## 阻塞项

- test BFF 远端仍缺少 `ACCESS_PLATFORM_SECRET_MASTER_KEY` 和 `PLATFORM_LOGIN_RESPONSE_MAX_BYTES`。
- `PLATFORM_LOGIN_RESPONSE_MAX_BYTES` 可按已批准安全边界补为 `1048576`。
- 平台主密钥没有可信来源：BFF `.env.test` 只有 Nacos bootstrap 字段，迭代文档与模板只保存占位值。
- `risks.md` 明确要求不从文档或代码生成真实密钥；缺少正确来源时必须在任何发布前停止。
- 为避免 test 批次出现 SSO/Admin 已瘦身而 BFF 无法通过强类型启动的半发布状态，本次尚未写入任何 Data ID。

## 恢复条件

将 test 环境现用的 32 字节标准 Base64 平台主密钥通过安全本地来源提供，例如临时写入 BFF 的 `.env.test`：`ACCESS_PLATFORM_SECRET_MASTER_KEY=<正确的 test 密钥>`。不得把密钥正文写入聊天、迭代 Markdown 或版本化模板。恢复后须重新核对六份摘要，再按 test 的 SSO→Admin→BFF 顺序发布。

## 最终发布结果

- published_at: `2026-10-28T16:04:00+08:00`
- authorization: 用户原话“授权执行迭代 016 的 Nacos dev/test 配置写入与回滚”及“你来随机生成一个”
- result: `passed`
- publish_order: `test SSO → test Admin → test BFF → dev SSO → dev Admin → dev BFF`
- secret_handling: test BFF 的 `ACCESS_PLATFORM_SECRET_MASTER_KEY` 使用密码学安全随机源在发布进程内生成；正文未输出、未写入迭代证据或产品仓库
- rollback_backup: 验收期间位于本机临时目录，六个文件权限均为 `0600`；真实验收通过后已整体移入系统废纸篓，避免明文敏感配置继续驻留

| 环境 | 服务 | 发布前 SHA-256 | 发布后 SHA-256 | 键数变化 | 精确读回 |
|---|---|---|---|---:|---|
| test | SSO | `431af342fdac46fa40e45da61b312f64652654b028eed4e6aaba98de89f8ea99` | `fb8caf5b6d36cbdae423d52fd4b7b6dd35d50573640826494127764f114460e2` | 20 → 6 | 通过 |
| test | Admin | `3a17fd54b22e127930a75dbedc45479ae32d9d7a4f019a5f71db1d7558c2d3d0` | `e52d53cb242ce787d20e2524cafc0cbbf2876e2d06ca9f033cb4b8a26dd07379` | 24 → 10 | 通过 |
| test | BFF | `bd4792dd598e9c5d36194ba3b454390ad45793ebea7f58d4d32a5d25446f8d1c` | `320cf84247cf0ebf13c2a61185de20d1638f3584f25990b47e01554b89ebd4f6` | 53 → 50 | 通过 |
| dev | SSO | `fb2725c89e003cdbd7123ff2025e216548e194d4bcb94b5521bb6f2b783a44e9` | `ce3b1271df57cf8c3087d34780dd84446217f47d447827a390d46e0421e9b2d0` | 21 → 7 | 通过 |
| dev | Admin | `9fe91f478d87f115103c744f08f9989f8884c4d32aab2b9cf8853e368b919d54` | `00eaa2b915ae795db8ef7978a4b07b288975e8f33e417bf20c71d2cf4eaf57e8` | 31 → 17 | 通过 |
| dev | BFF | `0568bbc2eabdfb4711aa580ab9c845ccaaf3c11487c6725fcc942151de25e623` | `9c0daa136246ba0a44c135d49d3ccb1250f92e4700e86124d3274a4ee4c605f8` | 60 → 55 | 通过 |

### 异常与回滚

- 前两次尝试因 Nacos Client API 读取到旧缓存而停止；每次仅改动 test SSO，脚本随即使用发布前备份回滚。
- 两次回滚后 test SSO SHA-256 均恢复为 `431af342fdac46fa40e45da61b312f64652654b028eed4e6aaba98de89f8ea99`，其余 Data ID 未写入。
- 发布脚本随后改为以 Admin API 做权威校验，并轮询 Client API 缓存收敛；最终六份均满足权威正文与运行时读回正文精确一致。
- 两个失败尝试的敏感临时备份已移入系统废纸篓；最终成功批次备份仅保留到真实验收结束。
- 最终成功批次的回滚备份在全部验收通过后也已移入系统废纸篓；远端发布前后摘要和回滚结果继续保留在本证据中。

### 配置解析验证

分别使用三仓 test/dev bootstrap 文件读取对应远端配置，再调用各仓 `validateEnv` 强类型解析：

- `bff-test`、`admin-test`、`sso-test`：通过。
- `bff-dev`、`admin-dev`、`sso-dev`：通过。
- 本步骤未启动或停止任何本地服务，也未修改 prod 配置。
