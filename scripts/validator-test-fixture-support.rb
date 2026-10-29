#!/usr/bin/env ruby

# 本支持模块在临时目录复制通用框架后制造失败场景，不修改真实框架或产品仓库。
# 它集中提供夹具、摘要和执行辅助方法，案例文件只描述单一行为变化。
# 每个案例在副本里建立独立的最小合法系统，不依赖真实业务轮次状态。
# 每个案例只改一个关键条件，并断言非零退出码和明确错误文本。
# 临时目录由 Dir.mktmpdir 自动清理，不遗留测试副本。

require "fileutils"
require "open3"
require "pathname"
require "tmpdir"
require_relative "capability-support"
require_relative "stage-approval-support"

# 精确替换一次文本；找不到目标时直接让测试失败。
def replaceOnce(path, beforeText, afterText)
  # 读取完整小型 Markdown 文件，避免引入额外模板依赖。
  content = path.read
  # 夹具漂移时不能静默生成一个没有效果的案例。
  raise "fixture text not found in #{path}" unless content.include?(beforeText)
  # sub 只替换第一次，保证每个案例保持单一变量。
  path.write(content.sub(beforeText, afterText))
end
# 从复制后的框架动态找到首个登记系统和首个活动轮次。
def locateActiveIteration(caseRoot)
  # systems 下的普通目录都是登记系统，软链接知识库不会进入这一层。
  systemsRoot = caseRoot.join("systems")
  # 测试仓库至少要有一个登记系统，否则无法覆盖迭代门禁。
  systemPath = systemsRoot.children.select(&:directory?).reject(&:symlink?).sort.first
  # 缺少系统时给出测试夹具错误，不伪装成校验器通过。
  raise "no registered system fixture" unless systemPath
  # 扫描普通轮次目录，和真实校验器使用同一种发现范围。
  iterationPaths = systemPath.join("iterations").children.select(&:directory?).reject(&:symlink?).sort
  # 读取合法状态，done 归档不参与活动轮次夹具选择。
  activePath = iterationPaths.find do |iterationPath|
    # 缺失 status 的失败案例不应被这里误选。
    statusPath = iterationPath.join("status.md")
    # 只从标准 phase 字段判断活动状态。
    statusPath.file? && statusPath.read.match?(/^- phase: (?:specify|plan|implement|verify)$/)
  end
  # 测试需要一个合成的活动轮次。
  raise "no active iteration fixture" unless activePath
  # 返回系统目录和活动轮次，案例可按需定位文件。
  [systemPath, activePath]
end

