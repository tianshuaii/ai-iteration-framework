#!/usr/bin/env ruby

# 所有创建测试都在临时框架副本内运行，不触碰真实系统轮次。
# 夹具仅复制创建脚本、通用模板和一个空系统入口。
# 成功路径检查时间替换、文件齐全和连续编号。
# 失败路径检查越界系统与非法主题不会发布任何轮次。

require "fileutils"
require "open3"
require "pathname"
require "tmpdir"
require "time"
require_relative "capability-support"
require_relative "stage-approval-support"
require_relative "user-intent-support"

# 在临时轮次中建立一个“简单迭代”的确定性访谈和阶段评审证据。
def prepareApprovalCapability(iterationPath, stageName, recordId, nonTrivial: false)
  # 审批、访谈和评审必须绑定同一份当前摘要。
  stageDigest = StageApproval.digest(iterationPath, stageName)
  # 需求和计划分别定位自己的唯一当前尝试。
  prefix = stageName == "requirements" ? "R" : "P"
  # 只修改临时轮次中的对应章节。
  interviewPath = iterationPath.join("design-interview.md")
  # 非贪婪截取到下一个二级标题或文件末尾。
  sectionPattern = /^## #{Regexp.escape(stageName)}\/#{prefix}-001\s*$\n(.*?)(?=^## |\z)/m
  # 缺少标准尝试说明模板已经漂移。
  sectionMatch = interviewPath.read.match(sectionPattern)
  raise "design interview fixture missing" unless sectionMatch
  # 简单轮允许 skipped，但十一项复杂度必须全部明确为 no。
  updatedSection = sectionMatch[1]
    .sub("- status: pending", "- status: skipped")
    .sub("- provider: 无", "- provider: iteration-design-interview")
    .sub("- provider_version: 无", "- provider_version: 1")
    .sub(/- input_digest: .+/, "- input_digest: #{stageDigest}")
    .sub("- started_at: 无", "- started_at: 2020-01-01T00:00:00+00:00")
    .sub("- completed_at: 无", "- completed_at: 2020-01-01T00:01:00+00:00")
    .sub("- classification: pending", "- classification: simple")
    .sub("- classification_reason: 无", "- classification_reason: 合成夹具无复杂度条件")
  # 逐行保留复杂度键名并把值稳定改成 no。
  updatedSection = updatedSection.gsub(/^(- complexity\.[a-z_]+:) .+$/, '\\1 no')
  # standard 档位用 product_code=yes 表示普通产品代码，不触发 strict 高风险条件。
  if nonTrivial
    # 普通产品代码的分类必须是 non-trivial。
    updatedSection = updatedSection.sub("- complexity.product_code: no", "- complexity.product_code: yes")
    # 需求阶段必须完成一次访谈；计划阶段允许由计划评审替代第二次访谈。
    targetStatus = stageName == "requirements" ? "completed" : "skipped"
    # 前面的通用构造先写 skipped，这里只调整需求阶段。
    updatedSection = updatedSection.sub("- status: skipped", "- status: #{targetStatus}")
    # 分类和原因同步反映档位测试场景。
    updatedSection = updatedSection.sub("- classification: simple", "- classification: non-trivial")
    updatedSection = updatedSection.sub("合成夹具无复杂度条件", "合成夹具包含普通产品代码")
    # completed 访谈至少需要一条已决问答；计划 skipped 不伪造问答。
    if stageName == "requirements"
      # 重批测试会再次调用本辅助函数，使用能力编号生成唯一问题编号。
      questionId = "Q#{recordId[/\d+/].to_i}"
      # 追加到新协议五列表格，并保留直接用户原话作为 resolved 依据。
      updatedSection = updatedSection.sub("|---|---|---|---|---|\n", "|---|---|---|---|---|\n| #{questionId} 是否修改产品代码 | 是 | 是 | resolved | 用户原话：#{questionId} 是 |\n")
    end
  end
  # 精确替换原章节正文，不影响另一阶段访谈。
  interviewPath.write(interviewPath.read.sub(sectionMatch[1], updatedSection))
  # 阶段评审报告必须真实存在，内容只需证明临时测试结论。
  evidenceName = "stage-review.md"
  # 两阶段共用一份分节报告；追加写证明能力索引可以安全指向同一文件。
  File.open(iterationPath.join("evidence", "analysis", evidenceName), "a") do |file|
    # 每次尝试保留阶段和记录编号，重批不会覆盖另一阶段证据。
    file.write("## #{stageName} #{recordId}\n\n无阻断发现。\n\n")
  end
  # 两阶段使用稳定能力名。
  capabilityName = stageName == "requirements" ? "requirements-review" : "plan-review"
  # 阶段字段与审批脚本当前 phase 对应。
  phaseName = stageName == "requirements" ? "specify" : "plan"
  # 追加通过记录；日志只追加，最新同行用于重批。
  recordLine = "| #{recordId} | #{capabilityName} | #{phaseName} | 无 | #{capabilityName} | 1 | passed | #{stageDigest} | evidence/analysis/#{evidenceName} | 2020-01-01T00:00:00+00:00 | 2020-01-01T00:01:00+00:00 | 0 | 0 | 0 |\n"
  # 直接追加到临时日志表尾，不触碰真实框架。
  File.open(iterationPath.join("capability-log.md"), "a") { |file| file.write(recordLine) }
