# mediatom

这套系统是 Mediatom 广告聚合管理后台。媒体开发者和平台运营从 `mediatom-web` 进入，接口、定时任务和开放接口由 `mediatom-manager` 提供。

## 包含的仓库

只在下表登记绝对路径。创建系统前必须只读确认路径真实存在。

| 仓库 | 绝对路径 | 职责 | 常用检查命令 |
|---|---|---|---|
| `mediatom-manager` | `/Users/mac/Documents/yidian/mediatom/mediatom-manager` | Spring Boot 管理端接口、定时任务和开放接口。Maven 包名是 `saas-manager-server` | `mvn -DskipTests test-compile`。Surefire 配置为跳过测试，定向测试命令待确认 |
| `mediatom-web` | `/Users/mac/Documents/yidian/mediatom/mediatom-web` | Vue 2 管理端。本系统只改 Mediatom 页面 `src/views` | `pnpm test:unit`；`pnpm lint`；`pnpm check:imports:mediatom` |

## 系统边界

- 只改 Mediatom 页面和 `mediatom-manager`。同一前端仓库里的 MergeX 页面（`src/viewsForManage`）不归这套系统。
- 落库、改数、删数只动测试数据，不动正式数据。定时任务也一样。
- 数据库迁移脚本所在目录待确认。确认前不新增迁移。前端不迁库。配置留在各自仓库。
- 不把密码、令牌、数据库连接串或环境地址写进系统说明。

## 知识库

这套系统的知识库是 [Mediatom 系统总览](./knowledge-base/handover/01-system-overview.md)。真实目录在 `/Users/mac/Documents/yidian/mediatom/docs`。这里的 `knowledge-base` 是指向该目录的绝对路径软链接，不是另一份文档。

## 迭代

下面是由各轮 `status.md` 和 `stage-approvals.md` 自动生成的只读视图。它方便查看全局进度与审批门禁，但不作为状态源，也不要手工编辑表格内容。

<!-- iteration-status-view:start -->
| 轮次 | 主题 | phase | work_state | approval_gate | updated_at | next_action |
|---|---|---|---|---|---|---|
<!-- iteration-status-view:end -->
