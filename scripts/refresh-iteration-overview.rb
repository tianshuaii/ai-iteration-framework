#!/usr/bin/env ruby

# 本入口从全部轮次 status.md 重新生成系统 overview.md 的只读状态视图。
# 它不修改任何轮次状态，也不接触 overview.md 登记的产品仓库。
# 目标必须是当前框架 systems/ 下的直接子目录，不能写任意 Markdown。
# 具体渲染和原子写入由共享模块完成，创建器与校验器使用同一契约。

require "pathname"
require_relative "iteration-overview-support"

# 命令只接受一个系统目录，避免隐式猜测当前系统。
abort "用法：ruby scripts/refresh-iteration-overview.rb systems/<system>" unless ARGV.length == 1
# 所有边界都从脚本位置推导，不绑定框架在本机的绝对安装路径。
frameworkRoot = Pathname.new(__dir__).join("..").realpath
# 先确认 systems/ 自身存在，再解析用户传入路径。
systemsRoot = frameworkRoot.join("systems").realpath
# 输入允许相对路径或绝对路径，但最终必须解析为真实目录。
requestedSystemPath = Pathname.new(ARGV[0]).expand_path
# 不存在的目录不能进入 realpath，先给出清晰错误。
abort "系统目录不存在：#{requestedSystemPath}" unless requestedSystemPath.directory?
# realpath 消除软链接别名，防止借链接越过 systems/ 边界。
systemPath = requestedSystemPath.realpath
# 只允许 systems/<system> 直接子目录，不接受 systems/ 本身或更深路径。
abort "目标必须是 systems/<system> 下的登记系统" unless systemPath.parent == systemsRoot
# 迭代目录是投影的唯一扫描范围，缺失说明系统登记不完整。
abort "系统缺少 iterations/：#{systemPath}" unless systemPath.join("iterations").directory?

# 刷新与新建轮次共用同一系统锁，避免两个 Agent 的总览写入互相覆盖。
lockPath = systemPath.join(".iteration-create.lock")
# 持久锁文件不存状态内容，只由操作系统对打开的描述符施加排他锁。
overviewPath = nil
# 仅当前用户可以读写锁文件，与创建脚本保持相同权限约束。
File.open(lockPath, File::RDWR | File::CREAT, 0o600) do |lockFile|
  # 外部工具可能改宽权限，每次使用都主动恢复为 0600。
  lockFile.chmod(0o600)
  # 排他锁覆盖全部 status.md 扫描和 overview 原子替换。
  lockFile.flock(File::LOCK_EX)
  # 共享模块会校验标记、字段并原子替换管理块。
  overviewPath = IterationOverview.refresh(systemPath)
end
# 输出绝对路径，方便 Agent 明确报告本次实际更新目标。
puts overviewPath