# 按本轮 file-map 解析标准文件；没有映射时直接使用标准名。
def resolveFixtureFile(iterationPath, standardName)
  # 历史轮次才有 file-map，新轮次通常没有。
  mapPath = iterationPath.join("file-map.md")
  # 缺少映射时返回标准英文文件。
  return iterationPath.join(standardName) unless mapPath.file?
  # 映射行固定使用两个反引号单元格。
  mappingPattern = /^\|\s*`#{Regexp.escape(standardName)}`\s*\|\s*`([^`]+)`\s*\|/
  # 找到目标标准名对应的实际文件。
  mappingMatch = mapPath.read.match(mappingPattern)
  # 未映射的新文件仍使用标准名。
  iterationPath.join(mappingMatch ? mappingMatch[1] : standardName)
end

# 向临时能力日志追加一条有真实证据文件的通过记录。
def appendFixtureCapability(iterationPath, id:, capability:, phase:, task:, digest:, evidence:)
  # 证据路径必须位于本轮 evidence/，与生产校验边界一致。
  evidencePath = iterationPath.join(evidence)
  # 父目录由模板提供；部分测试重写目录时仍确保存在。
  FileUtils.mkdir_p(evidencePath.dirname)
  # 简短正文足以证明索引不是悬空路径。
  evidencePath.write("# 合成能力证据\n\n#{capability} 已通过，无阻断发现。\n")
  # 固定时间与发现计数让夹具结果可重复。
  recordLine = "| #{id} | #{capability} | #{phase} | #{task} | #{capability} | 1 | passed | #{digest} | #{evidence} | 2020-01-01T00:00:00+00:00 | 2020-01-01T00:01:00+00:00 | 0 | 0 | 0 |\n"
  # 能力日志采用追加语义，测试也不覆盖已有历史行。
  File.open(iterationPath.join("capability-log.md"), "a") { |file| file.write(recordLine) }
end

# 只复制通用框架文件，真实系统档案不进入任何测试临时目录。
def copyFrameworkFixture(frameworkRoot, caseRoot)
  # 先建立临时根目录，所有复制目标都限定在其中。
  FileUtils.mkdir_p(caseRoot)
  # 通用规则、模板与校验器是被测对象，已登记业务系统不是。
  frameworkRoot.children.each do |sourcePath|
    # systems 单独只取入口规则，避免复制用户业务资料和知识库链接。
    next if sourcePath.basename.to_s == "systems"
    # .worktrees 可能包含大型临时产品仓库，不属于校验器夹具。
    next if sourcePath.basename.to_s == ".worktrees"
    # Git 基线只服务真实框架版本管理，复制到每个案例会放大磁盘和回归耗时。
    next if sourcePath.basename.to_s == ".git"
    # 保留原有目录结构供相对链接和脚本定位使用。
    FileUtils.cp_r(sourcePath, caseRoot.join(sourcePath.basename))
  end
  # systems/AGENTS.md 是校验器要求的通用入口。
  systemsRoot = caseRoot.join("systems")
  # 不复制 systems/ 下的任何已登记业务轮次。
  FileUtils.mkdir_p(systemsRoot)
  # 入口规则本身仍从真实框架复制，以便案例验证其内容。
  FileUtils.cp(frameworkRoot.join("systems", "AGENTS.md"), systemsRoot.join("AGENTS.md"))
end

# 从一次性构建的合法基线复制案例，避免每条断言重复执行审批和总览刷新子进程。
def copyPreparedFixture(caseRoot)
  # 每个案例仍使用独立目录，单变量修改不会污染其他案例或共享基线。
  FileUtils.mkdir_p(caseRoot)
  # 逐个复制基线根节点，保持框架根目录层级与真实调用完全一致。
  VALIDATOR_BASELINE_ROOT.children.each do |sourcePath|
    # 基线只包含通用框架和合成系统，不含真实业务档案或产品仓库。
    FileUtils.cp_r(sourcePath, caseRoot.join(sourcePath.basename))
  end
end
# 在临时框架副本中建立固定的最小合法系统和 verify 轮次。
def prepareActiveFixture(caseRoot)
  # 真实业务档案可能暂时校验失败，回归测试不应因此无法运行。
  systemsRoot = caseRoot.join("systems")
  # 中性系统名和临时检出目录不会与真实业务路径耦合。
  systemPath = systemsRoot.join("validator-example")
  # 校验器只要求检出路径存在，不会在其中执行代码。
  checkoutPath = caseRoot.join("validator-checkout")
  # 合成轮次仍遵循序号、日期与中文主题的目录格式。
  iterationPath = systemPath.join("iterations", "001-2020-01-01-校验夹具")
  # 所有新路径都限制在当前临时副本内。
  FileUtils.mkdir_p([checkoutPath, iterationPath, systemPath.join("agent")])
  # 系统入口沿用被测框架的模板，而不是在测试里复制一套规则。
  FileUtils.cp(caseRoot.join("system-template", "AGENTS.md"), systemPath.join("AGENTS.md"))
  # 会话绑定协议也由同一系统模板提供。
  FileUtils.cp(caseRoot.join("system-template", "agent", "README.md"), systemPath.join("agent", "README.md"))
  # 登记表只保留稳定入口，不复制动态阶段状态。
  systemsRoot.join("README.md").write("# 项目\n\n## 当前登记\n\n| 系统 | 说明 |\n|---|---|\n| [validator-example](./validator-example/overview.md) | 校验器夹具 |\n")
  # 根 README 的登记链接也必须指向夹具，不能留业务目录断链。
  rootReadmePath = caseRoot.join("README.md")
  # 仅在临时副本中把所有系统 overview 链接换成合成系统入口。
  rootReadmePath.write(rootReadmePath.read.gsub(%r{\./systems/[a-z0-9-]+/overview\.md}, "./systems/validator-example/overview.md"))
  # overview 登记临时仓库，并预留由 status.md 驱动的唯一管理块。
  systemPath.join("overview.md").write("# 校验器夹具\n\n| 仓库 | 绝对路径 | 常用检查命令 |\n|---|---|---|\n| validator-checkout | `#{checkoutPath}` | `ruby -v` |\n\n## 迭代\n\n<!-- iteration-status-view:start -->\n| 轮次 | 主题 | phase | work_state | approval_gate | updated_at | next_action |\n|---|---|---|---|---|---|---|\n<!-- iteration-status-view:end -->\n")
  # 必需轮次文件仍从框架模板复制，减少测试与产品规则的漂移。
  caseRoot.join("templates").children.each do |templatePath|
    # 说明文件与可选知识库不属于每轮必需产物。
    next if %w[README.md optional-knowledge-base].include?(templatePath.basename.to_s)
    # 仅写临时轮次目录，不修改真实模板。
    FileUtils.cp_r(templatePath, iterationPath.join(templatePath.basename))
  end
  # 合成活动轮模拟能力策略在 T-01 已进行时接入，既有 v1 审批不追溯访谈。
  approvalPath = iterationPath.join("stage-approvals.md")
  # 审批入口继续走真实 v1 摘要和用户证据逻辑。
  approvalPath.write(approvalPath.read.sub("capability-gates-v2", "user-gates-v1"))
  # 能力日志记录精确采用时间和迁移任务边界。
  capabilityLogPath = iterationPath.join("capability-log.md")
  # 一次替换模板字段，后续由共享解析器验证。
  # 合成基线模拟实施中接入能力策略的历史轮次，因此保留旧整轮摘要兼容语义。
  capabilityLogContent = capabilityLogPath.read
    .sub("<!-- capability-log-policy: task-guard-digest-v2 -->", "<!-- capability-log-policy: capability-gates-v1 -->")
    .sub("YYYY-MM-DDTHH:MM:SS+08:00", "2020-01-01T00:00:00+00:00")
    .sub("- migration_base_phase: new", "- migration_base_phase: implement")
    .sub("- migration_current_task: 无", "- migration_current_task: T-01")
    .sub("- migration_task_state: 无", "- migration_task_state: in_progress")
  # 保存迁移后的合法日志头。
  capabilityLogPath.write(capabilityLogContent)
  # 先从 specify 建立合法需求审批，再按真实顺序推进到 verify。
  iterationPath.join("status.md").write("# 状态\n\n- phase: specify\n- current_task: 无\n- work_state: blocked\n- updated_at: 2020-01-01T00:00:00+00:00\n- checkpoint: 合成规格已完成，等待审批\n- next_action: 请用户审批合成需求\n")
  # 一条已完成任务足以覆盖 verify 与 done 的任务门禁。
  iterationPath.join("tasks.md").write("# 任务清单\n\n- [x] T-01 校验夹具。依赖：无。文件：`fixture.txt`。检查：`ruby -v`\n")
  # 验收与测试各有一条受控豁免，供双向一致性案例复用。
  iterationPath.join("acceptance.md").write("# 验收标准\n\n| 编号 | 对应测试 | 标准 | 结果 |\n|---|---|---|---|\n| AC-01 | TC-01 | 校验夹具 | 豁免：用户确认仅测试夹具；残余风险仅限夹具 |\n")
  # 浅功能回归同时登记直接和一层相邻功能，验证范围与停止边界门禁。
  iterationPath.join("test-strategy.md").write("<!-- shallow-regression-policy: bounded-v1 -->\n<!-- risk-based-testing-policy: adaptive-v1 -->\n# 测试策略\n\n## 任务风险分级\n\n| 任务 | 档位 | 分级理由 | 影响仓库/模块 | 必须执行 | 可复用证据 | 升级条件 |\n|---|---|---|---|---|---|---|\n| T-01 | T2 | 校验器行为变化 | validator | ruby 校验器回归 | 输入未变化时复用 | 共享协议变化时升级 |\n\n## 受控浅功能回归\n\n| 编号 | 类型 | 功能或路径 | 纳入理由 | 停止边界 |\n|---|---|---|---|---|\n| SR-01 | 直接 | 校验器主路径 | 本轮直接变更 | 只检查退出码 |\n| SR-02 | 相邻 | 总览刷新 | 共享状态输入 | 不检查其他系统 |\n")
  # 正式 TC 和两个 SR 都提供最小可执行步骤。
  iterationPath.join("test-cases.md").write("# 测试用例\n\n## TC-01 校验夹具\n\n1. 运行夹具。\n\n期望：得到受控结果。\n\n## SR-01 校验器主路径\n\n1. 运行校验器。\n\n期望：退出码可判断。\n\n## SR-02 总览刷新\n\n1. 读取总览。\n\n期望：不影响其他系统。\n")
  # 现象列保留与验收及浅回归对应的可复核结果。
  iterationPath.join("test-log.md").write("# 测试记录\n\n| 用例 | 日期 | 结果 | 现象 |\n|---|---|---|---|\n| TC-01 | 2020-01-01 | 豁免 | 用户确认仅测试夹具；残余风险仅限夹具 |\n\n## 受控浅功能回归\n\n| 用例 | 日期 | 结果 | 现象 |\n|---|---|---|---|\n| SR-01 | 2020-01-01 | 通过 | 校验器主路径正常 |\n| SR-02 | 2020-01-01 | 通过 | 总览刷新边界正常 |\n")
  # 跟踪表只关联正式 AC/TC；SR 由测试策略单独维护影响依据。
  iterationPath.join("traceability.md").write("# 跟踪表\n\n| 需求要点 | 验收 | 用例 | 主要文件 |\n|---|---|---|---|\n| 合成需求 | AC-01 | TC-01 | fixture.txt |\n")
  # 已勾选的评审清单允许成功案例将 verify 切换为 done。
  reviewPath = iterationPath.join("review-checklist.md")
  # 沿用模板原有项目，只调整合成夹具的完成标记。
  reviewPath.write(reviewPath.read.gsub("- [ ]", "- [x]"))
  # 工作区登记独占资源，供路径和资源冲突案例使用。
  iterationPath.join("workspace.md").write("# 产品仓库基线\n\n更新时间：2020-01-01T00:00:00+00:00\n\n| 仓库 | 产品检出路径 | 隔离方式 | 分支 | HEAD | 接管前状态 | 当前任务涉及的文件 |\n|---|---|---|---|---|---|---|\n| `validator-checkout` | `#{checkoutPath}` | 独立 worktree | `fixture` | `fixture-head` | 无 | `fixture.txt` |\n\n## 接管前 dirty 明细\n\n- 无\n\n## 运行资源\n\n| 资源标识 | 占用方式 | 用途 |\n|---|---|---|\n| `validator-runtime` | 独占 | 合成验收 |\n")
  # 通过真实命令记录需求审批，确保夹具不伪造摘要。
  recordApproval(caseRoot, iterationPath, "requirements", "开始处理，需求审批通过")
  # 需求审批成功后进入 plan。
  statusPath = iterationPath.join("status.md")
  # 改写阶段和断点，保持其他字段合法。
  statusPath.write(statusPath.read.sub(/^- phase: specify$/, "- phase: plan").sub(/^- checkpoint: .+$/, "- checkpoint: 合成计划已完成，等待审批").sub(/^- next_action: .+$/, "- next_action: 请用户审批合成计划"))
  # 再通过真实命令记录计划审批。
  recordApproval(caseRoot, iterationPath, "plan", "开始处理，计划审批通过")
  # T-01 在采用策略时已经开始，因此不追溯事前守卫，但必须经过迭代级统一审核。
  planDigest = StageApproval.digest(iterationPath, "plan")
  # task=无 表示审核覆盖本轮全部实现差异而非单个任务。
  appendFixtureCapability(iterationPath, id: "C-001", capability: "code-review", phase: "implement", task: "无", digest: planDigest, evidence: "evidence/reviews/implementation-review.md")
  # 最终进入 verify，后续旧测试继续覆盖验收和完成态门禁。
  statusPath.write(statusPath.read.sub(/^- phase: plan$/, "- phase: verify").sub(/^- checkpoint: .+$/, "- checkpoint: 合成任务已通过检查").sub(/^- next_action: .+$/, "- next_action: 校验合成用例"))
  # 状态写完后用被测刷新入口生成基线，成功夹具不手工伪造动态视图。
  refreshOverview(caseRoot, systemPath)
