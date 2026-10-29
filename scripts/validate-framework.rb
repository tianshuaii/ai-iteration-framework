#!/usr/bin/env ruby

# 本脚本只读检查框架结构，不创建、修改或删除任何文件。
# 选择 Ruby 是为了复用 macOS 自带运行时，不给个人框架增加依赖。
# 所有路径都从脚本位置推导，避免写死用户目录或框架安装位置。
# 校验失败时统一收集问题，最后一次性输出，方便 Agent 完整修复。
# 历史轮次通过自己的 file-map.md 兼容，不把具体轮次写进通用逻辑。
# 产品仓库只验证路径是否存在，不进入仓库执行命令或读取敏感配置。
# 托管 CI 可显式使用可移植模式，跳过只有原机器才能确认的外部实体存在性。
# 可移植模式不放宽目录结构、状态、审批、证据、路径格式或生命周期关系。
# 校验器退出码为零表示结构可继续使用，非零表示必须先修复框架。

require "pathname"
require_relative "capability-support"
require_relative "framework-contract-validation-support"
require_relative "iteration-overview-support"
require_relative "iteration-content-validation-support"
require_relative "iteration-governance-validation-support"
require_relative "stage-approval-support"
require_relative "workspace-validation-support"

# 框架根目录是脚本目录的上一级。
frameworkRoot = Pathname.new(__dir__).join("..").expand_path
# 默认执行全局治理校验；日常迭代可显式选择一轮，避免无关历史档案阻断当前工作。
scopedIterationPath = nil
# 只有精确值 1 才启用可移植模式，避免普通环境变量意外降低本机校验强度。
portableValidation = ENV["AI_ITERATION_FRAMEWORK_PORTABLE_VALIDATION"] == "1"
# 本机完整模式继续验证产品仓库、知识库和临时检出的真实存在性。
validateExternalPaths = !portableValidation
# 只接受一个命名参数，防止位置参数被误解成系统名或轮次名。
unless ARGV.empty?
  # 局部模式必须同时提供开关和目标路径，其他组合直接显示稳定用法。
  abort "用法：ruby scripts/validate-framework.rb [--iteration systems/<system>/iterations/<iteration>]" unless ARGV.length == 2 && ARGV.first == "--iteration"
  # 相对路径以调用者当前目录解析，和现有脚本命令示例保持一致。
  candidateIterationPath = Pathname.new(ARGV.last).expand_path
  # 目标必须是普通目录，软链接不能借局部模式跳到框架外部。
  validDirectory = candidateIterationPath.directory? && !candidateIterationPath.symlink?
  # 目录层级必须精确位于 systems/<system>/iterations/ 下，不能选择整个系统或任意子目录。
  validHierarchy = candidateIterationPath.parent.basename.to_s == "iterations" && candidateIterationPath.parent.parent.parent == frameworkRoot.join("systems")
  # 非法目标在深层扫描前停止，避免输出大量与命令错误无关的诊断。
  abort "局部校验目标必须是框架内真实轮次目录：#{ARGV.last}" unless validDirectory && validHierarchy
  # 保存规范绝对路径，后续系统和轮次筛选都使用同一对象比较。
  scopedIterationPath = candidateIterationPath
