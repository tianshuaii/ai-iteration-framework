# 产品仓库基线

开始修改产品文件前填写当前任务会涉及的仓库。每次切换任务或发现已有改动时更新，不把接管前的 dirty 文件算成当前 Agent 新产生的改动。dirty 状态必须逐文件记录，不能只写数量。

同一系统有其他 `implement` 或 `verify` 轮次时，本轮必须使用不同的产品检出路径，推荐为每个受影响仓库创建独立 Git worktree。隔离方式只写“独立 worktree”或“共享检出”。`specify` 和 `plan` 尚未操作产品仓库时可以保留占位内容。

更新时间：2026-10-22T21:11:16+08:00

| 仓库 | 产品检出路径 | 隔离方式 | 分支 | HEAD | 接管前状态 | 当前任务涉及的文件 |
|---|---|---|---|---|---|---|
| `adx-bff-backend` | `/Users/mrzater/docker/adx/adx-bff-backend` | 共享检出 | `main` | `186ec23` | 已有本轮先前改过的注册开关和示例配置，见下方明细。003 当前任务只改 `prisma/schema.prisma`，和这次文件不重叠。 | `src/config/app.config.ts`、`src/platform/platform-sso-sub-service.bootstrap.ts`、`src/platform/platform-sso-sub-service.bootstrap.spec.ts`、`src/platform/platform-service.registry.spec.ts`、`nacos-config.dev.yml`、`nacos-config.test.yml` |

## 接管前 dirty 明细

按仓库粘贴 `git status --short` 的文件状态；干净仓库明确写“无”。不要记录文件内容、密码、令牌或环境变量值。

### adx-bff-backend

T-05 开始前已经存在、不是这次同步逻辑新产生的：

- `M nacos-config.dev.yml`
- `M nacos-config.test.yml`
- `M src/config/app.config.ts`
- `M src/nacos/nacos-naming.service.ts`
- `?? src/nacos/nacos-naming.service.spec.ts`

## 运行资源

只登记用于发现并发冲突的稳定资源标识，不记录密码、令牌、连接串或真实地址。端口、数据库、Nacos 服务、测试账号等无法安全共享的资源使用“独占”；确实支持并发且不会互相改写的资源才使用“共享”。没有运行资源时明确写“无”。

| 资源标识 | 占用方式 | 用途 |
|---|---|---|
| `bff-sso-gateway` | 独占 | 当前 verify 使用网关完成登录、连通和内建服务保存验收；T-05 当时仅跑单元测试 |
