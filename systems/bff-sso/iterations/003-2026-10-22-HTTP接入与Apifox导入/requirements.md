# 需求与注意事项：HTTP 接入与 Apifox 导入

范围见 [change-scope](./change-scope.md)。已经拍板的见 [decisions](./decisions.md)。验收见 [acceptance](./acceptance.md)。当前进度只看 [status](./status.md)。

## 背景

网关现在只按 gRPC 转发。接入服务页把通信方式藏起来，新建只能是 gRPC。转发时如果不是 gRPC，会直接拒绝。

接口项目和接入服务是分开的。建项目时可以填一个 Proto 地址，地址不入库，只用来第一次解析。「原接口文档」和「项目分支」上的更新按钮都叫「导入 Proto」。

接入服务上已经有一个 Apifox 项目 ID，用来把正在使用的运行包推到另一个 Apifox 项目。那个包里可以有改造和整合。接口项目上拉原始接口，用的不是这一个 ID。

这一轮要让网关既能打 gRPC，也能打 HTTP。HTTP 的原始接口从接口项目上配置的 Apifox 项目拉下来，后面的改造、整合、打包仍走现在这条路。

## 本次要做

### 页面

接口项目的新建、编辑弹窗是表单，要带 `validateTrigger={['onChange','onBlur']}` 和 `colon={false}`。有标签的必填项保留必填星。

#### 接口项目

新建时增加接口类型，默认 HTTP。

| 接口类型 | 接口值 | 表单上显示 | 必填 |
|---|---|---|---|
| HTTP | `http` | 原接口 Apifox 项目 ID | 必填 |
| gRPC | `grpc` | 现在的 Proto URL | 可不填 |

- 选 HTTP：隐藏 Proto URL。隐藏后的项不参与这次保存的校验。只保存项目和这个 ID，不向 Apifox 拉取。
- 选 gRPC：隐藏原接口 Apifox 项目 ID。Proto URL 仍可不填；填了就和现在一样，创建时必须解析成功，地址不入库。
- 编辑时接口类型只展示，不能改。HTTP 项目可以改原接口 Apifox 项目 ID，这次保存只改 ID，不拉取。
- 列表增加「接口类型」和「原接口 Apifox 项目 ID」。gRPC 项目这一列显示 `-`。
- 页头说明按类型写清：HTTP 新建只保存 ID；gRPC 仍可填 Proto 地址。

#### 原接口文档、项目分支

这两个页面的导入按钮跟着当前项目的接口类型走，不各自再选一次类型。

| 项目类型 | 按钮 | 弹窗 |
|---|---|---|
| gRPC | 导入 Proto | 仍要填 Proto 入口地址 |
| HTTP | 导入接口 | 不填地址。用该项目已保存的原接口 Apifox 项目 ID |

HTTP 点「导入接口」后：

- 从该 Apifox 项目拉出全部原始接口，写入当前分支的工作区，和 gRPC 导入后进工作区的方式一样。
- 和当前已有原接口比出新增、修改、删除。
- 改造和整合先出差异，等人确认再改。没确认就不要改这两层。
- 拉失败则这次不写入。不能写进一半。
- 页头、空状态里的「导入 Proto」在 HTTP 项目上改成「导入接口」。gRPC 项目保持原句。

整合步骤里「请先导入 Proto 或 OpenAPI」的空提示，HTTP 项目改成先点「导入接口」。选择步骤时 HTTP 仍按方法和路径，gRPC 仍按 gRPC 方法。不另做一套编辑页。

#### 接入服务

通信方式重新显示出来。新建默认 HTTP。老记录按库里的值回显。

- 不在这个页面增加、展示或提交原接口 Apifox 项目 ID。接入服务不保存、不读取这个 ID。
- 原来的「Apifox 项目 ID」留在原地，仍是把正在使用的运行包推到另一个 Apifox 项目，可空。说明文字保持这个用途，不要写成拉原始接口。
- 列表和筛选增加「通信方式」。
- 页头补一句：新建默认 HTTP；原始接口在接口项目里维护。
- 连通测试弹窗按这条记录的通信方式探测。HTTP 不写成 gRPC 探测。
- 平台内建 SSO 仍不能改通信方式、服务用途、启用状态。

### 接口与保存

接口项目创建、修改带上 `interfaceKind`。HTTP 的原接口项目 ID 字段名是 `sourceApifoxProjectId`。

