<!-- workspace-policy: managed-worktree-v2 -->
# 产品仓库基线

开始修改产品文件前填写当前任务会涉及的仓库。每次切换任务或发现已有改动时更新，不把接管前的 dirty 文件算成当前 Agent 新产生的改动。dirty 状态必须逐文件记录，不能只写数量。

进入 `implement / ready` 前先登记拟使用的产品检出路径、隔离方式和运行资源，并与其他 `implement` 或 `verify` 轮次核对；有冲突且无法隔离时留在 `plan / blocked`。需要独立 Git worktree 时，必须使用框架根目录的 `scripts/create-worktree.rb` 创建到 `.worktrees/`，不在其他位置手工创建。隔离方式只写“独立 worktree”或“共享检出”。`specify` 和尚未完成预留的 `plan` 可以保留占位内容；真正修改产品文件前再逐文件采集 HEAD 和 dirty 基线。

更新时间：2026-10-23T19:11:00+08:00（T-02 八个产品文件已逐文件核对接管基线）

| 仓库 | 产品检出路径 | 隔离方式 | 分支 | HEAD | 接管前状态 | 当前任务涉及的文件 |
|---|---|---|---|---|---|---|
| `adx-bff-backend` | `/Users/mrzater/docker/adx/adx-bff-backend` | 共享检出 | `main` | `c57b594194cdfd40f3d24e6d7836ebc0b0e453da` | 临时 worktree 已删除；真实仓库目标分支已同步并包含最终 HEAD | T-02 八个文件已逐文件接管 |

## 接管前 dirty 明细

按仓库粘贴 `git status --short` 的文件状态；干净仓库明确写“无”。不要记录文件内容、密码、令牌或环境变量值。

### `adx-bff-backend` 原仓库（计划时只读盘点，非 worktree 接管基线）

- ` M src/proxy/http-passthrough.service.ts`
- ` M src/proxy/http-passthrough.service.spec.ts`
- 两处已有改动不复制到本轮 worktree，也不在原目录覆盖；worktree 创建后逐文件记录它自己的 HEAD 和 dirty。合回 `main` 可能冲突，须先核对并保留原改动。

### `adx-bff-backend` 独立 worktree（创建后只读盘点）

- 无；`git status --short` 为空。T-01 开工前仍需逐文件登记接管基线。

### T-01 逐文件接管基线（2026-10-23T19:07:55+08:00）

- 分支：`codex/008-bff-cold-path`；HEAD：`ee616bcb333f9d27769d2d0604116907b64c8325`。
- `src/proxy/http-passthrough.service.ts`：`git status --short -- <path>` 为空，接管前干净。
- `src/runtime-interface/services/runtime-package-inventory.service.ts`：`git status --short -- <path>` 为空，接管前干净。
- `src/proxy/http-passthrough.service.spec.ts`：`git status --short -- <path>` 为空，接管前干净。

### T-02 逐文件接管基线（2026-10-23T19:11:00+08:00）

- 分支：`codex/008-bff-cold-path`；HEAD：`ee616bcb333f9d27769d2d0604116907b64c8325`。
- `src/proxy/proxy.service.ts`：接管前干净。
- `src/proxy/proxy.controller.ts`：接管前干净。
- `src/common/guards/session.guard.ts`：接管前干净。
- `src/session/session.service.ts`：接管前干净。
- `src/clients/admin-forward-context.client.ts`：接管前干净。
- `src/proxy/proxy.service.spec.ts`：接管前干净。
- `src/common/guards/session.guard.spec.ts`：接管前干净。
- `src/session/session.service.spec.ts`：接管前干净。

### T-04 逐文件续接基线（2026-10-23T19:46:49+08:00）

- 分支：`codex/008-bff-cold-path`；HEAD：`ee616bcb333f9d27769d2d0604116907b64c8325`。
- `src/proxy/http-passthrough.service.ts`：已有 T-01 计时改动，必须保留。
- `src/proxy/http-passthrough.service.spec.ts`：已有 T-01 计时断言，必须保留。
- `src/runtime-interface/services/runtime-package-inventory.service.ts`：已有 T-01 计时改动，必须保留。
- `src/runtime-interface/services/runtime-package-inventory.service.spec.ts`：`git status --short -- <path>` 为空，接管前干净。

### T-05 逐文件接管基线（2026-10-23T19:50:02+08:00）

- 分支：`codex/008-bff-cold-path`；HEAD：`ee616bcb333f9d27769d2d0604116907b64c8325`。
- `src/runtime-interface/services/runtime-interface-resolver.service.ts`：接管前干净。
- `src/runtime-interface/services/runtime-interface-cache-sync.service.ts`：接管前干净。
- `src/runtime-interface/services/runtime-interface-resolver.service.spec.ts`：接管前干净。
- `src/runtime-interface/services/runtime-interface-cache-sync.service.spec.ts`：任务检查覆盖的既有测试文件，接管前干净；仅在补足缓存键行为断言时修改。

