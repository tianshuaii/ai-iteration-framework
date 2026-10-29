# 产品仓库基线

收口后临时目录已删除。网关前端路径是真实目录 `/Users/mrzater/docker/adx/adx-bff-frontend`。样式提交 `d8eca13` 已合进 `main` 并推送，合并提交是 `a91961d`。账号权限两端本来就在真实目录。

更新时间：2026-10-23T16:54:40+08:00

| 仓库 | 产品检出路径 | 隔离方式 | 分支 | HEAD | 接管前状态 | 当前任务涉及的文件 |
|---|---|---|---|---|---|---|
| `adx-bff-frontend` | `/Users/mrzater/docker/adx/adx-bff-frontend` | 共享检出 | `main` | `a91961d` | 样式提交已合进 main 并推送。main 上后来的白名单筛选和耗时拆分还在 | `src/features/` 下全部页面、弹窗和抽屉，以及 `src/styles/global.css`、`src/app/providers.tsx`、`src/components/layout/AdminLayout.tsx` |
| `adx-admin-frontend` | `/Users/mrzater/docker/adx/adx-admin-frontend` | 共享检出 | `main` | `345226f` | 改动已提交并推到 `main` | 同上，页面在账号权限自己的 `src/features/` |
| `adx-bff-backend` | `/Users/mrzater/docker/adx/adx-bff-backend` | 共享检出 | `main` | `ee616bc` | 本轮没有改后端。临时目录已删 | 无 |
| `adx-admin-backend` | `/Users/mrzater/docker/adx/adx-admin-backend` | 共享检出 | `master` | `f519c0f39f6df73f8e1943036f5e8475c703f8b0` | 本轮没有改后端 | 无 |

## 当时怎么隔离

用户 2026-10-23 同意本轮单独开工作目录。做的时候网关前端和网关后端用过临时目录，分支名是 `iteration-006-ui`。账号权限两端一直用原目录。收口并推送之后，临时目录已删除。

## 运行资源

无
