# 测试记录

自动测试：

- T-01，2026-10-23，在 `adx-admin-backend` 用 `rg -n "public_path" prisma/schema.prisma prisma/migrations` 能看到项目列、运行包列和两张白名单表。两边 Prisma 模型都能通过语法检查。迁移文件已写好，没有执行。

- T-02，2026-10-23，在 `adx-bff-backend` 执行 `pnpm test -- src/interface-version/services/project.service.spec.ts`，7 条通过。缺路径、`one`、斜杠、重复路径、白名单对不上原接口都会失败。
- T-03，2026-10-23，在 `adx-bff-backend` 执行 `pnpm test -- src/runtime-interface/services/runtime-package-inventory.service.spec.ts`，通过。旧包没有快照时类型为空、白名单为空；有快照时原样返回。
- T-04，2026-10-23，在 `adx-bff-backend` 执行 `pnpm test -- src/proxy/http-passthrough.service.spec.ts`，4 条通过。两台服务拒绝、白名单不登录且没有超时、非白名单要登录、对不上原接口不请求上游。
- T-05、T-06，2026-10-23，在 `adx-bff-frontend` 对接口项目页、服务接口包页、查看抽屉和 `admin-api.ts` 执行 eslint，没有警告。

验收时重跑，仓库 `adx-bff-backend`，HEAD `186ec23`，测的是当前工作区（还有未提交改动）。时间 `2026-10-23T12:54:11+08:00` 到 `2026-10-23T12:54:14+08:00`。没有 CI 链接。

- `pnpm test -- src/interface-version/services/project.service.spec.ts`，退出码 0，7 条通过。
- `pnpm test -- src/proxy/http-passthrough.service.spec.ts`，退出码 0，4 条通过。
- `pnpm test -- src/runtime-interface/services/runtime-package-inventory.service.spec.ts`，退出码 0，4 条通过。

手工用例：未跑。2026-10-23T12:57:08+08:00 在 `adx-admin-backend` 执行 `pnpm prisma:migrate`，只应用了 `20261023123400_http_public_path_and_whitelist`，退出码 0。已有 4 个未删除接口项目的唯一路径都是空。两张白名单表已建好。

## 返工历史

2026-10-23T13:11:38+08:00 重启网关时进程退出。直通路由写成 `:publicPath/*rest`，Fastify 报 `Wildcard must be the last character in the route`。3000 和 5003 没有起来。受影响的是 TC-01 到 TC-10 的执行环境，当时都还是未测。修复任务是 T-07。

T-07，2026-10-23T13:21:51+08:00。直通路由改成 `/proxy/:publicPath/*`，GET、POST、PUT、DELETE 各挂一次。`pnpm test -- src/proxy/http-passthrough.service.spec.ts` 退出码 0，4 条通过。网关重新启动成功，日志里这四个方法和原来的 `/proxy/one`、`/proxy/batch` 都在。

T-08，2026-10-23T13:48:35+08:00。白名单从新建、编辑弹窗拿掉，菜单「接口白名单」放在「原接口文档」下面。`pnpm exec eslint --max-warnings 0` 检查了项目页、白名单页、菜单、路由和懒加载，退出码 0。页面上：当前是还没导入原接口的 HTTP 项目时，表格提示先去导入；新建弹窗仍有唯一路径、没有白名单；编辑 HTTP 仍有唯一路径、没有白名单；编辑 gRPC 这两项都没有。

T-09，2026-10-23T14:03:00+08:00。验收时发现两处：编辑传空路径被当成不修改；白名单只查工作区，已经提交的原接口保存失败。已改成空路径会清空，白名单按默认分支当前看得到的原接口核对。`pnpm test -- src/interface-version/services/project.service.spec.ts` 退出码 0，7 条通过。网关已自动重新启动。

| 用例 | 日期 | 结果 | 现象 |
|---|---|---|---|
| TC-01 | 2026-10-23 | 通过 | 网关管理页。不填唯一路径点创建，红框提示「请填写唯一路径」，列表仍是 4 条。填 `orders` 后提示创建成功，列表出现 `tc01-orders`，唯一路径是 `orders`。 |
| TC-02 | 2026-10-23 | 通过 | 新建弹窗改成 gRPC 后没有唯一路径和白名单，只有 Proto 地址。`tc02-grpc` 创建成功，列表路径是 `-`，库里路径为空、白名单 0 条。接口带路径返回「gRPC 接口项目不保存唯一路径」，带白名单返回「gRPC 接口项目不保存白名单」。这两个请求都没有落成新项目。 |
| TC-03 | 2026-10-23 | 通过 | 用创建接口再试四次。`orders` 提示「唯一路径已被使用」，`one` 和 `batch` 提示不能使用，`a/b` 提示只能是一段路径。四次都没有新项目。`tc01-orders` 的路径仍是 `orders`。 |
| TC-04 | 2026-10-23 | 通过 | 这一轮之前的 HTTP 项目当时路径已是 `mergex`。先把路径清空，只改描述，路径仍是空，描述能保存。不登录访问一个不存在的直通路径，返回「没有唯一的生效运行包」。测完把路径和描述写回。 |
| TC-05 | 2026-10-23 | 通过 | 原接口列表 328 条，没有改造或整合。保存两条原接口成功。再夹带一条不存在的路径，整次失败，原先两条还在。页面不能手写路径。 |
| TC-06 | 2026-10-23 | 通过 | 不登录访问白名单里的路径，网关没有要登录，请求到了接入服务。另用一条会分段输出的上游，第一段约 0.3 秒到，整段约 1.8 秒才结束，没有被提前掐断。 |
| TC-07 | 2026-10-23 | 通过 | 不在白名单里、不带登录，返回「缺少访问令牌」。带上登录后请求到了接入服务。路径不在运行包里时返回「路径不在该运行包的原接口里」，上游没有收到这次请求。 |
| TC-08 | 2026-10-23 | 通过 | 取消生效包后再访问，返回「没有唯一的生效运行包」。两台接入服务同时生效同一个唯一路径时，也是这句，没有挑一台转发。对照用的项目和服务测完已删。原来的生效包已切回。 |
| TC-09 | 2026-10-23 | 通过 | 新包接口类型是 HTTP，查看里的白名单是导入时的两条。项目白名单改成一条之后，这个包的查看仍是两条。旧包在服务接口包页的接口类型是 `-`。 |
| TC-10 | 2026-10-23 | 通过 | 不带登录调用 `POST /proxy/one`，返回「缺少访问令牌」。带登录后仍是原来的 `{code,msg,data}`，业务结果在 `data` 里。 |

结果通常使用“未测”“通过”或“未通过”。只有用户明确确认时才可写“豁免”，并在现象列同时写明“用户确认”和“残余风险”；缺少任一项都不能进入 `done`。
