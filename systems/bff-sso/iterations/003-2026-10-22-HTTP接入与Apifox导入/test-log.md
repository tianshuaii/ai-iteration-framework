# 测试记录

自动测试：2026-10-23 按测试策略重跑，通过。整套回归没跑。手工用例 TC-01 到 TC-09 已在页面或同一接口上看过，临时项目和临时服务已删除。没有真正把运行包推到 Apifox，也没有拿一条真实 Nacos 实例做缺少端口的调用。

- 2026-10-23 BFF `pnpm test -- src/interface-version/services/project.service.spec.ts src/interface-version/services/import-apifox.service.spec.ts src/interface-version/services/import-json.service.spec.ts src/proxy/proxy.service.spec.ts src/admin/sub-service-connectivity.service.spec.ts src/admin/dto/direct-address.spec.ts src/nacos/nacos-target.resolver.spec.ts src/runtime-interface/services/runtime-package-import.service.spec.ts`：8 套，58 条，通过。
- 2026-10-23 前端对本轮页面和 `admin-api.ts`、`service-list-filter.util.ts` 执行 `eslint --max-warnings 0`：通过。
- 2026-10-23 账号后端能找到 `source_apifox_project_id`。BFF 的迁移目录没有本轮新增文件。账号前端工作区干净。SSO 工作区有更早的未提交改动，本轮没有改那些文件。

- 2026-10-22 账号后端 `rg -n "source_apifox_project_id" prisma/schema.prisma prisma/migrations`：能找到新列。
- 2026-10-22 BFF `pnpm test -- src/interface-version/services/project.service.spec.ts`：通过。
- 2026-10-22 BFF `pnpm test -- src/interface-version/services/import-apifox.service.spec.ts`：通过。
- 2026-10-22 BFF `pnpm test -- src/proxy/proxy.service.spec.ts`：通过。
- 2026-10-22 BFF `pnpm test -- src/admin/sub-service-connectivity.service.spec.ts`：通过。
- 2026-10-22 前端对接口项目、原接口、分支、接入服务相关文件执行 `eslint --max-warnings 0`：通过。
- 2026-10-22 新建接口项目失败：库里没有 `interface_kind`。已在账号库执行迁移 `20261022213000_interface_kind_and_http_transport`，两列和 `http` 枚举都已存在。页面需要再点一次创建。
- 2026-10-22 导入后原接口页为空：文档里 328 个接口都没有 operationId，列表不显示。`import-json.service.spec.ts` 已通过。当前分支工作区已补上这 328 条，等刷新确认。
- 2026-10-22 直连地址只收 IPv4：HTTP 改为可填主机:端口或 http(s) 网址。`direct-address.spec.ts` 与 `nacos-target.resolver.spec.ts` 通过。前端 `ResourcePage.tsx` eslint 通过。账号库 `direct_address` 已是 VARCHAR(512)，迁移 `20261022221500_widen_direct_address` 已登记。
- 2026-10-23 HTTP 运行包导入看起来卡住：校验通过后逐条写 329 个接口。该包当时已经导入并生效。写入改为每层一次批量插入。`runtime-package-import.service.spec.ts` 通过。
- 2026-10-23 用已登录超管调 BFF `POST /proxy/one`，服务 `mergex-manager-api`，`GET /user/code`。HTTP 200。上游 `code=200`、`msg=success`，数据含 uuid 和验证码图片。审计记录目标路径为 `/api_test/user/code`，协议 https。

| 用例 | 日期 | 结果 | 现象 |
|---|---|---|---|
| TC-01 | 2026-10-23 | 通过 | 新建弹窗默认 HTTP，来源编号有必填星。空着保存时提示要填写 Apifox 项目 ID，窗口还在。填上示例编号 `7654321` 后保存成功。当时原接口工作区是 0 条，没有拉取。列表能看到 HTTP 和这个编号。临时项目已删除。 |
| TC-02 | 2026-10-23 | 通过 | 改成 gRPC 后不填来源编号也能保存，来源为空。原接口文档按钮是「导入 Proto」，弹窗要填 Proto 地址。同一列表里来源为空时显示 `-`。临时项目已删除。 |
| TC-03 | 2026-10-23 | 通过 | 原接口文档和项目分支的按钮都是「导入接口」，弹窗都写明不填地址。临时项目用本地文档做了两版，没有打外部 Apifox。草稿里修改、删除、新增各 1 条。这个项目没有改造和整合，第二次导入后这两层仍是空的，没有弹出确认框。临时项目已删除。 |
| TC-04 | 2026-10-23 | 通过 | 用示例编号去拉，Apifox 返回没有权限，工作区仍是 0 条。之后只改项目名称，来源编号还在，工作区仍是 0 条。 |
| TC-05 | 2026-10-23 | 通过 | 打开迁移前的 SSO 接口项目，编辑里类型是 gRPC 且下拉不能改。接口里把类型改成 HTTP 时返回「接口类型创建后不能修改」，记录仍是 gRPC、来源仍空。原接口文档按钮仍是「导入 Proto」。 |
| TC-06 | 2026-10-23 | 通过 | 新建接入服务弹窗默认 HTTP。没有「原接口 Apifox 项目 ID」。推送用的 Apifox 项目 ID 写明可空，用来推运行包。不填它也能保存。临时服务已删除。 |
| TC-07 | 2026-10-23 | 通过 | 没有改正在使用的服务。另建一条直连，地址用文档示例 `192.0.2.10:8080`。连通测试只有「HTTP 探测」，目标是 `http://192.0.2.10:8080`，没有 gRPC 探测。已有 gRPC 服务仍显示 gRPC。没有 `httpPort` 时不改用 gRPC 端口，这一条在自动测试里看到：没有该端口就返回空。没有拿真实 Nacos 实例再打。临时服务已删除。 |
| TC-08 | 2026-10-23 | 通过 | 对仍是 gRPC 的平台服务带上 method 调用，返回「gRPC 子服务转发不使用 method 字段」。平台内建服务的编辑按钮是灰的；改通信方式时返回「平台内建服务不可编辑」，类型仍是 gRPC。没有再发一次真实业务调用。 |
| TC-09 | 2026-10-23 | 通过 | 打开「推 Apifox」确认框后点了取消，没有真正推送。确认文案写的是推到接入服务上配置的 Apifox 项目。推送代码只读推送编号，不读来源编号。当前接入服务的推送编号是空的，和接口项目上的来源编号不是同一个字段。 |

结果通常使用“未测”“通过”或“未通过”。只有用户明确确认时才可写“豁免”，并在现象列同时写明“用户确认”和“残余风险”；缺少任一项都不能进入 `done`。