end

# 框架根目录仅用来读取脚本和模板。
frameworkRoot = Pathname.new(__dir__).join("..").realpath
# 三级档位的选择条件先做纯函数回归，不依赖任何真实业务轮次。
registryValidation = CapabilitySupport.registryValidation(frameworkRoot)
# 根配置无效时后续审批案例都没有可信含义，应立即失败。
raise "workflow profile registry invalid: #{registryValidation[:reason]}" unless registryValidation[:valid]
# 取得唯一配置源，下面不在测试中复制触发条件。
profileRules = registryValidation[:registry].fetch("workflow_profiles")
# 基线全部明确为 no，符合 lite 的确定性低风险要求。
simpleComplexity = CapabilitySupport::COMPLEXITY_KEYS.to_h { |key| [key, "no"] }
# lite 必须能通过简单复杂度校验。
raise "lite profile rejected simple work" unless CapabilitySupport.workflowProfileValidation("lite", simpleComplexity, profileRules)[:valid]
# 普通产品代码只提高到 standard，不应被误判为 strict。
productComplexity = simpleComplexity.merge("product_code" => "yes")
# standard 是普通产品代码的最低合法档位。
raise "standard profile rejected product code" unless CapabilitySupport.workflowProfileValidation("standard", productComplexity, profileRules)[:valid]
# 权限安全是高风险条件，standard 必须被拒绝。
strictComplexity = productComplexity.merge("permission_or_security" => "yes")
# 错误结果还应指出最低档位 strict，便于 Agent 自动升档。
strictFailure = CapabilitySupport.workflowProfileValidation("standard", strictComplexity, profileRules)
raise "standard profile accepted strict risk" if strictFailure[:valid] || !strictFailure[:reason].include?("strict")
# 显式 strict 应通过同一高风险证据。
raise "strict profile rejected strict risk" unless CapabilitySupport.workflowProfileValidation("strict", strictComplexity, profileRules)[:valid]
# 联合自然语言可以同时批准两个逻辑阶段，并连续完成本轮实现任务。
combinedIntent = UserIntentSupport.interpret("自动审批需求和计划，并完成所有任务")
# 外部写入、验收和收口都保持独立，不能从 all_tasks 自动推导。
raise "combined natural-language intent was not recognized" unless combinedIntent[:approval_stages] == %w[requirements plan] && combinedIntent[:execution_scope] == "all_tasks" && !combinedIntent[:verification_authorized] && !combinedIntent[:closure_authorized] && combinedIntent[:external_write] == false
# “都通过”是固定口令之外的等价审批表达。
raise "equivalent joint approval was rejected" unless UserIntentSupport.approvalStages("需求和计划都通过") == %w[requirements plan]
# 用户可直接用动宾短语审批单个阶段，无需补齐示例句式。
raise "concise requirement approval was rejected" unless UserIntentSupport.approvalStages("审批需求") == ["requirements"]
# 计划阶段使用同一规则，不能维护第二套固定口令。
raise "concise plan approval was rejected" unless UserIntentSupport.approvalStages("审批计划") == ["plan"]
# “不用再确认”描述减少打断，不是否定前面的自动审批动作。
raise "positive approval with no-more-confirmation was rejected" unless UserIntentSupport.approvalStages("自动审批需求和计划，不用我再确认") == %w[requirements plan]
# 截图中的真实说法表达完成整段审批流程，也必须映射到两个逻辑门禁。
raise "approval workflow phrase was rejected" unless UserIntentSupport.approvalStages("自动完成需求和计划审批流程") == %w[requirements plan]
# 两个阶段各自带“审批”时仍是同一个联合目标。
raise "repeated approval target was rejected" unless UserIntentSupport.approvalStages("自动完成需求审批和计划审批流程") == %w[requirements plan]
# 同一句联合审批在 specify 和 plan 必须得到不同的生命周期路由。
raise "specify approval route is wrong" unless UserIntentSupport.interpretForPhase("specify", "自动完成需求和计划审批流程")[:intent_route] == "requirements_then_plan"
raise "plan approval route is wrong" unless UserIntentSupport.interpretForPhase("plan", "自动完成需求和计划审批流程")[:intent_route] == "plan_approval"
# 完成态不能因历史的“完成所有任务”指令重新打开内部任务。
raise "done phase reopened tasks" unless UserIntentSupport.interpretForPhase("done", "自动审批需求和计划，并完成所有任务")[:intent_route] == "execution_not_ready"
# implement 中的全任务指令只连续完成实现和统一审核。
raise "implement all-task route is wrong" unless UserIntentSupport.interpretForPhase("implement", "完成所有任务")[:intent_route] == "all_implementation_tasks"
# 用户真实使用的“开始处理所有任务”也必须落到同一实现范围。
raise "natural all-task route is wrong" unless UserIntentSupport.interpretForPhase("implement", "开始处理所有任务")[:intent_route] == "all_implementation_tasks"
# 单独 all_tasks 到达 verify 后不能被重新解释成验收授权。
raise "all-task instruction started verification" unless UserIntentSupport.interpretForPhase("verify", "完成所有任务")[:intent_route] == "execution_not_ready"
# 仅要求完成任务不能被提升为需求或计划审批。
taskOnlyIntent = UserIntentSupport.interpret("完成所有任务")
# 任务、审批、验收和收口四种授权必须彼此独立。
raise "task-only instruction expanded authorization scope" unless taskOnlyIntent[:approval_stages].empty? && taskOnlyIntent[:execution_scope] == "all_tasks" && !taskOnlyIntent[:verification_authorized] && !taskOnlyIntent[:closure_authorized]
# 明确要求实现后验收时可以连续跨到 verify，但仍停在收口门禁前。
raise "implementation and verification route is wrong" unless UserIntentSupport.interpretForPhase("implement", "完成所有任务并验收")[:intent_route] == "all_implementation_tasks_then_verification"
# 只有三段范围都明确时，才允许连续实现、验收和收口。
raise "full lifecycle route is wrong" unless UserIntentSupport.interpretForPhase("implement", "完成所有任务，验收并收口")[:intent_route] == "all_implementation_tasks_then_verification_then_close"
# verify 阶段的验收、收口和联合表达必须形成三个不同路由。
raise "verification route is wrong" unless UserIntentSupport.interpretForPhase("verify", "开始验收")[:intent_route] == "run_verification"
raise "closure route is wrong" unless UserIntentSupport.interpretForPhase("verify", "收口")[:intent_route] == "close_iteration"
raise "verification and closure route is wrong" unless UserIntentSupport.interpretForPhase("verify", "验收并收口")[:intent_route] == "verification_then_close"
# 等价的自然语言组合不要求用户照抄“并”字句式。
raise "equivalent verification and closure route is wrong" unless UserIntentSupport.interpretForPhase("verify", "把验收和收口一起做完")[:intent_route] == "verification_then_close"
# 验收与收口的否定分别生效，不能互相吞掉正向授权。
raise "verification-only route was rejected" unless UserIntentSupport.interpretForPhase("verify", "开始验收，但不要收口")[:intent_route] == "run_verification"
# 用户对错误行为的追问只用于讨论，不能再次触发验收或收口。
questionIntent = UserIntentSupport.interpretForPhase("verify", "但是我授权了，咋把验收和收口一起做了")
# 问句即使包含两个阶段名，也必须保持没有授权动作。
raise "question reopened verification or closure" unless questionIntent[:intent_route] == "no_iteration_action" && !questionIntent[:verification_authorized] && !questionIntent[:closure_authorized]
# 普通写入授权继续保持原边界。
genericIntent = UserIntentSupport.interpret("开始处理")
# 它可以允许当前请求写框架，但不能批准阶段或执行产品任务。
raise "generic write authorization expanded scope" unless genericIntent[:approval_stages].empty? && genericIntent[:execution_scope] == "none" && genericIntent[:framework_write]
# 普通写入口令自身被否定、询问或放在条件句中时，不能只因关键词命中而放行框架文件。
["不要开始处理", "可以开始处理吗？", "先别开始执行", "如果可以就开始处理"].each do |unsafeGenericEvidence|
  # 这些表达都没有当前写入授权，路由和布尔字段必须给出一致结论。
  unsafeGenericIntent = UserIntentSupport.interpretForPhase("implement", unsafeGenericEvidence)
  # 同时检查字段与路由，防止调用方选择不同字段时得到相反权限。
  raise "unsafe generic write was accepted: #{unsafeGenericEvidence}" unless !unsafeGenericIntent[:framework_write] && unsafeGenericIntent[:intent_route] == "no_iteration_action"
