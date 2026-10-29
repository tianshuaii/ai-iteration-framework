# bff-sso系统

这套系统负责认人、记登录状态，并把页面请求转到后面的服务。浏览器只访问 BFF 和两个管理页。

## 包含的仓库

只在下表写绝对路径。迭代目录里不放源码，也不做指向仓库的文件夹快捷方式，避免编辑器把源码展开到这里。

| 仓库 | 绝对路径 | 干什么 | 常用检查命令 |
|---|---|---|---|
| `adx-bff-backend` | `/Users/mrzater/docker/adx/adx-bff-backend` | 对外的后端大门 | `pnpm test` |
| `adx-bff-frontend` | `/Users/mrzater/docker/adx/adx-bff-frontend` | 网关管理页 | `pnpm test` |
| `adx-sso-backend` | `/Users/mrzater/docker/adx/adx-sso-backend` | 验密码、改密码 | `pnpm test` |
| `adx-admin-backend` | `/Users/mrzater/docker/adx/adx-admin-backend` | 账号、角色、权限落库；治理表只在这里迁移 | `pnpm test` |
| `adx-admin-frontend` | `/Users/mrzater/docker/adx/adx-admin-frontend` | 账号权限管理页 | `pnpm test` |

## 这套系统的边界

- SSO 和账号后端不对浏览器开放业务接口。
- 治理表只在 `adx-admin-backend` 迁移。BFF 和 SSO 只同步模型。
- 页面权限只控制显示，不代替后面的服务做业务判断。

## 知识库

这套系统的知识库就是 [doc](./knowledge-base/README.md)，真实目录在 `/Users/mrzater/docker/adx/doc`。这里的 `knowledge-base` 是指过去的绝对路径软链接，不是另一份文档。

## 迭代

下面是由各轮 `status.md` 和 `stage-approvals.md` 自动生成的只读视图。它方便查看全局进度与审批门禁，但不作为状态源，也不要手工编辑表格内容。

