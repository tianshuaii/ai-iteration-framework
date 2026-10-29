#!/usr/bin/env ruby

# 本模块只校验结构化设计访谈，不读取能力登记表或改变迭代状态。
# 它由 capability-support.rb 在公共常量和基础方法就绪后加载。
# 保持 CapabilitySupport 命名空间不变，调用方无需知道内部拆分。
# 拆分只降低维护上下文，不新增业务轮次文件、步骤或证据要求。

module CapabilitySupport
  # 解析某阶段唯一的当前访谈尝试，供审批、恢复上下文和主校验器共用。
  def self.currentInterviewAttempt(iterationPath, stageName)
    # 文件固定在轮次根目录，历史迁移轮可由调用方决定是否跳过。
    interviewPath = Pathname.new(iterationPath).expand_path.join(INTERVIEW_FILE)
    # 新轮次缺失时直接阻断审批。
    return { valid: false, reason: "缺少 #{INTERVIEW_FILE}" } unless interviewPath.file?
    # 标记必须唯一，避免两个模板被拼在一起。
    content = interviewPath.read
    # 未知格式不尝试宽松解释。
    return { valid: false, reason: "#{INTERVIEW_FILE} 格式标记无效" } unless content.scan(INTERVIEW_MARKER).length == 1
    # 需求使用 R，计划使用 P；编号允许后续追加尝试。
    prefix = stageName == "requirements" ? "R" : stageName == "plan" ? "P" : nil
    # 未知阶段不能退化成空匹配。
    return { valid: false, reason: "未知访谈阶段：#{stageName}" } unless prefix
    # 抽取本阶段全部二级章节，保留文档顺序。
    attempts = content.scan(/^## #{Regexp.escape(stageName)}\/(#{prefix}-\d+)\s*$\n(.*?)(?=^## |\z)/m)
    # 没有尝试说明模板被删改。
    return { valid: false, reason: "#{INTERVIEW_FILE} 缺少 #{stageName} 尝试" } if attempts.empty?
    # 最后一个非 superseded 尝试是当前门禁对象。
    parsedAttempts = attempts.map do |attemptId, section|
      # 固定字段必须各出现一次。
      fieldNames = %w[status provider provider_version input_digest started_at completed_at classification classification_reason unresolved_count]
      # 复杂度字段使用点号原名，便于和模板直接对应。
      fieldNames.concat(COMPLEXITY_KEYS.map { |key| "complexity.#{key}" })
      # 逐字段解析并保留空值检查。
      fields = fieldNames.to_h do |fieldName|
        # 正则锚定列表项，正文同名词不会误入。
        matches = section.scan(/^- #{Regexp.escape(fieldName)}:\s*(.+)$/)
        # 重复字段按 nil 处理并由下方统一拒绝。
        [fieldName, matches.length == 1 ? matches.first.first.strip : nil]
      end
      # 问题展示协议按尝试渐进采用；历史尝试没有该字段时继续使用旧表格。
      protocolMatches = section.scan(/^- question_protocol:\s*(.+)$/)
      # 重复协议字段会让表格列数和确认要求不确定，必须拒绝。
      return { valid: false, reason: "#{INTERVIEW_FILE} #{attemptId} question_protocol 重复" } if protocolMatches.length > 1
      # 存在时保存协议值；缺失保持 nil，明确进入历史兼容分支。
      fields["question_protocol"] = protocolMatches.first&.first&.strip
      # 必填字段单独记账；可选协议字段为 nil 不能让历史尝试整体失效。
      requiredFieldsValid = fieldNames.all? do |fieldName|
        # 每个旧必填字段仍必须存在且非空，新协议只做渐进增强。
        !fields[fieldName].nil? && !fields[fieldName].empty?
      end
      # 同时保留问答章节用于检查非简单访谈是否真的问过问题。
      { id: attemptId, fields: fields, section: section, required_fields_valid: requiredFieldsValid }
    end
    # 任一尝试结构损坏会让历史链不可靠，不能只相信最后一段。
    return { valid: false, reason: "#{INTERVIEW_FILE} 尝试字段缺失或重复" } if parsedAttempts.any? { |attempt| !attempt[:required_fields_valid] }
    # 过滤被显式取代的历史尝试。
    activeAttempts = parsedAttempts.reject { |attempt| attempt[:fields]["status"] == "superseded" }
    # 同阶段只能有一个当前尝试，多个活动项会造成门禁歧义。
    return { valid: false, reason: "#{INTERVIEW_FILE} #{stageName} 活动尝试数量不是 1" } unless activeAttempts.length == 1
    # 取唯一当前尝试继续验证。
    attempt = activeAttempts.first
    # 解析成功只代表当前尝试唯一；阶段审批仍需继续验证完成态、摘要和复杂度。
    { valid: true, attempt: attempt }
  end

  # 校验当前尝试中的问题状态、待确认数量和用户原话证据。
  def self.interviewQuestionValidation(attempt)
    # 没有新协议字段的历史尝试保留旧行为，避免要求补造过去的聊天证据。
    protocol = attempt[:fields]["question_protocol"]
    # 逐行只解析第一列以 Q数字 开头的真实问题，不误读表头和分隔行。
    questionRows = []
    attempt[:section].each_line do |line|
      # 保留末尾空格后去掉 Markdown 两侧边界，得到稳定单元格数组。
      cells = line.strip.split("|", -1)[1...-1]&.map(&:strip)
      # 非表格行或普通表格行直接跳过。
      next unless cells && cells.first&.match?(/\AQ\d+\b/)
      # 新协议固定五列；历史格式保留四列供完成态兼容检查。
      expectedColumnCount = protocol ? 5 : 4
      # 列数不符时不能猜测哪一列是用户选择或确认依据。
      return { valid: false, reason: "#{attempt[:id]} 问题表格列数非法" } unless cells.length == expectedColumnCount
      # 问题编号与标题放在同一列，编号用于状态关联，完整文本用于同屏展示。
      questionId = cells[0][/\AQ\d+\b/]
      # 保存结构化问题，调用方无需再次拆 Markdown。
      questionRows << {
        id: questionId,
        question: cells[0],
        recommendation: cells[1],
        answer: cells[2],
        status: cells[3],
        confirmation: protocol ? cells[4] : nil
      }
    end
    # 历史尝试不追溯新确认协议，只把问题行返回给旧完成态检查。
    return { valid: true, protocol: nil, rows: questionRows } unless protocol
    # 未知协议不能被默认为当前规则，否则拼写错误会绕过确认证据。
    return { valid: false, reason: "#{attempt[:id]} question_protocol 非法" } unless protocol == QUESTION_PROTOCOL
    # 问题编号必须唯一，避免同一个 Q 被一行标 pending、另一行标 resolved。
    duplicateIds = questionRows.group_by { |row| row[:id] }.select { |_id, rows| rows.length > 1 }.keys
    # 一次报告全部重复编号。
    return { valid: false, reason: "#{attempt[:id]} 问题编号重复：#{duplicateIds.join(', ')}" } unless duplicateIds.empty?
    # 新协议只允许 pending 和 resolved 两种问题状态。
    invalidStatusRows = questionRows.reject { |row| %w[pending resolved].include?(row[:status]) }
    # 未知状态不能被算入未决数或完成数。
    return { valid: false, reason: "#{attempt[:id]} 问题状态非法：#{invalidStatusRows.map { |row| row[:id] }.join(', ')}" } unless invalidStatusRows.empty?
    # unresolved_count 必须是非负整数，不能把自然语言解释为零。
    unresolvedValue = attempt[:fields]["unresolved_count"]
    # 格式错误时先返回明确原因。
    return { valid: false, reason: "#{attempt[:id]} unresolved_count 非法" } unless unresolvedValue.match?(/\A\d+\z/)
    # 真实未决数由 pending 行计算，手工写零不能提前完成访谈。
    pendingRows = questionRows.select { |row| row[:status] == "pending" }
    # 计数漂移会让审批入口错误判断访谈已完成。
    return { valid: false, reason: "#{attempt[:id]} unresolved_count 与 pending 问题不一致" } unless unresolvedValue.to_i == pendingRows.length
    # pending 问题只能保存待确认占位符，禁止预填用户选择或确认原话。
    invalidPendingRows = pendingRows.reject { |row| row[:answer] == "待确认" && row[:confirmation] == "无" }
    # 提前写答案或确认依据即视为未确认问题被伪完成。
    return { valid: false, reason: "#{attempt[:id]} pending 问题夹带用户选择：#{invalidPendingRows.map { |row| row[:id] }.join(', ')}" } unless invalidPendingRows.empty?
    # resolved 必须同时有非占位选择和以固定前缀保存的用户原话。
    invalidResolvedRows = questionRows.select { |row| row[:status] == "resolved" }.reject do |row|
      # 用户选择不能是待确认或空语义，确认依据必须保留直接用户消息。
      !["", "无", "待确认"].include?(row[:answer]) && row[:confirmation].start_with?("用户原话：") && row[:confirmation] != "用户原话："
    end
    # 缺少原话时禁止把问题标成 resolved。
    return { valid: false, reason: "#{attempt[:id]} resolved 问题缺少用户确认原话：#{invalidResolvedRows.map { |row| row[:id] }.join(', ')}" } unless invalidResolvedRows.empty?
    # 返回待确认问题供上下文脚本展开问题全文和推荐答案。
    { valid: true, protocol: protocol, rows: questionRows, pending_rows: pendingRows }
  end

  # 解析某阶段最新的访谈尝试并验证其摘要、复杂度和未决问题。
  def self.interviewValidation(iterationPath, stageName, expectedDigest:, workflowProfile: DEFAULT_WORKFLOW_PROFILE, profileRules: nil)
    # 当前尝试解析由共享入口完成，避免恢复上下文和审批脚本选择不同章节。
    attemptResult = currentInterviewAttempt(iterationPath, stageName)
    # 结构或活动尝试数量错误直接透传。
    return attemptResult unless attemptResult[:valid]
    # 取得唯一当前尝试及字段继续做阶段门禁。
    attempt = attemptResult[:attempt]
    fields = attempt[:fields]
    # 状态集合固定，未知值不能被当作未完成。
    return { valid: false, reason: "#{stageName} 访谈状态非法" } unless INTERVIEW_STATUSES.include?(fields["status"])
    # 新协议的问题状态和用户原话在判断完成前先校验，pending 也不能夹带伪确认。
    questionValidation = interviewQuestionValidation(attempt)
    # 精确原因同时供主校验器与审批命令显示。
    return questionValidation unless questionValidation[:valid]
    # pending 和未完成尝试不能进入审批。
    return { valid: false, reason: "#{stageName} 访谈尚未完成" } unless %w[completed skipped].include?(fields["status"])
    # 输入摘要必须等于当前阶段文档摘要。
    return { valid: false, reason: "#{stageName} 访谈输入摘要已过期" } unless fields["input_digest"] == expectedDigest
    # unresolved_count 必须是零，问题不能被审批命令隐式跳过。
    return { valid: false, reason: "#{stageName} 访谈仍有未决问题" } unless fields["unresolved_count"] == "0"
    # 提供者和版本必须明确，不能保留模板值。
    return { valid: false, reason: "#{stageName} 访谈缺少提供者或版本" } if [fields["provider"], fields["provider_version"]].any? { |value| value == "无" }
    # 复杂度值只能三选一。
    complexityValues = COMPLEXITY_KEYS.map { |key| fields["complexity.#{key}"] }
    # 未知拼写会绕过非简单判断，必须拒绝。
    return { valid: false, reason: "#{stageName} 复杂度字段非法" } unless complexityValues.all? { |value| %w[yes no unknown].include?(value) }
    # 分类必须由复杂度字段确定，不能手工把 unknown 标成 simple。
    expectedClassification = complexityValues.all? { |value| value == "no" } ? "simple" : "non-trivial"
    # 分类不一致时拒绝，防止通过文案绕过 grill-me。
    return { valid: false, reason: "#{stageName} 复杂度分类与字段不一致" } unless fields["classification"] == expectedClassification
    # 把字段名和值组成映射，供配置驱动的档位选择复用。
    complexityFields = COMPLEXITY_KEYS.to_h { |key| [key, fields["complexity.#{key}"]] }
    # 新三级流程必须证明当前档位不低于复杂度要求；旧调用未传配置时保持原严格规则。
    if profileRules
      # 档位校验同时处理 unknown，防止 Agent 用不确定性进入轻量流程。
      profileValidation = workflowProfileValidation(workflowProfile, complexityFields, profileRules)
      # 失败原因直接指向档位或配置，不伪装成普通访谈未完成。
      return { valid: false, reason: profileValidation[:reason] } unless profileValidation[:valid]
    end
    # 简单轮始终可以按确定性清单跳过；非简单轮是否必访谈由当前档位配置决定。
    if fields["status"] == "skipped" && complexityValues.any? { |value| value != "no" }
      # 没有三级配置的旧调用保持升级前行为，避免测试或外部脚本意外放宽。
      return { valid: false, reason: "#{stageName} 非简单轮次不能跳过访谈" } unless profileRules
      # 每档只列出非简单需求必须访谈的阶段，未列阶段仍由对应评审能力把关。
      requiredStages = Array(profileRules.dig("profiles", workflowProfile, "non_trivial_interview_required_in"))
      # strict 两阶段必访谈，standard 只在需求阶段访谈，lite 实际不会通过非简单档位校验。
      return { valid: false, reason: "#{workflowProfile} 档位的 #{stageName} 非简单访谈不能跳过" } if requiredStages.include?(stageName)
    end
    # 开始和完成时间必须真实、带时区且顺序有效。
    begin
      # 两个时间都必须有显式时区。
      raise ArgumentError unless [fields["started_at"], fields["completed_at"]].all? { |value| value.match?(/(?:Z|[+-]\d{2}:\d{2})\z/) }
      # 完成时间不能早于开始时间。
      raise ArgumentError if Time.iso8601(fields["completed_at"]) < Time.iso8601(fields["started_at"])
    rescue ArgumentError
      # 无法建立顺序的访谈不具备耐久审计价值。
      return { valid: false, reason: "#{stageName} 访谈时间非法" }
    end
    # 非简单轮次完成访谈时至少要有一条已决问答行。
    if fields["status"] == "completed"
      if questionValidation[:protocol]
        # 新协议要求至少一条问题且全部具有用户原话，pending 已由计数校验排除。
        return { valid: false, reason: "#{stageName} 访谈没有已决问答" } if questionValidation[:rows].empty?
        # completed 不能仍包含 pending，即使手工把 unresolved_count 改成其他值也无法通过。
        return { valid: false, reason: "#{stageName} 访谈仍有未决问题" } unless questionValidation[:pending_rows].empty?
      else
        # 历史表格最后一列使用 resolved 或“已决”作为稳定完成标识。
        resolvedQuestion = attempt[:section].each_line.any? { |line| line.match?(/^\|.+\|.+\|.+\|\s*(?:resolved|已决)\s*\|\s*$/) }
        # 历史空问答仍不能冒充 grill-me 已执行。
        return { valid: false, reason: "#{stageName} 访谈没有已决问答" } unless resolvedQuestion
      end
    end
    # 成功结果返回当前尝试供审批入口记录。
    { valid: true, attempt: attempt }
  end

end