end
# 框架文档写入与产品任务执行仍是独立权限，用户可只禁止后者。
documentOnlyIntent = UserIntentSupport.interpret("开始处理需求文档，但不要执行产品任务")
# 明确开始处理文档时保留框架写入授权，但不得扩大成产品任务执行。
raise "document-only authorization was rejected or expanded" unless documentOnlyIntent[:framework_write] && documentOnlyIntent[:execution_scope] == "none"
# 疑问、条件和否定表达都不能产生阶段或任务授权。
%w[是否自动审批需求和计划？ 自动完成需求和计划审批流程吗 能否自动完成需求和计划审批流程 如果需求和计划都通过，就完成所有任务 不自动审批需求和计划 不完成所有任务 不要自动完成需求和计划审批流程 先别自动完成需求和计划审批流程].each do |unsafeEvidence|
  # 每个高风险边界都必须保守返回空审批；执行范围也不得扩大。
  unsafeIntent = UserIntentSupport.interpret(unsafeEvidence)
  # 分别包含审批否定或执行否定时，其他阶段也不能获得隐式授权。
  raise "unsafe intent was accepted: #{unsafeEvidence}" unless unsafeIntent[:approval_stages].empty? && unsafeIntent[:execution_scope] == "none" && !unsafeIntent[:verification_authorized] && !unsafeIntent[:closure_authorized]