<!-- iteration-status-view:start -->
| 轮次 | 主题 | phase | work_state | approval_gate | updated_at | next_action |
|---|---|---|---|---|---|---|
| [001-2026-10-22-接入服务直连](./iterations/001-2026-10-22-%E6%8E%A5%E5%85%A5%E6%9C%8D%E5%8A%A1%E7%9B%B4%E8%BF%9E/status.md) | 接入服务直连 | done | done | 历史免追溯 | 2026-10-22T17:18:23+08:00 | 无 |
| [002-2026-10-22-平台服务直连](./iterations/002-2026-10-22-%E5%B9%B3%E5%8F%B0%E6%9C%8D%E5%8A%A1%E7%9B%B4%E8%BF%9E/status.md) | 平台服务直连 | done | done | 历史免追溯 | 2026-10-22T21:33:53+08:00 | 无 |
| [003-2026-10-22-HTTP接入与Apifox导入](./iterations/003-2026-10-22-HTTP%E6%8E%A5%E5%85%A5%E4%B8%8EApifox%E5%AF%BC%E5%85%A5/status.md) | HTTP接入与Apifox导入 | done | done | 历史免追溯 | 2026-10-23T11:46:40+08:00 | 无 |
| [004-2026-10-23-HTTP直通与白名单](./iterations/004-2026-10-23-HTTP%E7%9B%B4%E9%80%9A%E4%B8%8E%E7%99%BD%E5%90%8D%E5%8D%95/status.md) | HTTP直通与白名单 | done | done | 历史免追溯 | 2026-10-23T14:08:58+08:00 | 本轮无后续动作。 |
| [005-2026-10-23-BFF转发链路耗时优化](./iterations/005-2026-10-23-BFF%E8%BD%AC%E5%8F%91%E9%93%BE%E8%B7%AF%E8%80%97%E6%97%B6%E4%BC%98%E5%8C%96/status.md) | BFF转发链路耗时优化 | done | done | 历史免追溯 | 2026-10-23T15:46:00+08:00 | 无 |
| [006-2026-10-23-项目UI优化](./iterations/006-2026-10-23-%E9%A1%B9%E7%9B%AEUI%E4%BC%98%E5%8C%96/status.md) | 项目UI优化 | done | done | 历史免追溯 | 2026-10-23T17:20:00+08:00 | 无 |
| [007-2026-10-23-BFF转发压测与阈值报告](./iterations/007-2026-10-23-BFF%E8%BD%AC%E5%8F%91%E5%8E%8B%E6%B5%8B%E4%B8%8E%E9%98%88%E5%80%BC%E6%8A%A5%E5%91%8A/status.md) | BFF转发压测与阈值报告 | done | done | 历史免追溯 | 2026-10-23T17:16:57+08:00 | 无 |
| [008-2026-10-23-BFF首次请求冷路径耗时优化](./iterations/008-2026-10-23-BFF%E9%A6%96%E6%AC%A1%E8%AF%B7%E6%B1%82%E5%86%B7%E8%B7%AF%E5%BE%84%E8%80%97%E6%97%B6%E4%BC%98%E5%8C%96/status.md) | BFF首次请求冷路径耗时优化 | done | done | 双审批通过 | 2026-10-23T20:48:00+08:00 | 无 |
| [009-2026-10-26-Admin账户精简与密码统一](./iterations/009-2026-10-26-Admin%E8%B4%A6%E6%88%B7%E7%B2%BE%E7%AE%80%E4%B8%8E%E5%AF%86%E7%A0%81%E7%BB%9F%E4%B8%80/status.md) | Admin账户精简与密码统一 | done | done | 双审批通过 | 2026-10-26T19:48:00+08:00 | 无 |
| [010-2026-10-26-数据库Schema瘦身与无用数据清理](./iterations/010-2026-10-26-%E6%95%B0%E6%8D%AE%E5%BA%93Schema%E7%98%A6%E8%BA%AB%E4%B8%8E%E6%97%A0%E7%94%A8%E6%95%B0%E6%8D%AE%E6%B8%85%E7%90%86/status.md) | 数据库Schema瘦身与无用数据清理 | done | done | 双审批通过 | 2026-10-27T11:23:00+08:00 | 无 |
| [011-2026-10-27-BFF账号与平台账号绑定](./iterations/011-2026-10-27-BFF%E8%B4%A6%E5%8F%B7%E4%B8%8E%E5%B9%B3%E5%8F%B0%E8%B4%A6%E5%8F%B7%E7%BB%91%E5%AE%9A/status.md) | BFF账号与平台账号绑定 | done | done | 双审批通过 | 2026-10-27T12:38:55+08:00 | 无 |
| [012-2026-10-27-平台请求密钥与登录接管](./iterations/012-2026-10-27-%E5%B9%B3%E5%8F%B0%E8%AF%B7%E6%B1%82%E5%AF%86%E9%92%A5%E4%B8%8E%E7%99%BB%E5%BD%95%E6%8E%A5%E7%AE%A1/status.md) | 平台请求密钥与登录接管 | done | done | 双审批通过 | 2026-10-27T15:49:00+08:00 | 无 |
| [013-2026-10-27-浏览器跨域响应头修复](./iterations/013-2026-10-27-%E6%B5%8F%E8%A7%88%E5%99%A8%E8%B7%A8%E5%9F%9F%E5%93%8D%E5%BA%94%E5%A4%B4%E4%BF%AE%E5%A4%8D/status.md) | 浏览器跨域响应头修复 | done | done | 双审批通过 | 2026-10-27T16:30:12+08:00 | 无 |
| [014-2026-10-27-接口白名单页面体验优化](./iterations/014-2026-10-27-%E6%8E%A5%E5%8F%A3%E7%99%BD%E5%90%8D%E5%8D%95%E9%A1%B5%E9%9D%A2%E4%BD%93%E9%AA%8C%E4%BC%98%E5%8C%96/status.md) | 接口白名单页面体验优化 | done | done | 双审批通过 | 2026-10-27T18:31:01+08:00 | 无 |
| [015-2026-10-28-全链路转发缺陷排查](./iterations/015-2026-10-28-%E5%85%A8%E9%93%BE%E8%B7%AF%E8%BD%AC%E5%8F%91%E7%BC%BA%E9%99%B7%E6%8E%92%E6%9F%A5/status.md) | 全链路转发缺陷排查 | done | done | 双审批通过 | 2026-10-28T11:54:10+08:00 | 无 |
| [016-2026-10-28-Nacos配置瘦身与代码配置外置](./iterations/016-2026-10-28-Nacos%E9%85%8D%E7%BD%AE%E7%98%A6%E8%BA%AB%E4%B8%8E%E4%BB%A3%E7%A0%81%E9%85%8D%E7%BD%AE%E5%A4%96%E7%BD%AE/status.md) | Nacos配置瘦身与代码配置外置 | done | done | 双审批通过 | 2026-10-28T16:12:44+08:00 | 无 |
| [017-2026-10-29-平台无登录接口与BFF加密登录](./iterations/017-2026-10-29-%E5%B9%B3%E5%8F%B0%E6%97%A0%E7%99%BB%E5%BD%95%E6%8E%A5%E5%8F%A3%E4%B8%8EBFF%E5%8A%A0%E5%AF%86%E7%99%BB%E5%BD%95/status.md) | 平台无登录接口与BFF加密登录 | specify | blocked | 需求未审批 | 2026-10-29T11:39:28+08:00 | 等待用户确认。Q6 加密信封与长度边界：`encryptedPassword` 使用版本化混合加密信封：RSA-OAEP-256 包装随机 AES-256 密钥，AES-GCM 加密载荷；推荐回复 `Q6 按推荐做`。Q7 Redis 故障与多实例一致性：nonce 使用 Redis `SET NX EX` 原子占位；Redis 不可用时登录失败关闭；所有 SSO 实例共享密钥环和 nonce 命名空间；推荐回复 `Q7 按推荐做`。Q8 公钥获取、缓存与重试：BFF 暴露统一匿名公钥接口并从 SSO 获取；响应 `no-store`；前端每次提交前获取，密钥过期只自动刷新并重试一次；推荐回复 `Q8 按推荐做`。若全部同意，可回复 `Q6-Q8 都按推荐做`。 |
<!-- iteration-status-view:end -->
