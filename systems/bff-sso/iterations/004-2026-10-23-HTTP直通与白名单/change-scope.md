# 改动范围

仓库绝对路径写在这套系统的 `overview.md`，按那个路径打开原来的仓库。系统名：`bff-sso`。

## 要改的项目

| 项目 | 这一轮它负责什么 |
|---|---|
| `adx-admin-backend` | 给接口项目加唯一路径，给白名单加表。只在这里做迁移。 |
| `adx-bff-backend` | 同步模型，不新增迁移。保存唯一路径和白名单。打包时把类型、路径、白名单抄进运行包。新增不设超时的 HTTP 直通。 |
| `adx-bff-frontend` | 接口项目的新建、编辑、列表。服务接口包的列表和查看。 |

## 页面上要改的位置

### 接口项目 `adx-bff-frontend/src/features/interface-version/InterfaceProjectPage.tsx`

| 位置 | 现在 | 改完 |
|---|---|---|
| 页头说明 | 新建默认 HTTP，填原接口 Apifox 项目 ID 后只保存、不拉取。gRPC 仍可填 Proto 地址。 | 保留原句，并补上：HTTP 要填唯一路径；白名单里的原接口可不登录，从这段路径直接转发。 |
| 列表 | 有接口类型、原接口 Apifox 项目 ID、状态、描述。 | 增加「唯一路径」。空的显示 `-`。 |
| 新建弹窗 | HTTP 显示原接口 Apifox 项目 ID。gRPC 显示 Proto 地址。 | HTTP 再加必填「唯一路径」。gRPC 不显示这一项，也不显示白名单。 |
| 编辑弹窗 | 接口类型只展示。HTTP 可以改原接口 Apifox 项目 ID。 | HTTP 可以改唯一路径。白名单不放在这个弹窗里。gRPC 不显示唯一路径。 |

筛选项这一页现在没有。这一轮不加筛选。

### 服务接口包 `RuntimePackagePage.tsx` 和查看抽屉 `RuntimePackageInventoryDrawer.tsx`

| 位置 | 现在 | 改完 |
|---|---|---|
| 页头 | 说明导入、生效、导出。 | 补一句：接口类型和白名单是打包时的那一份，改项目后要重新打包才变。 |
| 列表 | 描述、接口数量、Package ID、来源 Commit、导入时间、状态、操作。 | 增加「接口类型」。旧包没有记录时显示 `-`。 |
| 查看抽屉顶部 | 描述、Package ID、Digest、来源 Commit。 | 增加「接口类型」和「接口白名单」。白名单列出方法和路径；没有则显示空，不写全部放行。 |
| 操作里的查看、导出、设为生效、归档 | 保持现在的按钮。 | 不改这些按钮的动作。 |

## 大致文件

### adx-admin-backend

- `prisma/schema.prisma`：接口项目增加 `publicPath`。新增白名单表，一行一个原接口的方法和路径。
- `prisma/migrations/` 下新增一份迁移。已有项目的路径和白名单为空。不改已有行的接口类型。

### adx-bff-backend

- `prisma/schema.prisma`：同步上面的字段和表。不新增 `prisma/migrations`。
- `src/interface-version/dto/interface-version.dto.ts`：创建和修改带上 `publicPath`、`whitelist`。
- `src/interface-version/services/project.service.ts`：校验路径、拒绝 gRPC 写入这两项、白名单必须来自原接口。
- `src/interface-version/interface-version.controller.ts`：把这两个字段接进现有保存接口。
- `src/interface-version/services/package-export.service.ts`、`src/interface-version/types/ibundle-v2.types.ts`：导出的接口包带上类型、唯一路径和白名单。
- `src/runtime-interface/services/runtime-package-import.service.ts`：导入运行包时抄下这三项。
- `src/runtime-interface/services/runtime-package-inventory.service.ts`：查看接口把类型和白名单返回给页面。
- 新增直通入口和它的转发逻辑，放在 `src/proxy/`。不要把免登录挂到现有 `proxy.controller.ts` 的类级别守卫上。不在白名单里时，仍复用 `src/common/guards/session.guard.ts` 里现有的代理会话规则。
- 直通转发不调用 `src/proxy/forward-timeout.util.ts`，也不给这条请求套超时。

### adx-bff-frontend

- `src/features/interface-version/InterfaceProjectPage.tsx`：页头、列表、新建、编辑。新建和编辑都不选白名单。
- `src/features/interface-version/InterfaceWhitelistPage.tsx`：接口白名单页。只从当前项目默认分支的原接口里勾选。
- `src/components/layout/AdminLayout.tsx`：菜单放在「原接口文档」下面。
- `src/app/router.tsx`、`src/app/lazy-pages.ts`：挂上这个页面。
- `src/features/interface-version/RuntimePackagePage.tsx`：列表的接口类型，页头那一句。
- `src/features/interface-version/RuntimePackageInventoryDrawer.tsx`：查看里的类型和白名单。
- `src/lib/admin-api.ts`：请求和返回类型补上 `publicPath`、`whitelist`，以及运行包上的类型和白名单。

### 补测试

- `src/interface-version/services/project.service.spec.ts`：新建 HTTP 缺路径失败；路径重复、写成 `one` 或带斜杠失败；gRPC 带路径或白名单失败；白名单里有原接口之外的项时整次失败。
- 直通逻辑的测试：白名单不登录；非白名单要登录；两台服务同时生效失败；方法和路径对不上原接口失败；这条请求没有超时。
- `src/runtime-interface/services/runtime-package-inventory.service.ts` 旁的现有测试：查看结果带上抄下来的白名单。没有现成测试文件就新增。

## 明确不动

| 项目 | 为什么不动 |
|---|---|
| `adx-sso-backend` | 登录服务不参与这条直通。 |
| `adx-admin-frontend` | 账号管理页不配置接口项目。 |
| `src/proxy/proxy.controller.ts` 里的 `/proxy/one` 和 `/proxy/batch` | 仍一律要登录，请求体和超时保持现在这样。 |
| 接入服务页面和 `transportType` | 唯一路径、白名单不放在接入服务上。 |
| 已导入运行包的历史行 | 不回填类型和白名单。 |
