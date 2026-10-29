#!/usr/bin/env ruby

# 本脚本只读汇总一轮迭代的恢复上下文，不创建、修改或删除任何文件。
# 输出只包含状态、审批、当前任务、能力索引和下一批必读文件。
# 详细需求、源码与证据正文仍按当前阶段按需读取，避免一次加载整轮档案。
# status.md 继续是唯一动态进度源，本脚本不是第二份状态或缓存。
# 历史轮次缺少 workflow_profile 时按 standard 显示，与校验器保持一致。
# 所有路径都从脚本位置和用户给出的轮次目录推导，不硬编码系统名称。
# 可选 --intent 接收当前用户原话，让恢复入口同时给出确定性动作路由。
# 意图输出只辅助 Agent 选择流程，不替代审批、能力、摘要和写入边界。
# 调用方必须把原话作为单个安全参数传入，不能把未转义文本拼接进 shell。
# 本脚本本身不执行原话中的任何内容，也不会把原话回显到输出。

require "pathname"
require_relative "capability-support"
require_relative "stage-approval-support"
require_relative "user-intent-support"

# 默认只需轮次目录；每个用户回合应再传 --intent 和完整原话。
validArguments = ARGV.length == 1 || (ARGV.length == 3 && ARGV[1] == "--intent")
# 拒绝其他组合，避免部分原话被误当成完整授权。
abort "用法：ruby scripts/iteration-context.rb systems/<system>/iterations/<iteration> [--intent 用户原话]" unless validArguments
# 原话只在内存中解释，不写入上下文缓存或状态文件。
intentEvidence = ARGV[1] == "--intent" ? ARGV[2] : nil

# 框架根目录从脚本位置取得，移动整个框架后仍可使用同一命令。
frameworkRoot = Pathname.new(__dir__).join("..").realpath
# 先验证用户路径存在，再调用 realpath 消除软链接和相对路径差异。
requestedPath = Pathname.new(ARGV[0]).expand_path
# 不存在的路径不能作为恢复来源，直接给出明确错误。
abort "轮次目录不存在：#{requestedPath}" unless requestedPath.directory?
# 规范化路径用于下面的固定层级校验。
iterationPath = requestedPath.realpath
# 一轮必须直接位于某个系统的 iterations/ 下。
iterationsRoot = iterationPath.parent
# 系统目录是 iterations/ 的直接父级，不从轮次名猜系统名。
systemPath = iterationsRoot.parent
# 框架只信任 systems/ 下的登记系统，拒绝任意外部目录伪装成轮次。
systemsRoot = frameworkRoot.join("systems").realpath
# 同时检查目录层级和系统父目录，避免 `../` 或软链接越界。
abort "目标必须是 systems/<system>/iterations/<iteration>" unless iterationsRoot.basename.to_s == "iterations" && systemPath.parent == systemsRoot

# status.md 是恢复上下文的唯一动态输入；缺失时不尝试从其他文档拼状态。
statusPath = iterationPath.join("status.md")
# 半创建轮次不能产生看似可信的上下文摘要。
abort "轮次缺少 status.md：#{iterationPath}" unless statusPath.file?
# 一次读取小型状态文件，避免每个字段重复访问磁盘。
statusContent = statusPath.read

