# 状态

- workflow_profile: strict
- phase: specify
- current_task: 无
- work_state: blocked
- updated_at: 2026-10-29T11:39:28+08:00
- checkpoint: 用户原话 `Q1-Q5 都按推荐做` 已逐项记录；平台渠道、无平台账号 Session、密文硬切、私钥仅 SSO、2 分钟 nonce 防重放和 10 分钟旧钥匙宽限已确认。设计树展开到 Q6～Q8；未修改产品源码。
- next_action: 等待用户确认。Q6 加密信封与长度边界：`encryptedPassword` 使用版本化混合加密信封：RSA-OAEP-256 包装随机 AES-256 密钥，AES-GCM 加密载荷；推荐回复 `Q6 按推荐做`。Q7 Redis 故障与多实例一致性：nonce 使用 Redis `SET NX EX` 原子占位；Redis 不可用时登录失败关闭；所有 SSO 实例共享密钥环和 nonce 命名空间；推荐回复 `Q7 按推荐做`。Q8 公钥获取、缓存与重试：BFF 暴露统一匿名公钥接口并从 SSO 获取；响应 `no-store`；前端每次提交前获取，密钥过期只自动刷新并重试一次；推荐回复 `Q8 按推荐做`。若全部同意，可回复 `Q6-Q8 都按推荐做`。

`workflow_profile` 只能是 `lite`、`standard`、`strict`。新轮默认 `standard`；规格阶段按 `capabilities.yml` 的风险条件调整为最低安全档位，高风险或不确定项必须使用 `strict`。

`phase` 只能是 `specify`、`plan`、`implement`、`verify`、`done` 其中一个。`implement` 实现任务时使用 `T-xx`；首次统一审核或返工增量审核窗口使用 `无`。其他阶段固定写 `无`。

活动阶段的 `work_state` 只能是 `ready`、`in_progress` 或 `blocked`，`done` 阶段固定写 `done`。`updated_at` 使用带时区的 ISO 8601 时间。只在阶段切换、任务切换、阻塞、恢复或回合交接时更新 `checkpoint` 和 `next_action`；普通只读命令和同一连续步骤不制造微小状态写入。

实现和统一审核完成后使用 `verify / blocked` 等待验收授权；验收通过后继续使用 `verify / blocked` 等待收口授权。只有当前原话明确联合授权对应步骤时才可连续推进，不把“完成所有任务”自动解释为验收或收口。

等待设计问题时，`next_action` 必须同屏写出每个 `Qxx` 的问题全文、推荐方案和可直接复制的推荐回复，不能只写问题编号。用户明确回答前，访谈行保持 `待确认 / pending / 无`，不得提前标成 `resolved`。

阶段允许的读写范围只看 `prompts/` 中与 `phase` 对应的入口，不在本文件重复维护。
