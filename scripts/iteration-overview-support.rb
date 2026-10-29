#!/usr/bin/env ruby

# 本模块只把各轮 status.md 投影到系统 overview.md，不创造新的状态事实。
# status.md 仍是唯一权威来源；总览中的表格只是可重新生成的只读视图。
# 创建脚本、手工刷新入口和校验器复用同一份渲染逻辑，避免三套格式漂移。
# 所有路径都由调用方传入并在系统目录内解析，不硬编码系统名或轮次名。
# Markdown 单元格和链接标签统一转义，避免用户主题或下一步破坏表格结构。
# 写入只替换两个固定标记之间的内容，不触碰系统职责、仓库和边界说明。
# 临时文件与 overview.md 位于同一目录，最终 rename 保证读者不会看到半张表。

require "pathname"
require "tempfile"
require_relative "stage-approval-support"

# 迭代总览的生成与校验契约集中在一个命名空间内。
module IterationOverview
  # 起止标记限定脚本唯一可写的 overview.md 区域。
  START_MARKER = "<!-- iteration-status-view:start -->"
  END_MARKER = "<!-- iteration-status-view:end -->"
  # 投影只读取恢复工作真正需要的状态字段，不复制 checkpoint 等长文本。
  VIEW_FIELDS = %w[phase work_state updated_at next_action].freeze
  # 表头也是稳定契约，校验器据此发现手工改动或旧格式残留。
  TABLE_HEADER = "| 轮次 | 主题 | phase | work_state | approval_gate | updated_at | next_action |"
  # 分隔行与表头保持七列，避免 Markdown 渲染器错列。
  TABLE_SEPARATOR = "|---|---|---|---|---|---|---|"

  # 读取 status.md 中固定的列表字段；正文示例不会被误认成当前值。
  def self.readStatusFields(statusPath)
    # 文件缺失时返回空字段，严格刷新会给出明确错误，校验器仍可继续汇总。
    content = statusPath.file? ? statusPath.read : ""
    # 每个字段独立解析，避免字段顺序变化导致整张表无法生成。
    VIEW_FIELDS.to_h do |fieldName|
      # 字段名经过转义，未来扩展时不会把正则字符当语法。
      match = content.match(/^- #{Regexp.escape(fieldName)}:\s*(.+)$/)
      # 去除首尾空白，让投影视图保持稳定、可重复生成。
      [fieldName, match&.captures&.first&.strip]
    end
  end

  # Markdown 表格中的换行和竖线必须转义，否则会制造额外列。
  def self.escapeCell(value)
    # 空值保留为空，严格模式会在渲染前拒绝缺失字段。
    value.to_s.gsub("|", "\\|").gsub(/\s+/, " ").strip
  end

  # 链接标签单独转义方括号，防止轮次名截断 Markdown 链接文本。
  def self.escapeLinkLabel(value)
    # 反斜线必须先转义，避免随后添加的转义符被原文本吞掉。
    value.to_s.gsub("\\", "\\\\").gsub("[", "\\[").gsub("]", "\\]")
  end

  # 链接路径段使用 UTF-8 百分号编码，避免空格、括号或井号改变 Markdown 语义。
  def self.encodePathSegment(value)
    # 按字节编码能稳定处理中文；RFC 3986 非保留字符保持可读。
    value.to_s.encode("UTF-8").bytes.map do |byte|
      # ASCII 字母、数字、短横线、点、下划线和波浪线不需要转义。
      character = byte.chr
      # 其他字节统一写成大写十六进制，结果不再包含 Markdown 特殊字符。
      character.match?(/[A-Za-z0-9\-._~]/) ? character : format("%%%02X", byte)
    end.join
  end

  # 文件夹前缀固定为编号和完整日期，剩余部分才是用户主题。
  def self.iterationTheme(iterationName)
    # 正则一次吞掉 YYYY-MM-DD，避免把日期最后一天误放进主题。
    match = iterationName.match(/\A\d{3,}-\d{4}-\d{2}-\d{2}-(.+)\z/)
    # 捕获组保留主题内部的全部短横线；非标准历史目录回退显示全名。
    match ? match[1] : iterationName
  end

  # 根据全部轮次 status.md 生成一个确定性的 Markdown 管理块。
  def self.render(systemPath, strict: true)
    # 调用方可传字符串或 Pathname，统一展开后再访问固定 iterations/。
    normalizedSystemPath = Pathname.new(systemPath).expand_path
    # 只读取直接子目录，软链接不能把投影带到系统目录之外。
    iterationPaths = normalizedSystemPath.join("iterations").children
      .select(&:directory?)
      .reject(&:symlink?)
      .sort_by { |path| path.basename.to_s }
    # 固定头部保证空系统也拥有一张结构完整、可校验的表。
    lines = [START_MARKER, TABLE_HEADER, TABLE_SEPARATOR]
    # 每个真实轮次恰好生成一行，overview 不再依赖 Agent 手工补登记。
    iterationPaths.each do |iterationPath|
      # 轮次名同时用于显示和相对链接，不从状态正文猜测目录身份。
      iterationName = iterationPath.basename.to_s
      # 状态字段只从该轮自己的 status.md 读取。
      fields = readStatusFields(iterationPath.join("status.md"))
      # 手工刷新拒绝发布缺字段的视图，避免把损坏档案伪装成空状态。
      missingFields = VIEW_FIELDS.select { |fieldName| fields[fieldName].nil? || fields[fieldName].empty? }
      # 校验器使用非严格模式继续收集其他结构错误，刷新入口则立即停止。
      raise "#{iterationName}/status.md 缺少投影字段：#{missingFields.join(', ')}" if strict && !missingFields.empty?
      # 链接直接指向权威 status.md，用户可从总览进入详细断点。
      encodedIterationName = encodePathSegment(iterationName)
      # 目标路径完成百分号编码后不再需要依赖尖括号兼容特殊字符。
      iterationLink = "[#{escapeLinkLabel(iterationName)}](./iterations/#{encodedIterationName}/status.md)"
      # 审批门禁从耐久审批记录和当前文档摘要实时推导，不复制另一份状态。
      approvalGate = StageApproval.gateState(iterationPath, fields["phase"])
      # 主题、动态字段和门禁逐格转义后写入只读投影。
      rowValues = [iterationLink, iterationTheme(iterationName), fields["phase"], fields["work_state"], approvalGate, fields["updated_at"], fields["next_action"]]
      # 行首尾保留标准 Markdown 管道符，便于人读和精确校验。
      lines << "| #{rowValues.map { |value| escapeCell(value) }.join(' | ')} |"
    end
    # 管理块结尾保留换行，替换后与后续正文自然分隔。
    ([*lines, END_MARKER].join("\n") + "\n")
  end

  # 从 overview.md 中定位唯一管理块，供刷新和校验共同使用。
  def self.extractManagedBlock(content)
    # 标记数量不为一时不能判断哪个区域可安全覆盖。
    return nil unless content.scan(START_MARKER).length == 1 && content.scan(END_MARKER).length == 1
    # 非贪婪匹配只覆盖当前管理块，不吞掉后面的稳定说明。
    content[/#{Regexp.escape(START_MARKER)}.*?#{Regexp.escape(END_MARKER)}\n?/m]
  end

  # 原子刷新系统 overview.md 中的只读投影视图。
  def self.refresh(systemPath)
    # overview 固定属于系统根目录，不接受调用方传入任意目标文件。
    normalizedSystemPath = Pathname.new(systemPath).expand_path
    # 缺少系统入口时停止，不能新建一份不完整说明。
    overviewPath = normalizedSystemPath.join("overview.md")
    raise "系统缺少 overview.md：#{overviewPath}" unless overviewPath.file?
    # 只允许替换模板预留的管理块，防止脚本猜位置改坏人工内容。
    originalContent = overviewPath.read
    managedBlock = extractManagedBlock(originalContent)
    raise "overview.md 缺少唯一迭代状态视图标记" unless managedBlock
    # 在写临时文件前完整生成新块，任何状态错误都不会触碰原文件。
    refreshedContent = originalContent.sub(managedBlock, render(normalizedSystemPath, strict: true))
    # 内容完全一致时不重写文件，减少无意义的 mtime 变化和并发编辑冲突。
    return overviewPath if refreshedContent == originalContent
    # 临时文件放在同目录，rename 在同一文件系统内原子替换。
    Tempfile.create([".overview-", ".md"], overviewPath.dirname.to_s) do |temporaryFile|
      # 一次写入完整内容并刷到磁盘，再暴露给其他 Agent。
      temporaryFile.write(refreshedContent)
      temporaryFile.flush
      temporaryFile.fsync
      # 保留原文件权限，避免刷新意外改变协作访问范围。
      temporaryFile.chmod(overviewPath.stat.mode & 0o777)
      # rename 后临时路径消失，Tempfile 收尾不会删除新 overview。
      File.rename(temporaryFile.path, overviewPath)
    end
    # 返回路径便于命令行入口打印可核实结果。
    overviewPath
  end
end