end
# 统一保存阻断问题，避免检查到第一项就提前退出。
errors = []
# phase 只允许生命周期标准声明的五个值。
allowedPhases = %w[specify plan implement verify done].freeze
# work_state 对所有活动阶段使用同一套待开始、进行中和阻塞状态。
allowedWorkStates = %w[ready in_progress blocked done].freeze
# 工作流档位采用固定三值；具体选择条件仍来自 capabilities.yml。
allowedWorkflowProfiles = CapabilitySupport::WORKFLOW_PROFILES
# status 的六个进度字段共同组成唯一动态进度源，档位字段另做向后兼容读取。
requiredStatusFields = %w[phase current_task work_state updated_at checkpoint next_action].freeze
# 过程汇报的四个用户可见标签共同表达结果、后续动作和协作边界。
requiredProgressLabels = ["已完成：", "下一步：", "需要你：", "无需你操作："].freeze
# 新建轮次规则必须同时点名唯一脚本入口和人工创建禁令。
requiredCreationPolicyMarkers = ["create-iteration.rb", "禁止人工创建"].freeze
# worktree 规则必须同时点名受控目录、创建、同步和清理入口。
requiredWorktreePolicyMarkers = [".worktrees", "create-worktree.rb", "sync-worktree.rb", "cleanup-worktree.rb"].freeze
# 双审批与三段执行规则必须同时点名记录入口、自然语言和验收/收口边界。
requiredApprovalPolicyMarkers = ["stage-approvals.md", "record-stage-approval.rb", "需求审批通过", "计划审批通过", "等价自然语言", "完成所有任务", "开始验收", "确认收口", "--intent"].freeze
# 能力门禁必须在启动入口中同时点名登记表、日志、证据目录和总控 Skill。
requiredCapabilityPolicyMarkers = ["capabilities.yml", "capability-log.md", "evidence/", "iteration-governor", "implementation-review.md", "受控浅功能回归", "问题全文", "未确认"].freeze
# v1 历史文档继续校验原有生命周期，不强行倒推当时不存在的同步证据。
managedWorktreeV1Marker = "<!-- workspace-policy: managed-worktree-v1 -->"
# v2 新文档要求真实仓库目标分支已拉取并包含 worktree 最终提交。
managedWorktreeV2Marker = "<!-- workspace-policy: managed-worktree-v2 -->"
# 两个标记按能力版本传给统一校验函数，避免散落字符串判断。
managedWorktreeMarkers = { v1: managedWorktreeV1Marker, v2: managedWorktreeV2Marker }.freeze
# 新轮次必须包含这些标准英文文件。
requiredFiles = %w[
  status.md
  requirements.md
  decisions.md
  change-scope.md
  implementation-plan.md
  tasks.md
  acceptance.md
  test-strategy.md
  test-cases.md
  test-log.md
  traceability.md
  risks.md
  review-checklist.md
  workspace.md
].freeze
# 运行时共享模块属于框架契约；缺失时上下文和主校验都会在加载阶段直接失败。
# iteration-context.rb 已由独立入口检查覆盖，这里只列它加载的支持模块，避免重复报错。
requiredRuntimeSupportScripts = %w[
  capability-digest-support.rb
  capability-support.rb
  review-coverage-support.rb
  risk-test-support.rb
  user-intent-support.rb
].freeze

# 将错误写入同一个数组，保持主流程容易阅读。
def addError(errors, message)
  # 每条信息都带相对路径或明确对象，便于直接定位。
  errors << message
end

# 检查框架入口文件，确保从不同目录启动都能自动定位。
%w[AGENTS.md systems/AGENTS.md system-template/AGENTS.md].each do |relativePath|
  # 每个入口都必须真实存在。
  targetPath = frameworkRoot.join(relativePath)
  # 缺少入口时记录阻断错误。
  addError(errors, "缺少 Agent 入口：#{relativePath}") unless targetPath.file?
  # 每个通用入口都必须要求结果、下一步和用户协作边界。
  FrameworkContractValidation.validateProgressReportingContract(errors, targetPath, relativePath, requiredProgressLabels)
  # 任意启动层级都不能丢失新建轮次的强制脚本入口。
  FrameworkContractValidation.validateIterationCreationContract(errors, targetPath, relativePath, requiredCreationPolicyMarkers)
  # 任意启动层级都必须把临时源码限制在受控目录并要求收口清理。
  FrameworkContractValidation.validateWorktreePolicyContract(errors, targetPath, relativePath, requiredWorktreePolicyMarkers)
  # 任意启动层级都必须声明需求和计划不能自动跨过用户审批。
  FrameworkContractValidation.validateApprovalPolicyContract(errors, targetPath, relativePath, requiredApprovalPolicyMarkers)
  # 任意启动层级都必须声明能力登记、证据和总控边界。
  FrameworkContractValidation.validateCapabilityPolicyContract(errors, targetPath, relativePath, requiredCapabilityPolicyMarkers)
end

