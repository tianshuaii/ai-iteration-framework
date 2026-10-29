#!/usr/bin/env ruby

# 本模块集中校验单轮迭代的状态、审批和能力证据。
# 拆分只改变校验器内部职责，不增加任何轮次文档、命令或用户操作。
# 所有方法保持只读，错误继续汇总到主入口传入的同一数组。
# 显式加载直接依赖，避免依赖主入口的 require 顺序才能运行。
# 代码保持 Ruby 2.6 兼容，不使用项目外第三方依赖。

require "time"
require_relative "capability-digest-support"
require_relative "capability-support"
require_relative "iteration-content-validation-support"
require_relative "review-coverage-support"
require_relative "stage-approval-support"

# 迭代治理门禁按状态推进顺序组织，主入口只负责调度。
module IterationGovernanceValidation
  # 暴露模块方法，避免实例化没有状态的校验对象。
  module_function

  # 本模块维持四层互不替代的治理不变量。
  # 状态层只判断阶段、任务、工作状态和恢复动作是否合法。
  # 问题层保证未决问题真实可见，且不能提前形成审批结果。
  # 审批层只验证用户证据与当前文档摘要是否仍然一致。
  # 能力层验证访谈、评审、实施守卫和验收证据是否覆盖阶段。
  # 兼容历史完成档案时只放宽无法追溯的旧协议字段。
  # 活动轮次始终使用当前策略，不能借历史兼容跳过新门禁。
  # 所有摘要都由共享模块计算，不在这里复制哈希算法。
  # 任一解析异常只转成可定位错误，不允许校验器整体崩溃。

  # 将错误写入调用方的共享数组，保留一次性完整报告行为。
  def addError(errors, message)
    # 错误文本由具体校验方法提供路径和对象。
    errors << message
  end

  # 完成态允许机器占位值和等价的人类表述，避免纯文案差异制造治理噪音。
  def doneNextAction?(value)
    # 只去除末尾常见标点，不做宽泛模糊匹配，防止真实后续动作被误判为空。
    normalizedValue = value.to_s.strip.sub(/[。.!！]\z/, "")
    # 可接受值保持极小集合；新增表述必须有明确完成态语义。
    ["无", "本轮无后续动作"].include?(normalizedValue)
  end

  # 读取 Markdown 状态字段，不对正文格式作额外假设。
  def readStatusField(content, fieldName)
    # 字段固定写成列表项，避免误读正文中的示例。
    match = content.match(/^- #{Regexp.escape(fieldName)}:\s*(.+)$/)
    # 没找到时返回 nil，由调用方给出具体错误。
    match&.captures&.first&.strip
  end

  # 校验一份 status.md，并返回后续流程可以复用的字段集合。
  def validateStatusFields(errors, content, label, allowedPhases, allowedWorkStates, requiredStatusFields, validateTimestamp, allowedWorkflowProfiles)
    # 一次解析所有必需字段，避免各阶段分别维护另一套读取逻辑。
    fields = requiredStatusFields.to_h do |fieldName|
      # 字段值仍使用统一的 Markdown 列表格式读取。
      [fieldName, readStatusField(content, fieldName)]
    end
    # 新轮次显式保存档位；旧轮次缺字段时使用兼容的 standard，不要求批量改写历史档案。
    fields["workflow_profile"] = readStatusField(content, "workflow_profile") || CapabilitySupport::DEFAULT_WORKFLOW_PROFILE

    # 每个缺失字段都单独报告，方便一次补齐完整恢复点。
    requiredStatusFields.each do |fieldName|
      # 空值和缺少行都会由 readStatusField 返回 nil。
      addError(errors, "#{label} 缺少状态字段：#{fieldName}") unless fields[fieldName]
    end

    # 取出阶段和工作状态，下面检查二者的组合是否合法。
    phase = fields["phase"]
    # current_task 只在 implement 阶段允许使用任务编号。
    currentTask = fields["current_task"]
    # work_state 记录当前阶段是待开始、进行中、阻塞还是完成。
    workState = fields["work_state"]
    # 档位决定访谈与证据组织方式，但不改变双审批或产品写入授权。
    workflowProfile = fields["workflow_profile"]
    # 非法 phase 会让 Agent 打开错误的阶段入口。
    addError(errors, "#{label} phase 非法：#{phase.inspect}") if phase && !allowedPhases.include?(phase)
    # 非法 work_state 会让断点恢复行为不可判定。
    addError(errors, "#{label} work_state 非法：#{workState.inspect}") if workState && !allowedWorkStates.include?(workState)
    # 未知档位不能被当成默认值，否则可能绕过更严格的访谈要求。
    addError(errors, "#{label} workflow_profile 非法：#{workflowProfile.inspect}") unless allowedWorkflowProfiles.include?(workflowProfile)

    # 真实轮次必须提供可解析且带时区的 ISO 8601 时间。
    if validateTimestamp && fields["updated_at"]
      # Time.iso8601 会同时拒绝模板占位符和缺少时区的模糊时间。
      begin
        parsedTime = Time.iso8601(fields["updated_at"])
        # utc_offset 一定存在；保留局部变量可以明确这里确实完成了解析。
        parsedTime.utc_offset
      rescue ArgumentError
        # 时间不可解析时，Agent 无法判断 in_progress 是否来自历史中断。
        addError(errors, "#{label} updated_at 不是带时区的 ISO 8601 时间")
      end
    end

    # implement 通常指向一个未完成任务；全部实现写完后的统一审核窗口使用“无”。
    if phase == "implement"
      # 只允许稳定任务编号或统一审核哨兵，避免自然语言步骤进入机器字段。
      addError(errors, "#{label} implement 阶段 current_task 非法") unless currentTask == "无" || currentTask&.match?(/\AT-\d+\z/)
      # 活动阶段不能使用 done，否则任务尚未完成却会被当成归档。
      addError(errors, "#{label} implement 阶段 work_state 非法：#{workState.inspect}") unless %w[ready in_progress blocked].include?(workState)
    elsif allowedPhases.include?(phase)
      # 其他阶段没有当前代码任务，必须明确写无。
      addError(errors, "#{label} #{phase} 阶段 current_task 必须为无") unless currentTask == "无"
    end

    # done 必须同时收口工作状态和后续动作。
    if phase == "done"
      # 完成态使用独立状态，避免和暂停中的活动阶段混淆。
      addError(errors, "#{label} done 阶段 work_state 必须为 done") unless workState == "done"
      # 完成态出现动作说明状态尚未真正收口。
      addError(errors, "#{label} done 阶段 next_action 必须表示无后续动作") unless doneNextAction?(fields["next_action"])
    elsif allowedPhases.include?(phase)
      # 所有活动阶段都使用同一组工作状态，包括 specify、plan 和 verify。
      addError(errors, "#{label} #{phase} 阶段 work_state 非法：#{workState.inspect}") unless %w[ready in_progress blocked].include?(workState)
      # 活动阶段必须给出恢复后的第一步，不能让 Agent 再靠聊天猜测。
      addError(errors, "#{label} #{phase} 阶段 next_action 不能为无") if fields["next_action"] == "无"
    end
    # 返回解析结果，活动轮次和当前任务检查继续复用。
    fields
  end

  # 校验待确认设计问题必须可见、可恢复，且不能与审批或 resolved 状态并存。
  def validateQuestionVisibilityGate(errors, iterationPath, statusFields, label)
    # 只有规格和计划阶段会等待设计访谈问题；其他阶段由跨阶段能力门禁负责。
    phase = statusFields["phase"]
    stageName = phase == "specify" ? "requirements" : phase == "plan" ? "plan" : nil
    # 非访谈阶段不解析历史问题，避免完成轮次被新规则追溯。
    return unless stageName
    # 缺少访谈文件会由必需文件检查报告，这里不制造重复错误。
    return unless iterationPath.join(CapabilitySupport::INTERVIEW_FILE).file?
    # 使用共享解析器选出唯一当前尝试，不能从旧 superseded 章节挑一个问题。
    attemptResult = CapabilitySupport.currentInterviewAttempt(iterationPath, stageName)
    unless attemptResult[:valid]
      # 当前尝试损坏会让 Agent 无法知道应显示哪一轮问题。
      addError(errors, "#{label} #{attemptResult[:reason]}")
      return
    end
    # 新协议同时校验问题状态、未决计数和用户原话证据。
    questionValidation = CapabilitySupport.interviewQuestionValidation(attemptResult[:attempt])
    unless questionValidation[:valid]
      # 缺少用户确认原话或 pending 夹带答案时立即阻断。
      addError(errors, "#{label} #{questionValidation[:reason]}")
      return
    end
    # 历史尝试没有新协议时不倒推同屏展示证据。
    return unless questionValidation[:protocol]
    # 只处理真实 pending 行；完成访谈没有等待动作。
    pendingRows = questionValidation[:pending_rows]
    # next_action 是用户可见恢复入口，后续逐项检查编号和问题标题。
    nextAction = statusFields["next_action"].to_s
    if pendingRows.empty?
      # 已决问题不能继续出现在等待动作中，否则 Agent 会重复索要已经确认的决定。
      resolvedIds = questionValidation[:rows].select { |row| row[:status] == "resolved" }.map { |row| row[:id] }
      staleQuestionIds = nextAction.scan(/\bQ\d+\b/).uniq & resolvedIds
      # 报告具体编号，便于修正状态而不是重做整段访谈。
      addError(errors, "#{label} next_action 仍在等待已决问题：#{staleQuestionIds.join(', ')}") unless staleQuestionIds.empty?
      return
    end
    # 等待用户决定是真正阻塞，不能显示 ready 或 in_progress。
    addError(errors, "#{label} 有未决问题时 work_state 必须为 blocked") unless statusFields["work_state"] == "blocked"
    # 审批文件存在时，同阶段不能继续保留 approved，否则回答前已经跨过门禁。
    approvalRecords = StageApproval.read(iterationPath)
    # 文件损坏由审批校验另行报告；成功解析时检查当前阶段记录。
    if approvalRecords && approvalRecords.fetch(stageName)["status"] == "approved"
      # 需求或计划审批都必须在问题解决和评审重跑之后重新取得。
      addError(errors, "#{label} 未决问题仍保留 #{stageName} approved 审批")
    end
    # 每个未决问题都必须在 next_action 中保留编号和完整标题，防止只剩不透明编号。
    pendingRows.each do |row|
      # 第一列就是稳定的“Q编号 + 问题全文”，必须原样出现在恢复动作里。
      addError(errors, "#{label} next_action 未同屏写出 #{row[:id]} 问题全文") unless nextAction.include?(row[:question])
      # 推荐方案也必须同屏，用户不能为了理解回复口令再去翻访谈文件。
      addError(errors, "#{label} next_action 未同屏写出 #{row[:id]} 推荐方案") unless nextAction.include?(row[:recommendation])
      # 推荐回复短语让用户可以直接确认，同时不替代上面的完整问题。
      addError(errors, "#{label} next_action 缺少 #{row[:id]} 推荐回复") unless nextAction.include?("#{row[:id]} 按推荐做")
    end
  end

  # 校验一轮的审批记录、文档摘要和当前 phase 是否满足阶段门禁。
  def validateStageApprovals(errors, iterationPath, statusFields, label)
    # phase 非法已由状态校验报告，这里避免制造连锁错误。
    phase = statusFields["phase"]
    # 只处理框架定义的五个阶段。
    return unless %w[specify plan implement verify done].include?(phase)

    # 审批文件使用固定名称，不允许 file-map 把证据指到其他路径。
    approvalPath = iterationPath.join(StageApproval::FILE_NAME)
    # 历史完成轮次不倒推当时不存在的用户审批。
    unless approvalPath.file?
      # 活动轮次必须迁移或由模板创建审批文件。
      addError(errors, "#{label} 缺少 #{StageApproval::FILE_NAME}") unless phase == "done"
      return
    end

    # 结构损坏时无法安全判断任何阶段，先给出一个根因。
    records = StageApproval.parse(approvalPath.read)
    unless records
      # 不继续做摘要检查，避免同一损坏文件产生多条误导信息。
      addError(errors, "#{label} #{StageApproval::FILE_NAME} 格式无效")
      return
    end

    # pending 记录必须保持其他字段为“无”，不能夹带半份伪审批。
    records.each do |stageName, record|
      # 已批准记录的详细有效性由共享模块检查。
      next unless record["status"] == "pending"
      # 三个证据字段必须一起为空语义。
      evidenceFields = %w[approved_at evidence digest]
      # 任一残留值都说明状态切换没有原子完成。
      addError(errors, "#{label} #{stageName} pending 记录仍包含审批证据") unless evidenceFields.all? { |fieldName| record[fieldName] == "无" }
    end

    # 对已经声明 approved 的记录始终验证，哪怕当前仍停在较早阶段。
    validations = StageApproval::STAGES.keys.to_h do |stageName|
      # 同一轮同一阶段只计算一次摘要。
      [stageName, StageApproval.validation(iterationPath, stageName, records)]
    end
    # 摘要失效或证据非法不能静默保留 approved 文案。
    validations.each do |stageName, validation|
      # pending 是合法等待状态，由阶段门禁决定是否允许。
      next unless records.fetch(stageName)["status"] == "approved"
      # 有效记录无需报告。
      next if validation[:valid]
      # 错误包含共享模块给出的具体失效原因。
      addError(errors, "#{label} #{stageName} 审批无效：#{validation[:reason]}")
    end

    # 计划审批绝不能绕过需求审批，即使当前 phase 尚未推进。
    if records.fetch("plan")["status"] == "approved" && !validations.fetch("requirements")[:valid]
      # 这条错误直接说明阶段依赖关系。
      addError(errors, "#{label} 计划审批前需求审批必须有效")
    end

    # plan 表示规格已结束，因此必须持有当前有效的需求审批。
    if %w[plan implement verify done].include?(phase) && !validations.fetch("requirements")[:valid]
      # pending 和 stale 都统一阻断跨阶段。
      addError(errors, "#{label} #{phase} 阶段缺少有效需求审批")
    end
    # implement 及以后表示计划已结束，因此双审批都必须有效。
    if %w[implement verify done].include?(phase) && !validations.fetch("plan")[:valid]
      # 计划摘要变化也要求退回 plan 重新审批。
      addError(errors, "#{label} #{phase} 阶段缺少有效计划审批")
    end
  end

  # 校验一轮 Skills/MCP 能力证据是否覆盖当前已经跨过的门禁。
  def validateCapabilityGates(errors, iterationPath, statusFields, label, profileRules)
    # 旧完成轮次没有能力日志时免追溯，不伪造历史 Skill 执行记录。
    logPath = iterationPath.join(CapabilitySupport::LOG_FILE)
    # 活动轮次必须迁移；完成轮次只有采用新日志后才执行新门禁。
    unless logPath.file?
      # done 是明确历史兼容边界，其余阶段不能继续缺少能力状态。
      addError(errors, "#{label} 缺少 #{CapabilitySupport::LOG_FILE}") unless statusFields["phase"] == "done"
      return
    end

    # 整份日志结构必须先有效，不能从损坏记录中挑一行放行。
    parsedLog = CapabilitySupport.parseLog(iterationPath)
    unless parsedLog[:valid]
      # 保留共享模块的精确原因。
      addError(errors, "#{label} #{parsedLog[:reason]}")
      return
    end
    # 新轮次启用完整需求和计划能力；迁移轮只从登记基线向后生效。
    migrationBase = parsedLog[:headers]["migration_base_phase"]
    # 所有采用能力日志的轮次都必须保留四类证据目录。
    %w[analysis reviews tests delivery].each do |evidenceCategory|
      # 缺目录会让阶段执行无法按约定落盘。
      addError(errors, "#{label} 缺少 evidence/#{evidenceCategory}/") unless iterationPath.join("evidence", evidenceCategory).directory?
    end
    # 新轮次从规格阶段开始，必须持久保存需求和计划访谈树。
    if migrationBase == "new" && !iterationPath.join(CapabilitySupport::INTERVIEW_FILE).file?
      # 迁移到 implement 的旧轮可以不伪造已经通过的访谈。
      addError(errors, "#{label} 缺少 #{CapabilitySupport::INTERVIEW_FILE}")
    end
    # 当前阶段决定哪些已经跨过的阶段门禁必须存在。
    phase = statusFields["phase"]
    # v2 审批摘要是访谈与阶段评审共同绑定的输入。
    approvalPolicy = StageApproval.readPolicy(iterationPath)
    # 新轮次必须使用 v2；历史 v1 只有迁移基线不追溯已通过审批。
    if migrationBase == "new" && approvalPolicy != "capability-gates-v2"
      # v1 无法证明能力门禁发生在用户审批之前。
      addError(errors, "#{label} 新能力轮次必须使用 capability-gates-v2 审批策略")
      return
    end

    # 需求阶段已经结束时，访谈和需求评审必须匹配当前需求摘要。
    if %w[new specify].include?(migrationBase) && %w[plan implement verify done].include?(phase)
      # 摘要计算失败由下方 rescue 转为单条门禁错误。
      requirementsDigest = StageApproval.digest(iterationPath, "requirements")
      # 访谈必须已完成，简单轮也只能按全否清单跳过。
      interview = CapabilitySupport.interviewValidation(
        iterationPath,
        "requirements",
        expectedDigest: requirementsDigest,
        workflowProfile: statusFields["workflow_profile"],
        profileRules: profileRules
      )
      # 逐项报告便于直接回到访谈或评审证据。
      addError(errors, "#{label} 需求访谈无效：#{interview[:reason]}") unless interview[:valid]
      # 需求评审必须处理完所有阻断发现。
      review = CapabilitySupport.capabilityValidation(iterationPath, "requirements-review", phase: "specify", expectedDigest: requirementsDigest)
      # 能力缺失或摘要过期都阻止后续阶段。
      addError(errors, "#{label} 需求评审能力无效：#{review[:reason]}") unless review[:valid]
    end
    # 计划阶段已经结束时执行同样的计划访谈和评审检查。
    if %w[new specify plan].include?(migrationBase) && %w[implement verify done].include?(phase)
      # v2 计划摘要包含 workspace 的稳定计划区。
      planDigest = StageApproval.digest(iterationPath, "plan")
      # 计划访谈必须绑定同一输入。
      interview = CapabilitySupport.interviewValidation(
        iterationPath,
        "plan",
        expectedDigest: planDigest,
        workflowProfile: statusFields["workflow_profile"],
        profileRules: profileRules
      )
      # 未决问题和过期摘要都不能通过。
      addError(errors, "#{label} 计划访谈无效：#{interview[:reason]}") unless interview[:valid]
      # 计划评审证据与审批摘要保持一致。
      review = CapabilitySupport.capabilityValidation(iterationPath, "plan-review", phase: "plan", expectedDigest: planDigest)
      # 严重或未处置 P2 同样阻断。
      addError(errors, "#{label} 计划评审能力无效：#{review[:reason]}") unless review[:valid]
    end

    # 实施证据只对采用能力策略的实施中、验证中和完成轮次检查。
    if %w[implement verify done].include?(phase) && migrationBase != "verify"
      # 任务清单是任务顺序和完成状态的事实源。
      tasksPath = StageApproval.resolveIterationFile(iterationPath, "tasks.md")
      # 提取全部任务及 checkbox，正文中的依赖编号不会误入。
      taskRows = tasksPath.file? ? tasksPath.read.scan(/^- \[([ xX])\]\s+(T-\d+)\b/) : []
      # 整轮计划摘要只绑定最终统一审核，不再让一条任务变化使其他守卫失效。
      planDigest = StageApproval.digest(iterationPath, "plan")
      # 完成态可能在合法重批计划后留下旧守卫，但必须有更晚的当前统一审核作补偿。
      currentDoneUnifiedReview = phase == "done" ? CapabilitySupport.capabilityValidation(iterationPath, "code-review", phase: "implement", task: "无", expectedDigest: planDigest) : nil
      # 新日志使用任务级摘要；旧日志保留产生时语义，避免要求历史任务补造证据。
      taskGuardPolicyEnabled = parsedLog[:policy] == CapabilityDigestSupport::DEFAULT_LOG_POLICY
      # implement 迁移时，登记任务之前的任务不追溯，登记任务仅豁免已错过的前置守卫。
      migrationTask = parsedLog[:headers]["migration_current_task"]
      # 在任务顺序中定位迁移点；新轮次没有迁移任务。
      migrationIndex = taskRows.index { |_mark, taskId| taskId == migrationTask }
      # 错误迁移编号不能静默导致所有任务被当作新任务。
      addError(errors, "#{label} 迁移当前任务不在 tasks.md：#{migrationTask}") if migrationBase == "implement" && migrationIndex.nil?
      # 保存已经通过当前门禁的守卫行，供审核覆盖链按日志顺序判断增量范围。
      validatedGuardRows = {}
      # 新策略的增量审核绑定任务摘要；旧日志继续绑定产生时使用的计划摘要。
      taskReviewDigests = {}
      # 只有采用策略后实际要求守卫的任务才进入增量审核覆盖集合。
      reviewTaskIds = []
      # 对每个已完成任务只验证写入前守卫；代码审核在全部任务完成后统一执行。
      taskRows.each_with_index do |(mark, taskId), taskIndex|
        # 只检查已经勾选完成的任务。
        next if mark == " "
        # 迁移点之前的任务明确属于采用策略前历史，不伪造证据。
        next if migrationBase == "implement" && migrationIndex && taskIndex < migrationIndex
        # 迁移时已进行中的当前任务可以没有事前守卫。
        unless migrationBase == "implement" && taskId == migrationTask && parsedLog[:headers]["migration_task_state"] != "ready"
          # 新日志把守卫绑定到当前任务及共享写入上界，旧日志只验证当时真实通过记录。
          guardDigest = taskGuardPolicyEnabled ? CapabilityDigestSupport.implementationGuardDigest(iterationPath, taskId) : nil
          # 其他完成任务必须有实施前守卫；任务勾选不会改变摘要。
          guard = CapabilitySupport.capabilityValidation(iterationPath, "implementation-guard", phase: "implement", task: taskId, expectedDigest: guardDigest)
          # done 归档只对“摘要过期”提供补偿路径，缺失、失败或带发现的守卫仍不能兼容。
          archivedGuardCovered = false
          if phase == "done" && guard[:reason] == "implementation-guard 输入摘要已过期" && guard[:row] && currentDoneUnifiedReview&.dig(:valid)
            # 旧守卫本身必须真实通过且没有未处置发现，不能只依赖统一审核掩盖失败。
            cleanGuard = guard[:row][:status] == "passed" && [guard[:row][:p0], guard[:row][:p1], guard[:row][:p2_open]].all? { |value| value == "0" }
            # 通过日志追加顺序证明当前统一审核发生在旧守卫之后，不依赖容易漂移的时间字符串。
            guardIndex = parsedLog[:rows].index { |row| row[:id] == guard[:row][:id] }
            # 当前统一审核已经由能力校验确认摘要、证据和发现数，这里只取其稳定顺序。
            reviewIndex = parsedLog[:rows].index { |row| row[:id] == currentDoneUnifiedReview[:row][:id] }
            # 两个索引都存在且审核更晚时，才允许用最终全量审核补偿无法追溯重做的事前守卫。
            archivedGuardCovered = cleanGuard && guardIndex && reviewIndex && reviewIndex > guardIndex
          end
          # 活动轮次始终要求当前守卫；完成归档只有满足上述补偿控制才不报错。
          guardAccepted = guard[:valid] || archivedGuardCovered
          # 守卫过期或缺失说明任务不应被勾选，除非完成态已经有当前统一审核覆盖。
          addError(errors, "#{label} #{taskId} 实施守卫无效：#{guard[:reason]}") unless guardAccepted
          # 有效守卫或被补偿覆盖的旧守卫都保留真实日志行，供审核覆盖链核对先后顺序。
          validatedGuardRows[taskId] = guard[:row] if guardAccepted
          # v2 使用任务摘要；v1 的历史增量记录仍使用当前有效计划摘要。
          taskReviewDigests[taskId] = taskGuardPolicyEnabled ? guardDigest : planDigest
          # 完成任务必须被首次整轮审核或后续同任务增量审核覆盖。
          reviewTaskIds << taskId
        end
      end
      # 当前任务开始修改后必须先有守卫，只有迁移时已开始的同一任务例外。
      if phase == "implement" && statusFields["current_task"].to_s.match?(/\AT-\d+\z/) && %w[in_progress blocked].include?(statusFields["work_state"])
        # 判断是否是采用规则时已无法追溯的任务。
        migratedStartedTask = migrationBase == "implement" && statusFields["current_task"] == migrationTask && parsedLog[:headers]["migration_task_state"] != "ready"
        unless migratedStartedTask
          # 当前任务沿用同一任务级摘要，避免恢复时与已完成任务使用两套门禁。
          guardDigest = taskGuardPolicyEnabled ? CapabilityDigestSupport.implementationGuardDigest(iterationPath, statusFields["current_task"]) : nil
          # 新日志严格检查当前任务摘要；旧日志继续兼容已经落盘的整轮计划摘要。
          guard = CapabilitySupport.capabilityValidation(iterationPath, "implementation-guard", phase: "implement", task: statusFields["current_task"], expectedDigest: guardDigest)
          # 缺失时实现应回到 blocked，而不是继续写代码。
          addError(errors, "#{label} 当前任务实施守卫无效：#{guard[:reason]}") unless guard[:valid]
        end
      end

      # 跨入 verify 后必须有首次整轮审核，并用增量记录覆盖其后的返工守卫。
      if %w[verify done].include?(phase)
        # 追加顺序让旧整轮基线保持有效，新任务不再迫使未变化仓库重新审核。
        reviewCoverage = ReviewCoverageSupport.validation(
          rows: parsedLog[:rows],
          taskIds: reviewTaskIds,
          guardRows: validatedGuardRows,
          taskDigests: taskReviewDigests,
          unifiedDigest: planDigest
        )
        # 已完成历史轮次保留逐任务证据兼容；活动 verify 不允许继续沿用旧模式。
        legacyReviewValid = false
        if phase == "done" && !reviewCoverage[:valid]
          # 只检查迁移点及之后的已完成任务，和旧门禁的追溯边界保持一致。
          legacyReviewValid = taskRows.each_with_index.all? do |(mark, taskId), taskIndex|
            # 未完成任务会由内容门禁报告；这里不把它误当成审核通过。
            next false if mark == " "
            # 迁移点之前的旧任务不要求补造历史审核。
            next true if migrationBase == "implement" && migrationIndex && taskIndex < migrationIndex
            # 历史逐任务审核仍必须匹配计划摘要且没有未处置发现。
            CapabilitySupport.capabilityValidation(iterationPath, "code-review", phase: "implement", task: taskId, expectedDigest: planDigest)[:valid]
          end
        end
        # 新活动轮次缺少基线或增量覆盖时直接阻断进入验收。
        addError(errors, "#{label} 迭代级统一代码审核无效：#{reviewCoverage[:reason]}") unless reviewCoverage[:valid] || legacyReviewValid
      end
    end

    # done 前必须同时有整体验证和交付复核，迁移轮也不豁免未来门禁。
    return unless phase == "done"
    # 新轮次由测试策略标记启用浅回归，并把策略本身纳入最终摘要。
    testStrategyPath = StageApproval.resolveIterationFile(iterationPath, "test-strategy.md")
    # 一次读取同时识别模板标记与迁移轮保留的新版表头。
    testStrategyContent = testStrategyPath.file? ? testStrategyPath.read : ""
    # 旧版 SR 四列表不启用新协议，避免要求历史完成轮补造类型和新摘要。
    shallowPolicyEnabled = IterationContentValidation.boundedShallowPolicyEnabled?(testStrategyContent)
    # 新协议必须绑定测试策略；旧完成态仍按产生证据时的五文件协议验证。
    verificationFiles = shallowPolicyEnabled ? %w[acceptance.md test-strategy.md test-cases.md test-log.md traceability.md review-checklist.md] : %w[acceptance.md test-cases.md test-log.md traceability.md review-checklist.md]
    # 由当前协议选择后的文档集合生成稳定摘要。
    verificationDigest = CapabilityDigestSupport.documentsDigest(iterationPath, verificationFiles)
    # v1 完成档案产生于当前摘要冻结规则之前，只校验证据、状态和发现数，不补造新摘要。
    expectedVerificationDigest = parsedLog[:policy] == CapabilityDigestSupport::DEFAULT_LOG_POLICY ? verificationDigest : nil
    # 测试验证必须绑定最终产物且不存在阻断发现。
    testValidation = CapabilitySupport.capabilityValidation(iterationPath, "test-verification", phase: "verify", expectedDigest: expectedVerificationDigest)
    # 缺失时不能进入完成态。
    addError(errors, "#{label} 测试验证能力无效：#{testValidation[:reason]}") unless testValidation[:valid]
    # 交付评审使用同一最终摘要，防止复核后又改验收结果。
    deliveryValidation = CapabilitySupport.capabilityValidation(iterationPath, "delivery-review", phase: "verify", expectedDigest: expectedVerificationDigest)
    # 交付评审也必须处置所有 P0-P2。
    addError(errors, "#{label} 交付评审能力无效：#{deliveryValidation[:reason]}") unless deliveryValidation[:valid]
  rescue StandardError => error
    # 摘要缺文件或映射损坏时保留根因，不让主校验器崩溃。
    addError(errors, "#{label} 能力门禁校验失败：#{error.message}")
  end

end