### T-06 返工续接基线（2026-10-23T19:53:24+08:00）

- 分支与 HEAD 不变；16 个目标文件均为 T-01～T-05 的本轮未提交改动，T-06 只处理这些文件的格式与 lint，不接管其他产品文件。
- 验收前 7 suites / 66 tests 和构建通过；ESLint 为本任务的失败入口，具体 215 errors / 1 warning 已写入 `test-log.md`。

### T-07 冷路径返工续接基线（2026-10-23T20:21:00+08:00）

- 分支与 HEAD 不变；六个目标文件均已在 T-04/T-05 中产生本轮未提交改动，必须完整保留，不接管其他产品文件。
- 正式优化后四路各 30 个有效独立重启样本均未达到 AC-03；原 BFF、测试服务直连和固定替身均已恢复，T-07 后重新申请同一组独占资源执行复测。
- 本轮仍使用登记的独立 worktree；未发现新增并行轮次占用该路径或 `本机 BFF :3000`。

## 运行资源

只登记用于发现并发冲突的稳定资源标识，不记录密码、令牌、连接串或真实地址。端口、数据库、Nacos 服务、测试账号等无法安全共享的资源使用“独占”；确实支持并发且不会互相改写的资源才使用“共享”。没有运行资源时明确写“无”。

| 资源标识 | 占用方式 | 用途 |
|---|---|---|
| `本机 BFF :3000` | 独占 | 已有本机进程监听；正式采样只在本轮已获准的短时重启窗口占用；本回合不启停。 |
| `测试服务直连配置` | 独占 | 固定替身上游采样前保存原值，采样后同轮恢复并读回核对；不切包。 |
| `固定替身上游监听端口` | 独占 | 实施时选可用端口并登记具体值，避免写死端口和撞用。 |
| `运行包缓存对应 Redis 命名空间` | 独占 | 只做业务自然读写，不清缓存；采样时避免其他 BFF 实例或管理操作并发改写。 |

## 临时 worktree 生命周期

只有使用独立 worktree 的仓库才填写。创建和清理分别运行 `scripts/create-worktree.rb` 与 `scripts/cleanup-worktree.rb`，由脚本维护本表和上面的产品检出路径。状态只使用“使用中”“待清理”“已删除”，或 `用户确认保留：用户确认……；保留原因……`。`done` 前必须清理为“已删除”；确需保留时必须在状态中同时写明用户确认和保留原因。临时目录删除后不抹掉历史路径、成果分支和最终 HEAD。

| 仓库 | 原仓库路径 | 临时 worktree 路径 | 分支 | 创建 HEAD | 最终 HEAD | 创建时间 | 状态 | 清理时间 |
|---|---|---|---|---|---|---|---|---|
| `adx-bff-backend` | `/Users/mrzater/docker/adx/adx-bff-backend` | `/Users/mrzater/docker/adx/ai-iteration-framework/.worktrees/bff-sso/008-2026-10-23-BFF首次请求冷路径耗时优化/adx-bff-backend` | `codex/008-bff-cold-path` | `ee616bcb333f9d27769d2d0604116907b64c8325` | `c57b594194cdfd40f3d24e6d7836ebc0b0e453da` | 2026-10-23T19:04:16+08:00 | 已删除 | 2026-10-23T20:46:03+08:00 |

独立 worktree 已由框架脚本创建；T-01 获得执行授权前不修改其中产品文件。成果提交、合入并推送到显式目标分支 `main` 均需分别授权；取得拉取授权后，先由 `scripts/sync-worktree.rb` 在真实仓库当前 `main` 执行 `git pull --ff-only` 并验证包含最终 HEAD，再由 `scripts/cleanup-worktree.rb` 清理副本。

## worktree 成果同步

成果提交并合入目标分支的上游后，取得拉取授权，再运行 `scripts/sync-worktree.rb <轮次目录> <仓库名> <目标分支>`；同步验证成功前不得清理独立 worktree。

| 仓库 | 目标分支 | worktree 最终 HEAD | 原仓库同步 HEAD | 同步时间 | 状态 |
|---|---|---|---|---|---|
| `adx-bff-backend` | `main` | `c57b594194cdfd40f3d24e6d7836ebc0b0e453da` | `c57b594194cdfd40f3d24e6d7836ebc0b0e453da` | 2026-10-23T20:45:58+08:00 | 已同步验证 |