# 新系统必须从模板获得会话级轮次绑定说明。
templateBindingPath = frameworkRoot.join("system-template", "agent", "README.md")
# 缺少模板时，现有系统虽然可用，下一次登记仍会退回不完整结构。
addError(errors, "缺少轮次绑定模板：system-template/agent/README.md") unless templateBindingPath.file?
# 绑定说明也要阻止没有活动轮次时退回人工复制模板。
FrameworkContractValidation.validateIterationCreationContract(errors, templateBindingPath, "system-template/agent/README.md", requiredCreationPolicyMarkers)
# 会话绑定说明也要提醒 Agent 读取审批证据，不能只看 phase。
FrameworkContractValidation.validateApprovalPolicyContract(errors, templateBindingPath, "system-template/agent/README.md", requiredApprovalPolicyMarkers)
# 新系统会话绑定也必须读取能力日志，而不是仅凭阶段名恢复。
FrameworkContractValidation.validateCapabilityPolicyContract(errors, templateBindingPath, "system-template/agent/README.md", requiredCapabilityPolicyMarkers)

# 阶段入口是实际创建动作的直接指令，必须保留相同硬约束。
openIterationPromptPath = frameworkRoot.join("prompts", "01-open-iteration.md")
# 缺少入口本身会导致新轮次没有受控执行路径。
addError(errors, "缺少新建轮次入口：prompts/01-open-iteration.md") unless openIterationPromptPath.file?
# 直接入口不得重新允许人工兜底。
FrameworkContractValidation.validateIterationCreationContract(errors, openIterationPromptPath, "prompts/01-open-iteration.md", requiredCreationPolicyMarkers)

# 规划、实现和验收入口共同覆盖 worktree 的创建、使用与清理阶段。
%w[prompts/03-plan.md prompts/04-implement.md prompts/05-verify.md].each do |relativePath|
  # 缺失入口由本地链接或人工检查发现，这里只校验存在文件的契约内容。
  policyPath = frameworkRoot.join(relativePath)
  # 三个阶段都必须点名相同的受控目录和三个生命周期脚本。
  FrameworkContractValidation.validateWorktreePolicyContract(errors, policyPath, relativePath, requiredWorktreePolicyMarkers)
end

# 阶段总入口集中声明完整审批契约，各阶段页再给出自己的操作细节。
promptIndexPath = frameworkRoot.join("prompts", "README.md")
# 总入口必须同时出现记录文件、唯一命令和两条用户短语。
FrameworkContractValidation.validateApprovalPolicyContract(errors, promptIndexPath, "prompts/README.md", requiredApprovalPolicyMarkers)
# 阶段总入口必须声明能力门禁与证据位置。
FrameworkContractValidation.validateCapabilityPolicyContract(errors, promptIndexPath, "prompts/README.md", requiredCapabilityPolicyMarkers)

# 根能力登记表必须能被安全解析并包含全部必需能力和权限边界。
registryValidation = CapabilitySupport.registryValidation(frameworkRoot)
# 配置错误会影响所有新轮次，作为根级阻断问题报告。
addError(errors, registryValidation[:reason]) unless registryValidation[:valid]

# 只读上下文入口是三级流程减少重复扫描的公共命令，缺失时文档承诺无法执行。
contextScriptPath = frameworkRoot.join("scripts", "iteration-context.rb")
# 脚本必须真实存在；语法由框架回归和 code review 继续验证。
addError(errors, "缺少上下文汇总脚本：scripts/iteration-context.rb") unless contextScriptPath.file?
# 逐项检查摘要与日志共享模块，避免发布不完整脚本集合后才在业务轮次恢复时暴露 LoadError。
requiredRuntimeSupportScripts.each do |scriptName|
  # 报错保留稳定相对路径，调用者可以直接定位缺失文件。
  scriptPath = frameworkRoot.join("scripts", scriptName)
  # 支持模块不存在时给出运行时依赖错误，不与入口文件错误重复。
  addError(errors, "缺少框架运行脚本：scripts/#{scriptName}") unless scriptPath.file?
end

# 八个仓库兜底 Skill 必须各有可读入口，外部 Skill 不可用时才能降级。
requiredRepositorySkills = %w[
  iteration-design-interview iteration-requirements-review iteration-plan-review
  iteration-implementation-guard iteration-code-review iteration-test-verification
  iteration-delivery-review iteration-governor
].freeze
# 逐项检查固定入口；内容质量另由 skill validator 和 code review 复核。
requiredRepositorySkills.each do |skillName|
  # SKILL.md 是 Codex 发现仓库 Skill 的标准入口。
  skillPath = frameworkRoot.join(".agents", "skills", skillName, "SKILL.md")
  # 缺失时 required capability 无法按登记表降级。
  addError(errors, "缺少仓库 Skill：#{skillName}") unless skillPath.file?
