#!/usr/bin/env ruby

# 本模块集中管理需求和计划的用户审批记录，避免各入口各自解释门禁。
# 审批记录不替代 status.md；它只保存用户确认及当时文档摘要的耐久证据。
# 摘要覆盖会影响实现含义的阶段文件，后续改文档会自动使旧审批失效。
# 验收结果和任务勾选属于执行期变化，规范化后不参与审批摘要。
# 历史文件名通过该轮 file-map.md 解析，不在通用逻辑里硬编码轮次。
# 所有写入都使用同目录临时文件和原子改名，避免留下半份审批记录。
# 调用方负责取得系统级锁，本模块只处理单份轮次文件的确定性内容。
# 用户证据采用确定性意图解析，支持等价自然语言但拒绝否定、疑问和假设句。
# 审批时间必须带时区，便于跨会话核对证据先后顺序。

require "digest"
require "pathname"
require "tempfile"
require "time"
require_relative "user-intent-support"

# 双审批门禁的格式、摘要和有效性检查都收敛到同一命名空间。
module StageApproval
  # 版本标记让校验器能拒绝未来无法识别的手工格式。
  # v1 保留给既有轮次；v2 把能力评审和 workspace 计划部分纳入审批门禁。
  POLICY_MARKERS = {
    "user-gates-v1" => "<!-- stage-approval-policy: user-gates-v1 -->",
    "capability-gates-v2" => "<!-- stage-approval-policy: capability-gates-v2 -->"
  }.freeze
  # 所有新轮次使用 v2；读取既有轮次时仍按文件自己的版本计算摘要。
  DEFAULT_POLICY = "capability-gates-v2"
  # workspace 仅哈希稳定计划区，运行期 HEAD、dirty 和同步结果不会使审批过期。
  WORKSPACE_SCOPE_START = "<!-- plan-approval-scope:start -->"
  # 结束标记与开始标记成对出现，避免摘要边界依赖自由文本标题。
  WORKSPACE_SCOPE_END = "<!-- plan-approval-scope:end -->"
  # 审批证据使用固定文件名，不参与历史 file-map 兼容。
  FILE_NAME = "stage-approvals.md"
  # 阶段配置同时定义标题、用户示例和摘要输入文件。
  STAGES = {
    "requirements" => {
      title: "需求审批",
      example: "开始处理，需求审批通过",
      files: %w[requirements.md decisions.md change-scope.md acceptance.md test-strategy.md test-cases.md traceability.md]
    },
    "plan" => {
      title: "计划审批",
      example: "开始处理，计划审批通过",
      files: %w[implementation-plan.md tasks.md risks.md workspace.md]
    }
  }.freeze

  # 新轮次和迁移中的活动轮次都从明确待审批状态开始。
  def self.pendingRecord
    # 每次返回新对象，防止调用方修改一个阶段时连带污染另一个阶段。
    { "status" => "pending", "approved_at" => "无", "evidence" => "无", "digest" => "无" }
  end

  # 构造两阶段的独立初始记录。
  def self.pendingRecords
    # to_h 块会对每个阶段调用一次 pendingRecord。
    STAGES.to_h { |stageName, _config| [stageName, pendingRecord] }
  end

  # 将结构化记录渲染成唯一、稳定且便于人工查看的 Markdown。
  def self.render(records, policyName: DEFAULT_POLICY)
    # 未知版本不能被写入，否则后续校验无法解释其摘要范围。
    policyMarker = POLICY_MARKERS.fetch(policyName) { raise "未知审批策略：#{policyName}" }
    # 标记和说明固定在文件顶部，字段顺序不随 Hash 插入顺序漂移。
    lines = [policyMarker, "# 阶段审批", "", "本文件只记录用户阶段审批及对应文档摘要，不替代 `status.md`。", ""]
    # 按配置顺序写需求、计划，保证摘要和测试输出可重复。
    STAGES.each do |stageName, config|
      # 缺少阶段时按 pending 补齐，避免写出结构残缺的文件。
      record = records.fetch(stageName, pendingRecord)
      # 用户证据压成单行，阻止换行意外生成伪造字段。
      evidence = normalizeEvidence(record.fetch("evidence", "无"))
      # 四个字段由解析器和校验器共同使用，名称保持英文稳定。
      lines.concat([
        "## #{config[:title]}",
        "- status: #{record.fetch('status', 'pending')}",
        "- approved_at: #{record.fetch('approved_at', '无')}",
        "- evidence: #{evidence.empty? ? '无' : evidence}",
        "- digest: #{record.fetch('digest', '无')}",
        ""
      ])
    end
    # 文件始终以一个换行结束，便于普通文本工具追加或比较。
    lines.join("\n")
  end

  # 从本轮 file-map.md 解析一个标准文件名对应的真实文件。
  def self.resolveIterationFile(iterationPath, standardName)
    # 新轮次没有映射时直接使用标准英文名。
    normalizedIterationPath = Pathname.new(iterationPath).expand_path
    # 历史映射只允许直接文件名，和框架主校验器保持相同边界。
    mapPath = normalizedIterationPath.join("file-map.md")
    # 缺少映射或目标条目时使用标准名。
    return normalizedIterationPath.join(standardName) unless mapPath.file?
    # 两列都用反引号，避免把说明正文误读成路径。
    pattern = /^\|\s*`#{Regexp.escape(standardName)}`\s*\|\s*`([^`]+)`\s*\|/
    # 读取本轮自己的映射，不搜索其他轮次。
    match = mapPath.read.match(pattern)
    # 非直接子文件的映射由主校验器拒绝；这里也避免路径逃逸。
    actualName = match ? match[1] : standardName
    # 摘要计算只允许轮次目录中的直接文件。
    raise "file-map 目标不是本轮直接文件：#{actualName}" unless actualName == File.basename(actualName) && !%w[. ..].include?(actualName)
    # 返回实际 Pathname 供摘要读取。
    normalizedIterationPath.join(actualName)
  end

  # 去掉审批后执行期允许变化的字段，保留其余规格或计划语义。
  def self.canonicalize(standardName, content, policyName: DEFAULT_POLICY)
    # v2 计划审批只保护 workspace 中的计划预留区，不锁住执行期采集结果。
    if standardName == "workspace.md"
      # v1 当时没有把 workspace 纳入摘要，兼容读取时不会走到这个分支。
      raise "workspace 计划摘要只适用于 capability-gates-v2" unless policyName == "capability-gates-v2"
      # 两个标记必须各出现一次，防止重复区块让审批对象不唯一。
      raise "workspace.md 缺少唯一计划审批范围" unless content.scan(WORKSPACE_SCOPE_START).length == 1 && content.scan(WORKSPACE_SCOPE_END).length == 1
      # 只提取含首尾标记的稳定区块，让计划修改可以可靠使旧审批失效。
      scopeMatch = content.match(/#{Regexp.escape(WORKSPACE_SCOPE_START)}.*?#{Regexp.escape(WORKSPACE_SCOPE_END)}/m)
      # 标记顺序错误时 match 为空，必须明确阻断。
      raise "workspace.md 计划审批范围顺序无效" unless scopeMatch
      # 返回唯一计划范围作为摘要输入。
      return scopeMatch[0]
    end
    # 验收表只忽略 AC 数据行最后的结果列，标准和测试关联仍参与摘要。
    if standardName == "acceptance.md"
      # 逐行处理能保留标题、正文和表头的原始内容。
      return content.each_line.map do |line|
        # 非 AC 数据行不变，避免误伤正文中普通竖线。
        next line unless line.match?(/^\|\s*AC-\d+\s*\|/)
        # 保留末尾换行所在的最后空单元格，只替换真实结果格。
        cells = line.split("|", -1)
        # 标准数据行至少包含首尾边界和四个字段。
        cells[-2] = " <execution-result> " if cells.length >= 6
        # 重新拼接后表格结构和换行仍与原文一致。
        cells.join("|")
      end.join
    end
    # 任务完成勾选属于执行进度；任务正文、依赖、文件和检查仍参与摘要。
    if standardName == "tasks.md"
      # 只归一化 Markdown 任务前缀，不改变正文中的普通方括号。
      return content.gsub(/^(\s*-\s+)\[[ xX]\]/, '\\1[ ]')
    end
    # 其他阶段文件的每个字符都属于审批对象。
    content
  end

  # 计算某个审批阶段当前文档集合的 SHA-256 摘要。
  def self.digest(iterationPath, stageName, policyName: nil)
    # 未知阶段必须显式失败，不能静默生成空摘要。
    config = STAGES.fetch(stageName) { raise "未知审批阶段：#{stageName}" }
    # 未显式传入时从轮次审批文件读取，便于验证历史 v1 记录。
    resolvedPolicy = policyName || readPolicy(iterationPath) || DEFAULT_POLICY
    # v1 的计划摘要文件集合保持原样，不能因框架升级让历史审批自动失效。
    digestFiles = resolvedPolicy == "user-gates-v1" ? config[:files] - ["workspace.md"] : config[:files]
    # 文件名和内容都进入摘要，防止两份内容相同的文件互换位置。
    digestInput = digestFiles.map do |standardName|
      # 历史轮次按自身映射读取真实文件。
      documentPath = resolveIterationFile(iterationPath, standardName)
      # 缺失文件不能得到可审批摘要。
      raise "审批摘要缺少文件：#{standardName}" unless documentPath.file?
      # NUL 分隔文件名和正文，消除简单拼接的边界歧义。
      [standardName, canonicalize(standardName, documentPath.read, policyName: resolvedPolicy)].join("\0")
    end.join("\0\0")
    # 十六进制摘要适合人工复制和 Markdown 保存。
    Digest::SHA256.hexdigest(digestInput)
  end

  # 解析固定格式的审批文件；结构损坏时返回 nil 交由校验器报告。
  def self.policyName(content)
    # 所有策略标记（包括未来未知版本）总数必须恰好为一。
    return nil unless content.scan(/<!-- stage-approval-policy:[^>]+-->/).length == 1
    # 恰好一个已知标记才具有确定版本；多个标记不能按优先级猜测。
    matches = POLICY_MARKERS.select { |_name, marker| content.scan(marker).length == 1 }
    # 未知、缺失或同时存在多个版本都返回 nil。
    matches.length == 1 ? matches.keys.first : nil
  end

  # 读取某轮审批策略，不解析审批记录本身。
  def self.readPolicy(iterationPath)
    # 审批文件路径与 read 使用同一固定名称。
    approvalPath = Pathname.new(iterationPath).expand_path.join(FILE_NAME)
    # 缺失时交给上层按迁移规则处理。
    approvalPath.file? ? policyName(approvalPath.read) : nil
  end

  # 解析固定格式的审批文件；结构损坏时返回 nil 交由校验器报告。
  def self.parse(content)
    # 版本必须唯一且已知，重复或未来版本不能被当前代码误判为有效。
    return nil unless policyName(content)
    # 每个阶段都必须有独立二级标题和四个字段。
    records = {}
    # 按已知阶段逐项解析，不接受标题相似的自由文本。
    STAGES.each do |stageName, config|
      # 同一审批标题重复出现会让人工和脚本看到不同含义，必须拒绝。
      return nil unless content.scan(/^## #{Regexp.escape(config[:title])}\s*$/).length == 1
      # 非贪婪截取到下一个二级标题或文件末尾。
      sectionMatch = content.match(/^## #{Regexp.escape(config[:title])}\s*$\n(.*?)(?=^## |\z)/m)
      # 缺少任一阶段都让整份记录无效。
      return nil unless sectionMatch
      # 四个字段必须各出现一次；内容保留为单行字符串。
      fields = %w[status approved_at evidence digest].to_h do |fieldName|
        # 每个字段也只能出现一次，防止后追加的伪字段被静默忽略。
        fieldPattern = /^- #{Regexp.escape(fieldName)}:\s*(.+)$/
        # 重复或缺失都先保存 nil，下面统一判定整份记录无效。
        fieldMatches = sectionMatch[1].scan(fieldPattern)
        # 列表项名称固定，避免正文中的同名词被误读。
        fieldValue = fieldMatches.length == 1 ? fieldMatches.first.first.strip : nil
        # 找不到或重复字段时保存 nil，下面统一拒绝。
        [fieldName, fieldValue]
      end
      # 任一字段缺失都无法证明审批状态。
      return nil if fields.values.any? { |value| value.nil? || value.empty? }
      # 保存阶段记录供有效性检查复用。
      records[stageName] = fields
    end
    # 返回完整结构化记录。
    records
  end

  # 将用户原话压成审批文件使用的稳定单行证据。
  def self.normalizeEvidence(evidence)
    # 只折叠空白，不改动中文标点和实际授权语义。
    evidence.to_s.gsub(/\s+/, " ").strip
  end

  # 判断用户原话是否明确批准指定阶段，不要求逐字匹配固定口令。
  def self.evidenceMatches?(stageName, evidence)
    # fetch 先拒绝未知阶段，避免错误参数被当成普通不匹配。
    STAGES.fetch(stageName)
    # 同一原话可以批准两个阶段，但每次记录仍只写当前阶段摘要。
    UserIntentSupport.approvalStages(evidence).include?(stageName)
  end

  # 读取需求审批中保存的跨阶段原话，供计划阶段复用站立授权。
  def self.deferredEvidence(iterationPath, stageName)
    # 只有计划允许复用更早的联合审批；需求不能从未来阶段倒推。
    return nil unless stageName == "plan"
    # 审批文件损坏时返回 nil，真正错误由后续 read/validation 给出。
    records = read(iterationPath)
    # 需求记录必须已经保存真实用户原话。
    evidence = records&.dig("requirements", "evidence")
    # 原话必须明确同时批准计划，单独需求审批不能被升级。
    evidenceMatches?(stageName, evidence) ? evidence : nil
  end

  # 读取一轮审批文件；缺失或格式损坏时返回 nil。
  def self.read(iterationPath)
    # 文件位置固定，调用方不用自行拼路径。
    approvalPath = Pathname.new(iterationPath).expand_path.join(FILE_NAME)
    # 活动轮次缺失由校验器报告，历史完成轮次可按兼容策略处理。
    return nil unless approvalPath.file?
    # 内容解析保持只读。
    parse(approvalPath.read)
  end

  # 检查单个阶段记录是否与当前文档完全匹配。
  def self.validation(iterationPath, stageName, records = nil)
    # 调用方可传已解析记录，避免总览为同一轮重复读取文件。
    normalizedRecords = records || read(iterationPath)
    # 文件缺失和格式损坏使用同一明确原因。
    return { valid: false, state: "missing", reason: "缺少或无法解析审批记录" } unless normalizedRecords
    # 阶段记录由 parse 保证存在；防御性 fetch 仍给出清晰异常。
    record = normalizedRecords.fetch(stageName)
    # pending 是正常等待状态，不伪装成损坏。
    return { valid: false, state: "pending", reason: "等待用户审批", record: record } if record["status"] == "pending"
    # 除 approved 外的状态都属于格式错误。
    return { valid: false, state: "invalid", reason: "status 非法", record: record } unless record["status"] == "approved"
    # 用户证据必须表达当前阶段批准，包含关键词的否定句不能替代。
    return { valid: false, state: "invalid", reason: "缺少明确用户审批证据", record: record } unless evidenceMatches?(stageName, record["evidence"])
    # 审批时间必须是真实带时区 ISO 8601，而不是模板值。
    begin
      # 先要求结尾含 Z 或显式时区，再交给标准库验证日期本身。
      raise ArgumentError unless record["approved_at"].match?(/(?:Z|[+-]\d{2}:\d{2})\z/)
      # 标准库负责闰日、小时和偏移范围等细节。
      Time.iso8601(record["approved_at"])
    rescue ArgumentError, TypeError
      # 时间不合法时无法建立审批顺序。
      return { valid: false, state: "invalid", reason: "审批时间非法", record: record }
    end
    # 当前摘要在检查时重算，任何受保护文档变化都会使旧批准失效。
    currentDigest = digest(iterationPath, stageName)
    # 摘要不一致明确归类为 stale，便于总览和错误提示区分。
    return { valid: false, state: "stale", reason: "审批后文档已变化", record: record, current_digest: currentDigest } unless record["digest"] == currentDigest
    # 所有证据一致才视为有效审批。
    { valid: true, state: "approved", reason: "审批有效", record: record, current_digest: currentDigest }
  rescue StandardError => error
    # 缺文件或映射错误不能让总览崩溃，保留具体原因供校验器显示。
    { valid: false, state: "invalid", reason: error.message }
  end

  # 为系统总览生成一格简短的审批门禁状态。
  def self.gateState(iterationPath, phase)
    # 旧完成轮次没有新文件时按迁移策略免追溯，不伪造历史审批。
    records = read(iterationPath)
    return phase == "done" ? "历史免追溯" : "缺少审批记录" unless records
    # 需求审批先于计划审批。
    requirementsValidation = validation(iterationPath, "requirements", records)
    # pending 和失效使用不同文案，让用户知道是尚未批还是需要重批。
    return "需求未审批" if requirementsValidation[:state] == "pending"
    return "需求审批失效" unless requirementsValidation[:valid]
    # 需求已批后再检查计划。
    planValidation = validation(iterationPath, "plan", records)
    # specify 中已批需求属于即将进入计划的短暂状态。
    return phase == "specify" ? "需求已审批" : "计划未审批" if planValidation[:state] == "pending"
    return "计划审批失效" unless planValidation[:valid]
    # 两份摘要都匹配当前文档时才显示通过。
    "双审批通过"
  end

  # 原子写入审批文件，避免并发读者看到截断内容。
  def self.write(iterationPath, records, policyName: nil)
    # 目标始终是轮次根目录下固定文件。
    approvalPath = Pathname.new(iterationPath).expand_path.join(FILE_NAME)
    # 在同目录生成临时文件，rename 保持原子性。
    Tempfile.create([".stage-approvals-", ".md"], approvalPath.dirname.to_s) do |temporaryFile|
      # 一次写入完整渲染结果。
      # 更新既有文件时保留其策略；新文件才使用当前默认策略。
      resolvedPolicy = policyName || readPolicy(iterationPath) || DEFAULT_POLICY
      # 一次写入完整渲染结果。
      temporaryFile.write(render(records, policyName: resolvedPolicy))
      # 刷新用户态和内核缓冲，降低异常中断留下空文件的风险。
      temporaryFile.flush
      temporaryFile.fsync
      # 已有文件保留权限，新文件使用普通私有可写权限。
      temporaryFile.chmod(approvalPath.file? ? approvalPath.stat.mode & 0o777 : 0o644)
      # 同盘改名发布完整文件。
      File.rename(temporaryFile.path, approvalPath)
    end
    # 返回路径供命令行入口展示。
    approvalPath
  end

  # 记录一个阶段的明确用户审批，并维护阶段间依赖。
  def self.approve(iterationPath, stageName, evidence, approvedAt: Time.now)
    # 配置不存在时立即失败，不生成未知章节。
    config = STAGES.fetch(stageName) { raise "未知审批阶段：#{stageName}" }
    # 证据必须表达明确审批意图；普通写入授权或否定句不能通过。
    raise "用户证据必须明确批准#{config[:title]}，例如：#{config[:example]}" unless evidenceMatches?(stageName, evidence)
    # 现有文件必须能解析；创建脚本生成的 pending 文件不应被静默覆盖损坏。
    records = read(iterationPath)
    raise "缺少或无法解析 #{FILE_NAME}" unless records
    # 计划审批要求当前需求审批仍然有效。
    if stageName == "plan"
      # 先检查依赖，阻止跳过需求门禁。
      requirementsValidation = validation(iterationPath, "requirements", records)
      # 错误中保留失效原因，便于用户直接回到规格。
      raise "计划审批前需求审批必须有效：#{requirementsValidation[:reason]}" unless requirementsValidation[:valid]
    end
    # 写入审批时间、原始用户证据和当前摘要。
    records[stageName] = {
      "status" => "approved",
      "approved_at" => approvedAt.iso8601,
      "evidence" => normalizeEvidence(evidence),
      "digest" => digest(iterationPath, stageName)
    }
    # 需求重新审批意味着旧计划基于旧规格，必须重新等待计划审批。
    records["plan"] = pendingRecord if stageName == "requirements"
    # 原子保存并返回结构化结果。
    write(iterationPath, records)
    records
  end
end
