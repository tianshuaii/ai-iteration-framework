#!/usr/bin/env ruby

# 本模块只校验单轮任务、仓库基线、验收链路和完成态结果。
# 主校验器负责目录发现、阶段能力、worktree 和全局输出，本模块不重复扫描系统。
# 历史 file-map 由调用方先校验，再作为只读映射传入，避免重新解析同一文件。
# 所有错误继续追加到调用方的数组，保持原有顺序、文案和一次性汇总行为。
# 模块只读取轮次文件，不执行外部命令，也不修改状态或证据。
# 保持 Ruby 2.6 兼容，不引入 gem、并行线程或新的每轮产物。
# 独立模块让高频内容规则可以在不扩大主入口上下文的情况下维护。

require "pathname"
require_relative "capability-support"
require_relative "risk-test-support"

# 单轮内容门禁集中在命名空间中，避免向主脚本继续暴露顶层方法。
module IterationContentValidation
  # 模块函数既可由主入口直接调用，也保持内部辅助方法不污染 Object。
  module_function

  # 将内容问题写入调用方的统一错误集合。
  def addError(errors, message)
    # 保留原有追加语义，错误顺序仍按校验执行顺序稳定输出。
    errors << message
  end

# 识别一轮是否已经明确采用 bounded-v1 浅回归协议。
# 显式标记是新模板的首选事实源，不能被正文格式变化覆盖。
# 少数迁移轮在标记引入前已经写入新版五列表，因此还需识别表头。
# 旧版四列表同样使用 SR 编号，但第二列是功能描述，不代表新协议类型。
# 这里不按日期或具体轮次名判断，避免把历史路径硬编码进通用校验器。
def boundedShallowPolicyEnabled?(testStrategyContent)
  # 新模板有标记时直接启用，后续内容校验会继续发现缺行或非法类型。
  return true if testStrategyContent.include?("<!-- shallow-regression-policy: bounded-v1 -->")

  # 无标记迁移轮必须保留新版“类型”表头，才能证明采用过 bounded-v1。
  testStrategyContent.each_line.any? do |line|
    # 只识别 Markdown 表头，不把正文里偶然出现的“类型”二字当成协议证据。
    line.match?(/^\|\s*编号\s*\|\s*类型\s*\|/)
  end
end


  # 根据已经校验过的 file-map 解析本轮标准文件。
  def resolveIterationFile(iterationPath, fileMap, standardName)
    # 未映射文件继续使用标准英文名，历史轮次只影响自己的直接子文件。
    actualName = fileMap.fetch(standardName, standardName)
    # file-map 的路径安全由主校验器先行验证，这里只复用确定结果。
    iterationPath.join(actualName)
  end