end

# 模板本身也必须符合恢复协议，否则以后创建的每一轮都会带错状态。
templateStatusPath = frameworkRoot.join("templates", "status.md")
# 缺少模板时 requiredFiles 无法覆盖，因为模板不属于任何系统轮次。
if templateStatusPath.file?
  # 使用同一校验函数，保证模板和真实轮次没有两套标准。
  IterationGovernanceValidation.validateStatusFields(errors, templateStatusPath.read, "templates/status.md", allowedPhases, allowedWorkStates, requiredStatusFields, false, allowedWorkflowProfiles)
  # 只有模板必须显式带档位；历史真实轮次仍允许按 standard 兼容读取。
  addError(errors, "templates/status.md 缺少状态字段：workflow_profile") unless IterationGovernanceValidation.readStatusField(templateStatusPath.read, "workflow_profile")
else
  # 明确报告模板缺失，避免直到新开迭代时才发现。
  addError(errors, "缺少状态模板：templates/status.md")
end

# 新轮次必须自带访谈、能力日志和证据目录模板。
templateCapabilityLogPath = frameworkRoot.join("templates", CapabilitySupport::LOG_FILE)
# 模板日志必须能用占位时间替换后解析；这里先检查格式标记和字段。
addError(errors, "缺少能力日志模板：templates/#{CapabilitySupport::LOG_FILE}") unless templateCapabilityLogPath.file?
# 设计访谈是需求与计划共同的耐久决策树。
templateInterviewPath = frameworkRoot.join("templates", CapabilitySupport::INTERVIEW_FILE)
# 缺失时非平凡轮次无法完成双审批前访谈。
addError(errors, "缺少设计访谈模板：templates/#{CapabilitySupport::INTERVIEW_FILE}") unless templateInterviewPath.file?
# 证据目录说明和四类子目录必须随新轮次一次发布。
%w[README.md analysis reviews tests delivery].each do |evidenceEntry|
  # 目录和说明统一从模板复制，避免创建后再人工补结构。
  addError(errors, "缺少证据模板：templates/evidence/#{evidenceEntry}") unless frameworkRoot.join("templates", "evidence", evidenceEntry).exist?
end

# 新轮次必须从模板获得两项 pending 审批记录。
templateApprovalPath = frameworkRoot.join("templates", StageApproval::FILE_NAME)
# 缺少模板会让创建脚本发布无法进入后续阶段的新轮次。
if templateApprovalPath.file?
  # 模板必须能按当前版本完整解析。
  templateApprovalRecords = StageApproval.parse(templateApprovalPath.read)
  # 格式损坏时给出直接错误，不等新建轮次后才发现。
  if templateApprovalRecords
    # 两个阶段初始都只能是 pending，不能预置用户批准。
    StageApproval::STAGES.each_key do |stageName|
      # 模板中的任何 approved 都属于伪造审批。
      addError(errors, "templates/#{StageApproval::FILE_NAME} #{stageName} 初始状态必须为 pending") unless templateApprovalRecords.fetch(stageName)["status"] == "pending"
    end
  else
    # 无法解析的模板不能继续发布。
    addError(errors, "templates/#{StageApproval::FILE_NAME} 格式无效")
  end
else
  # 单独报告审批模板缺失。
  addError(errors, "缺少审批模板：templates/#{StageApproval::FILE_NAME}")
end

# 新轮次的 workspace 模板必须启用受控 worktree 生命周期门禁。
templateWorkspacePath = frameworkRoot.join("templates", "workspace.md")
# 模板缺失最终也会被轮次文件列表发现，但这里给出更直接的框架错误。
if templateWorkspacePath.file?
  # 新模板必须启用 v2；历史轮次仍可保留 v1 标记继续原规则校验。
  addError(errors, "templates/workspace.md 缺少受控 worktree v2 版本标记") unless templateWorkspacePath.read.include?(managedWorktreeV2Marker)
  # 固定章节是创建、清理和完成态门禁共享的唯一记录位置。
  addError(errors, "templates/workspace.md 缺少临时 worktree 生命周期章节") unless templateWorkspacePath.read.include?("## 临时 worktree 生命周期")
  # 同步章节是目标分支和两端 HEAD 的唯一结构化证据源。
  addError(errors, "templates/workspace.md 缺少 worktree 成果同步章节") unless templateWorkspacePath.read.include?("## worktree 成果同步")