end

# 调用临时框架自己的刷新脚本，确保测试覆盖真实命令行入口和共享模块。
def refreshOverview(caseRoot, systemPath)
  # 子进程从临时框架根目录运行，路径解析与用户实际使用一致。
  stdout, stderr, status = Open3.capture3("ruby", "scripts/refresh-iteration-overview.rb", systemPath.to_s, chdir: caseRoot.to_s)
  # 夹具刷新失败属于测试准备错误，立即给出完整命令输出。
  raise "overview refresh fixture failed: #{stdout}\n#{stderr}" unless status.success?
end

# 通过临时框架自己的命令记录阶段审批，覆盖实际参数和锁路径。
def recordApproval(caseRoot, iterationPath, stageName, evidence)
  # 子进程使用复制后的脚本和模块，避免测试绕过被测入口。
  stdout, stderr, status = Open3.capture3("ruby", "scripts/record-stage-approval.rb", iterationPath.to_s, stageName, evidence, chdir: caseRoot.to_s)
  # 夹具审批失败说明测试准备不合法，应立即显示完整输出。
  raise "stage approval fixture failed: #{stdout}\n#{stderr}" unless status.success?
end

# 把临时活动轮次切成 done，供完成态门禁案例复用。
def markFixtureDone(iterationPath)
  # 新轮次把测试策略纳入摘要，历史轮次继续使用产生证据时的旧协议。
  testStrategyPath = resolveFixtureFile(iterationPath, "test-strategy.md")
  # 一次读取同时识别新模板标记和迁移轮保留的新版表头。
  testStrategyContent = testStrategyPath.file? ? testStrategyPath.read : ""
  # 显式标记优先；无标记迁移轮只有保留“类型”表头才表示采用新版协议。
  shallowPolicyEnabled = testStrategyContent.include?("<!-- shallow-regression-policy: bounded-v1 -->") || testStrategyContent.lines.any? { |line| line.match?(/^\|\s*编号\s*\|\s*类型\s*\|/) }
  # 根据协议选择能力证据绑定的最终文件集合。
  verificationFiles = shallowPolicyEnabled ? %w[acceptance.md test-strategy.md test-cases.md test-log.md traceability.md review-checklist.md] : %w[acceptance.md test-cases.md test-log.md traceability.md review-checklist.md]
  # done 能力证据绑定最终验收、测试、跟踪和评审清单摘要。
  verificationDigest = CapabilityDigestSupport.documentsDigest(iterationPath, verificationFiles)
  # 测试验证与交付评审是两个不可互相替代的门禁。
  appendFixtureCapability(iterationPath, id: "C-002", capability: "test-verification", phase: "verify", task: "无", digest: verificationDigest, evidence: "evidence/delivery/final-review.md")
  # 最终复核使用同一产物摘要和同一分节报告，避免重复读取与抄写。
  appendFixtureCapability(iterationPath, id: "C-003", capability: "delivery-review", phase: "verify", task: "无", digest: verificationDigest, evidence: "evidence/delivery/final-review.md")
  # 所有替换都只发生在临时副本。
  statusPath = iterationPath.join("status.md")
  # verify 进入完成态。
  statusPath.write(statusPath.read.sub(/^- phase: verify$/, "- phase: done"))
  # 完成态固定使用 done。
  statusPath.write(statusPath.read.sub(/^- work_state: .+$/, "- work_state: done"))
  # 完成态不保留下一步。
  statusPath.write(statusPath.read.sub(/^- next_action: .+$/, "- next_action: 无"))
  # 任何合法状态写入都必须同步刷新系统级只读投影。
  systemPath = iterationPath.parent.parent
  # 从轮次层级向上四级得到临时框架根目录，不依赖固定绝对路径。
  caseRoot = systemPath.parent.parent
  # 复用真实刷新入口，让后续案例只关注各自要制造的门禁条件。
  refreshOverview(caseRoot, systemPath)
