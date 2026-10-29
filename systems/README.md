# 项目

这里的「项目」是一套系统，不是某一个代码仓库。一套系统里可以只有一个仓库，也可以有好几个。仓库的绝对路径写在 `overview.md`，迭代目录里不放源码。默认使用真实仓库，未提交修改不触发隔离；只有另一 `implement` 或 `verify` 轮次使用同一仓库时，临时 Git worktree 才由根目录脚本放进 `.worktrees/`，不放进任何系统目录，并在轮次收口时清理。

标准和模版在总目录，不跟某一套系统绑死。在本目录启动 Agent 时，[AGENTS.md](./AGENTS.md) 会引导它使用 [00-register-system](../prompts/00-register-system.md)。取得写入授权后，从 [system-template](../system-template) 创建新系统。

| 一套系统里有什么 | 作用 |
|---|---|
| `AGENTS.md` | 从系统目录启动 Agent 时自动恢复上下文 |
| `overview.md` | 这套系统做什么、各仓库的绝对路径、不能破的边界 |
| `agent/README.md` | 说明每个 Agent 会话如何绑定一个轮次；不保存会被并发覆盖的全局当前指针 |
| `knowledge-base` | 绝对路径软链接，指向这套系统自己的文档目录 |
| `iterations/` | 这套系统自己的各轮迭代，文件夹名带序号。某一轮可以再带自己的 `knowledge-base/`，没有就不建 |

## 当前登记

| 系统 | 说明 |
|---|---|
| [bff-sso](./bff-sso/overview.md) | 登录、账号权限、请求转发 |
| [mediatom](./mediatom/overview.md) | Mediatom 广告聚合管理后台的页面和接口 |
| [mergex-manager](./mergex-manager/overview.md) | MergeX 管理端的前端、接口和定时任务 |
