# 能力证据

本目录保存 Skills、MCP 和确定性检查产生的详细证据。索引统一写入同轮 `capability-log.md`。

- `analysis/stage-review.md`：分节保存需求审查和计划审查；两条能力日志可以索引同一文件。
- `reviews/<task-id>.md`：只保存该任务写入前的 implementation guard；任务完成时不重复做完整检查与审核。
- `reviews/implementation-review.md`：全部实现任务完成后，统一保存任务检查命令、整轮 code review、修复和复验。
- `tests/`：自动测试、手工用例及返工后的重新验证。
- `delivery/final-review.md`：合并测试验证、交付复核、同步、清理和残余风险检查。

证据不得包含密码、令牌、连接串、用户隐私或无需归档的源码全文。