end

# 把夹具转换为能力策略从 verify 才开始采用的历史轮次。
def markFixtureAsHistoricalVerifyMigration(iterationPath)
  # 历史轮不保留会被后续测试文档变化作废的新审批记录。
  FileUtils.rm(iterationPath.join("stage-approvals.md"))
  # 能力日志仍保存最终测试和交付证据，只调整迁移边界头。
  capabilityLogPath = iterationPath.join("capability-log.md")
  # 三个迁移字段必须一起变化，避免产生“非 implement 仍有当前任务”的非法组合。
  capabilityLogContent = capabilityLogPath.read
    .sub("- migration_base_phase: implement", "- migration_base_phase: verify")
    .sub("- migration_current_task: T-01", "- migration_current_task: 无")
    .sub("- migration_task_state: in_progress", "- migration_task_state: 无")
  # 保存自洽的 verify 迁移头。
  capabilityLogPath.write(capabilityLogContent)
end

# 把合成轮次退回 plan，并登记一个采用新协议的待确认问题。
def preparePendingQuestionFixture(iterationPath, nextAction:, preservePlanApproval: false)
  # 当前模板计划尝试固定为 P-001；只替换这一节，不能误改 requirements 表格。
  interviewPath = iterationPath.join("design-interview.md")
  # 非贪婪截取计划尝试正文。
  sectionPattern = /^## plan\/P-001\s*$\n(.*?)(?=^## |\z)/m
  # 模板漂移时测试必须立即失败而不是得到假阳性。
  sectionMatch = interviewPath.read.match(sectionPattern)
  raise "plan interview fixture missing" unless sectionMatch
  # pending 问题只需要更新未决计数和五列表格；其余模板字段保持合法占位。
  pendingSection = sectionMatch[1]
    .sub("- unresolved_count: 0", "- unresolved_count: 1")
    .sub("|---|---|---|---|---|\n", "|---|---|---|---|---|\n| Q99 是否采用安全迁移顺序 | 先删外键再删表 | 待确认 | pending | 无 |\n")
  # 用包含标题的完整章节替换，避免 requirements 与 plan 初始正文相同时误改第一节。
  updatedPlanSection = "## plan/P-001\n#{pendingSection}"
  # 保存当前问题协议结构。
  interviewPath.write(interviewPath.read.sub(sectionMatch[0], updatedPlanSection))
  # 共享解析器必须能识别该 pending 行，否则后续案例只会测试总览刷新。
  attemptResult = CapabilitySupport.currentInterviewAttempt(iterationPath, "plan")
  # 夹具构造失败应在运行校验器前给出明确原因。
  raise "pending interview fixture invalid: #{attemptResult[:reason]}" unless attemptResult[:valid]
  # 问题协议必须返回唯一 Q99 pending 行。
  questionResult = CapabilitySupport.interviewQuestionValidation(attemptResult[:attempt])
  unless questionResult[:valid] && questionResult[:pending_rows]&.map { |row| row[:id] } == ["Q99"]
    raise "pending question fixture invalid: #{questionResult.inspect}; fields=#{attemptResult[:attempt][:fields].inspect}"
  end
  # 等待问题时必须回到 plan / blocked，且没有当前产品任务。
  statusPath = iterationPath.join("status.md")
  # next_action 由案例参数控制，用于分别验证完整问题和裸编号。
  statusContent = statusPath.read
    .sub(/^- phase: verify$/, "- phase: plan")
    .sub(/^- work_state: .+$/, "- work_state: blocked")
    .sub(/^- checkpoint: .+$/, "- checkpoint: 合成计划等待 Q99 用户决定")
    .sub(/^- next_action: .+$/, "- next_action: #{nextAction}")
  # 写回临时状态。
  statusPath.write(statusContent)
  # 正常等待场景必须撤销计划审批；失败案例可显式保留以验证冲突门禁。
  return if preservePlanApproval
  # 使用共享解析与渲染器清空计划记录，不手工拼接审批格式。
  approvalPath = iterationPath.join(StageApproval::FILE_NAME)
  # 保留需求审批和策略版本，只把计划恢复为 pending。
  approvalRecords = StageApproval.parse(approvalPath.read)
  approvalRecords["plan"] = StageApproval.pendingRecord
  # 写回临时审批文件。
  approvalPath.write(StageApproval.render(approvalRecords, policyName: StageApproval.readPolicy(iterationPath)))
