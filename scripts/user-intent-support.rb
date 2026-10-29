#!/usr/bin/env ruby

# 本模块把用户原话解释成阶段审批和迭代执行范围，不修改任何文件。
# 解析基于“目标 + 动作 + 极性”，不再要求整句逐字等于固定口令。
# 需求与计划仍是两个独立审批目标；一句话可以明确授权两个目标。
# “完成所有任务”只覆盖本轮实现任务和统一审核，不再隐含验收或收口。
# 验收与收口使用彼此独立的授权字段，只有明确联合表达才允许连续执行。
# 否定句、疑问句和假设句宁可返回无意图，也不冒险扩大用户授权。
# 普通“继续”“可以”和单独“开始处理”仍不能被解释成阶段审批。
# 调用方必须继续检查阶段、摘要、能力证据和实际允许写入的文件。

# 自然语言授权的确定性解析集中在同一命名空间。
module UserIntentSupport
  # 阶段关键词允许用户使用“需求”或“规格”表达同一个审批对象。
  STAGE_TERMS = {
    "requirements" => /(?:需求|规格)/,
    "plan" => /计划/
  }.freeze
  # 疑问或假设表达不是当前授权，避免把讨论方案误当成批准。
  NON_DECLARATIVE_PATTERNS = [/[?？]/, /吗(?:[呢啊])?(?:[。！!]*)\z/, /是否/, /能否/, /可否/, /能不能/, /可不可以/, /为什么/, /为何/, /怎么/, /咋(?:么)?/, /如何/, /(?:如果|假如|若)/].freeze
  # 审批否定只围绕批准动作判断；“不用再问，自动审批”不会被误拒绝。
  APPROVAL_DENIAL_PATTERNS = [
    /(?:不要|别|不准|禁止|拒绝|取消|暂不|先不|不同意)[^，。；;]{0,8}(?:审批|批准|通过|同意)/,
    /(?:不要|别|不准|禁止|取消|暂不|先不|先别|不需要)[^，。；;]{0,12}(?:完成|走完|处理完|推进完)[^，。；;]{0,12}(?:审批|批准)/,
    /不(?:自动)?(?:审批|批准|通过|同意)/,
    /(?:需求|规格|计划)[^，。；;]{0,8}(?:不通过|不批准|不审批|不同意|先别|暂不|取消)/
  ].freeze
  # 执行否定与审批否定分开；用户可以批准计划但明确要求暂不执行。
  EXECUTION_DENIAL_PATTERNS = [
    /(?:不要|别|不准|禁止|取消|暂不|先不)[^，。；;]{0,8}(?:完成|执行|处理|做完|推进)/,
    /不(?:再|要)?(?:完成|执行|处理|做完|推进)/,
    /(?:任务|本轮|当前轮)[^，。；;]{0,8}(?:不执行|不处理|不完成|先别|暂不)/
  ].freeze
  # 验收否定单独计算，允许“完成实现，但先不验收”只保留实现授权。
  VERIFICATION_DENIAL_PATTERNS = [
    /(?:不要|别|不准|禁止|取消|暂不|先不|先别)[^，。；;]{0,8}(?:验收|验证)/,
    /不(?:再|要)?(?:验收|验证)/
  ].freeze
  # 收口否定不能反向吞掉同一句里的验收授权。
  CLOSURE_DENIAL_PATTERNS = [
    /(?:不要|别|不准|禁止|取消|暂不|先不|先别)[^，。；;]{0,8}(?:收口|归档)/,
    /不(?:再|要)?(?:收口|归档)/
  ].freeze
  # 普通框架写入也必须检查极性，不能因为句中出现“开始处理”就忽略前置否定。
  GENERIC_WRITE_DENIAL_PATTERNS = [
    /(?:不要|别|不准|禁止|取消|暂不|先不|先别)[^，。；;]{0,8}(?:开始处理|开始执行)/,
    /不(?:再|要)?(?:开始处理|开始执行)/
  ].freeze
  # 阶段名允许自带“审批”，覆盖“需求审批和计划审批”这类并列说法。
  REQUIREMENT_TARGET = /(?:需求|规格)(?:审批)?/.freeze
  # 计划目标与需求目标保持同一可选后缀规则。
  PLAN_TARGET = /计划(?:审批)?/.freeze
  # 两阶段联合目标只识别有连接关系的表述，避免“审批需求后写计划”误批计划。
  JOINT_STAGE_TARGET = /(?:#{REQUIREMENT_TARGET}\s*(?:和|与|、|以及|及)\s*#{PLAN_TARGET}|#{PLAN_TARGET}\s*(?:和|与|、|以及|及)\s*#{REQUIREMENT_TARGET})/.freeze

  # 折叠空白并保留中文标点，审批文件仍保存用户真实语义。
  def self.normalize(evidence)
    # nil 和非字符串输入统一转成安全字符串。
    evidence.to_s.gsub(/\s+/, " ").strip
  end

  # 疑问和条件句需要用户真正下达指令后再执行。
  def self.nonDeclarative?(normalizedEvidence)
    # 任一模式命中就保持只读或等待明确表达。
    NON_DECLARATIVE_PATTERNS.any? { |pattern| normalizedEvidence.match?(pattern) }
  end

  # 判断审批动作是否被明确否定。
  def self.approvalDenied?(normalizedEvidence)
    # 否定只影响审批，不会吞掉同句里的其他只读信息。
    APPROVAL_DENIAL_PATTERNS.any? { |pattern| normalizedEvidence.match?(pattern) }
  end

  # 判断任务执行是否被明确否定。
  def self.executionDenied?(normalizedEvidence)
    # 与审批分开计算，支持“计划通过，但先不执行”。
    EXECUTION_DENIAL_PATTERNS.any? { |pattern| normalizedEvidence.match?(pattern) }
  end

  # 判断验收动作是否被明确否定。
  def self.verificationDenied?(normalizedEvidence)
    # 独立极性使“开始验收，但不要收口”仍能安全进入验收。
    VERIFICATION_DENIAL_PATTERNS.any? { |pattern| normalizedEvidence.match?(pattern) }
  end

  # 判断收口动作是否被明确否定。
  def self.closureDenied?(normalizedEvidence)
    # 收口权限最窄，任何明确否定都保持 verify 阶段。
    CLOSURE_DENIAL_PATTERNS.any? { |pattern| normalizedEvidence.match?(pattern) }
  end

  # 判断“开始处理/开始执行”本身是否被明确否定。
  def self.genericWriteDenied?(normalizedEvidence)
    # 独立极性避免“开始处理文档，但不要执行产品任务”被整体误判为无写入授权。
    GENERIC_WRITE_DENIAL_PATTERNS.any? { |pattern| normalizedEvidence.match?(pattern) }
  end

  # 判断一句话是否把需求与计划作为共同审批目标。
  def self.jointApproval?(normalizedEvidence)
    # 没有明确连接的两个名词不构成联合授权。
    return false unless normalizedEvidence.match?(JOINT_STAGE_TARGET)
    # 动作可以放在联合目标前，也可以放在联合目标后。
    approvalBefore = normalizedEvidence.match?(/(?:自动|一并|同时)?(?:审批|批准)[^，。；;]{0,4}#{JOINT_STAGE_TARGET}/)
    # “都通过”是用户最常见的后置批准表达。
    approvalAfter = normalizedEvidence.match?(/#{JOINT_STAGE_TARGET}[^，。；;]{0,6}(?:都|均|一并|全部)?(?:审批通过|批准|通过|没问题|确认通过)/)
    # “自动完成需求和计划审批流程”表达的是把两道审批流程推进完。
    approvalWorkflow = normalizedEvidence.match?(/(?:自动|直接|一并|请|帮我)?(?:完成|走完|处理完|推进完)[^，。；;]{0,3}#{JOINT_STAGE_TARGET}[^，。；;]{0,4}(?:审批|批准)(?:流程)?/)
    # 目标在前时也接受“需求和计划审批流程自动完成”。
    workflowAfter = normalizedEvidence.match?(/#{JOINT_STAGE_TARGET}[^，。；;]{0,4}(?:审批|批准)(?:流程)?[^，。；;]{0,4}(?:自动|一并)?(?:完成|走完|处理完|推进完)/)
    # 任一明确结构都表示两个逻辑门禁获得同一条用户证据。
    approvalBefore || approvalAfter || approvalWorkflow || workflowAfter
  end

  # 判断单个阶段是否具有明确批准表达。
  def self.stageApproved?(stageName, normalizedEvidence)
    # 未知阶段由 fetch 直接暴露给调用方，不能静默退化成无审批。
    stageTerm = STAGE_TERMS.fetch(stageName)
    # “审批需求”“批准计划”属于动作在前的直接表达。
    approvalBefore = normalizedEvidence.match?(/(?:审批|批准)[^，。；;]{0,3}#{stageTerm}/)
    # “需求审批通过”“计划没问题”属于目标在前的直接表达。
    approvalAfter = normalizedEvidence.match?(/#{stageTerm}[^，。；;]{0,4}(?:审批通过|批准通过|已批准|通过|没问题|确认通过)/)
    # “同意需求”“确认计划”也属于明确肯定，但不接受远距离自由文本。
    explicitAgreement = normalizedEvidence.match?(/(?:同意|确认)[^，。；;]{0,2}#{stageTerm}/)
    # 三种结构都不依赖固定整句，仍要求目标和动作紧邻。
    approvalBefore || approvalAfter || explicitAgreement
  end

  # 返回本句明确批准的阶段列表。
  def self.approvalStages(evidence)
    # 所有判断都基于同一份规范化文本。
    normalizedEvidence = normalize(evidence)
    # 空白、疑问、假设或否定审批都不产生授权。
    return [] if normalizedEvidence.empty? || nonDeclarative?(normalizedEvidence) || approvalDenied?(normalizedEvidence)
    # 联合表达一次返回两个目标，后续仍分别绑定各自摘要。
    return STAGE_TERMS.keys if jointApproval?(normalizedEvidence)
    # 单阶段表达逐项判断，不让需求批准自动变成计划批准。
    STAGE_TERMS.keys.select { |stageName| stageApproved?(stageName, normalizedEvidence) }
  end

  # 返回任务执行范围：none、current_task 或 all_tasks。
  def self.executionScope(evidence)
    # 执行语义与审批语义共享规范化和陈述句边界。
    normalizedEvidence = normalize(evidence)
    # 否定、疑问或假设不授权产品文件写入。
    return "none" if normalizedEvidence.empty? || nonDeclarative?(normalizedEvidence) || executionDenied?(normalizedEvidence)
    # 动作在前的表达覆盖“完成所有任务”“执行本轮全部任务”等常见说法。
    allTasksForward = normalizedEvidence.match?(/(?:完成|做(?:完)?|处理(?:完)?|执行(?:完)?|推进(?:完)?)(?:本轮|当前轮|这一轮)?(?:的)?(?:所有|全部)(?:实现)?任务/)
    # 动作在后的表达覆盖“把本轮全部做完”。
    allTasksBackward = normalizedEvidence.match?(/(?:把)?(?:本轮|当前轮|这一轮)(?:的)?(?:所有|全部)?(?:实现)?(?:任务)?(?:都)?(?:完成|做(?:完)?|处理(?:完)?|执行(?:完)?)/)
    # 全任务授权优先于当前任务，避免组合句被意外收窄。
    return "all_tasks" if allTasksForward || allTasksBackward
    # 当前任务授权保留旧的 T-xx 组合句，并允许不重复编号。
    currentTask = normalizedEvidence.match?(/(?:执行|处理|完成)(?:当前|本次)任务(?:\s*T-\d+)?/)
    # 没有任务级动作时不因阶段审批推断产品写入。
    currentTask ? "current_task" : "none"
  end

  # 判断当前原话是否明确授权执行验收。
  def self.verificationAuthorized?(evidence)
    # 验收与任务执行共享陈述句边界，但不共享授权结果。
    normalizedEvidence = normalize(evidence)
    # 空白、疑问、条件或验收否定都不能启动真实校验。
    return false if normalizedEvidence.empty? || nonDeclarative?(normalizedEvidence) || verificationDenied?(normalizedEvidence)
    # 动作在前覆盖“开始验收”“完成本轮验证”等直接指令。
    actionBefore = normalizedEvidence.match?(/(?:开始|执行|进行|继续|完成|做完)[^，。；;]{0,6}(?:验收|验证)/)
    # 目标在前覆盖“验收当前迭代”和“验收并收口”等自然表达。
    targetBefore = normalizedEvidence.match?(/(?:验收|验证)(?:本轮|当前轮|当前迭代|这一轮|(?:并|和|与|及|、)(?:直接)?(?:收口|归档)|(?:完成后|完后|后)(?:直接)?(?:收口|归档))/)
    # verify 阶段常见的单词式命令同样是明确祈使句，不要求固定长文案。
    conciseCommand = normalizedEvidence.match?(/\A(?:验收|验证)(?:吧|一下)?[。！!]?\z/)
    # 实现与验收联合授权允许“完成所有任务并验收”连续跨到 verify。
    afterAllTasks = normalizedEvidence.match?(/(?:完成|做(?:完)?|处理(?:完)?|执行(?:完)?)[^，。；;]{0,12}(?:所有|全部)(?:实现)?任务[^，。；;]{0,6}(?:并|和|与|及|、|后)?(?:验收|验证)/)
    # 只有明确结构才返回 true，孤立提到“验收”仍保持只读。
    actionBefore || targetBefore || afterAllTasks || conciseCommand
  end

  # 判断当前原话是否明确授权把已通过验收的轮次收口。
  def self.closureAuthorized?(evidence)
    # 收口授权使用同一规范化文本，避免标点和空格产生不同解释。
    normalizedEvidence = normalize(evidence)
    # 疑问、条件和明确否定都不能把状态推进到 done。
    return false if normalizedEvidence.empty? || nonDeclarative?(normalizedEvidence) || closureDenied?(normalizedEvidence)
    # 动作在前覆盖“确认收口”“直接归档”等明确指令。
    actionBefore = normalizedEvidence.match?(/(?:开始|执行|进行|确认|完成|直接)[^，。；;]{0,6}(?:收口|归档)/)
    # 目标在前覆盖“收口当前迭代”，但不接受只有名词的讨论句。
    targetBefore = normalizedEvidence.match?(/(?:收口|归档)(?:本轮|当前轮|当前迭代|这一轮)/)
    # 已在 verify 等待时，单独回复“收口”也属于清晰授权。
    conciseCommand = normalizedEvidence.match?(/\A(?:收口|归档)(?:吧|一下)?[。！!]?\z/)
    # 联合表达只有显式出现验收与收口关系时才允许连续完成。
    afterVerification = normalizedEvidence.match?(/(?:验收|验证)[^，。；;]{0,6}(?:并|和|与|及|、|后|完成后)?(?:直接)?(?:收口|归档)/)
    # 任一明确结构都只授予收口，实际 done 仍需新鲜验收和交付证据。
    actionBefore || targetBefore || afterVerification || conciseCommand
  end

  # 汇总调用方最常用的确定性解释结果。
  def self.interpret(evidence)
    # 汇总阶段复用同一份规范化文本，避免普通写入与其他意图使用不同空白语义。
    normalizedEvidence = normalize(evidence)
    # 原始文本只保存在审批或状态证据里，本结果不复制外部权限。
    stageNames = approvalStages(evidence)
    # 执行范围决定是否可以连续推进实现任务。
    taskScope = executionScope(evidence)
    # 验收和收口必须分别来自当前原话，不能由 all_tasks 推导。
    verificationAuthorized = verificationAuthorized?(evidence)
    # 收口授权只决定是否可以尝试交付复核，不能绕过完成门禁。
    closureAuthorized = closureAuthorized?(evidence)
    # 固定写入口令继续兼容；阶段审批只授权框架阶段写入。
    # 疑问、条件和明确否定不构成普通写入授权；只否定产品任务时仍保留文档写入语义。
    genericWrite = !normalizedEvidence.empty? && !nonDeclarative?(normalizedEvidence) && !genericWriteDenied?(normalizedEvidence) && normalizedEvidence.match?(/(?:开始处理|开始执行)/)
    # 返回普通 Hash，兼容系统 Ruby 2.6 且便于单元测试。
    {
      approval_stages: stageNames,
      execution_scope: taskScope,
      verification_authorized: verificationAuthorized,
      closure_authorized: closureAuthorized,
      framework_write: genericWrite || !stageNames.empty? || taskScope != "none" || verificationAuthorized || closureAuthorized,
      external_write: false
    }
  end

  # 把已解释意图映射成当前阶段可执行的稳定路由。
  def self.route(phase, intentResult)
    # 完成态不能被任何历史授权重新打开。
    hasIterationAction = intentResult[:execution_scope] != "none" || intentResult[:verification_authorized] || intentResult[:closure_authorized]
    # 审批在 done 阶段也不重复记录，动作则明确返回不可执行。
    return hasIterationAction ? "execution_not_ready" : "approval_not_applicable" if phase == "done"
    # 联合审批并完成所有实现任务时，按生命周期从当前阶段接续。
    if intentResult[:approval_stages] == STAGE_TERMS.keys && intentResult[:execution_scope] == "all_tasks"
      # 只有三项都明确授权，才允许实现后连续验收并收口。
      continuation = if intentResult[:verification_authorized] && intentResult[:closure_authorized]
                       "all_implementation_tasks_then_verification_then_close"
                     elsif intentResult[:verification_authorized]
                       "all_implementation_tasks_then_verification"
                     else
                       "all_implementation_tasks"
                     end
      # specify 必须先需求、再计划，不能跳过任何阶段能力门禁。
      return "requirements_then_plan_then_#{continuation}" if phase == "specify"
      # plan 已经有需求审批，只需继续计划门禁和明确授权的后续动作。
      return "plan_then_#{continuation}" if phase == "plan"
      # implement 只执行上面已经区分好的授权范围。
      return continuation if phase == "implement"
      # verify 没有剩余实现任务；改按当前原话中的验收和收口字段路由。
    end
    # 只联合审批时仍按阶段拆成两道独立摘要门禁。
    if intentResult[:approval_stages] == STAGE_TERMS.keys
      # specify 路由包含后续计划编制和评审，不代表计划已提前通过。
      return "requirements_then_plan" if phase == "specify"
      # plan 阶段复用此前保存的联合审批原话。
      return "plan_approval" if phase == "plan"
      # 没有迭代动作时，其他阶段只说明审批已经不适用。
      return "approval_not_applicable" unless hasIterationAction
    end
    # 单独需求审批只适用于 specify。
    return "requirements_approval" if phase == "specify" && intentResult[:approval_stages].include?("requirements")
    # 单独计划审批只适用于 plan。
    return "plan_approval" if phase == "plan" && intentResult[:approval_stages].include?("plan")
    # 只有审批且当前阶段不适用时保持原有稳定结果；组合动作继续向下路由。
    return "approval_not_applicable" if !intentResult[:approval_stages].empty? && !hasIterationAction
    # 全任务授权只覆盖 implement 中剩余实现任务与统一审核。
    if intentResult[:execution_scope] == "all_tasks" && phase == "implement"
      # 明确联合验收和收口时才允许连续跨越后两道边界。
      return "all_implementation_tasks_then_verification_then_close" if intentResult[:verification_authorized] && intentResult[:closure_authorized]
      # 只联合验收时在验收完成后仍必须等待收口授权。
      return "all_implementation_tasks_then_verification" if intentResult[:verification_authorized]
      # 单独 all_tasks 在统一审核后停止并等待验收。
      return "all_implementation_tasks"
    end
    # 当前任务授权不能从规格、计划或完成态启动产品写入。
    return phase == "implement" ? "current_task" : "execution_not_ready" if intentResult[:execution_scope] == "current_task"
    # verify 阶段可显式联合执行验收和收口。
    return "verification_then_close" if phase == "verify" && intentResult[:verification_authorized] && intentResult[:closure_authorized]
    # 单独验收授权只运行测试验证，完成后保持 verify 等待收口。
    return "run_verification" if phase == "verify" && intentResult[:verification_authorized]
    # 单独收口授权只在已有新鲜验收证据时运行交付复核并尝试 done。
    return "close_iteration" if phase == "verify" && intentResult[:closure_authorized]
    # 在前置阶段请求验收或收口不能跳过实现和统一审核。
    return "verification_not_ready" if intentResult[:verification_authorized]
    # 收口同样只能发生在 verify，且仍受所有完成门禁约束。
    return "closure_not_ready" if intentResult[:closure_authorized]
    # verify 中重复“完成所有任务”不再被误解释为验收授权。
    return "execution_not_ready" if intentResult[:execution_scope] == "all_tasks"
    # 普通写入授权和无动作表达都不能跨阶段门禁。
    "no_iteration_action"
  end

  # 一次返回语义和阶段路由，供每回合恢复入口直接消费。
  def self.interpretForPhase(phase, evidence)
    # 保留原解释字段，审批脚本仍可独立复用低层 API。
    intentResult = interpret(evidence)
    # route 使用同一个结果，避免同一原话被重复解析出不同结论。
    intentResult.merge(intent_route: route(phase, intentResult))
  end
end