else
  # 没有 workspace 模板时新轮次无法登记检出与资源。
  addError(errors, "缺少工作区模板：templates/workspace.md")
end

# systems 下的普通目录都视为已登记系统。
systemsRoot = frameworkRoot.join("systems")
# 从真实目录动态取得系统名，不在校验器里硬编码任何业务系统。
registeredSystemNames = systemsRoot.children.select(&:directory?).reject(&:symlink?).map { |path| path.basename.to_s }
# 收集新版 workspace 登记的活动临时路径，最后与 .worktrees 实体做反向核对。
managedWorktreeTargets = []
# 通用 prompts 不允许重新引入某一套系统的历史兼容信息。
promptContent = frameworkRoot.join("prompts").glob("*.md").map(&:read).join("\n")
# 每个已登记系统名都只应出现在系统自己的目录中。
registeredSystemNames.each do |systemName|
  # 动态检查保证以后新增系统时自动获得同样的隔离门禁。
  addError(errors, "通用 prompts 硬编码了系统名：#{systemName}") if promptContent.include?(systemName)
end
# 具体历史轮次名也不能进入通用 prompts。
addError(errors, "通用 prompts 硬编码了历史轮次") if promptContent.match?(/001-\d{4}-\d{2}-\d{2}-/)

# 本地链接校验独立封装，局部模式规则仍由同一个目标路径控制。
FrameworkContractValidation.validateLocalMarkdownLinks(errors, frameworkRoot, scopedIterationPath, validateExternalPaths: validateExternalPaths)

