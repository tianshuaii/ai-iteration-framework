# 新开一轮

先读 [入口说明](./README.md)。用户明确要求新开迭代时使用本入口；同一系统可以保留其他未完成轮次，不要求先把它们标成 `done`。

## 先读

- 该系统的 `overview.md`
- [iteration-standard](../iteration-standard.md)
- `iterations/*/status.md`，用于列出已有活动轮次和取得下一个未占用序号；不得因为旧轮次未完成而拒绝新建

## 只许做

必须运行 `ruby scripts/create-iteration.rb systems/<系统> 中文主题`，并使用输出的绝对路径绑定新轮次。若当前位于系统目录，可使用等价相对路径 `ruby ../../scripts/create-iteration.rb . 中文主题`。脚本在系统目录内准备完整模板、写入真实带时区时间后才发布到 `iterations/`；同一系统的并发创建由文件锁串行化。禁止人工创建轮次目录或复制模板；脚本不可用或执行失败时停止写入并报告阻塞。

新轮次名字是 `00N-日期-中文主题`，序号接在这套系统已有轮次后面，从 `001` 起。把 `templates/` 里除 `README.md` 和 `optional-knowledge-base/` 以外的文件复制进去，包括 `scripts/`。`status.md` 初始为 `workflow_profile: standard`、`phase: specify`、`current_task: 无`、`work_state: ready`，`updated_at` 必须是真实带时区的 ISO 8601 时间，并保留“规格尚未编写”的断点和下一步；规格完成前再按复杂度调整到最低安全档位。

这一轮需要额外资料时，再把 `templates/optional-knowledge-base` 复制进来并改名为 `knowledge-base`。不需要就不要建。

## 不许做

不改 `overview.md` 里列出的仓库。不建仓库文件夹快捷方式。

## 做完

先运行 `ruby scripts/iteration-context.rb <新轮次目录>` 确认档位、阶段、断点和 `read_next`，再运行 `ruby scripts/validate-framework.rb --iteration <新轮次目录>`。局部校验只证明通用契约与新轮次有效，不代表其他历史轮次或全局状态通过；框架修改和最终治理检查仍运行无参数全局校验。停在新轮次的 `specify`，报告实际执行的创建命令、脚本已取得系统级文件锁、新轮次路径和其他活动轮次，但不创建或更新任何全局“当前轮次”指针。下一步用 [02-specify](./02-specify.md)，后续 Agent 必须明确绑定这一个新轮次。