# 解析任务清单，返回后续阶段门禁可以复用的结构化任务。
def readTasks(errors, tasksPath, label, enforceDetails)
  # 文件缺失已经由必需文件检查报告，这里返回空集合避免重复异常。
  return [] unless tasksPath.file?

  # 每个任务保存编号、完成状态、依赖和原始行。
  tasks = []
  # 逐行只识别标准 Markdown checkbox 任务。
  tasksPath.read.each_line do |line|
    # 普通说明和链接列表不属于任务。
    match = line.match(/^- \[([ xX])\] (T-\d+)\b(.*)$/)
    # 没匹配的行直接跳过。
    next unless match

    # 任务编号用于唯一性、依赖和 current_task 检查。
    taskId = match[2]
    # x 或 X 都表示已完成，空格表示尚未完成。
    completed = match[1].downcase == "x"
    # 剩余正文包含依赖、文件和检查命令。
    detail = match[3]
    # 依赖字段截止到文件字段，允许中间使用自然语言补充。
    dependencyText = detail[/依赖：(.+?)(?:。文件：|\z)/, 1]
    # 从依赖字段提取所有任务编号。
    dependencies = dependencyText.to_s.scan(/T-\d+/)

    # 进入实现后每条任务都必须具备可执行的三个字段。
    if enforceDetails
      # 缺依赖会让顺序检查失效。
      addError(errors, "#{label} #{taskId} 缺少依赖") unless detail.include?("依赖：")
      # 文件范围是产品写入边界的一部分。
      addError(errors, "#{label} #{taskId} 缺少文件范围") unless detail.include?("文件：")
      # 检查命令必须真实存在，不能保留模板占位符。
      hasCheck = detail.include?("检查：") && !detail.match?(/检查：\s*(?:一条命令)?\s*$/)
      # 没有检查命令时任务不能被勾选。
      addError(errors, "#{label} #{taskId} 缺少可执行检查命令") unless hasCheck
    end

    # 保存结构化结果，阶段门禁不再重复解析原文。
    tasks << { id: taskId, completed: completed, dependencies: dependencies, line: line.strip }
  end

  # 重复编号会让 current_task 和依赖解析产生歧义。
  duplicateIds = tasks.group_by { |task| task[:id] }.select { |_taskId, rows| rows.length > 1 }.keys
  # 每个重复编号单独报告，便于直接定位。
  duplicateIds.each { |taskId| addError(errors, "#{label} 任务编号重复：#{taskId}") }
  # 所有依赖都必须指向同一份任务清单中的其他任务。
  taskIds = tasks.map { |task| task[:id] }
  # 逐任务检查未知依赖和自依赖。
  tasks.each do |task|
    # 自依赖永远无法完成。
    addError(errors, "#{label} #{task[:id]} 不能依赖自己") if task[:dependencies].include?(task[:id])
    # 指向不存在任务的依赖无法用于阶段门禁。
    task[:dependencies].each do |dependencyId|
      # 只报告真正缺失的任务编号。
      addError(errors, "#{label} #{task[:id]} 依赖不存在：#{dependencyId}") unless taskIds.include?(dependencyId)
    end
  end
  # 返回解析结果供 current_task 和阶段检查使用。
  tasks
end

# 读取以编号开头的 Markdown 表格数据行。
def readTableRows(content, idPattern)
  # 返回值按编号保存，便于检查重复和结果列。
  rows = []
  # 表格正文逐行解析，不把表头和分隔行当成数据。
  content.each_line do |line|
    # 只接受首尾都有竖线的常规 Markdown 表格。
    next unless line.strip.start_with?("|") && line.strip.end_with?("|")
    # 去掉首尾空单元格后再清理每列空白。
    # 保留结尾空单元格，才能在去掉首尾边界后留下真正的最后一列。
    cells = line.strip.split("|", -1)[1...-1].map(&:strip)
    # 第一列不符合目标编号时属于其他表格。
    next unless cells.first&.match?(idPattern)
    # 保留整行单元格，调用方决定结果列的位置。
    rows << cells
  end
  # 返回当前文件内目标类型的全部数据行。
  rows
end

# 检查编号集合是否存在重复项。
def validateUniqueIds(errors, rows, label)
  # 按第一列编号分组，出现两行以上就是重复。
  duplicateIds = rows.group_by(&:first).select { |_rowId, groupedRows| groupedRows.length > 1 }.keys
  # 每个重复编号单独输出，避免只给笼统错误。
  duplicateIds.each { |rowId| addError(errors, "#{label} 编号重复：#{rowId}") }
end

