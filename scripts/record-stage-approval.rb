#!/usr/bin/env ruby

# 本入口只记录已经由用户明确给出的需求或计划审批，不猜测模糊聊天含义。
# 审批支持等价自然语言；普通“继续”“开始处理”仍不能替代批准动作。
# 需求只能在 specify 记录，计划只能在 plan 记录，防止事后补写证据。
# 计划审批依赖仍有效的需求审批，需求重新审批会重置旧计划审批。
# 同一系统复用 .iteration-create.lock，串行化审批、创建和总览刷新。
# 脚本不自动修改 status.md；Agent 在记录成功后按阶段入口写准确断点。
# 审批成功后刷新 overview 的派生门禁列，避免用户看到陈旧视图。

require "pathname"
require_relative "capability-support"
require_relative "iteration-overview-support"
require_relative "stage-approval-support"

# 需求必须传原话；计划可省略原话并复用需求阶段保存的联合审批证据。
validArguments = ARGV.length == 3 || (ARGV.length == 2 && ARGV[1] == "plan")
# 其他组合直接显示稳定用法，避免空证据被误判成授权。
abort "用法：ruby scripts/record-stage-approval.rb systems/<system>/iterations/<iteration> requirements|plan [用户原话]" unless validArguments
# 所有路径从脚本所在框架根目录推导。
frameworkRoot = Pathname.new(__dir__).join("..").realpath
# 三级档位选择只相信根能力登记表，审批入口不能维护另一套风险条件。
registryValidation = CapabilitySupport.registryValidation(frameworkRoot)
# 配置损坏会影响访谈是否允许跳过，因此在取得锁前直接阻断。
abort "能力登记无效：#{registryValidation[:reason]}" unless registryValidation[:valid]
# 保存配置引用供锁内两阶段门禁复用，不在循环里重复解析 YAML。
profileRules = registryValidation[:registry].fetch("workflow_profiles")
# 轮次必须真实存在，realpath 同时消除软链接别名。
requestedIterationPath = Pathname.new(ARGV[0]).expand_path
abort "轮次目录不存在：#{requestedIterationPath}" unless requestedIterationPath.directory?
# 规范化后的路径用于严格验证目录层级。
iterationPath = requestedIterationPath.realpath
# 阶段只接受模块定义的两个稳定键。
stageName = ARGV[1]
abort "审批阶段只能是 requirements 或 plan" unless StageApproval::STAGES.key?(stageName)
# 完整用户原话进入耐久证据；计划可复用需求记录中的联合审批原话。
evidence = ARGV[2] || StageApproval.deferredEvidence(iterationPath, stageName)
# 先拒绝普通写入授权或否定句，不能让后续能力缺失掩盖授权错误。
approvalExample = StageApproval::STAGES.fetch(stageName)[:example]
# 没有可复用原话或意图不匹配时给出自然语言示例，不要求逐字复制。
abort "用户证据必须明确批准当前阶段，例如：#{approvalExample}" unless StageApproval.evidenceMatches?(stageName, evidence)
# systems 根目录只允许直接系统子目录。
systemsRoot = frameworkRoot.join("systems").realpath
# 轮次父级必须是系统自己的 iterations/。
iterationsRoot = iterationPath.parent
systemPath = iterationsRoot.parent
# 同时检查目录名和父级，阻止任意外部目录伪装成轮次。
abort "目标必须是 systems/<system>/iterations/<iteration>" unless iterationsRoot.basename.to_s == "iterations" && systemPath.parent == systemsRoot
# 系统入口和总览存在才能记录可追踪审批。
abort "系统缺少 AGENTS.md 或 overview.md" unless systemPath.join("AGENTS.md").file? && systemPath.join("overview.md").file?
# 当前 phase 先从本轮 status.md 读取，用于快速拒绝明显错误的调用。
statusPath = iterationPath.join("status.md")
abort "轮次缺少 status.md" unless statusPath.file?
# 列表字段格式与框架状态解析器保持一致。
phase = statusPath.read[/^- phase:\s*(.+)$/, 1]&.strip
# 每种审批只能在其阶段结束时记录。
expectedPhase = stageName == "requirements" ? "specify" : "plan"
abort "#{stageName} 审批只能在 #{expectedPhase} 阶段记录，当前为 #{phase.inspect}" unless phase == expectedPhase
# 系统级持久锁与创建、刷新入口共用，避免覆盖彼此的总览结果。
lockPath = systemPath.join(".iteration-create.lock")
# 锁文件只允许当前用户读写。
File.open(lockPath, File::RDWR | File::CREAT, 0o600) do |lockFile|
  # 已存在的宽权限锁也恢复成私有权限。
  lockFile.chmod(0o600)
  # 排他锁覆盖摘要计算、记录写入和总览刷新。
  lockFile.flock(File::LOCK_EX)
  # 等锁期间 phase 可能已被另一个合规 Agent 推进，必须在操作前重新读取。
  lockedPhase = statusPath.read[/^- phase:\s*(.+)$/, 1]&.strip
  # 锁内复核消除检查与写入之间的竞态窗口。
  abort "#{stageName} 审批只能在 #{expectedPhase} 阶段记录，当前为 #{lockedPhase.inspect}" unless lockedPhase == expectedPhase
  # 读取能力迁移边界；损坏日志不能被当成“尚未启用”而绕过。
  capabilityLog = CapabilitySupport.parseLog(iterationPath)
  # 新 v2 始终检查；v1 迁移轮只从尚未经过的需求或计划门禁开始检查。
  migrationBase = capabilityLog[:valid] ? capabilityLog[:headers]["migration_base_phase"] : nil
  # 需求与计划分别计算迁移时尚未经过的阶段。
  capabilityRequired = if stageName == "requirements"
                         # specify 接入时，需求审批仍是未来门禁。
                         %w[new specify].include?(migrationBase)
                       else
                         # plan 接入时，计划审批仍是未来门禁。
                         %w[new specify plan].include?(migrationBase)
                       end
  # 日志存在但格式无效时明确阻断，避免损坏证据降级成旧轮兼容。
  abort "能力日志无效：#{capabilityLog[:reason]}" if iterationPath.join(CapabilitySupport::LOG_FILE).file? && !capabilityLog[:valid]
  # v2 和迁移边界共同决定审批前是否执行能力门禁。
  if StageApproval.readPolicy(iterationPath) == "capability-gates-v2" || capabilityRequired
    # 摘要与即将写入审批记录的输入完全相同，避免检查和记录相信不同文档版本。
    stageDigest = StageApproval.digest(iterationPath, stageName)
    # 工作流档位属于 status.md 的恢复状态；历史轮次缺字段时按 standard 兼容。
    workflowProfile = CapabilitySupport.workflowProfile(iterationPath)
    # 非简单轮次必须完成访谈；简单轮次也要留下确定性跳过清单。
    interviewValidation = CapabilitySupport.interviewValidation(
      iterationPath,
      stageName,
      expectedDigest: stageDigest,
      workflowProfile: workflowProfile,
      profileRules: profileRules
    )
    # 访谈无效时保留具体原因，Agent 可直接回到未决问题或摘要更新处。
    abort "#{stageName} 审批前设计访谈无效：#{interviewValidation[:reason]}" unless interviewValidation[:valid]
    # 两个审批阶段分别绑定自己的评审能力，不允许用另一阶段证据替代。
    reviewCapability = stageName == "requirements" ? "requirements-review" : "plan-review"
    # 阶段评审必须使用同一摘要并已处置所有 P0、P1 和 P2。
    reviewValidation = CapabilitySupport.capabilityValidation(iterationPath, reviewCapability, phase: expectedPhase, expectedDigest: stageDigest)
    # 缺失、过期或仍有发现都阻断用户审批记录。
    abort "#{stageName} 审批前能力评审无效：#{reviewValidation[:reason]}" unless reviewValidation[:valid]
  end
  # 模块会校验证据短语、依赖审批和当前文档摘要。
  records = StageApproval.approve(iterationPath, stageName, evidence)
  # 审批列是派生视图，和记录写入处于同一系统锁内。
  IterationOverview.refresh(systemPath)
  # 输出可复核文件与摘要，不输出任何产品仓库内容。
  puts iterationPath.join(StageApproval::FILE_NAME)
  puts "#{stageName}: #{records.fetch(stageName).fetch('digest')}"
end
