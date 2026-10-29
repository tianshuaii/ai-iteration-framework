#!/usr/bin/env ruby

# 本模块只读取能力登记、访谈和证据索引，不执行 Skill 或 MCP。
# Skill 负责产生方法化结果，MCP 负责取得事实或执行已授权动作。
# 门禁只相信轮次目录中的结构化记录和实际存在的证据文件。
# status.md 仍是唯一动态进度源，能力日志不能改变 phase 或 task。
# 历史完成轮次没有能力日志时免追溯；迁移基线决定从哪一阶段生效。
# 证据默认留在 evidence/；访谈能力可直接引用本轮标准 design-interview.md，避免重复正文。
# 输入摘要必须是 SHA-256，阶段文件变化后旧证据会自然失效。
# P0、P1 和未处置 P2 都阻断通过，不能用 passed 文案掩盖发现项。

require "digest"
require "pathname"
require "time"
require "yaml"
require_relative "capability-digest-support"

# 能力门禁的格式解析和确定性校验统一放在同一命名空间。
module CapabilitySupport
  # 根登记表是稳定能力事实源，每轮只记录执行结果。
  REGISTRY_FILE = "capabilities.yml"
  # 两份轮次结构化文件使用固定名称，避免 file-map 改写证据语义。
  LOG_FILE = "capability-log.md"
  INTERVIEW_FILE = "design-interview.md"
  INTERVIEW_MARKER = "<!-- design-interview-policy: design-tree-v1 -->"
  # 迁移基线只允许生命周期阶段或全量启用的新轮次。
  BASE_PHASES = %w[new specify plan implement verify].freeze
  # 能力状态保持小集合；superseded 仅用于保留历史执行。
  CAPABILITY_STATUSES = %w[pending passed failed skipped superseded].freeze
  # 日志只接受登记表中的稳定能力名，防止拼写错误变成永远匹配不到的记录。
  CAPABILITY_NAMES = %w[design-interview requirements-review plan-review implementation-guard code-review test-verification delivery-review iteration-governor].freeze
  # 访谈尝试额外使用 completed 表示已经回答完成。
  INTERVIEW_STATUSES = %w[pending completed skipped superseded].freeze
  # 新访谈尝试使用同屏提问与用户原话证据协议；旧尝试没有该字段时按历史格式读取。
  QUESTION_PROTOCOL = "inline-confirmation-v1"
  # 复杂度字段与根登记表逐项对应，uncertain 用于显式表达未知。
  COMPLEXITY_KEYS = %w[
    product_code interface_or_schema database_or_migration permission_or_security
    concurrency performance multiple_repositories external_service deployment
    destructive_operation uncertain
  ].freeze
  # 档位名称是跨脚本协议；具体触发条件仍由 capabilities.yml 提供，避免在代码中复制策略。
  WORKFLOW_PROFILES = %w[lite standard strict].freeze
  # 缺少新字段的历史轮次按 standard 处理，既不伪造轻量资格，也不强制升级全部旧档案。
  DEFAULT_WORKFLOW_PROFILE = "standard"

  # 读取并验证根能力登记表的最低稳定结构。
  def self.registryValidation(frameworkRoot)
    # 路径固定在框架根，不允许某个系统维护局部宽松版本。
    registryPath = Pathname.new(frameworkRoot).expand_path.join(REGISTRY_FILE)
    # 缺失时所有能力名和权限边界都失去来源。
    return { valid: false, reason: "缺少 #{REGISTRY_FILE}" } unless registryPath.file?
    # YAML 使用 safe_load，配置不需要对象反序列化或别名。
    registry = YAML.safe_load(registryPath.read, permitted_classes: [], aliases: false)
    # 版本、策略和能力集合共同构成当前契约。
    return { valid: false, reason: "#{REGISTRY_FILE} 版本或策略无效" } unless registry.is_a?(Hash) && registry["version"] == 1 && registry["policy"] == "capability-gates-v1"
    # 八项能力必须全部存在，后续阶段门禁才有稳定名称。
    requiredCapabilities = %w[design-interview requirements-review plan-review implementation-guard code-review test-verification delivery-review iteration-governor]
    # 找出缺失项并一次返回，避免调用方猜测配置内容。
    missingCapabilities = requiredCapabilities - registry.fetch("capabilities", {}).keys
    # 任一缺失都会让对应阶段无法可靠降级或阻断。
    return { valid: false, reason: "#{REGISTRY_FILE} 缺少能力：#{missingCapabilities.join(', ')}" } unless missingCapabilities.empty?
    # 三级流程必须完整登记；选择规则和每档行为都由同一配置提供。
    workflowConfig = registry.fetch("workflow_profiles", {})
    # YAML 允许把映射误写成字符串或数组；先检查类型，避免后续 fetch 抛出实现异常。
    return { valid: false, reason: "#{REGISTRY_FILE} 工作流档位配置必须是映射" } unless workflowConfig.is_a?(Hash)
    # profiles 缺档会让同一 status 在不同脚本中得到不同解释。
    profileConfigs = workflowConfig.fetch("profiles", {})
    # profiles 必须以档位名为键，其他类型无法提供稳定的规则查询。
    return { valid: false, reason: "#{REGISTRY_FILE} 工作流档位列表必须是映射" } unless profileConfigs.is_a?(Hash)
    # 三个稳定档位必须全部存在，不能静默回退到某个默认流程。
    missingProfiles = WORKFLOW_PROFILES - profileConfigs.keys
    # 一次报告全部缺失项，便于修复配置而不是在审批阶段逐个失败。
    return { valid: false, reason: "#{REGISTRY_FILE} 缺少工作流档位：#{missingProfiles.join(', ')}" } unless missingProfiles.empty?
    # 每个档位仍必须是映射，防止 rank 和访谈阶段读取时崩溃。
    invalidProfile = WORKFLOW_PROFILES.find { |profileName| !profileConfigs.fetch(profileName).is_a?(Hash) }
    # 返回具体档位，配置维护者可以直接定位错误项。
    return { valid: false, reason: "#{REGISTRY_FILE} 工作流档位配置非法：#{invalidProfile}" } if invalidProfile
    # 选择条件只能引用设计访谈已经持久化的复杂度字段。
    selectionConfig = workflowConfig.fetch("selection", {})
    # 选择规则必须是映射，不能把未知结构静默解释为空条件。
    return { valid: false, reason: "#{REGISTRY_FILE} 工作流选择规则必须是映射" } unless selectionConfig.is_a?(Hash)
    # 高风险和普通产品代码条件都必须是数组，防止字符串被逐字符解释。
    selectionKeys = Array(selectionConfig["strict_when_any"]) + Array(selectionConfig["standard_when_any"])
    # 未知字段无法从 design-interview.md 取得证据，因此必须拒绝。
    invalidSelectionKeys = selectionKeys - COMPLEXITY_KEYS
    # 配置漂移时在框架校验阶段直接给出根因。
    return { valid: false, reason: "#{REGISTRY_FILE} 工作流选择字段非法：#{invalidSelectionKeys.join(', ')}" } unless invalidSelectionKeys.empty?
    # 默认档位也必须属于固定集合，避免拼写错误导致隐式降级。
    return { valid: false, reason: "#{REGISTRY_FILE} 工作流默认档位非法" } unless WORKFLOW_PROFILES.include?(selectionConfig["default"])
    # 每档需要唯一正整数等级和明确的非简单访谈阶段。
    profileRanks = profileConfigs.values.map { |config| config["rank"] }
    # 重复或非法等级会让“最低安全档位”比较失去确定性。
    return { valid: false, reason: "#{REGISTRY_FILE} 工作流档位等级非法" } unless profileRanks.all? { |rank| rank.is_a?(Integer) && rank.positive? } && profileRanks.uniq.length == profileRanks.length
    # 访谈阶段只允许审批脚本已经认识的 requirements 和 plan。
    validInterviewStages = %w[requirements plan]
    # 任一档位含未知阶段都视为配置错误，不能在运行期猜测。
    invalidInterviewStage = profileConfigs.values.flat_map { |config| Array(config["non_trivial_interview_required_in"]) }.find { |stage| !validInterviewStages.include?(stage) }
    # 返回具体非法阶段，便于直接修复 capabilities.yml。
    return { valid: false, reason: "#{REGISTRY_FILE} 工作流访谈阶段非法：#{invalidInterviewStage}" } if invalidInterviewStage
    # 外部动作必须保留明确授权规则，不能退化成 MCP 自行决定。
    externalPolicy = registry.dig("authorization", "external_mutations")
    # 只接受当前约定值，拼写漂移也会被校验发现。
    return { valid: false, reason: "#{REGISTRY_FILE} 缺少外部写入授权边界" } unless externalPolicy == "explicit-user-authorization"
    # 返回结构供文档或其他脚本复用。
    { valid: true, registry: registry }
  rescue KeyError, NoMethodError, Psych::Exception => error
    # YAML 语法或必要结构错误不应让主校验器崩溃。
    { valid: false, reason: "#{REGISTRY_FILE} 无法解析：#{error.message}" }
  end

  # 从 status.md 读取本轮工作流档位；历史轮次缺字段时使用兼容默认值。
  def self.workflowProfile(iterationPath)
    # 档位属于动态恢复状态，因此只从本轮 status.md 读取。
    statusPath = Pathname.new(iterationPath).expand_path.join("status.md")
    # 缺少状态文件由主校验器报告，这里返回兼容默认值避免额外异常。
    return DEFAULT_WORKFLOW_PROFILE unless statusPath.file?
    # 字段使用和其他状态相同的 Markdown 列表格式。
    profile = statusPath.read[/^- workflow_profile:\s*(.+)$/, 1]&.strip
    # 缺字段仅代表旧轮次；非法值保留给调用方给出明确错误。
    profile || DEFAULT_WORKFLOW_PROFILE
  end

  # 根据复杂度证据计算最低安全档位，并验证当前档位没有降级绕过。
  def self.workflowProfileValidation(workflowProfile, complexityFields, profileRules)
    # 配置已由 registryValidation 检查；调用方仍可能直接传入空值，因此保持防御性失败。
    return { valid: false, reason: "缺少工作流档位配置" } unless profileRules.is_a?(Hash)
    # 档位必须在固定协议和当前配置中同时存在。
    profileConfigs = profileRules.fetch("profiles", {})
    # 未知档位不能被当成 strict，也不能静默降级成 standard。
    return { valid: false, reason: "工作流档位非法：#{workflowProfile}" } unless WORKFLOW_PROFILES.include?(workflowProfile) && profileConfigs.key?(workflowProfile)
    # 选择规则只判断字段是否明确为 no；yes 和 unknown 都要求采用更安全的档位。
    selectionConfig = profileRules.fetch("selection", {})
    # 任一高风险字段不是 no 时，最低档位固定为 strict。
    strictRequired = Array(selectionConfig["strict_when_any"]).any? { |key| complexityFields[key] != "no" }
    # 没有高风险时，产品代码字段不是 no 则至少使用 standard。
    standardRequired = Array(selectionConfig["standard_when_any"]).any? { |key| complexityFields[key] != "no" }
    # 剩余确定性低风险工作可以进入配置声明的默认档位。
    minimumProfile = strictRequired ? "strict" : standardRequired ? "standard" : selectionConfig.fetch("default")
    # 等级来自配置，比较结果不依赖档位名称的字典序。
    actualRank = profileConfigs.fetch(workflowProfile).fetch("rank")
    # 最低等级同样来自配置，便于未来调整而不改 Ruby 逻辑。
    minimumRank = profileConfigs.fetch(minimumProfile).fetch("rank")
    # 档位过低会漏掉必要访谈，必须在用户审批前阻断。
    return { valid: false, reason: "当前 #{workflowProfile} 低于复杂度要求的 #{minimumProfile}" } if actualRank < minimumRank
    # 返回最低档位供上下文汇总和诊断显示。
    { valid: true, minimum_profile: minimumProfile, profile: workflowProfile }
  rescue KeyError => error
    # 配置缺键时不允许审批脚本继续使用半份策略。
    { valid: false, reason: "工作流档位配置不完整：#{error.message}" }
  end

  # 解析能力日志头和表格行；任何结构问题都作为错误列表返回。
  def self.parseLog(iterationPath)
    # 日志固定在轮次根目录，不接受外部绝对路径。
    logPath = Pathname.new(iterationPath).expand_path.join(LOG_FILE)
    # 缺失由迁移策略决定是否允许，这里只返回明确状态。
    return { valid: false, reason: "缺少 #{LOG_FILE}" } unless logPath.file?
    # 一次读取便于同时验证标记、头字段和表格。
    content = logPath.read
    # 任意策略标记总数必须恰好为一，防止拼接两份日志后按较宽松版本解释。
    policyMarkerCount = content.scan(/<!-- capability-log-policy:[^>]+-->/).length
    # 已知策略也必须唯一命中；未知版本不能由当前代码猜测兼容行为。
    matchedPolicies = CapabilityDigestSupport::LOG_POLICY_MARKERS.select { |_policyName, marker| content.scan(marker).length == 1 }
    # 缺失、重复或未知策略都会让摘要语义不确定，因此整份日志失效。
    return { valid: false, reason: "#{LOG_FILE} 格式标记无效" } unless policyMarkerCount == 1 && matchedPolicies.length == 1
    # 后续实施守卫根据日志产生时的策略决定是否执行任务级摘要校验。
    policyName = matchedPolicies.keys.first
    # 三个头字段各自只能出现一次。
    headers = %w[adopted_at migration_base_phase migration_current_task migration_task_state note].to_h do |fieldName|
      # 锚定列表项，避免把表格或说明中的同名单词误读为字段。
      matches = content.scan(/^- #{Regexp.escape(fieldName)}:\s*(.+)$/)
      # 重复或缺失保留 nil，下面统一拒绝。
      [fieldName, matches.length == 1 ? matches.first.first.strip : nil]
    end
    # 空字段不能建立迁移边界。
    return { valid: false, reason: "#{LOG_FILE} 头字段缺失或重复" } if headers.values.any? { |value| value.nil? || value.empty? }
    # adopted_at 必须带时区并能被标准库解析。
    begin
      # 先检查时区后缀，避免本地无时区时间产生环境依赖。
      raise ArgumentError unless headers["adopted_at"].match?(/(?:Z|[+-]\d{2}:\d{2})\z/)
      # 日期本身仍交给标准库校验。
      Time.iso8601(headers["adopted_at"])
    rescue ArgumentError
      # 时间非法时整份日志不可作为证据。
      return { valid: false, reason: "#{LOG_FILE} adopted_at 非法" }
    end
    # 未知迁移基线会让阶段豁免范围不确定。
    return { valid: false, reason: "#{LOG_FILE} migration_base_phase 非法" } unless BASE_PHASES.include?(headers["migration_base_phase"])
    # 新轮次没有迁移任务；实施中接入时必须记录当时任务和状态以界定非追溯范围。
    if headers["migration_base_phase"] == "implement"
      # 任务必须使用框架稳定编号，不能把自然语言写入机器字段。
      return { valid: false, reason: "#{LOG_FILE} migration_current_task 非法" } unless headers["migration_current_task"].match?(/\AT-\d+\z/)
      # 只有已开始或被阻塞的任务才可能错过实现前守卫。
      return { valid: false, reason: "#{LOG_FILE} migration_task_state 非法" } unless %w[ready in_progress blocked].include?(headers["migration_task_state"])
    elsif headers["migration_current_task"] != "无" || headers["migration_task_state"] != "无"
      # 其他基线不允许夹带无效任务例外。
      return { valid: false, reason: "#{LOG_FILE} 非 implement 迁移不能记录当前任务" }
    end
    # 能力表固定十四列，行解析不依赖自然语言正文。
    rows = []
    # 逐行只处理标准数据行；表头和分隔行自然被过滤。
    content.each_line do |line|
      # 数据行必须以 C-编号开始，防止正文表格误入。
      next unless line.match?(/^\|\s*C-\d+\s*\|/)
      # 保留空单元格再去掉排版空白。
      cells = line.strip.split("|", -1)[1...-1].map(&:strip)
      # 列数不符说明记录损坏，不能部分解析。
      return { valid: false, reason: "#{LOG_FILE} 记录列数非法" } unless cells.length == 14
      # 保存字段名结构，调用方不用依赖数组位置。
      rows << %i[id capability phase task provider provider_version status input_digest evidence started_at completed_at p0 p1 p2_open].zip(cells).to_h
    end
    # 编号重复会让“最新记录”依赖文件顺序，必须拒绝。
    duplicateIds = rows.group_by { |row| row[:id] }.select { |_id, values| values.length > 1 }.keys
    # 一次报告全部重复编号。
    return { valid: false, reason: "#{LOG_FILE} 记录编号重复：#{duplicateIds.join(', ')}" } unless duplicateIds.empty?
    # 逐条检查字段、路径和真实证据。
    rows.each do |row|
      # 未登记能力不能进入门禁日志。
      return { valid: false, reason: "#{row[:id]} capability 名称非法" } unless CAPABILITY_NAMES.include?(row[:capability])
      # phase 必须是生命周期阶段，能力不能挂在自然语言阶段上。
      return { valid: false, reason: "#{row[:id]} phase 非法" } unless %w[specify plan implement verify done].include?(row[:phase])
      # 提供者和版本是复现能力执行的最低信息。
      return { valid: false, reason: "#{row[:id]} 缺少 provider 或 provider_version" } if [row[:provider], row[:provider_version]].any? { |value| value.empty? || value == "无" }
      # 状态必须属于小集合，未知值不能默认为失败或通过。
      return { valid: false, reason: "#{row[:id]} capability status 非法" } unless CAPABILITY_STATUSES.include?(row[:status])
      # 三个发现计数都必须是非负整数。
      return { valid: false, reason: "#{row[:id]} 发现计数非法" } unless [row[:p0], row[:p1], row[:p2_open]].all? { |value| value.match?(/\A\d+\z/) }
      # 非 pending 记录必须绑定确定输入摘要。
      if %w[passed failed skipped superseded].include?(row[:status])
        # SHA-256 使用固定 64 位小写十六进制。
        return { valid: false, reason: "#{row[:id]} input_digest 非法" } unless row[:input_digest].match?(/\A[0-9a-f]{64}\z/)
      end
      # 证据默认位于本轮 evidence/；设计访谈可复用轮次根部的标准结构化文件。
      evidencePath = Pathname.new(row[:evidence])
      # pending 可以暂时使用无；其余状态必须有真实文件。
      next if row[:status] == "pending" && row[:evidence] == "无"
      # 只有 design-interview 能力可以直接引用唯一标准访谈文件，其他根文件仍然禁止。
      canonicalInterviewEvidence = row[:capability] == "design-interview" && evidencePath.to_s == INTERVIEW_FILE
      # 普通证据必须以 evidence 为第一段，不能借绝对路径或上级跳转越界。
      standardEvidence = !evidencePath.absolute? && !evidencePath.each_filename.include?("..") && evidencePath.each_filename.first == "evidence"
      # 两种受控形式之外的路径都拒绝，不能引用需求正文、产品仓库或系统外文件。
      return { valid: false, reason: "#{row[:id]} evidence 路径越界" } unless canonicalInterviewEvidence || standardEvidence
      # 证据根目录必须是轮次内的真实目录，不能用软链接跳到产品仓库。
      evidenceRoot = Pathname.new(iterationPath).expand_path.join("evidence")
      # 普通证据要求真实 evidence 根；标准访谈文件不依赖该目录的重复副本。
      if standardEvidence
        # 缺目录或根目录软链接都不能作为安全边界。
        return { valid: false, reason: "#{row[:id]} evidence 根目录无效" } unless evidenceRoot.directory? && !evidenceRoot.symlink?
      end
      # 逐级拒绝路径中的软链接，避免最终文件 realpath 越出本轮。
      currentEvidencePath = Pathname.new(iterationPath).expand_path
      # 相对路径已经通过 .. 检查，可以安全逐段拼接。
      evidencePath.each_filename do |pathPart|
        # 每一级都必须留在当前轮次的词法路径内。
        currentEvidencePath = currentEvidencePath.join(pathPart)
        # 任一软链接都会让后续 file? 跟随到未知位置。
        return { valid: false, reason: "#{row[:id]} evidence 不能包含软链接" } if currentEvidencePath.symlink?
      end
      # 文件必须真实存在，只有日志索引不能证明能力已执行。
      return { valid: false, reason: "#{row[:id]} evidence 文件不存在" } unless currentEvidencePath.file?
      # 完成记录的开始和结束时间都必须带时区。
      [row[:started_at], row[:completed_at]].each do |timestamp|
        # 时间解析放在 rescue 覆盖范围内。
        raise ArgumentError unless timestamp.match?(/(?:Z|[+-]\d{2}:\d{2})\z/)
        # 标准库验证真实日期范围。
        Time.iso8601(timestamp)
      end
    end
    # 返回头、行和路径供阶段校验复用。
    { valid: true, headers: headers, rows: rows, path: logPath, policy: policyName }
  rescue ArgumentError
    # 任一完成时间非法都使日志失去审计顺序。
    { valid: false, reason: "#{LOG_FILE} 能力记录时间非法" }
  end

  # 查找与阶段、任务和摘要匹配的最新通过记录。
  def self.capabilityValidation(iterationPath, capabilityName, phase:, task: "无", expectedDigest: nil)
    # 先验证整份日志，不能从损坏文件里挑一行放行。
    parsedLog = parseLog(iterationPath)
    # 原因透传给审批脚本和框架校验器。
    return parsedLog unless parsedLog[:valid]
    # 只选择同能力、阶段和任务的记录，最后一行代表最近尝试。
    candidates = parsedLog[:rows].select { |row| row[:capability] == capabilityName && row[:phase] == phase && row[:task] == task }
    # 没有记录时给出稳定原因。
    return { valid: false, reason: "缺少 #{capabilityName} 能力记录" } if candidates.empty?
    # 日志只追加，因此同一选择集最后一行是最新结果。
    row = candidates.last
    # 必需阶段能力必须真实通过；简单访谈的 skipped 在 design-interview.md 单独校验。
    return { valid: false, reason: "#{capabilityName} 最新状态不是 passed", row: row } unless row[:status] == "passed"
    # 阶段摘要变化后旧能力证据必须重新执行。
    return { valid: false, reason: "#{capabilityName} 输入摘要已过期", row: row } if expectedDigest && row[:input_digest] != expectedDigest
    # 严重发现和未处置 P2 都不能被 passed 字段覆盖。
    return { valid: false, reason: "#{capabilityName} 仍有未处置发现", row: row } unless [row[:p0], row[:p1], row[:p2_open]].all? { |value| value == "0" }
    # 所有结构和证据均有效时返回匹配行。
    { valid: true, row: row, log: parsedLog }
  end

end

# 访谈解析按职责拆分，但仍由原入口加载，所有调用方保持兼容。
require_relative "capability-interview-support"