# 校验一轮迭代的任务、仓库基线、验收链路和完成态证据。
def validate(errors, iterationPath, statusFields, fileMap, label)
  # phase 决定当前轮次需要启用哪些内容门禁。
  phase = statusFields["phase"]
  # 非法或缺失 phase 已由状态校验报告，这里不制造连锁错误。
  return unless %w[specify plan implement verify done].include?(phase)
  # current_task 只在 implement 阶段参与精确任务检查。
  currentTask = statusFields["current_task"]
  # work_state 用于判断产品工作是否已经实际开始。
  workState = statusFields["work_state"]

  # 进入实现后，每条任务都必须具备完整的依赖、文件和检查信息。
  tasksPath = resolveIterationFile(iterationPath, fileMap, "tasks.md")
  # specify 和 plan 允许模板仍在填写；implement 之后必须严格校验。
  enforceTaskDetails = %w[implement verify done].include?(phase)
  # 历史中文任务清单和标准英文任务清单使用同一门禁，不再整体豁免。
  tasks = readTasks(errors, tasksPath, label, enforceTaskDetails)
  # 进入实现后没有真实任务，说明计划阶段尚未完成。
  addError(errors, "#{label} #{phase} 阶段没有任务") if enforceTaskDetails && tasks.empty?

  # implement 的 current_task 指向未完成任务；全部任务写完后用“无”进入统一审核窗口。
  if phase == "implement" && tasksPath.file? && currentTask
    if currentTask == "无"
      # 统一审核只能在全部实现任务已经勾选后开始。
      pendingTaskIds = tasks.reject { |task| task[:completed] }.map { |task| task[:id] }
      # 仍有未完成任务时不能提前隐藏 current_task。
      addError(errors, "#{label} 统一审核前仍有未完成任务：#{pendingTaskIds.join(', ')}") unless pendingTaskIds.empty?
    else
      # 从结构化任务里精确查找，避免 T-01 错命中 T-010。
      currentTaskRecord = tasks.find { |task| task[:id] == currentTask }
      # 找不到未勾任务时，状态与任务清单已经漂移。
      addError(errors, "#{label} current_task 不存在或已经完成：#{currentTask}") unless currentTaskRecord && !currentTaskRecord[:completed]
      # 当前任务的依赖必须全部完成，不能只依赖列表顺序。
      if currentTaskRecord
        # 建立已完成编号集合，依赖检查保持线性复杂度。
        completedTaskIds = tasks.select { |task| task[:completed] }.map { |task| task[:id] }
        # 找出尚未完成的显式依赖。
        unfinishedDependencies = currentTaskRecord[:dependencies] - completedTaskIds
        # 任一依赖未完成都阻断当前任务。
        addError(errors, "#{label} #{currentTask} 仍有未完成依赖：#{unfinishedDependencies.join(', ')}") unless unfinishedDependencies.empty?
      end
    end
  end

  # verify 和 done 都要求全部实现任务已经完成。
  if %w[verify done].include?(phase)
    # 收集所有尚未勾选的实现任务。
    pendingTaskIds = tasks.reject { |task| task[:completed] }.map { |task| task[:id] }
    # 遗留任务说明阶段提前推进。
    addError(errors, "#{label} #{phase} 仍有未完成任务：#{pendingTaskIds.join(', ')}") unless pendingTaskIds.empty?
  end

  # 产品修改已经开始或进入验收时，仓库基线通常不能保留模板占位符。
  baselineRequired = (phase == "implement" && %w[in_progress blocked].include?(workState)) || %w[verify done].include?(phase)
  # workspace 使用标准名，不依赖自然语言断点代替仓库证据。
  workspacePath = resolveIterationFile(iterationPath, fileMap, "workspace.md")
  # 没有能力日志的 done 轮次明确属于能力门禁引入前的历史档案。
  historicalDoneWithoutCapabilityLog = phase == "done" && !iterationPath.join(CapabilitySupport::LOG_FILE).file?
  # 历史完成轮不追补当时不存在的逐文件基线；活动轮和已采用能力协议的轮次仍严格检查。
  enforceWorkspaceBaseline = baselineRequired && !historicalDoneWithoutCapabilityLog
  # 有产品工作时必须至少有一条真实基线记录。
  if enforceWorkspaceBaseline && workspacePath.file?
    # 一次读取正文，同时检查占位符和逐文件 dirty 证据。
    workspaceContent = workspacePath.read
    # 占位符说明尚未采集 HEAD 和 dirty 文件。
    addError(errors, "#{label} 产品仓库基线尚未采集") if workspaceContent.include?("尚未采集")
    # 只有数量不能支持下一位 Agent 区分既有改动和自己产生的改动。
    addError(errors, "#{label} 产品仓库基线缺少 dirty 明细") unless workspaceContent.include?("## 接管前 dirty 明细")
  end

  # 新协议在计划阶段为每条任务确定测试深度和影响宽度；旧轮次继续兼容。
  testStrategyPath = resolveIterationFile(iterationPath, fileMap, "test-strategy.md")
  # 文件缺失由档案检查统一报告，这里用空文本避免重复读取异常。
  testStrategyContent = testStrategyPath.file? ? testStrategyPath.read : ""
  # 策略表必须覆盖当前任务集合，不能因代码行数少而隐式跳过高风险检查。
  riskTestValidation = RiskTestSupport.validation(
    testStrategyContent,
    taskIds: tasks.map { |task| task[:id] },
    phase: phase
  )
  # 一次输出具体缺失或非法任务，避免逐项修复、逐项重跑校验器。
  addError(errors, "#{label} 风险测试策略无效：#{riskTestValidation[:reason]}") unless riskTestValidation[:valid]

  # specify、plan 和 implement 不需要解析验收表格。
  return unless %w[verify done].include?(phase)
  # 验收标准、测试用例、测试记录和跟踪表必须互相对应。
  acceptancePath = resolveIterationFile(iterationPath, fileMap, "acceptance.md")
  # 测试用例标题是 TC 编号的事实源。
  testCasesPath = resolveIterationFile(iterationPath, fileMap, "test-cases.md")
  # 测试记录每个 TC 只能保留一行当前结果。
  testLogPath = resolveIterationFile(iterationPath, fileMap, "test-log.md")
  # 跟踪表必须覆盖全部验收编号。
  traceabilityPath = resolveIterationFile(iterationPath, fileMap, "traceability.md")
  # 最终评审清单只在 done 阶段要求全部完成。
  reviewPath = resolveIterationFile(iterationPath, fileMap, "review-checklist.md")

  # 只有文件存在时才继续内容检查，缺失错误已由档案检查报告。
  acceptanceRows = acceptancePath.file? ? readTableRows(acceptancePath.read, /\AAC-\d+\z/) : []
  # verify 之前必须已经定义至少一条可核实的验收标准。
  addError(errors, "#{label} #{phase} 没有验收标准") if acceptanceRows.empty?
  # AC 编号不能重复，否则跟踪关系不唯一。
  validateUniqueIds(errors, acceptanceRows, "#{label} 验收标准")
  # 从二级标题提取测试用例编号。
  testCaseIds = testCasesPath.file? ? testCasesPath.read.scan(/^## (TC-\d+)\b/).flatten : []
  # 没有测试用例时，空集合之间的差集不能证明链路完整。
  addError(errors, "#{label} #{phase} 没有测试用例") if testCaseIds.empty?
  # 测试用例标题也必须唯一。
  duplicateTestCaseIds = testCaseIds.group_by(&:itself).select { |_testId, rows| rows.length > 1 }.keys
  # 逐项报告重复标题。
  duplicateTestCaseIds.each { |testId| addError(errors, "#{label} 测试用例编号重复：#{testId}") }
  # 测试记录行使用同一套表格解析。
  testLogRows = testLogPath.file? ? readTableRows(testLogPath.read, /\ATC-\d+\z/) : []
  # 同一个 TC 出现两行会让当前结果不唯一。
  validateUniqueIds(errors, testLogRows, "#{label} 测试记录")
  # 活动 verify 必须采用新规则；历史 done 只在明确采用 bounded-v1 时执行新门禁。
  # 显式标记和新版表头都比日期推断稳定，也不会把旧版 SR 四列表误判成新协议。
  shallowPolicyEnabled = boundedShallowPolicyEnabled?(testStrategyContent)
  # verify 总是要求浅回归，避免旧活动轮次借兼容分支跳过未来验收。
  shallowRequired = phase == "verify" || shallowPolicyEnabled
  # 先给完成态逻辑一个稳定空集合；启用新协议后再解析真实记录。
  shallowLogRows = []
  if shallowRequired
    # 浅功能回归范围由测试策略中的 SR 编号定义，和正式 AC/TC 保持分离。
    shallowStrategyRows = readTableRows(testStrategyContent, /\ASR-\d+\z/)
    # 至少覆盖一条本轮直接功能和一条一层高概率相邻功能。
    addError(errors, "#{label} #{phase} 缺少受控浅功能回归范围") if shallowStrategyRows.empty?
    # 重复编号会让用例和日志无法唯一对应。
    validateUniqueIds(errors, shallowStrategyRows, "#{label} 浅功能回归范围")
    # 类型只允许直接或相邻，防止用模糊的“全量”扩张测试范围。
    shallowTypes = shallowStrategyRows.map { |row| row[1] }
    # 两类范围缺一都会偏离本轮直接功能加受影响功能的约定。
    addError(errors, "#{label} 浅功能回归缺少直接功能") unless shallowTypes.include?("直接")
    addError(errors, "#{label} 浅功能回归缺少相邻功能") unless shallowTypes.include?("相邻")
    # 每行必须写清功能、纳入理由和停止边界，避免浅回归演变成全系统回归。
    incompleteShallowRows = shallowStrategyRows.select { |row| row.length < 5 || row[2..4].any? { |value| value.to_s.empty? } }.map(&:first)
    # 一次报告所有不完整范围项。
    addError(errors, "#{label} 浅功能回归范围不完整：#{incompleteShallowRows.join(', ')}") unless incompleteShallowRows.empty?
    # SR 用例正文和 TC 一样使用二级标题，便于执行时定位步骤。
    shallowCaseIds = testCasesPath.file? ? testCasesPath.read.scan(/^## (SR-\d+)\b/).flatten : []
    # 用例编号仍需唯一。
    duplicateShallowCaseIds = shallowCaseIds.group_by(&:itself).select { |_testId, rows| rows.length > 1 }.keys
    # 报告重复的浅回归用例。
    duplicateShallowCaseIds.each { |testId| addError(errors, "#{label} 浅功能回归用例编号重复：#{testId}") }
    # 测试记录必须为每个 SR 保留当前结果。
    shallowLogRows = testLogPath.file? ? readTableRows(testLogPath.read, /\ASR-\d+\z/) : []
    # 同一 SR 不能出现两个当前结果。
    validateUniqueIds(errors, shallowLogRows, "#{label} 浅功能回归记录")
    # 策略、用例和日志三处编号必须完全一致。
    shallowStrategyIds = shallowStrategyRows.map(&:first)
    shallowLoggedIds = shallowLogRows.map(&:first)
    # 分别报告正文或记录缺口，方便直接补齐。
    addError(errors, "#{label} 浅功能回归缺少用例：#{(shallowStrategyIds - shallowCaseIds).join(', ')}") unless (shallowStrategyIds - shallowCaseIds).empty?
    addError(errors, "#{label} 浅功能回归包含未登记用例：#{(shallowCaseIds - shallowStrategyIds).join(', ')}") unless (shallowCaseIds - shallowStrategyIds).empty?
    addError(errors, "#{label} 浅功能回归缺少记录：#{(shallowStrategyIds - shallowLoggedIds).join(', ')}") unless (shallowStrategyIds - shallowLoggedIds).empty?
    addError(errors, "#{label} 浅功能回归包含未知记录：#{(shallowLoggedIds - shallowStrategyIds).join(', ')}") unless (shallowLoggedIds - shallowStrategyIds).empty?
  end
  # 验收标准引用的每个 TC 都必须真实存在。
  referencedTestIds = acceptanceRows.flat_map { |row| row[1].to_s.scan(/TC-\d+/) }.uniq
  # 每条 AC 都必须至少关联一个测试用例，不能靠其他 AC 的引用蒙混通过。
  acceptanceRows.each do |row|
    # 第二列是模板规定的“对应测试”列。
    addError(errors, "#{label} #{row.first} 没有关联测试用例") if row[1].to_s.scan(/TC-\d+/).empty?
  end
  # 找出验收引用但没有用例正文的编号。
  missingTestCases = referencedTestIds - testCaseIds
  # 缺少用例时跟踪链不完整。
  addError(errors, "#{label} 验收引用不存在的测试用例：#{missingTestCases.join(', ')}") unless missingTestCases.empty?
  # 没有被任何 AC 引用的用例同样失去验收目的。
  orphanTestCases = testCaseIds - referencedTestIds
  # 逐项汇总孤立用例，便于回到验收表修正关系。
  addError(errors, "#{label} 测试用例未关联验收：#{orphanTestCases.join(', ')}") unless orphanTestCases.empty?
  # 每个测试用例都应在测试记录中有唯一一行。
  loggedTestIds = testLogRows.map(&:first)
  # 找出尚未建立记录行的用例。
  missingTestLogs = testCaseIds - loggedTestIds
  # 没有记录行的用例无法在 done 时证明结果。
  addError(errors, "#{label} 测试记录缺少用例：#{missingTestLogs.join(', ')}") unless missingTestLogs.empty?
  # 测试记录不得出现没有用例正文的游离编号。
  unknownTestLogs = loggedTestIds - testCaseIds
  # 游离记录可能来自删除或改名后的旧用例，必须显式处理。
  addError(errors, "#{label} 测试记录包含未知用例：#{unknownTestLogs.join(', ')}") unless unknownTestLogs.empty?
  # 跟踪表至少要出现每个验收编号。
  traceabilityContent = traceabilityPath.file? ? traceabilityPath.read : ""
  # 找出未进入跟踪表的验收编号。
  missingTraceability = acceptanceRows.map(&:first).reject { |acceptanceId| traceabilityContent.match?(/\b#{Regexp.escape(acceptanceId)}\b/) }
  # 跟踪缺口会让需求、验收和文件失去对应关系。
  addError(errors, "#{label} 跟踪表缺少验收：#{missingTraceability.join(', ')}") unless missingTraceability.empty?
  # 测试用例也必须出现在跟踪表，保证实现文件能反查到验证入口。
  missingTestTraceability = testCaseIds.reject { |testId| traceabilityContent.match?(/\b#{Regexp.escape(testId)}\b/) }
  # 单独报告 TC 缺口，避免和 AC 缺口混在一起难以定位。
  addError(errors, "#{label} 跟踪表缺少测试用例：#{missingTestTraceability.join(', ')}") unless missingTestTraceability.empty?

  # verify 允许未测或未过，用 work_state 和断点表达阻塞。
  return unless phase == "done"
  # 验收豁免必须同时写明用户确认和残余风险，普通“收口”不能绕过门禁。
  validAcceptanceWaivers = acceptanceRows.select do |row|
    # 结果列使用固定前缀，并在同一单元格保留完整决策依据。
    result = row.last.to_s
    # 空结果会得到空字符串并正常判定失败，不让格式异常触发脚本崩溃。
    result.start_with?("豁免：") && result.include?("用户确认") && result.include?("残余风险")
  end
  # 找出使用豁免前缀但证据不完整的验收项。
  invalidAcceptanceWaiverIds = acceptanceRows.select { |row| row.last.to_s.start_with?("豁免") }.map(&:first) - validAcceptanceWaivers.map(&:first)
  # 缺少任一证据都不能成为完成态。
  addError(errors, "#{label} 验收豁免缺少用户确认或残余风险：#{invalidAcceptanceWaiverIds.join(', ')}") unless invalidAcceptanceWaiverIds.empty?
  # done 时每条验收必须通过或具有受控豁免；未测、失败、SKIP 和“收口”仍被拒绝。
  acceptedAcceptanceIds = acceptanceRows.select { |row| row.last == "通过" }.map(&:first) + validAcceptanceWaivers.map(&:first)
  # 找出既未通过也未合法豁免的验收编号。
  failedAcceptanceIds = acceptanceRows.map(&:first) - acceptedAcceptanceIds
  # 非终态结果逐项汇总。
  addError(errors, "#{label} done 验收未全部通过或受控豁免：#{failedAcceptanceIds.join(', ')}") unless failedAcceptanceIds.empty?

  # 测试豁免的结果列固定写“豁免”，详细证据放在现象列。
  validTestWaivers = testLogRows.select do |row|
    # 现象列必须同时保留用户确认和仍未覆盖的残余风险。
    row[2] == "豁免" && row[3].to_s.include?("用户确认") && row[3].to_s.include?("残余风险")
  end
  # 结果写了豁免但证据不完整时单独报告。
  invalidTestWaiverIds = testLogRows.select { |row| row[2] == "豁免" }.map(&:first) - validTestWaivers.map(&:first)
  # 不完整豁免不能被当成通过。
  addError(errors, "#{label} 测试豁免缺少用户确认或残余风险：#{invalidTestWaiverIds.join(', ')}") unless invalidTestWaiverIds.empty?
  # done 时每条测试必须通过或具有受控豁免。
  acceptedTestIds = testLogRows.select { |row| row[2] == "通过" }.map(&:first) + validTestWaivers.map(&:first)
  # 找出仍是未测、未通过、SKIP、收口或无效豁免的测试。
  failedTestIds = testLogRows.map(&:first) - acceptedTestIds
  # 没有测试记录行不能证明验收完成。
  addError(errors, "#{label} done 没有测试记录") if testLogRows.empty?
  # 非终态测试结果阻止收口。
  addError(errors, "#{label} done 测试未全部通过或受控豁免：#{failedTestIds.join(', ')}") unless failedTestIds.empty?

  if shallowRequired
    # 浅功能回归可以受控豁免，但必须和正式测试一样留下用户确认及残余风险。
    validShallowWaivers = shallowLogRows.select do |row|
      # 结果列和现象列沿用测试记录的固定结构。
      row[2] == "豁免" && row[3].to_s.include?("用户确认") && row[3].to_s.include?("残余风险")
    end
    # 结果写豁免但证据不全时阻断完成态。
    invalidShallowWaiverIds = shallowLogRows.select { |row| row[2] == "豁免" }.map(&:first) - validShallowWaivers.map(&:first)
    # 给出具体 SR 编号，避免和 AC/TC 豁免混淆。
    addError(errors, "#{label} 浅功能回归豁免缺少用户确认或残余风险：#{invalidShallowWaiverIds.join(', ')}") unless invalidShallowWaiverIds.empty?
    # done 时每条 SR 都必须通过或具有完整受控豁免。
    acceptedShallowIds = shallowLogRows.select { |row| row[2] == "通过" }.map(&:first) + validShallowWaivers.map(&:first)
    # 未测、未通过或普通跳过都不能完成收口。
    failedShallowIds = shallowLogRows.map(&:first) - acceptedShallowIds
    # 空记录和失败结果分别给出明确错误。
    addError(errors, "#{label} done 没有浅功能回归记录") if shallowLogRows.empty?
    addError(errors, "#{label} done 浅功能回归未全部通过或受控豁免：#{failedShallowIds.join(', ')}") unless failedShallowIds.empty?
  end

  # 受控测试豁免必须同步到引用它的验收项，避免验收结果伪装成普通通过。
  waivedTestIds = validTestWaivers.map(&:first)
  # 逐条验收检查其引用的测试是否包含豁免。
  acceptanceRows.each do |row|
    # 第二列保存当前验收关联的全部 TC 编号。
    linkedTestIds = row[1].to_s.scan(/TC-\d+/)
    # 只要引用了豁免测试，验收结果也必须是受控豁免。
    referencesWaivedTest = !(linkedTestIds & waivedTestIds).empty?
    # 当前验收是否已经通过完整证据校验。
    acceptanceWaived = validAcceptanceWaivers.any? { |waiverRow| waiverRow.first == row.first }
    # 单边测试豁免会让验收结果失真。
    addError(errors, "#{label} 豁免测试未同步到验收：#{row.first}") if referencesWaivedTest && !acceptanceWaived
    # 没有任何测试豁免时，验收本身也不能凭空豁免。
    addError(errors, "#{label} 验收豁免没有对应测试豁免：#{row.first}") if acceptanceWaived && !referencesWaivedTest
  end
  # 评审清单必须存在真实 checkbox，空文件不能通过。
  reviewChecks = reviewPath.file? ? reviewPath.read.scan(/^- \[([ xX])\]/).flatten : []
  # 空清单不能证明执行过最终评审。
  addError(errors, "#{label} done 没有评审清单项") if reviewChecks.empty?
  # 任一未勾清单项都阻止收口。
  addError(errors, "#{label} done 仍有未完成评审") if reviewChecks.any? { |mark| mark == " " }
end

end