end

# 为合成轮次写入新版受控 worktree 记录，覆盖完成态生命周期门禁。
def writeManagedWorkspace(iterationPath, sourcePath:, targetPath:, state:, finalHead: "fixture-final", cleanedAt: "2020-01-02T00:00:00+00:00", includeSync: nil, syncFinalHead: nil)
  # 已删除状态的当前产品路径必须恢复为原仓库，其他状态继续指向临时目录。
  activeWorktree = state != "已删除"
  # 产品表的隔离方式与当前检出路径保持一致。
  checkoutPath = activeWorktree ? targetPath : sourcePath
  # 已删除使用共享检出，使用中和保留状态继续使用独立 worktree。
  isolationMode = activeWorktree ? "独立 worktree" : "共享检出"
  # 生命周期表保留原路径、临时路径、创建与最终版本。
  workspaceContent = <<~MARKDOWN
    <!-- workspace-policy: managed-worktree-v2 -->
    # 产品仓库基线

    更新时间：2020-01-01T00:00:00+00:00

    | 仓库 | 产品检出路径 | 隔离方式 | 分支 | HEAD | 接管前状态 | 当前任务涉及的文件 |
    |---|---|---|---|---|---|---|
    | `validator-checkout` | `#{checkoutPath}` | #{isolationMode} | `fixture` | `fixture-head` | 无 | `fixture.txt` |

    ## 接管前 dirty 明细

    - 无

    ## 运行资源

    | 资源标识 | 占用方式 | 用途 |
    |---|---|---|
    | `validator-runtime` | 独占 | 合成验收 |

    ## 临时 worktree 生命周期

    | 仓库 | 原仓库路径 | 临时 worktree 路径 | 分支 | 创建 HEAD | 最终 HEAD | 创建时间 | 状态 | 清理时间 |
    |---|---|---|---|---|---|---|---|---|
    | `validator-checkout` | `#{sourcePath}` | `#{targetPath}` | `fixture` | `fixture-created` | `#{finalHead}` | 2020-01-01T00:00:00+00:00 | #{state} | #{cleanedAt} |

    ## worktree 成果同步

    | 仓库 | 目标分支 | worktree 最终 HEAD | 原仓库同步 HEAD | 同步时间 | 状态 |
    |---|---|---|---|---|---|
  MARKDOWN
  # 已删除记录默认携带完整同步证据；其他状态默认尚未同步。
  shouldIncludeSync = includeSync.nil? ? state == "已删除" : includeSync
  if shouldIncludeSync
    # 可选覆盖最终 HEAD 用于制造两张表不一致的失败用例。
    recordedSyncHead = syncFinalHead || finalHead
    # 目标分支名保持中性，不假设 main 或 master。
    workspaceContent << "| `validator-checkout` | `target-branch` | `#{recordedSyncHead}` | `fixture-source-head` | 2020-01-01T12:00:00+00:00 | 已同步验证 |\n"
  end
  # 只覆盖临时夹具中的 workspace.md。
  iterationPath.join("workspace.md").write(workspaceContent)
end