- HTTP：`sourceApifoxProjectId` 去掉空白后必须还有内容。`interfaceKind` 写成 `http`。
- gRPC：不要求这个 ID，保存时写成数据库空值 `null`。不能用空字符串代替 `null`。
- 创建之后不能改 `interfaceKind`。请求里如果带了另一种类型，拒绝保存。
- 新建 HTTP 项目的保存接口不调用 Apifox。
- 「导入接口」只读该接口项目上的 `sourceApifoxProjectId`。不读接入服务上的 `apifoxPushProjectId`。
- 令牌和 Apifox 地址用现有配置。没配令牌或拉失败，这次导入失败，工作区保持原样。
- 导入成功后，原接口进入工作区，并给出和当前原接口的差异。改造、整合的变更仍走现在的确认后再应用。

接入服务创建、修改带上 `transportType`，取值 `http` 或 `grpc`。

- 请求里不要出现 `sourceApifoxProjectId`。出现了就拒绝，避免把原始接口项目 ID 写进接入服务。
- 原来的 `apifoxPushProjectId` 规则不变：可空，只用于推送运行包。
- 转发时先看接入服务的 `transportType`。`http` 按方法和路径打 HTTP，不读 Proto，不拼 `grpc://`。`grpc` 保持现在的做法。
- 直连且通信方式是 HTTP：把 `directAddress` 拼成 `http://ip:端口`。
- Nacos 且通信方式是 HTTP：用实例 metadata 里的 `httpPort`。没有这个端口就失败，不改用实例的 gRPC 端口。
- 正在使用的接口包和通信方式对不上时，这次转发失败。例如 HTTP 服务配了一包 gRPC 文档。

### 数据

接口项目表 `sys_interface_project` 增加：

| 页面和接口上的名字 | 库里的类型和列 | 取值 |
|---|---|---|
| `interfaceKind` | 枚举 `InterfaceKind`，列 `interface_kind` | `http` 或 `grpc`。已有行默认 `grpc` |
| `sourceApifoxProjectId` | 可空字符串，列 `source_apifox_project_id` | HTTP 必填。gRPC 为 `null`。已有行为空 |

接入服务表 `sys_sub_service` 的 `transport_type` 增加取值 `http`。已有行保持 `grpc`。列的默认值仍是 `grpc`，避免没传这个字段的旧调用把新行写成 HTTP。新建页面默认 HTTP 只是表单行为。

表结构只在 `adx-admin-backend` 做迁移。BFF 的 Prisma 模型同步这些字段，不要在 BFF 里对这套表执行迁移。

## 默认与老数据

| 场景 | 行为 |
|---|---|
| 新建接口项目 | 接口类型默认 HTTP，原接口 Apifox 项目 ID 必填。保存不拉取 |
| 新建时改选 gRPC | 不要求这个 ID，Proto URL 仍可选 |
| 现在已有的接口项目 | 迁移后是 `grpc`，原接口项目 ID 为空。仍用「导入 Proto」 |
| 编辑 HTTP 项目只改名称或 ID | 只保存。要更新接口必须再点「导入接口」 |
| 新建接入服务 | 通信方式默认 HTTP。不出现原接口 Apifox 项目 ID |
| 现在已有的接入服务 | 仍是 `grpc`。编辑时回显 gRPC，可以改成 HTTP |
| 平台内建 SSO | 通信方式保持原值，编辑时不能改 |
| 推送正在使用的运行包 | 仍用接入服务上的 `apifoxPushProjectId`，不用 `sourceApifoxProjectId` |

## 不做

- 不把原接口 Apifox 项目 ID 存到接入服务，也不让接入服务去读它。
- 不把 `sourceApifoxProjectId` 拿去推送运行包，也不改「推 Apifox」现在用的那个项目 ID。
- 不在新建 HTTP 项目时自动拉取。
- 不在只改项目名称、描述、状态或这个 ID 时自动拉取。
- 创建后不允许把一个项目从 HTTP 改成 gRPC，或反过来。要另一种类型就另建项目。
- 不改账号管理页，不改 SSO。
- 不改验密码仍走 SSO 的方式。
- 不把 Apifox 地址、令牌写进代码常量。

## 注意事项

- 文件列表见改动范围，这里不重复贴路径。
- 迁移只在 `adx-admin-backend` 执行。BFF 只同步模型。
- 文档里不写真实 Apifox 项目 ID、令牌或内网地址。示例 ID 用 `7654321` 这种明显的占位。
