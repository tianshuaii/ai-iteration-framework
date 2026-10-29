#!/usr/bin/env ruby

# 只创建一轮规格档案，不接触登记的产品仓库或外部系统。
# 模板先在系统目录中的临时目录完成初始化，再发布到 iterations/。
# 同一系统的脚本调用使用文件锁，避免两个 Agent 同时取到相同序号。
# 创建失败时只清理由本次调用生成的临时目录，不删除已有轮次。
# 真实时间只取一次，保证目录日期和状态时间属于同一次创建。

require "fileutils"
require "pathname"
require "time"
require "tmpdir"
require_relative "iteration-overview-support"

# 所有框架路径都从脚本位置推导，不绑定本机安装位置。
frameworkRoot = Pathname.new(__dir__).join("..").realpath
# 用户必须明确给出系统目录和中文主题。
abort "用法：ruby scripts/create-iteration.rb systems/<system> 中文主题" unless ARGV.length == 2
# 展开用户输入后再确认它确实是框架下已登记的系统。
requestedSystemPath = Pathname.new(ARGV[0]).expand_path
# 主题不能含路径分隔符或控制字符，防止越出目标目录。
theme = ARGV[1]
# 中文主题至少包含一个汉字；其余字符允许常见编号与标点。
abort "主题必须包含中文且不能包含路径分隔符或控制字符" unless theme.match?(/\p{Han}/) && !theme.match?(%r{[/\\\p{Cntrl}]})
# 只有真实存在的系统目录才允许创建轮次。
abort "系统目录不存在：#{requestedSystemPath}" unless requestedSystemPath.directory?
# realpath 消除软链接，不能借别名绕过系统目录边界。
systemPath = requestedSystemPath.realpath
# 系统名来自目录，不从主题或用户自定义参数猜测。
systemsRoot = frameworkRoot.join("systems").realpath
# 拒绝系统目录之外的路径以及 systems/ 自身。
abort "目标必须是 systems/<system> 下的登记系统" unless systemPath.parent == systemsRoot
# 系统入口和迭代目录缺失说明登记尚未完成。
abort "系统缺少 AGENTS.md 或 iterations/" unless systemPath.join("AGENTS.md").file? && systemPath.join("iterations").directory?
# overview 必须先预留唯一管理块，保证发布新轮次时总览能在同一锁内刷新。
overviewPath = systemPath.join("overview.md")
# 创建前验证管理块存在，避免轮次已经发布后才发现无法更新总览。
abort "系统 overview.md 缺少唯一迭代状态视图标记" unless overviewPath.file? && IterationOverview.extractManagedBlock(overviewPath.read)

# 模板目录是唯一的新轮次文件来源。
templatesRoot = frameworkRoot.join("templates")
# 持久锁文件不包含动态进度，只用于串行化同一系统的创建。
lockPath = systemPath.join(".iteration-create.lock")
# 只给当前用户读写锁，避免把系统目录写成公共同步通道。
File.open(lockPath, File::RDWR | File::CREAT, 0o600) do |lockFile|
  # 已有锁文件可能被外部工具改宽权限，每次使用都恢复为仅当前用户可读写。
  lockFile.chmod(0o600)
  # 文件锁覆盖序号计算和最终发布，防止协作 Agent 抢同一编号。
  lockFile.flock(File::LOCK_EX)
  # 成功取得锁后才取时间，避免等待跨日时仍使用加锁前的旧日期。
  createdAt = Time.now
  # 已登记轮次按三位起始编号识别，日期和主题不参与排序。
  iterationsRoot = systemPath.join("iterations")
  # 保留既有编号；新轮次总是接在最大编号之后。
  existingNumbers = iterationsRoot.children.map { |path| path.basename.to_s[/\A(\d{3,})-/, 1]&.to_i }.compact
  # 目录名包含同一创建时间的本地日期和用户主题。
  iterationName = format("%03d-%s-%s", (existingNumbers.max || 0) + 1, createdAt.strftime("%Y-%m-%d"), theme)
  # 最终目录只能是该系统自己的 iterations/ 下的一个轮次。
  destinationPath = iterationsRoot.join(iterationName)
  # 手工已创建的同名目录不能被脚本覆盖。
  abort "轮次已存在：#{destinationPath}" if destinationPath.exist?

  # 临时目录位于同一文件系统，最终 rename 不会退化成跨盘复制。
  temporaryPath = Dir.mktmpdir(".iteration-", systemPath.to_s)
  # 发布后原临时路径已不存在，不能让 mktmpdir 的块自动清理它。
  begin
    # 只复制标准模板，可选知识库由用户按轮次需要另行建立。
    templatesRoot.children.each do |templatePath|
      # 说明文件和可选资料不是轮次本体。
      next if %w[README.md optional-knowledge-base].include?(templatePath.basename.to_s)
      # 目录和 Markdown 都复制到本次临时目录，不写产品源码。
      FileUtils.cp_r(templatePath, Pathname.new(temporaryPath).join(templatePath.basename))
    end
    # 只替换模板中唯一的时间占位符；缺少它说明模板契约已变化。
    statusPath = Pathname.new(temporaryPath).join("status.md")
    # 状态文件必须在发布前具备可解析的真实时间。
    placeholder = "YYYY-MM-DDTHH:MM:SS+08:00"
    # 拒绝未按当前模板生成的状态，而不是发布半成品。
    abort "状态模板缺少时间占位符" unless statusPath.read.include?(placeholder)
    # 一次替换不会影响状态文件中的说明文字。
    statusPath.write(statusPath.read.sub(placeholder, createdAt.iso8601))
    # 能力日志与状态使用同一创建时间，便于审计门禁从何时开始生效。
    capabilityLogPath = Pathname.new(temporaryPath).join("capability-log.md")
    # 新模板必须带独立占位符；缺失时不发布能力证据不完整的轮次。
    abort "能力日志模板缺少时间占位符" unless capabilityLogPath.file? && capabilityLogPath.read.include?(placeholder)
    # 只替换 adopted_at 的单个占位符，其他正文保持模板原样。
    capabilityLogPath.write(capabilityLogPath.read.sub(placeholder, createdAt.iso8601))
    # 最后一刻重新确认目标不存在，避免覆盖手工创建的轮次。
    abort "轮次已存在：#{destinationPath}" if destinationPath.exist?
    # 同盘改名一次发布完整轮次，不暴露占位符状态。
    File.rename(temporaryPath, destinationPath)
    # 同一系统锁内立刻重建总览，避免新轮次存在但入口仍缺行。
    begin
      # 刷新器只读取新轮状态并替换 overview 的受控管理块。
      IterationOverview.refresh(systemPath)
    rescue StandardError
      # 总览刷新失败时撤回刚发布的全新轮次，保持创建操作整体一致。
      FileUtils.remove_entry(destinationPath) if destinationPath.directory?
      # 原异常包含具体标记或字段错误，交给调用方定位。
      raise
    end
  ensure
    # 仅在创建失败且临时路径仍存在时清理本次生成的草稿。
    FileUtils.remove_entry(temporaryPath) if File.exist?(temporaryPath)
  end
  # 输出可直接绑定的绝对路径，不创建共享 current 指针。
  puts destinationPath
end
