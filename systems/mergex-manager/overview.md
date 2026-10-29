# mergex-manager

这套系统是 MergeX 管理端。页面从 `mediatom-web` 进入，接口由 `mergex-manager` 提供，定时任务在 `mergex-datasyn`。

## 包含的仓库

只在下表写绝对路径。迭代目录里不放源码，也不做指向仓库的文件夹快捷方式。

| 仓库 | 绝对路径 | 职责 | 常用检查命令 |
|---|---|---|---|
| `mediatom-web` | `/Users/mrzater/project/mediatom-web` | MergeX 管理端页面。同一仓库里还有 Mediatom 页面，本系统不改那一半 | `pnpm test:unit`；`pnpm lint`；`pnpm check:imports:mergex` |
| `mergex-manager` | `/Users/mrzater/java/mergex-manager` | MergeX 管理端接口。管理端的数据库脚本也在这个仓库 | 待确认 |
| `mergex-datasyn` | `/Users/mrzater/java/mergex-datasyn` | MergeX 定时任务。同步、清理、报表推送都在这里，自己的建表脚本也留在这个仓库 | 待确认 |

## 系统边界

- 只改 MergeX 页面、管理端接口和定时任务。不改 Mediatom 页面，也不收 React 前端。
- 落库、改数、删数只动测试数据，不动正式数据。定时任务也一样。
- 管理端的表只在 `mergex-manager` 迁移。定时任务自己的建表脚本留在 `mergex-datasyn`，不挪到管理端。前端不迁库。
- 页面接口以 `mergex-manager` 为准。配置留在各自仓库，不把地址、密码或令牌写进系统说明。

## 知识库

这套系统的知识库是 [MergeX平台](./knowledge-base/00-MergeX平台业务知识库索引.md)。真实目录在 `/Users/mrzater/Documents/Obsidian Vault/平台知识库/MergeX平台`。这里的 `knowledge-base` 是指过去的绝对路径软链接，不是另一份文档。

## 迭代

下面是由各轮 `status.md` 和 `stage-approvals.md` 自动生成的只读视图。它方便查看全局进度与审批门禁，但不作为状态源，也不要手工编辑表格内容。

<!-- iteration-status-view:start -->
| 轮次 | 主题 | phase | work_state | approval_gate | updated_at | next_action |
|---|---|---|---|---|---|---|
| [001-2026-10-26-流量广告位下拉改查](./iterations/001-2026-10-26-%E6%B5%81%E9%87%8F%E5%B9%BF%E5%91%8A%E4%BD%8D%E4%B8%8B%E6%8B%89%E6%94%B9%E6%9F%A5/status.md) | 流量广告位下拉改查 | done | done | 双审批通过 | 2026-10-27T14:45:38+08:00 | 无 |
| [002-2026-10-27-BFF密钥和用户编号登录](./iterations/002-2026-10-27-BFF%E5%AF%86%E9%92%A5%E5%92%8C%E7%94%A8%E6%88%B7%E7%BC%96%E5%8F%B7%E7%99%BB%E5%BD%95/status.md) | BFF密钥和用户编号登录 | done | done | 双审批通过 | 2026-10-27T18:57:50+08:00 | 无 |
| [003-2026-10-27-下拉权限和鲲鹏空结果](./iterations/003-2026-10-27-%E4%B8%8B%E6%8B%89%E6%9D%83%E9%99%90%E5%92%8C%E9%B2%B2%E9%B9%8F%E7%A9%BA%E7%BB%93%E6%9E%9C/status.md) | 下拉权限和鲲鹏空结果 | done | done | 双审批通过 | 2026-10-27T18:52:00+08:00 | 无 |
| [004-2026-10-27-广告源标准化和利润价格过滤](./iterations/004-2026-10-27-%E5%B9%BF%E5%91%8A%E6%BA%90%E6%A0%87%E5%87%86%E5%8C%96%E5%92%8C%E5%88%A9%E6%B6%A6%E4%BB%B7%E6%A0%BC%E8%BF%87%E6%BB%A4/status.md) | 广告源标准化和利润价格过滤 | done | done | 双审批通过 | 2026-10-27T19:51:30+08:00 | 本轮无后续动作。 |
| [005-2026-10-28-流量筛选移植到广告位和广告平台](./iterations/005-2026-10-28-%E6%B5%81%E9%87%8F%E7%AD%9B%E9%80%89%E7%A7%BB%E6%A4%8D%E5%88%B0%E5%B9%BF%E5%91%8A%E4%BD%8D%E5%92%8C%E5%B9%BF%E5%91%8A%E5%B9%B3%E5%8F%B0/status.md) | 流量筛选移植到广告位和广告平台 | done | done | 双审批通过 | 2026-10-29T11:35:14+08:00 | 无 |
<!-- iteration-status-view:end -->