# README 是人类可见的系统登记表，必须与真实目录一致。
systemsReadme = systemsRoot.join("README.md").read
# 登记表只保存稳定说明，不能复制当前轮次、阶段或恢复字段。
dynamicRegistryPattern = /当前一轮|待开发|已验收|phase|current_task|work_state|updated_at|checkpoint|next_action/
# 任一动态标记都说明登记表正在形成第二份进度源。
addError(errors, "systems/README.md 复制了动态迭代状态") if systemsReadme.match?(dynamicRegistryPattern)
# 逐系统检查入口、边界、会话绑定说明和知识库。
systemsRoot.children.select(&:directory?).reject(&:symlink?).sort.each do |systemPath|
  # 局部模式只深入目标轮次所属系统；根规则与系统登记表仍已在上方统一校验。
  next if scopedIterationPath && systemPath.expand_path != scopedIterationPath.parent.parent.expand_path
  # 系统名只用于输出，不参与任何硬编码分支。
  systemName = systemPath.basename.to_s
  # 统一使用英文小写短横线，避免路径在不同工具中解析不一致。
  addError(errors, "系统目录名不符合英文短横线格式：#{systemName}") unless systemName.match?(/\A[a-z0-9]+(?:-[a-z0-9]+)*\z/)
  # 真实目录必须出现在人类可见登记表中。
  registryTarget = "./#{systemName}/overview.md"
  # 缺少登记行会让人从 systems/ 无法发现该系统。
  addError(errors, "#{systemName} 未登记到 systems/README.md") unless systemsReadme.include?(registryTarget)
  # 系统根目录必须有自动入口。
  systemAgentPath = systemPath.join("AGENTS.md")
  # 缺少系统入口时无法恢复系统级规则。
  addError(errors, "#{systemName} 缺少 AGENTS.md") unless systemAgentPath.file?
  # 每个已登记系统都必须继承同一套用户可见过程汇报协议。
  FrameworkContractValidation.validateProgressReportingContract(errors, systemAgentPath, "#{systemName}/AGENTS.md", requiredProgressLabels)
  # 从具体系统目录启动时也必须经过同一创建脚本和文件锁。
  FrameworkContractValidation.validateIterationCreationContract(errors, systemAgentPath, "#{systemName}/AGENTS.md", requiredCreationPolicyMarkers)
  # 具体系统入口也必须继承统一 worktree 创建与清理规则。
  FrameworkContractValidation.validateWorktreePolicyContract(errors, systemAgentPath, "#{systemName}/AGENTS.md", requiredWorktreePolicyMarkers)
  # 具体系统入口必须继承双审批门禁，不允许系统局部放宽。
  FrameworkContractValidation.validateApprovalPolicyContract(errors, systemAgentPath, "#{systemName}/AGENTS.md", requiredApprovalPolicyMarkers)
  # 具体系统入口也必须继承能力选择和证据门禁。
  FrameworkContractValidation.validateCapabilityPolicyContract(errors, systemAgentPath, "#{systemName}/AGENTS.md", requiredCapabilityPolicyMarkers)
  # overview 是仓库和系统边界的唯一来源。
  overviewPath = systemPath.join("overview.md")
  # 缺少 overview 时后续路径检查没有依据。
  addError(errors, "#{systemName} 缺少 overview.md") unless overviewPath.file?
  # 会话绑定说明取代共享 current 指针，避免并行 Agent 相互覆盖。
  bindingPath = systemPath.join("agent", "README.md")
  # 缺少绑定说明时，多活动轮次下无法可靠选择目标。
  addError(errors, "#{systemName} 缺少 agent/README.md") unless bindingPath.file?
  # 无活动轮次时最容易从绑定说明直接创建，因此这里也做契约检查。
  FrameworkContractValidation.validateIterationCreationContract(errors, bindingPath, "#{systemName}/agent/README.md", requiredCreationPolicyMarkers)
  # 轮次绑定说明必须要求读取审批记录并识别等待状态。
  FrameworkContractValidation.validateApprovalPolicyContract(errors, bindingPath, "#{systemName}/agent/README.md", requiredApprovalPolicyMarkers)
  # 多轮次绑定时必须读取所绑定轮的能力日志，不能串用其他轮证据。
  FrameworkContractValidation.validateCapabilityPolicyContract(errors, bindingPath, "#{systemName}/agent/README.md", requiredCapabilityPolicyMarkers)
  # 缺少关键文件时停止本系统的深层检查，避免连锁噪音。
  next unless overviewPath.file? && bindingPath.file?

  # overview 不能保留系统模板标题。
  overviewContent = overviewPath.read
  # 未替换占位符说明登记还没有完成。
  addError(errors, "#{systemName}/overview.md 仍有系统名占位符") if overviewContent.include?("（系统名）")
  # 每个仓库都应登记可核实的常用检查命令。
  addError(errors, "#{systemName}/overview.md 缺少常用检查命令列") unless overviewContent.include?("常用检查命令")
  # overview 只允许在固定标记内保存由 status.md 生成的状态投影。
  managedOverviewBlock = IterationOverview.extractManagedBlock(overviewContent)
  # 缺少或重复标记时刷新脚本无法安全判断可写范围。
  addError(errors, "#{systemName}/overview.md 缺少唯一自动生成的迭代状态视图") unless managedOverviewBlock
  # 投影以外仍属于人工维护区，不能再次复制动态状态形成第三份来源。
  stableOverviewContent = managedOverviewBlock ? overviewContent.sub(managedOverviewBlock, "") : overviewContent
  # 检查全部动态列名，而不是只拦截中文“状态”这一种写法。
  dynamicOverviewColumns = ["状态", "phase", "current_task", "work_state", "approval_gate", "updated_at", "checkpoint", "next_action"]
  # 只识别 Markdown 表头单元格，正文解释字段含义不会误报。
  hasUnmanagedStatusColumn = stableOverviewContent.each_line.any? do |line|
    # 列位置可以任意变化，只要位于管理块外就属于手工重复状态。
    line.strip.start_with?("|") && (line.split("|").map(&:strip) & dynamicOverviewColumns).any?
  end
  # 管理块之外的动态列继续沿用原错误语义，兼容已有失败用例。
  addError(errors, "#{systemName}/overview.md 复制了迭代状态列") if hasUnmanagedStatusColumn
  # iterations 存在时才能重算期望视图；目录缺失由后续结构检查单独报告。
  if !scopedIterationPath && managedOverviewBlock && systemPath.join("iterations").directory?
    # 非严格渲染允许校验器继续报告缺失状态字段，而不是在首个坏轮次异常退出。
    expectedOverviewBlock = IterationOverview.render(systemPath, strict: false)
    # 任一轮次漏行或字段过期都说明 Agent 修改状态后忘记刷新总览。
    addError(errors, "#{systemName}/overview.md 迭代状态视图已过期，请运行 refresh-iteration-overview.rb") unless managedOverviewBlock == expectedOverviewBlock
  end
  # overview 中所有反引号包裹的绝对路径都必须存在。
  absolutePaths = overviewContent.scan(/`(\/[^`]+)`/).flatten
  # 已登记系统至少要包含一个产品仓库或知识目录绝对路径。
  addError(errors, "#{systemName}/overview.md 没有绝对路径") if absolutePaths.empty?
  # 每个登记路径都做存在性检查。
  absolutePaths.each do |absolutePath|
    # 只验证存在性，不读取目标仓库内容。
    addError(errors, "#{systemName} 路径不存在：#{absolutePath}") if validateExternalPaths && !Pathname.new(absolutePath).exist?
  end

  # 知识库是可选项；存在时必须是绝对目标软链接。
  knowledgePath = systemPath.join("knowledge-base")
  if knowledgePath.exist? || knowledgePath.symlink?
    # 普通目录会造成正文复制和双重事实源，因此不允许。
    addError(errors, "#{systemName}/knowledge-base 不是软链接") unless knowledgePath.symlink?
    # 只有软链接才读取目标，避免普通目录触发异常。
    if knowledgePath.symlink?
      # 目标必须是绝对路径，保证从任意 cwd 打开结果一致。
      linkTarget = Pathname.new(knowledgePath.readlink)
      # 相对目标违反框架约定。
      addError(errors, "#{systemName}/knowledge-base 不是绝对路径") unless linkTarget.absolute?
      # 失效链接会让 Agent 丢失系统背景。
      addError(errors, "#{systemName}/knowledge-base 目标不存在") if validateExternalPaths && !knowledgePath.exist?
    end
  end

  # iterations 是系统生命周期档案的固定目录。
  iterationsRoot = systemPath.join("iterations")
  # 缺少目录时 Agent 无法新开或恢复轮次。
  unless iterationsRoot.directory?
    addError(errors, "#{systemName} 缺少 iterations/")
    next
  end

  # 保存每轮解析后的状态和文件映射，后续检查直接复用。
  iterationRecords = {}
  # 每个迭代目录都必须有 status，避免半创建轮次被静默忽略。
  iterationDirectories = iterationsRoot.children.select(&:directory?).reject(&:symlink?)
  # 局部模式只执行目标轮次的内容、审批、能力和 workspace 门禁。
  iterationDirectories.select! { |candidatePath| candidatePath.expand_path == scopedIterationPath } if scopedIterationPath
  # 逐目录检查完整恢复字段和字段组合。
  iterationDirectories.each do |candidatePath|
    # status 是轮次能否被恢复的最低条件。
    candidateStatusPath = candidatePath.join("status.md")
    # 缺少 status 时记录错误并跳过该目录的 phase 解析。
    unless candidateStatusPath.file?
      addError(errors, "#{systemName} 迭代缺少 status.md：#{candidatePath.basename}")
      next
    end
    # 非当前轮次也必须满足恢复协议，否则归档状态可能被误判。
    statusLabel = "#{systemName} 迭代 #{candidatePath.basename}"
    # 先校验并保存六个恢复字段。
    statusFields = IterationGovernanceValidation.validateStatusFields(
      errors,
      candidateStatusPath.read,
      statusLabel,
      allowedPhases,
      allowedWorkStates,
      requiredStatusFields,
      true,
      allowedWorkflowProfiles
    )
    # 规格和计划阶段的未决问题必须在状态中完整可见，并与审批状态保持一致。
    IterationGovernanceValidation.validateQuestionVisibilityGate(errors, candidatePath, statusFields, statusLabel)
    # 每个历史映射都必须限制在自己的轮次目录内。
    fileMap = FrameworkContractValidation.readFileMap(candidatePath, errors, statusLabel, requiredFiles)
    # 所有轮次都检查完整档案，不只检查 current 指向的一轮。
    requiredFiles.each do |standardName|
      # status 始终使用固定名称，其他文件允许本轮自己的兼容映射。
      targetPath = standardName == "status.md" ? candidateStatusPath : FrameworkContractValidation.resolveIterationFile(candidatePath, fileMap, standardName)
      # 缺少任一标准产物都会破坏归档恢复能力。
      addError(errors, "#{statusLabel} 缺少 #{standardName}") unless targetPath.file?
    end
    # 每轮 scripts 目录必须保留，即使当前没有临时脚本。
    addError(errors, "#{statusLabel} 缺少 scripts/") unless candidatePath.join("scripts").directory?
    # 所有历史与活动轮次都执行同一套内容门禁，避免归档后绕过完成态证据。
    IterationContentValidation.validate(errors, candidatePath, statusFields, fileMap, statusLabel)
    # 活动轮次和采用新审批文件的完成轮次执行双审批阶段门禁。
    IterationGovernanceValidation.validateStageApprovals(errors, candidatePath, statusFields, statusLabel)
    # 能力门禁按本轮迁移基线执行，历史完成轮次没有日志时免追溯。
    # 根配置有效时按三级档位校验；配置错误已经单独报告，这里传空结构避免脚本崩溃。
    profileRules = registryValidation[:valid] ? registryValidation[:registry].fetch("workflow_profiles") : {}
    # 能力门禁同时验证档位没有低于当前复杂度证据要求。
    IterationGovernanceValidation.validateCapabilityGates(errors, candidatePath, statusFields, statusLabel, profileRules)
    # 进入 implement 时就要预留检出路径和运行资源，不能等到开始写代码才发现冲突。
    # verify 继续持有这些预留；specify 和 plan 仍可保留未采集的模板。
    isolationRequired = %w[implement verify].include?(statusFields["phase"])
    # 使用当前轮自己的 file-map 解析历史 workspace 文件名。
    workspacePath = FrameworkContractValidation.resolveIterationFile(candidatePath, fileMap, "workspace.md")
    # 结构化隔离信息供系统级跨轮次检查复用。
    isolation = WorkspaceValidation.readWorkspaceIsolation(errors, workspacePath, statusLabel, isolationRequired, validatePathExistence: validateExternalPaths)
    # 新版 workspace 对临时路径、生命周期状态和 done 清理门禁做严格校验。
    managedWorktreeRecords = WorkspaceValidation.validateManagedWorktrees(
      errors,
      workspacePath,
      candidatePath,
      statusLabel,
      frameworkRoot,
      statusFields,
      isolation[:checkouts],
      managedWorktreeMarkers,
      validatePathExistence: validateExternalPaths
    )
    # 已删除记录不应有实体；其他状态都属于当前受控目录清单。
    managedWorktreeRecords.reject { |record| record[:state] == "已删除" }.each do |record|
      # 展开后的字符串足以与固定根目录下的物理路径比较。
      managedWorktreeTargets << record[:targetPath].to_s
    end
    # 保存结构化结果，后面不再重复读取和解析。
    iterationRecords[candidatePath.expand_path.to_s] = { fields: statusFields, fileMap: fileMap, isolation: isolation }
  end

  # 多活动轮次合法，但接触产品与运行环境的轮次必须彼此隔离。
  WorkspaceValidation.validateConcurrentIsolation(errors, systemName, iterationRecords)
end

# 物理目录反查与 workspace 生命周期解析属于同一工作区安全职责。
WorkspaceValidation.validatePhysicalTargets(errors, frameworkRoot, scopedIterationPath, managedWorktreeTargets)

# 所有检查结束后再统一输出，便于一次修完。
if errors.empty?
  # 成功信息标明校验范围，防止局部绿色被误报成全局绿色。
  if scopedIterationPath
    # 使用框架相对路径，输出稳定且不泄露无关用户目录。
    puts "OK: scoped iteration validation passed: #{scopedIterationPath.relative_path_from(frameworkRoot)}"
  else
    # 无参数时仍保持原有全局成功文案，兼容现有自动化。
    # 日志明确区分托管 CI 的档案校验与本机包含外部实体的完整校验。
    successLabel = portableValidation ? "portable framework validation" : "framework validation"
    # 稳定前缀和退出码保持不变，调用方仍可用同一命令判断结果。
    puts "OK: #{successLabel} passed"
  end
  # 零退出码供后续自动化调用。
  exit 0
end

# 失败时先输出数量，再逐条输出定位信息。
warn "FAILED: #{errors.length} framework validation error(s)"
# 每行一个问题，方便终端与审核文档引用。
errors.each { |message| warn "- #{message}" }
# 非零退出码阻止误把失败状态当成通过。
exit 1
