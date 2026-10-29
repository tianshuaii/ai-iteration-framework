# 改动范围

仓库绝对路径写在这套系统的 `overview.md`，按那个路径打开原来的仓库。系统名：`bff-sso`。

## 要改的项目

| 项目 | 这一轮它负责什么 |
|---|---|
| `adx-bff-frontend` | 接口项目选择类型并保存原接口 Apifox 项目 ID；HTTP 用「导入接口」；接入服务显示出通信方式，新建默认 HTTP。 |
| `adx-bff-backend` | 保存接口类型和来源 ID；从 Apifox 拉原始接口并做差异；HTTP 转发和连通测试。只同步模型，不在这里做迁移。 |
| `adx-admin-backend` | 给接口项目加 `interface_kind`、`source_apifox_project_id`，给接入服务的传输类型加上 `http`。只在这里做迁移。 |

## 页面上要改的位置

### 接口项目 `InterfaceProjectPage.tsx`

| 位置 | 现在 | 改完 |
|---|---|---|
| 页头说明 | 创建时可临时传入 Proto 地址，地址不入库 | 新建默认 HTTP。HTTP 填写原接口 Apifox 项目 ID，只保存不拉取。gRPC 仍可填 Proto 地址 |
| 列表 | 没有接口类型和来源项目 | 增加「接口类型」「原接口 Apifox 项目 ID」。gRPC 的来源项目显示 `-` |
| 新建弹窗 | 项目编码、名称、描述、可选 Proto URL。没有失焦校验和 `colon={false}` | 增加接口类型，默认 HTTP。HTTP 显示必填的原接口 Apifox 项目 ID，隐藏 Proto URL。gRPC 反过来。表单补上 `validateTrigger={['onChange','onBlur']}`、`colon={false}`，有标签的必填出星 |
| 编辑弹窗 | 名称、描述、状态 | 类型只展示，不能改。HTTP 可改原接口 Apifox 项目 ID，保存不拉取。同样补上失焦校验和 `colon={false}` |

### 原接口文档 `OpenapiUpstreamPage.tsx`

| 位置 | 现在 | 改完 |
|---|---|---|
| 页头说明 | 写的是导入 Proto | HTTP 项目写成「导入接口」。gRPC 项目保持「导入 Proto」 |
| 空状态 | 提示点击「导入 Proto」 | HTTP 项目提示「导入接口」。gRPC 项目保持原句 |
| 右上角按钮和弹窗 | 「导入 Proto」，要填 Proto 入口地址 | HTTP 为「导入接口」，不填地址，用项目上已保存的 ID，拉完给出和现有原接口的差异。gRPC 弹窗不变 |
| 列表列 | 有 gRPC 方法名时显示方法名，否则显示方法和路径 | 保持这个规则。HTTP 显示方法和路径，gRPC 显示 gRPC 方法 |

### 项目分支 `InterfaceBranchPage.tsx`

| 位置 | 现在 | 改完 |
|---|---|---|
| 导入按钮和弹窗 | 「导入 Proto」，要填 Proto 地址 | 与原接口文档同一规则：HTTP 为「导入接口」且不填地址；gRPC 仍填 Proto 地址 |
| 失败提示 | 「导入 Proto 失败」 | HTTP 改成「导入接口失败」。gRPC 保持原句 |

### 整合步骤 `CompositeOrchestrationPanel.tsx`

| 位置 | 现在 | 改完 |
|---|---|---|
| 没有原接口时的提示 | 「请先导入 Proto 或 OpenAPI」 | HTTP 项目写成请先「导入接口」。gRPC 保持导入 Proto。选择步骤的方式不另做一套 |

### 接入服务 `ResourcePage.tsx`

| 位置 | 现在 | 改完 |
|---|---|---|
| 页头说明 | 没写通信方式 | 补上新建默认 HTTP，原始接口在接口项目维护 |
| 筛选 | 没有通信方式 | 增加通信方式，可选 HTTP、gRPC、全部 |
| 列表 | 没有通信方式列 | 增加「通信方式」 |
| 新建弹窗 | 通信方式隐藏，固定 `grpc` | 显示通信方式，默认 HTTP。不增加原接口 Apifox 项目 ID |
| 编辑弹窗 | 同上，按记录回显时也被藏起来 | 回显 `http` 或 `grpc`。平台内建 SSO 的通信方式不可改 |
| 原有 Apifox 项目 ID | 可空，说明是推送服务接口包 | 位置和是否必填不变。说明仍是推送正在使用的运行包，不要写成拉原始接口 |

