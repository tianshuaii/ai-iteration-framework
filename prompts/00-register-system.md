# 登记一套系统

从 `systems/` 启动并需要新增系统时使用本入口。未收到“开始执行”或“开始处理”前只做只读预检。

## 先确认

- 系统英文短横线名称及职责。
- 需要纳入的代码仓库、绝对路径和各自职责。
- 不能破坏的业务、数据、权限、迁移和部署边界。
- 是否有现成知识库目录；没有时不创建空软链接。
- 各仓库已有的测试、lint、构建或校验命令，不确定时标为待确认，不能编造。

## 写入范围

取得授权后，只创建：

1. `systems/<system>/AGENTS.md`，从 `system-template/AGENTS.md` 复制并按系统边界补充。
2. `systems/<system>/overview.md`，从 `system-template/overview.md` 填写，并完整保留迭代状态视图的起止标记；生成表不得手工填写。
3. `systems/<system>/agent/README.md`，从模板复制，说明每个 Agent 会话如何独立绑定轮次。
4. 空的 `systems/<system>/iterations/`。
5. 可选的 `systems/<system>/knowledge-base` 绝对路径软链接。
6. `systems/README.md` 的登记行。

## 禁止

- 不修改产品仓库。
- 不创建指向产品仓库的软链接或源码副本。
- 不创建第一轮迭代，除非用户同时明确要求；登记完成后默认停下。
- 不把密码、令牌、数据库连接串或环境地址写入系统说明。

## 做完

运行 `ruby scripts/validate-framework.rb`。报告新系统路径、已验证的仓库路径、未确认事项，并说明下一步入口是 [01-open-iteration](./01-open-iteration.md)。