# 状态字段沿用框架的 Markdown 列表格式；未知字段返回“无”便于人类诊断。
def readStatusValue(content, fieldName)
  # 锚定行首，正文中的同名单词不会被误读成状态值。
  content[/^- #{Regexp.escape(fieldName)}:\s*(.+)$/, 1]&.strip || "无"
end

# 当前阶段先给出常态最小集合，后面再按问题、任务和明确意图做窄幅调整。
phaseReadSets = {
  # 规格常态只读目标、既有决定、写入边界和验收标准；测试细节在对应动作时按需读取。
  "specify" => %w[requirements.md decisions.md change-scope.md acceptance.md],
  # 计划常态保留已审批目标和范围，只读方案与任务；资源预留在计划审批时切入。
  "plan" => %w[requirements.md change-scope.md implementation-plan.md tasks.md],
  # 实现集合由当前任务和既有审核证据动态生成，这里不保存第二套任务状态。
  "implement" => [],
  # 验收常态只读验收、风险策略、用例和既有结果；收口材料由明确意图追加。
  "verify" => %w[acceptance.md test-strategy.md test-cases.md test-log.md],
  # 完成态没有默认后续动作；交付证据只在用户明确审计或复核时按需读取。
  "done" => []
}.freeze

# 单独收口不重跑测试设计，只核对验收结果、交付清单和工作区生命周期。
closureReadFiles = %w[acceptance.md test-log.md review-checklist.md workspace.md].freeze
# 联合验收收口显式跨越两段流程，才一次提供测试与交付两组最小材料。
verificationThenClosureReadFiles = %w[acceptance.md test-strategy.md test-cases.md test-log.md review-checklist.md workspace.md].freeze

# 先读取六个恢复字段，输出顺序与 status.md 模板保持一致。
phase = readStatusValue(statusContent, "phase")
# 档位通过共享模块读取，使历史兼容默认值只有一个实现。
workflowProfile = CapabilitySupport.workflowProfile(iterationPath)
# 当前任务只在 implement 阶段有编号，其他阶段通常为“无”。
currentTask = readStatusValue(statusContent, "current_task")
# 工作状态告诉 Agent 是开始、续做、解除阻塞还是只读归档。
workState = readStatusValue(statusContent, "work_state")

# 可选用户原话由共享解析器一次解释并路由，审批脚本和恢复入口不会出现两套语义。
intentResult = intentEvidence ? UserIntentSupport.interpretForPhase(phase, intentEvidence) : nil
# 没有 --intent 时保持旧版纯恢复输出，兼容已有只读调用方。

# 审批记录不替代状态，但恢复时需要知道两道门是否有效或已经过期。
approvalPath = iterationPath.join(StageApproval::FILE_NAME)
# 缺失或损坏时保留明确摘要，不在只读脚本里尝试修复。
approvalRecords = approvalPath.file? ? StageApproval.parse(approvalPath.read) : nil
# 两个阶段使用同一共享校验，摘要变化会显示 stale 或 invalid。
approvalSummaries = StageApproval::STAGES.keys.to_h do |stageName|
  # 结构无效时不能调用 validation 猜测记录内容。
  if approvalRecords
    # validation 返回状态、原因和当前摘要，输出只取恢复所需的状态与原因。
    begin
      # 残缺阶段文档不应让只读恢复脚本崩溃；校验异常降级成可见诊断。
      validation = StageApproval.validation(iterationPath, stageName, approvalRecords)
      # 将机器状态和人类原因放在同一行，减少后续再次读取审批文件。
      [stageName, "#{validation[:state]}（#{validation[:reason]}）"]
    rescue StandardError => error
      # 只暴露异常类型和消息，不输出调用栈或潜在文件正文。
      [stageName, "invalid（#{error.class}: #{error.message}）"]
    end
  else
    # 缺文件与格式损坏都作为 invalid，详细路径已经在上方固定。
    [stageName, "invalid（审批文件缺失或格式无效）"]
  end
end

# 当前任务正文来自 tasks.md；只摘录对应一行，不把完整任务清单复制到输出。
tasksPath = StageApproval.resolveIterationFile(iterationPath, "tasks.md")
# 非 implement 或任务文件缺失时保持“无”，由框架校验器报告结构问题。
currentTaskLine = "无"
# 任务编号使用固定格式，避免自然语言误匹配依赖中的其他编号。
if currentTask.match?(/\AT-\d+\z/) && tasksPath.file?
  # 行首 checkbox 加任务编号共同确定当前任务正文。
  taskPattern = /^- \[[ xX]\]\s+#{Regexp.escape(currentTask)}\b.*$/
  # 找不到时输出明确冲突，提醒 Agent 停止产品写入。
  currentTaskLine = tasksPath.read[taskPattern] || "未找到 #{currentTask} 对应任务"
end

# 能力日志只汇总当前阶段真正可能使用的记录，不把全部历史重新灌入上下文。
parsedLog = CapabilitySupport.parseLog(iterationPath)
# 当前阶段与任务共同决定恢复所需能力，阶段审批状态已经由上方独立汇总。
relevantCapabilityKeys = case phase
                         when "specify"
                           # 规格只关心访谈、需求评审和总控恢复记录。
                           [["design-interview", "无"], ["requirements-review", "无"], ["iteration-governor", "无"]]
                         when "plan"
                           # 计划只关心访谈、计划评审和总控恢复记录。
                           [["design-interview", "无"], ["plan-review", "无"], ["iteration-governor", "无"]]
                         when "implement"
                           # 有任务时显示对应守卫；无任务时显示整轮统一审核。
                           currentTask == "无" ? [["code-review", "无"], ["iteration-governor", "无"]] : [["implementation-guard", currentTask], ["iteration-governor", "无"]]
                         when "verify", "done"
                           # 验收与完成态关注统一审核、测试验证和交付复核。
                           [["code-review", "无"], ["test-verification", "无"], ["delivery-review", "无"], ["iteration-governor", "无"]]
                         else
                           # 未知阶段不猜测能力集合，结构错误由主校验器报告。
                           []
                         end
# 无效日志保留原因；有效日志再按能力和任务取最新记录。
# 精简只改变默认展示范围，不删除日志中的任何历史证据。
# 用户或 Agent 仍可按需直接读取 capability-log.md 完成深度审计。
capabilitySummary = if parsedLog[:valid]
                      # Hash 赋值覆盖旧记录，符合追加日志按最后一次尝试恢复的规则。
                      latestRows = {}
                      # 阶段不是恢复筛选键，因为同一能力的约定阶段在登记表中已经固定。
                      parsedLog[:rows].each { |row| latestRows[[row[:capability], row[:task]]] = row }
                      # 当前阶段相关记录与任何最新失败记录都要显示，避免精简后隐藏阻塞事实。
                      selectedRows = latestRows.values.select do |row|
                        relevantCapabilityKeys.include?([row[:capability], row[:task]]) || %w[pending failed].include?(row[:status])
                      end
                      # 空集合明确写“无”，避免 Agent 把没有记录误读成脚本漏输出。
                      selectedRows.empty? ? ["无"] : selectedRows.map { |row| "#{row[:capability]}/#{row[:task]}=#{row[:status]} -> #{row[:evidence]}" }
                    else
                      # 单条错误比空列表更能解释为什么当前门禁不能推进。
                      ["invalid -> #{parsedLog[:reason]}"]
                    end
# 历史计数保留审计规模感知，但不展开 superseded 或无关任务的路径。
capabilityHistorySummary = if parsedLog[:valid]
                             # superseded 数帮助识别返工历史，同时保持输出长度恒定。
                             supersededCount = parsedLog[:rows].count { |row| row[:status] == "superseded" }
                             "total=#{parsedLog[:rows].length}, superseded=#{supersededCount}, policy=#{parsedLog[:policy]}"
                           else
                             # 日志无效时不伪造任何数量。
                             "invalid"
                           end
# 当前任务摘要直接输出，实施守卫无需读取整份 capability-log 才能取得 input_digest。
currentTaskDigest = if currentTask.match?(/\AT-\d+\z/) && parsedLog[:valid] && parsedLog[:policy] == CapabilityDigestSupport::DEFAULT_LOG_POLICY
                      # 计算失败仍应让脚本给出诊断，而不是中止其他恢复字段输出。
                      begin
                        CapabilityDigestSupport.implementationGuardDigest(iterationPath, currentTask)
                      rescue StandardError => error
                        "invalid（#{error.message}）"
                      end
                    else
                      "无"
                    end

# 规格和计划阶段可能因设计问题等待用户决定；恢复时必须展开问题全文而不是只显示 Q 编号。
pendingQuestionSummaries = []
# 只有两个访谈阶段需要读取当前尝试，其他阶段不制造额外上下文。
interviewStage = phase == "specify" ? "requirements" : phase == "plan" ? "plan" : nil
if interviewStage
  # 当前尝试选择与审批脚本共用同一解析器，避免恢复到历史 superseded 章节。
  attemptResult = CapabilitySupport.currentInterviewAttempt(iterationPath, interviewStage)
  if attemptResult[:valid]
    # 新问题协议会返回结构化 pending 行；历史协议没有同屏保证时保持空列表。
    questionValidation = CapabilitySupport.interviewQuestionValidation(attemptResult[:attempt])
    if questionValidation[:valid] && questionValidation[:protocol]
      # 每条都包含问题全文、推荐答案和可以直接复制的推荐回复。
      pendingQuestionSummaries = questionValidation[:pending_rows].map do |row|
        # 分隔符只用于单行阅读，不改变设计访谈的权威正文。
        "#{row[:question]}｜推荐：#{row[:recommendation]}｜如同意请回复：#{row[:id]} 按推荐做"
      end
    end
  end
end

# 意图已识别不代表可以跳过访谈；把真实阻塞原因和路由并列输出。
intentBlockers = []
# 任一待确认问题都必须先由用户直接回答，联合审批不能替代设计决策。
intentBlockers << "pending_design_questions" if intentResult && !pendingQuestionSummaries.empty?

# 阶段未知时只要求回读 status.md，不从错误值猜测下一批文档。
nextReadFiles = phaseReadSets.fetch(phase, ["status.md"]).dup
# 待确认问题优先于阶段常态集合；摘要已同屏展示，正文只需问题、当前产物和决定依据。
if !pendingQuestionSummaries.empty? && phase == "specify"
  # 需求问题不提前加载测试、跟踪和计划材料。
  nextReadFiles = %w[design-interview.md requirements.md decisions.md]
elsif !pendingQuestionSummaries.empty? && phase == "plan"
  # 计划问题只围绕访谈、当前方案和风险处置继续。
  nextReadFiles = %w[design-interview.md implementation-plan.md risks.md]
elsif phase == "implement" && currentTask.match?(/\AT-\d+\z/)
  # 当前任务正文和摘要已经进入上下文，只补共享写入边界与检出基线。
  nextReadFiles = %w[change-scope.md workspace.md]
  # 守卫证据存在时用于恢复；首次执行前不存在，不能建议读取一个悬空路径。
  taskEvidence = "evidence/reviews/#{currentTask}.md"
  # 固定 evidence 子路径由任务编号推导，不读取或信任文档中的任意路径。
  taskEvidencePath = iterationPath.join(taskEvidence)
  # 软链接证据由校验器阻断，恢复入口也不把它推荐给调用方读取。
  nextReadFiles << taskEvidence if taskEvidencePath.file? && !taskEvidencePath.symlink?
elsif phase == "implement" && currentTask == "无"
  # 全部任务完成后只核对任务范围和统一审核，不再加载实现期验收材料。
  nextReadFiles = %w[tasks.md change-scope.md]
  # 已有审核报告用于续做和返工判断；首次统一审核前保持两份输入。
  reviewEvidence = "evidence/reviews/implementation-review.md"
  # 路径存在性决定是否建议读取，不新增状态字段或缓存。
  reviewEvidencePath = iterationPath.join(reviewEvidence)
  # 统一审核证据同样必须是轮次内普通文件，不能沿软链接读取框架外内容。
  nextReadFiles << reviewEvidence if reviewEvidencePath.file? && !reviewEvidencePath.symlink?
elsif phase == "implement"
  # 非法 current_task 不能伪装成零读取成本，先回读唯一动态状态源再停止写入。
  nextReadFiles = ["status.md"]
end

# 阶段审批只替换当前阶段材料，不提前加载联合授权中的未来阶段正文。
if intentResult && pendingQuestionSummaries.empty? && phase == "specify" && intentResult[:approval_stages].include?("requirements")
  # 需求审批复核验收与测试策略，不重复加载访谈和完整用例正文。
  nextReadFiles = %w[requirements.md change-scope.md acceptance.md test-strategy.md]
elsif intentResult && pendingQuestionSummaries.empty? && phase == "plan" && intentResult[:approval_stages].include?("plan")
  # 计划审批聚焦方案、任务、风险和资源预留，需求内容已有有效审批摘要。
  nextReadFiles = %w[implementation-plan.md tasks.md risks.md workspace.md]
end

# 验收阶段只有明确收口意图才切换材料；普通恢复和单独验收沿用四份常态集合。
if phase == "verify" && intentResult
  # 路由由共享意图解析器给出，这里只消费稳定枚举，不重新解释用户原话。
  case intentResult[:intent_route]
  when "close_iteration"
    # 已有验收证据时直接进入交付复核，不重复读取测试设计。
    nextReadFiles = closureReadFiles.dup
  when "verification_then_close"
    # 用户明确联合授权时才一次展开验收和收口的六份材料。
    nextReadFiles = verificationThenClosureReadFiles.dup
  end
end

# 输出采用稳定 Markdown，既方便人读，也便于 Agent 直接引用字段。
puts "# 迭代上下文"
# 系统名来自登记目录，不需要额外读取 overview 才能识别归属。
puts "- system: #{systemPath.basename}"
# 轮次使用真实目录名，避免同主题轮次混淆。
puts "- iteration: #{iterationPath.basename}"
# 档位决定访谈深度和证据组织，但不替代审批或写入授权。
puts "- workflow_profile: #{workflowProfile}"
# 以下字段逐项来自 status.md，不从聊天记录推断。
puts "- phase: #{phase}"
puts "- current_task: #{currentTask}"
puts "- work_state: #{workState}"
puts "- updated_at: #{readStatusValue(statusContent, 'updated_at')}"
puts "- checkpoint: #{readStatusValue(statusContent, 'checkpoint')}"
puts "- next_action: #{readStatusValue(statusContent, 'next_action')}"
# 传入当前原话时，输出必须位于审批摘要前，方便 Agent 优先决定本回合动作。
if intentResult
  # 多阶段用逗号连接；没有审批时明确写 none，不能从空白猜测。
  puts "- intent_approval_stages: #{intentResult[:approval_stages].empty? ? 'none' : intentResult[:approval_stages].join(',')}"
  # 执行范围使用解析器的稳定枚举。
  puts "- intent_execution_scope: #{intentResult[:execution_scope]}"
  # 验收授权独立输出，all_tasks 不能再被调用方解释成自动验收。
  puts "- intent_verification_authorized: #{intentResult[:verification_authorized]}"
  # 收口授权独立输出，只有 true 才能在验收证据通过后尝试 done。
  puts "- intent_closure_authorized: #{intentResult[:closure_authorized]}"
  # 框架写入与外部写入分列，避免连续执行被扩大到外部系统。
  puts "- intent_framework_write: #{intentResult[:framework_write]}"
  puts "- intent_external_write: #{intentResult[:external_write]}"
  # 路由是本轮 Agent 应采取的流程，不等价于门禁已通过。
  puts "- intent_route: #{intentResult[:intent_route]}"
  # none 表示可以继续检查下一道门禁；有值时不得再索要另一句审批口令。
  puts "- intent_blockers: #{intentBlockers.empty? ? 'none' : intentBlockers.join(',')}"
end
# 审批摘要帮助 Agent 判断能否跨阶段，不输出用户原话全文。
puts "- requirements_approval: #{approvalSummaries.fetch('requirements')}"
puts "- plan_approval: #{approvalSummaries.fetch('plan')}"
# 当前任务只保留单行，避免上下文脚本变成任务文档副本。
puts "- current_task_line: #{currentTaskLine}"
# 任务级摘要让守卫记录可以直接绑定当前任务，不再复制整轮计划摘要。
puts "- current_task_digest: #{currentTaskDigest}"
# 能力索引只显示当前阶段相关和失败项，空证据不会制造多行噪音。
puts "- capability_latest: #{capabilitySummary.join('; ')}"
# 历史只输出固定长度统计，详细记录按需读取 capability-log.md。
puts "- capability_history: #{capabilityHistorySummary}"
# pending 问题逐条独立输出，防止长列表被一个不透明 Q 编号替代。
pendingQuestionSummaries.each { |summary| puts "- pending_question: #{summary}" }
# 空读取集合使用稳定的人类可读哨兵，避免完成态被误解为输出损坏。
readNextSummary = nextReadFiles.empty? ? "无" : nextReadFiles.join(", ")
# 最后一行明确建议下一批文件，由阶段入口决定而不是全量扫描。
puts "- read_next: #{readNextSummary}"