### 连通测试 `ServiceConnectivityModal.tsx`

| 位置 | 现在 | 改完 |
|---|---|---|
| 结果说明 | 按发现方式展示，探测走 gRPC | HTTP 记录写成 HTTP 探测，不出现「按 gRPC 探测」。gRPC 记录保持现在的说法 |

## 大致文件

### adx-bff-frontend

- `src/features/interface-version/InterfaceProjectPage.tsx`
- `src/features/interface-version/InterfaceBranchPage.tsx`
- `src/features/openapi/OpenapiUpstreamPage.tsx`
- `src/features/openapi/components/CompositeOrchestrationPanel.tsx`
- `src/features/resources/ResourcePage.tsx`
- `src/features/resources/ServiceConnectivityModal.tsx`
- `src/lib/admin-api.ts`：请求类型补上 `interfaceKind`、`sourceApifoxProjectId`，以及接入服务的 `transportType: 'http' | 'grpc'`
- `src/lib/service-list-filter.util.ts`：列表筛选增加通信方式。不改绑定环境和地址换行。

### adx-bff-backend

- `prisma/schema.prisma`：同步 `InterfaceKind`、`sourceApifoxProjectId`，以及 `SubServiceTransport` 的 `http`。不在这个仓库执行迁移。
- `src/interface-version/dto/interface-version.dto.ts`
- `src/interface-version/interface-version.controller.ts`
- `src/interface-version/interface-version.module.ts`：注册导入服务，并引入已有的 Apifox 模块。不改推送流程。
- `src/interface-version/services/project.service.ts`
- `src/interface-version/services/import-proto.service.ts`：gRPC 导入保持。HTTP 不走进这个解析。
- `src/interface-version/services/import-apifox.service.ts`：新增。按项目上的 `sourceApifoxProjectId` 拉全部原始接口，写入工作区并给出差异。
- `src/apifox/apifox.client.ts`：在现有推送之外，增加按项目导出 OpenAPI。地址和令牌用现有配置。
- `src/admin/dto/admin.dto.ts`
- `src/admin/admin.service.ts`：保存 `transportType`。拒绝接入服务请求里的 `sourceApifoxProjectId`。
- `src/admin/sub-service-connectivity.service.ts`
- `src/admin/sub-service-connectivity.types.ts`：HTTP 探测单独返回，不写进 gRPC 结果
- `src/proxy/proxy.service.ts`
- `src/nacos/nacos-target.resolver.ts`
- `src/nacos/nacos-host.util.ts`：HTTP 目标使用 metadata 的 `httpPort`。

### 补测试

- `src/interface-version/services/project.service.spec.ts`
- `src/interface-version/services/import-apifox.service.spec.ts`：没有这个文件就新增。
- `src/proxy/proxy.service.spec.ts`
- `src/admin/sub-service-connectivity.service.spec.ts`

### adx-admin-backend

- `prisma/schema.prisma`：与 BFF 同步上述枚举和列。
- `prisma/migrations/` 下新增一份迁移：已有接口项目写成 `grpc` 且来源 ID 为空；已有接入服务的传输类型保持 `grpc`；传输类型允许 `http`。

## 明确不动

| 项目 | 为什么不动 |
|---|---|
| `adx-sso-backend` | 验密码和 SSO 模型不在这一轮。 |
| `adx-admin-frontend` | 账号管理页不管接口接入。 |
| 接入服务上的 `apifoxPushProjectId` 推送流程 | 仍把正在使用的运行包推到另一个 Apifox 项目。不改成拉取来源。`src/runtime-interface/services/runtime-apifox-target.service.ts` 这一轮不改，只用来回归确认它仍先用接入服务上的 ID。 |
| `adx-bff-backend` 的迁移目录 | 这套表只在账号后端迁移。 |
