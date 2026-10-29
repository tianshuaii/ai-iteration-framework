# 跟踪表

| 需求要点 | 验收 | 用例 | 主要文件 |
|---|---|---|---|
| 新建 HTTP 必填唯一路径 | AC-01 | TC-01 | `InterfaceProjectPage.tsx`、`project.service.ts` |
| gRPC 不保存路径和白名单 | AC-02 | TC-02 | `project.service.ts`、`interface-version.dto.ts` |
| 路径唯一，且不能占用 `one`、`batch` | AC-03 | TC-03 | `project.service.ts`、账号后端迁移 |
| 已有 HTTP 项目可空，空则新地址拒绝 | AC-04 | TC-04 | `project.service.ts`、`src/proxy/` 直通入口 |
| 白名单只选自原接口 | AC-05 | TC-05 | `project.service.ts`、`InterfaceProjectPage.tsx` |
| 白名单直通、按流、不超时 | AC-06 | TC-06 | `src/proxy/` 直通入口 |
| 非白名单要登录，对不上拒绝 | AC-07 | TC-07 | `src/proxy/` 直通入口、`session.guard.ts` |
| 生效包必须正好一台 | AC-08 | TC-08 | `src/proxy/` 直通入口 |
| 运行包展示打包时的类型和白名单 | AC-09 | TC-09 | `runtime-package-import.service.ts`、`RuntimePackagePage.tsx`、`RuntimePackageInventoryDrawer.tsx` |
| 原转发仍要登录 | AC-10 | TC-10 | `proxy.controller.ts` |