end
# 临时目录自动清理，测试不会留下伪造系统。
Dir.mktmpdir("ai-iteration-create-test-") do |temporaryRoot|
  # 测试框架和真实框架保持相同的相对目录结构。
  caseRoot = Pathname.new(temporaryRoot).join("framework")
  # 只建立创建脚本真正需要的入口，不复制业务资料。
  FileUtils.mkdir_p([caseRoot.join("scripts"), caseRoot.join("systems", "example", "iterations")])
  # 模板完整复制，确保脚本与真实文件列表一致。
  FileUtils.cp_r(frameworkRoot.join("templates"), caseRoot.join("templates"))
  # 审批入口的三级档位规则来自根配置，测试副本不能维护第二套触发条件。
  FileUtils.cp(frameworkRoot.join("capabilities.yml"), caseRoot.join("capabilities.yml"))
  # 被测脚本在副本中从 __dir__ 推导自己的根目录。
  FileUtils.cp(frameworkRoot.join("scripts", "create-iteration.rb"), caseRoot.join("scripts", "create-iteration.rb"))
  # 创建器与刷新入口共用投影模块，测试副本必须保留相同依赖。
  FileUtils.cp(frameworkRoot.join("scripts", "iteration-overview-support.rb"), caseRoot.join("scripts", "iteration-overview-support.rb"))
  # 投影模块读取审批门禁，测试副本必须带上同一摘要实现。
  FileUtils.cp(frameworkRoot.join("scripts", "stage-approval-support.rb"), caseRoot.join("scripts", "stage-approval-support.rb"))
  # 审批模块的自然语言解释集中在独立运行时文件，测试副本必须同步复制。
  FileUtils.cp(frameworkRoot.join("scripts", "user-intent-support.rb"), caseRoot.join("scripts", "user-intent-support.rb"))
  # v2 审批入口还依赖能力日志和访谈校验模块。
  FileUtils.cp(frameworkRoot.join("scripts", "capability-support.rb"), caseRoot.join("scripts", "capability-support.rb"))
  # 访谈校验已经下沉为直接依赖，临时框架必须保持同一加载图。
  FileUtils.cp(frameworkRoot.join("scripts", "capability-interview-support.rb"), caseRoot.join("scripts", "capability-interview-support.rb"))
  # 能力模块把任务级摘要拆到独立文件，临时框架必须复制完整运行时依赖。
  FileUtils.cp(frameworkRoot.join("scripts", "capability-digest-support.rb"), caseRoot.join("scripts", "capability-digest-support.rb"))
  # 上下文脚本复用同一状态、审批和能力解析模块，纳入创建成功路径回归。
  FileUtils.cp(frameworkRoot.join("scripts", "iteration-context.rb"), caseRoot.join("scripts", "iteration-context.rb"))
  # 同时复制真实审批入口，覆盖明确短语、阶段限制和摘要失效规则。
  FileUtils.cp(frameworkRoot.join("scripts", "record-stage-approval.rb"), caseRoot.join("scripts", "record-stage-approval.rb"))
  # 系统入口证明目标是已登记系统，而不是任意路径。
  FileUtils.cp(frameworkRoot.join("system-template", "AGENTS.md"), caseRoot.join("systems", "example", "AGENTS.md"))
  # overview 模板预留唯一受控管理块，创建成功后由脚本自动填入新轮次。
  FileUtils.cp(frameworkRoot.join("system-template", "overview.md"), caseRoot.join("systems", "example", "overview.md"))
  # 子进程都从副本根目录启动，覆盖最常用的相对路径调用。
  scriptPath = caseRoot.join("scripts", "create-iteration.rb").to_s
  # 第一次创建必须成功并输出绝对轮次目录。
  firstOutput, firstError, firstStatus = Open3.capture3("ruby", scriptPath, "systems/example", "流程 优化(二)", chdir: caseRoot.to_s)
  # 报错文本保留在断言里，方便定位真实失败原因。
  raise "first create failed: #{firstError}" unless firstStatus.success?
  # 输出路径必须是该系统的第一轮。
  firstPath = Pathname.new(firstOutput.strip)
  # 日期取本机时区，测试不依赖写死的日历日期。
  raise "wrong first iteration path" unless firstPath.basename.to_s.match?(/\A001-\d{4}-\d{2}-\d{2}-流程 优化\(二\)\z/)
  # 第一次真实创建必须留下系统级持久锁文件，证明入口没有绕过并发保护。
  lockPath = caseRoot.join("systems", "example", ".iteration-create.lock")
  # 锁内容保持为空，真正的排他状态由操作系统绑定到打开的文件描述符。
  raise "creation lock missing or not empty" unless lockPath.file? && lockPath.size.zero?
  # 创建脚本承诺锁文件仅当前用户可读写，避免形成公共同步通道。
  lockMode = lockPath.stat.mode & 0o777
  # 临时夹具从空目录开始，因此权限应精确等于脚本声明的 0600。
  raise "creation lock mode is not 0600" unless lockMode == 0o600
  # 新状态不能包含模板时间占位符。
  firstStatusText = firstPath.join("status.md").read
  # 真实时间应能被 Ruby 按带时区 ISO 8601 解析。
  timestamp = firstStatusText[/^- updated_at: (.+)$/, 1]
  # 无效时间或缺失状态都立即让测试失败。
  raise "invalid timestamp" unless timestamp && Time.iso8601(timestamp)
  # 新轮次默认 standard，规格阶段再按复杂度证据升降档。
  raise "new iteration workflow profile is not standard" unless firstStatusText.include?("- workflow_profile: standard")
  # 只读上下文入口应能直接汇总新轮次，而不要求先填写全部阶段正文。
  contextOutput, contextError, contextStatus = Open3.capture3("ruby", "scripts/iteration-context.rb", firstPath.to_s, chdir: caseRoot.to_s)
  # 输出同时包含档位、阶段和下一批文件，证明 Agent 无需全量扫描档案。
  raise "iteration context failed: #{contextError}" unless contextStatus.success? && contextOutput.include?("workflow_profile: standard") && contextOutput.include?("phase: specify") && contextOutput.include?("read_next:")
  # 每个用户回合把原话交给恢复入口后，应得到可执行的联合审批路由。
  intentContextOutput, intentContextError, intentContextStatus = Open3.capture3("ruby", "scripts/iteration-context.rb", firstPath.to_s, "--intent", "自动完成需求和计划审批流程", chdir: caseRoot.to_s)
  # 路由必须要求先需求、后计划，不能只返回识别结果让 Agent 再猜。
  unless intentContextStatus.success? && intentContextOutput.include?("intent_approval_stages: requirements,plan") && intentContextOutput.include?("intent_route: requirements_then_plan")
    raise "iteration intent route failed: #{intentContextError}\n#{intentContextOutput}"
  end
  # 上下文必须显式输出验收与收口授权，调用方不能再从 execution_scope 猜测。
  unless intentContextOutput.include?("intent_verification_authorized: false") && intentContextOutput.include?("intent_closure_authorized: false")
    raise "iteration intent authorization fields missing: #{intentContextOutput}"
  end
  # 保存初始访谈与状态，问题可见性案例完成后必须精确恢复，不影响后续审批测试。
  originalInterviewContent = firstPath.join("design-interview.md").read
  originalStatusContent = firstPath.join("status.md").read
  # 构造一个真实 pending 问题，验证恢复上下文不会只输出 Q 编号。
  requirementDigest = StageApproval.digest(firstPath, "requirements")
  # 只替换 requirements 当前尝试的字段和空问答表。
  pendingInterviewContent = originalInterviewContent
    .sub("- provider: 无", "- provider: iteration-design-interview")
    .sub("- provider_version: 无", "- provider_version: 1")
    .sub("- input_digest: 无", "- input_digest: #{requirementDigest}")
    .sub("- started_at: 无", "- started_at: 2020-01-01T00:00:00+00:00")
    .sub("- classification: pending", "- classification: non-trivial")
    .sub("- classification_reason: 无", "- classification_reason: 合成问题可见性测试")
    .sub("- unresolved_count: 0", "- unresolved_count: 1")
    .sub("- complexity.product_code: unknown", "- complexity.product_code: yes")
    .sub("|---|---|---|---|---|\n", "|---|---|---|---|---|\n| Q99 是否采用安全迁移顺序 | 先删外键再删表 | 待确认 | pending | 无 |\n")
  # 写入临时轮次，不触碰真实业务档案。
  firstPath.join("design-interview.md").write(pendingInterviewContent)
  # 状态必须阻塞，并同屏保留完整问题及推荐回复。
  pendingStatusContent = originalStatusContent
    .sub(/^- work_state: .+$/, "- work_state: blocked")
    .sub(/^- next_action: .+$/, "- next_action: 请确认 Q99 是否采用安全迁移顺序；如同意请回复“Q99 按推荐做”")
  # 保存临时状态后运行真实上下文入口。
  firstPath.join("status.md").write(pendingStatusContent)
  # 上下文必须把完整问题、推荐答案和回复一起展开。
  pendingOutput, pendingError, pendingStatus = Open3.capture3("ruby", "scripts/iteration-context.rb", firstPath.to_s, "--intent", "自动完成需求和计划审批流程", chdir: caseRoot.to_s)
  # 裸 Q99 不能满足断言；三段内容都必须出现。
  unless pendingStatus.success? && pendingOutput.include?("Q99 是否采用安全迁移顺序") && pendingOutput.include?("推荐：先删外键再删表") && pendingOutput.include?("Q99 按推荐做") && pendingOutput.include?("intent_blockers: pending_design_questions")
    raise "pending question was not expanded: #{pendingError}\n#{pendingOutput}"
  end
  # 模拟 Agent 未取得用户原话就把问题改成 resolved。
  invalidResolvedContent = pendingInterviewContent
    .sub("- status: pending", "- status: completed")
    .sub("- completed_at: 无", "- completed_at: 2020-01-01T00:01:00+00:00")
    .sub("- unresolved_count: 1", "- unresolved_count: 0")
    .sub("| Q99 是否采用安全迁移顺序 | 先删外键再删表 | 待确认 | pending | 无 |", "| Q99 是否采用安全迁移顺序 | 先删外键再删表 | 按推荐做 | resolved | 无 |")
  # 写入伪确认后，审批命令必须在能力评审前就拒绝。
  firstPath.join("design-interview.md").write(invalidResolvedContent)
  _invalidAnswerOutput, invalidAnswerError, invalidAnswerStatus = Open3.capture3("ruby", "scripts/record-stage-approval.rb", firstPath.to_s, "requirements", "开始处理，需求审批通过", chdir: caseRoot.to_s)
  # 失败原因必须明确指向缺少用户确认原话。
  if invalidAnswerStatus.success? || !invalidAnswerError.include?("缺少用户确认原话")
    raise "resolved question without user evidence was accepted: #{invalidAnswerError}"
  end
  # 恢复初始模板，让后续原有审批、摘要和档位测试保持单一变量。
  firstPath.join("design-interview.md").write(originalInterviewContent)
  firstPath.join("status.md").write(originalStatusContent)
  # 脚本应复制全部必需模板，包括 scripts/ 子目录。
  expectedNames = caseRoot.join("templates").children.map { |path| path.basename.to_s } - %w[README.md optional-knowledge-base]
  # 缺少任何模板项都说明创建不是完整发布。
  raise "incomplete iteration" unless expectedNames.all? { |name| firstPath.join(name).exist? }
  # 创建成功必须同时把新轮次及初始状态写入系统总览。
  firstOverviewText = caseRoot.join("systems", "example", "overview.md").read
  # 链接、动态字段和审批门禁共同证明视图来自刚发布的轮次档案。
  raise "first iteration missing from overview" unless firstOverviewText.include?(firstPath.basename.to_s) && firstOverviewText.include?("| specify | ready | 需求未审批 |")
  # 主题列必须去掉完整编号和日期，不能残留日期中的日字段。
  raise "iteration theme parsed incorrectly" unless firstOverviewText.include?("| 流程 优化(二) | specify |")
  # 链接目标必须编码空格、中文和括号，标签仍保留人类可读的原始轮次名。
  raise "iteration link target was not encoded" unless firstOverviewText.include?("%20") && firstOverviewText.include?("%28") && firstOverviewText.include?("%29")
  # 普通写入授权不能冒充需求审批。
  _genericOutput, genericError, genericStatus = Open3.capture3("ruby", "scripts/record-stage-approval.rb", firstPath.to_s, "requirements", "开始处理", chdir: caseRoot.to_s)
  # 失败信息应直接指出缺少的明确用户短语。
  raise "generic write authorization was accepted as requirement approval" if genericStatus.success? || !genericError.include?("需求审批通过")
  # 即使包含审批关键词，否定句也不能成为批准证据。
  _negativeOutput, _negativeError, negativeStatus = Open3.capture3("ruby", "scripts/record-stage-approval.rb", firstPath.to_s, "requirements", "开始处理，需求审批通过，但不要批准", chdir: caseRoot.to_s)
  # 意图解析必须拒绝附带否定含义的后缀。
  raise "negative requirement sentence was accepted as approval" if negativeStatus.success?
  # 即使短语正确，缺少访谈与需求评审时也不能记录审批。
  _missingCapabilityOutput, missingCapabilityError, missingCapabilityStatus = Open3.capture3("ruby", "scripts/record-stage-approval.rb", firstPath.to_s, "requirements", "开始处理，需求审批通过", chdir: caseRoot.to_s)
  # 错误必须指向能力门禁，而不是把明确审批意图当成充分条件。
  raise "requirement approval bypassed capability gates" if missingCapabilityStatus.success? || !missingCapabilityError.include?("设计访谈无效")
  # 建立简单轮的确定性访谈和需求评审证据。
  prepareApprovalCapability(firstPath, "requirements", "C-001", nonTrivial: true)
  # 普通产品代码至少需要 standard；临时降为 lite 时审批必须被档位门禁阻断。
  firstStatusPath = firstPath.join("status.md")
  # 只在临时副本改档位，失败后立即恢复。
  firstStatusPath.write(firstStatusPath.read.sub("- workflow_profile: standard", "- workflow_profile: lite"))
  # 明确审批短语也不能绕过复杂度要求。
  _liteOutput, liteError, liteStatus = Open3.capture3("ruby", "scripts/record-stage-approval.rb", firstPath.to_s, "requirements", "开始处理，需求审批通过", chdir: caseRoot.to_s)
  # 错误应直接指出 lite 低于 standard，而不是泛化为缺少证据。
  raise "lite profile accepted product code: #{liteError}" if liteStatus.success? || !liteError.include?("低于复杂度要求的 standard")
  # 恢复 standard 后继续验证正常审批路径。
  firstStatusPath.write(firstStatusPath.read.sub("- workflow_profile: lite", "- workflow_profile: standard"))
  # 联合自然语言先记录当前已就绪的需求摘要，并保存原始站立授权。
  combinedEvidence = "自动审批需求和计划，并完成所有任务"
  # 计划仍需等计划文档和评审就绪后单独绑定摘要。
  requirementOutput, requirementError, requirementStatus = Open3.capture3("ruby", "scripts/record-stage-approval.rb", firstPath.to_s, "requirements", combinedEvidence, chdir: caseRoot.to_s)
  # 命令必须输出审批文件和当前摘要。
  raise "requirement approval failed: #{requirementError}" unless requirementStatus.success? && requirementOutput.include?("requirements:")
  # 需求审批后计划必须仍为 pending。
  firstApprovalRecords = StageApproval.parse(firstPath.join("stage-approvals.md").read)
  # 需求已批准、计划待批准是第一道门结束时的唯一合法组合。
  raise "requirement approval did not preserve plan gate" unless firstApprovalRecords.dig("requirements", "status") == "approved" && firstApprovalRecords.dig("plan", "status") == "pending"
  # 进入 plan 后才允许记录计划审批。
  firstStatusPath = firstPath.join("status.md")
  # 测试只改变 phase，其他字段仍是合法活动状态。
  firstStatusPath.write(firstStatusPath.read.sub(/^- phase: specify$/, "- phase: plan"))
  # 计划也必须拒绝普通授权。
  _genericPlanOutput, genericPlanError, genericPlanStatus = Open3.capture3("ruby", "scripts/record-stage-approval.rb", firstPath.to_s, "plan", "开始处理", chdir: caseRoot.to_s)
  # 错误应点名计划审批短语。
  raise "generic write authorization was accepted as plan approval" if genericPlanStatus.success? || !genericPlanError.include?("计划审批通过")
  # 计划审批也必须先具备访谈和计划评审证据。
  # standard 的非简单计划允许跳过第二次访谈，但计划评审仍必须存在。
  prepareApprovalCapability(firstPath, "plan", "C-002", nonTrivial: true)
  # 计划就绪后复用需求阶段保存的联合审批原话，无需用户再回复固定文案。
  _planOutput, planError, planStatus = Open3.capture3("ruby", "scripts/record-stage-approval.rb", firstPath.to_s, "plan", chdir: caseRoot.to_s)
  # 计划审批需要先验证有效需求审批。
  raise "plan approval failed: #{planError}" unless planStatus.success?
  # 复用只允许保存真实原话，不能生成脚本自造的审批证据。
  reusedApprovalRecords = StageApproval.parse(firstPath.join("stage-approvals.md").read)
  # 两个阶段分别绑定摘要，但证据都应保持用户最初的联合授权。
  raise "deferred approval did not preserve user evidence" unless reusedApprovalRecords.dig("plan", "evidence") == combinedEvidence
  # workspace 的运行期采集字段不属于计划审批范围。
  workspacePath = firstPath.join("workspace.md")
  # 保存原文，两个摘要边界案例都从同一审批版本出发。
  originalWorkspace = workspacePath.read
  # 只更新计划区外的运行期时间。
  workspacePath.write(originalWorkspace.sub("更新时间：尚未采集", "更新时间：2020-01-01T00:00:00+00:00"))
  # 运行期基线变化不能迫使用户重批计划。
  raise "runtime workspace data invalidated plan approval" unless StageApproval.validation(firstPath, "plan")[:valid]
  # 恢复后再修改受保护的计划检出行。
  workspacePath.write(originalWorkspace.sub("|  |  | 独立 worktree / 共享检出 |  |", "| example | /tmp/example | 独立 worktree | target |"))
  # 计划路径、隔离或目标分支变化必须使审批过期。
  raise "workspace planning change did not invalidate plan approval" if StageApproval.validation(firstPath, "plan")[:valid]
  # 余下案例继续使用审批时的原始版本。
  workspacePath.write(originalWorkspace)
  # 验收结果变化属于执行期更新，不应使需求审批失效。
  acceptancePath = firstPath.join("acceptance.md")
  # 保存原文，测试后精确恢复。
  originalAcceptance = acceptancePath.read
  # 只切换结果列。
  acceptancePath.write(originalAcceptance.sub("| 未测 |", "| 通过 |"))
  # 摘要规范化必须忽略结果列。
  raise "acceptance result invalidated requirement approval" unless StageApproval.validation(firstPath, "requirements")[:valid]
  # 恢复原验收正文。
  acceptancePath.write(originalAcceptance)
  # 任务勾选属于执行进度，不应使计划审批失效。
  tasksPath = firstPath.join("tasks.md")
  # 保存计划审批时的任务正文。
  originalTasks = tasksPath.read
  # 只改变 checkbox。
  tasksPath.write(originalTasks.sub("- [ ]", "- [x]"))
  # 计划摘要必须继续有效。
  raise "task checkbox invalidated plan approval" unless StageApproval.validation(firstPath, "plan")[:valid]
  # 恢复任务正文。
  tasksPath.write(originalTasks)
  # 实现计划正文变化必须使计划审批失效。
  planPath = firstPath.join("implementation-plan.md")
  # 保存原计划用于恢复。
  originalPlan = planPath.read
  # 追加一条有语义的新做法。
  planPath.write("#{originalPlan}\n新增实现步骤。\n")
  # 旧摘要不能继续通过。
  raise "plan content change did not invalidate approval" if StageApproval.validation(firstPath, "plan")[:valid]
  # 恢复后旧摘要应再次匹配。
  planPath.write(originalPlan)
  # 需求正文变化必须使需求审批失效。
  requirementsPath = firstPath.join("requirements.md")
  # 保存规格审批时的正文。
  originalRequirements = requirementsPath.read
  # 追加规格语义用于模拟返工。
  requirementsPath.write("#{originalRequirements}\n新增需求约束。\n")
  # 旧需求摘要不能继续通过。
  raise "requirement content change did not invalidate approval" if StageApproval.validation(firstPath, "requirements")[:valid]
  # 需求重批只能在 specify 阶段进行。
  firstStatusPath.write(firstStatusPath.read.sub(/^- phase: plan$/, "- phase: specify"))
  # 规格变化后旧能力摘要也必须重建，不能只刷新用户审批。
  prepareApprovalCapability(firstPath, "requirements", "C-003", nonTrivial: true)
  # 重新批准当前规格。
  _reapproveOutput, reapproveError, reapproveStatus = Open3.capture3("ruby", "scripts/record-stage-approval.rb", firstPath.to_s, "requirements", "开始处理，需求审批通过", chdir: caseRoot.to_s)
  # 重批命令必须成功。
  raise "requirement reapproval failed: #{reapproveError}" unless reapproveStatus.success?
  # 重新批准需求必须强制清空旧计划审批。
  reapprovedRecords = StageApproval.parse(firstPath.join("stage-approvals.md").read)
  # 防止旧计划在新规格上继续生效。
  raise "requirement reapproval did not reset plan approval" unless reapprovedRecords.dig("plan", "status") == "pending"
  # 模拟外部工具把已有锁文件权限改宽，验证下一次使用会主动收紧。
  lockPath.chmod(0o644)
  # 第二次创建使用相同主题，也必须拿到下一个未占用编号。
  secondOutput, secondError, secondStatus = Open3.capture3("ruby", scriptPath, "systems/example", "流程优化", chdir: caseRoot.to_s)
  # 同主题不应覆盖前一次的目录。
  raise "second create failed: #{secondError}" unless secondStatus.success?
  # 已有锁文件也必须恢复为仅当前用户可读写。
  raise "existing creation lock mode was not repaired" unless (lockPath.stat.mode & 0o777) == 0o600
  # 第二轮编号固定递增，原轮仍保持不变。
  raise "sequence did not advance" unless Pathname.new(secondOutput.strip).basename.to_s.start_with?("002-") && firstPath.directory?
  # 第二次创建后总览必须同时保留第一轮和新增第二轮，不能只显示最新一轮。
  secondOverviewText = caseRoot.join("systems", "example", "overview.md").read
  # 两个目录名都存在才说明刷新器扫描了全部 status.md。
  raise "overview lost an iteration" unless secondOverviewText.include?(firstPath.basename.to_s) && secondOverviewText.include?(Pathname.new(secondOutput.strip).basename.to_s)
  # 非法主题必须在创建任何新轮次前被拒绝。
  _badOutput, _badError, badStatus = Open3.capture3("ruby", scriptPath, "systems/example", "../越界", chdir: caseRoot.to_s)
  # 失败后本系统仍只有前两轮。
  raise "unsafe theme accepted" if badStatus.success? || caseRoot.join("systems", "example", "iterations").children.length != 2
  # 系统目录之外的路径不能借模板生成文件。
  _outsideOutput, _outsideError, outsideStatus = Open3.capture3("ruby", scriptPath, "templates", "越界", chdir: caseRoot.to_s)
  # 越界输入必须非零退出，真实模板不能发生变化。
  raise "outside system accepted" if outsideStatus.success?
  # 并发脚本应由系统锁串行化，不能发布两个相同编号。
  concurrentResults = 2.times.map do
    # 每个线程启动独立 Ruby 进程，模拟两个 Agent 同时新建。
    Thread.new { Open3.capture3("ruby", scriptPath, "systems/example", "并发轮次", chdir: caseRoot.to_s) }
  end.map(&:value)
  # 两次创建都必须成功，失败信息附在断言中便于诊断。
  raise "concurrent create failed: #{concurrentResults.map { |result| result[1] }.join}" unless concurrentResults.all? { |result| result[2].success? }
  # 两个新编号应分别是 003 和 004，而不是重复发布。
  concurrentNames = concurrentResults.map { |result| Pathname.new(result[0].strip).basename.to_s }.sort
  # 这里只检查前缀，日期仍由真实创建时间决定。
  raise "concurrent sequence collided" unless concurrentNames[0].start_with?("003-") && concurrentNames[1].start_with?("004-")
  # 系统锁还必须串行化总览刷新，两个并发轮次不能互相覆盖表格行。
  concurrentOverviewText = caseRoot.join("systems", "example", "overview.md").read
  # 每个并发创建结果都应在最终只读视图中出现一次。
  raise "concurrent overview refresh lost an iteration" unless concurrentNames.all? { |iterationName| concurrentOverviewText.scan(iterationName).length == 1 }
  # 缺失时间占位符的模板必须失败，不能发布无效状态。
  statusTemplatePath = caseRoot.join("templates", "status.md")
  # 只改临时副本，真实模板仍保留原始占位符。
  statusTemplatePath.write(statusTemplatePath.read.sub("YYYY-MM-DDTHH:MM:SS+08:00", "非法时间"))
  # 创建器应在发布前察觉模板契约漂移。
  _invalidOutput, _invalidError, invalidStatus = Open3.capture3("ruby", scriptPath, "systems/example", "坏模板", chdir: caseRoot.to_s)
  # 失败不应新增第五个轮次。
  raise "invalid template published" if invalidStatus.success? || caseRoot.join("systems", "example", "iterations").children.length != 4
  # 失败路径只清理本次草稿，不能留下隐藏的半创建目录。
  temporaryDrafts = caseRoot.join("systems", "example").children.select { |path| path.basename.to_s.start_with?(".iteration-") && path.directory? }
  # 锁文件不是草稿目录，检查只针对目录实体。
  raise "failed creation left draft" unless temporaryDrafts.empty?
  # 失败的第五轮不能泄漏到只读视图，overview 与真实目录数量必须一致。
  finalOverviewText = caseRoot.join("systems", "example", "overview.md").read
  # 每轮的编号日期前缀在可读标签和编码目标中各出现一次，四轮共八次。
  raise "failed creation polluted overview" unless finalOverviewText.scan(/00[1-4]-\d{4}-\d{2}-\d{2}-/).length == 8
end

# 所有场景通过后输出简短结果，方便框架回归命令调用。
puts "OK: iteration creation tests passed"
