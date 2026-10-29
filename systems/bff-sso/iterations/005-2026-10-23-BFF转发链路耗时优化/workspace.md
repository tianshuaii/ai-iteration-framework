# 产品仓库基线与资源预留

本轮从系统目录启动。001～004 已是 `done`。006 也在 `implement`，但它用独立工作目录，不改本轮的请求日志文件，也不占用本轮预留的网关进程。本轮仍用下面的共享检出。

更新时间：2026-10-23T15:29:00+08:00（T-03、T-04 接管前已逐文件复核）

| 仓库 | 产品检出路径 | 隔离方式 | 分支 | HEAD | 接管前状态 | 本轮涉及的文件 |
|---|---|---|---|---|---|---|
| `adx-bff-backend` | `/Users/mrzater/docker/adx/adx-bff-backend` | 共享检出 | `main` | `53ca7113dca4ecc21752361b2edcba025c3e5374` | 规划时 `git status --short` 为空；不是任务接管基线 | `src/proxy/http-passthrough.service.ts`、`src/request-logs/request-log-hooks.ts`、`src/request-logs/trace-context.ts`、`src/request-logs/redis-log-store.ts` 及范围内测试 |
| `adx-bff-frontend` | `/Users/mrzater/docker/adx/adx-bff-frontend` | 共享检出 | `main` | `0695d75f5ec93b16b530454b12f0a49f54c56a5f` | 规划时 `git status --short` 为空；不是任务接管基线 | 请求查询列表、详情和时间轴的范围内文件及测试 |

## 接管前 dirty 明细

T-01 开始前，`adx-bff-backend` 分支 `main`，HEAD `53ca7113dca4ecc21752361b2edcba025c3e5374`。下面这些文件的 `git status --short` 都是空的，没有未提交改动：

- `src/proxy/http-passthrough.service.ts`
- `src/proxy/http-passthrough.service.spec.ts`
- `src/request-logs/request-log-hooks.ts`
- `src/request-logs/request-log-hooks.spec.ts`
- `src/request-logs/trace-context.ts`

本任务不改前端。001～004 都是 `done`。006 用的是另一套目录。

T-03 开始前，`adx-bff-backend` 仍是分支 `main`，HEAD `53ca7113dca4ecc21752361b2edcba025c3e5374`。`src/request-logs/redis-log-store.ts` 和 `src/request-logs/redis-log-store.spec.ts` 的 `git status --short` 是空的。同一仓库里 T-01、T-02 改过的 6 个文件当时已有未提交改动，没有覆盖。

T-04 开始前，`adx-bff-frontend` 分支 `main`，HEAD `0695d75f5ec93b16b530454b12f0a49f54c56a5f`。下面 5 个文件的 `git status --short` 都是空的：

- `src/features/request-logs/RequestQueryPage.tsx`
- `src/features/request-logs/request-logs-table.util.tsx`
- `src/features/request-logs/request-log-timeline.util.ts`
- `src/features/request-logs/RequestLogLifecycleTimeline.tsx`
- `src/features/request-logs/request-log-timeline.util.spec.ts`

## 运行资源

本机网关已有用户运行的进程，本轮不在规划阶段重启、接管或变更它。正式性能基线/复测前确认测试环境、版本和独占窗口；服务启停及测试数据写入另行取得授权。

| 资源标识 | 占用方式 | 用途 |
|---|---|---|
| `bff-sso-local-gateway-runtime` | 独占 | 预留优化前后同版本条件的 BFF 性能采样及功能回归；尚未接管现有进程 |
| `bff-sso-test-runtime-package` | 独占 | 预留切包、白名单、非法路径等可控测试夹具；尚未改写，禁止改用户现有包 |
| `bff-sso-test-upstream` | 独占 | 预留固定响应和流式响应对照；尚未启动，不改真实上游业务 |
