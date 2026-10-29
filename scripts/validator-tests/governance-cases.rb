# 状态、审批与能力门禁回归

# 覆盖恢复状态、双审批、问题可见性、能力摘要和代码审核覆盖链。
# 本文件由统一测试入口在同一 Ruby 进程中加载，共享一次准备好的合法夹具。
# 案例只修改临时副本，不读取或改写真实业务轮次。

# 设计访谈能力可直接引用本轮标准结构化访谈，避免在 evidence/ 重复整份正文。
runSuccessCase(FRAMEWORK_ROOT, "design interview uses canonical iteration evidence") do |caseRoot|
  # 合成轮次已由模板提供真实 design-interview.md，不创建第二份副本。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 追加一条只用于路径边界的能力索引，摘要保持合法 SHA-256 形状。
  recordLine = "| C-990 | design-interview | specify | 无 | grill-me | 1 | passed | #{'a' * 64} | design-interview.md | 2020-01-01T00:00:00+00:00 | 2020-01-01T00:01:00+00:00 | 0 | 0 | 0 |\n"
  # 日志仍采用追加语义，不覆盖其他阶段能力记录。
  File.open(iterationPath.join("capability-log.md"), "a") { |file| file.write(recordLine) }
end
# 根部白名单只覆盖标准访谈文件，其他能力不能借此引用任意轮次正文。
runFailureCase(FRAMEWORK_ROOT, "non interview capability cannot use root evidence", "evidence 路径越界") do |caseRoot|
  # requirements.md 真实存在，但不是允许直接引用的能力证据路径。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 使用合法字段构造单一越界条件。
  recordLine = "| C-991 | code-review | implement | 无 | code-review-skill | 1 | passed | #{'b' * 64} | requirements.md | 2020-01-01T00:00:00+00:00 | 2020-01-01T00:01:00+00:00 | 0 | 0 | 0 |\n"
  # 追加后主解析器必须在读取其他能力之前拒绝该根部路径。
  File.open(iterationPath.join("capability-log.md"), "a") { |file| file.write(recordLine) }
end

# 完成态允许面向用户的等价文案，避免为了机器字面值反复修历史状态。
runSuccessCase(FRAMEWORK_ROOT, "done with human-readable no next action") do |caseRoot|
  # 从合法 verify 夹具生成具备完整验收证据的完成态。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 复用统一辅助函数，确保本案例只改变 next_action 文案。
  markFixtureDone(iterationPath)
  # 将机器占位值替换成项目汇报规则要求的人类可读表达。
  statusPath = iterationPath.join("status.md")
  # 末尾句号也应被安全规范化，不应成为全局治理失败。
  replaceOnce(statusPath, "- next_action: 无", "- next_action: 本轮无后续动作。")
end


# 完成态没有后续动作时，恢复摘要不应默认要求加载交付证据正文。
runSuccessCase(FRAMEWORK_ROOT, "done context has no default evidence reads") do |caseRoot|
  # 合成夹具先按真实门禁生成合法完成态。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 完成态证据仍完整存在，只改变恢复入口的默认读取建议。
  markFixtureDone(iterationPath)
  # 无后续动作使用明确哨兵，不能输出空值或四份默认文件。
  assertFixtureReadNext(caseRoot, iterationPath, [])
end

# 活动阶段恢复按当前动作保持有界集合，不再机械读取整阶段全部正文。
runSuccessCase(FRAMEWORK_ROOT, "active context read sets stay bounded") do |caseRoot|
  # 合成基线从合法 verify 状态开始，所有变体只在同一临时副本中短暂切换。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 保存原始状态，案例结束前恢复，后续全局校验仍验证合法基线。
  statusPath = iterationPath.join("status.md")
  originalStatus = statusPath.read
  # 普通验收只读取验收、策略、用例和既有结果。
  verifyFiles = %w[acceptance.md test-strategy.md test-cases.md test-log.md]
  assertFixtureReadNext(caseRoot, iterationPath, verifyFiles)
  # 单独收口切换到交付材料，不重复加载测试设计。
  closureFiles = %w[acceptance.md test-log.md review-checklist.md workspace.md]
  assertFixtureReadNext(caseRoot, iterationPath, closureFiles, intent: "确认收口")
  # 联合验收收口是唯一一次扩展到六份材料的显式路径。
  combinedFiles = %w[acceptance.md test-strategy.md test-cases.md test-log.md review-checklist.md workspace.md]
  assertFixtureReadNext(caseRoot, iterationPath, combinedFiles, intent: "验收并收口")
  # 规格常态保持四份核心文档，测试和跟踪材料留到对应动作。
  specifyStatus = originalStatus.sub(/^- phase: verify$/, "- phase: specify")
  statusPath.write(specifyStatus)
  specifyFiles = %w[requirements.md decisions.md change-scope.md acceptance.md]
  assertFixtureReadNext(caseRoot, iterationPath, specifyFiles)
  # 需求审批改读验收与策略，不提前读取计划正文。
  requirementApprovalFiles = %w[requirements.md change-scope.md acceptance.md test-strategy.md]
  assertFixtureReadNext(caseRoot, iterationPath, requirementApprovalFiles, intent: "需求审批通过")
  # 计划常态保留已审批需求和范围，只读取当前方案与任务。
  planStatus = originalStatus.sub(/^- phase: verify$/, "- phase: plan")
  statusPath.write(planStatus)
  planFiles = %w[requirements.md change-scope.md implementation-plan.md tasks.md]
  assertFixtureReadNext(caseRoot, iterationPath, planFiles)
  # 计划审批再切换到方案、任务、风险和资源预留。
  planApprovalFiles = %w[implementation-plan.md tasks.md risks.md workspace.md]
  assertFixtureReadNext(caseRoot, iterationPath, planApprovalFiles, intent: "计划审批通过")
  # 当前任务正文已在摘要中，只需读取共享范围和检出基线；首次守卫尚无证据文件。
  implementStatus = originalStatus.sub(/^- phase: verify$/, "- phase: implement").sub(/^- current_task: .+$/, "- current_task: T-01")
  statusPath.write(implementStatus)
  assertFixtureReadNext(caseRoot, iterationPath, %w[change-scope.md workspace.md])
  # 全部任务完成且已有统一审核证据时，恢复集合增加该报告但不加载验收正文。
  reviewStatus = implementStatus.sub(/^- current_task: .+$/, "- current_task: 无")
  statusPath.write(reviewStatus)
  reviewFiles = %w[tasks.md change-scope.md evidence/reviews/implementation-review.md]
  assertFixtureReadNext(caseRoot, iterationPath, reviewFiles)
  # 非法任务值只能引导回读状态，不能得到“无”并继续产品写入。
  invalidTaskStatus = implementStatus.sub(/^- current_task: .+$/, "- current_task: invalid")
  statusPath.write(invalidTaskStatus)
  assertFixtureReadNext(caseRoot, iterationPath, ["status.md"])
  # 恢复合法 verify 状态，确保本案例仍通过完整框架校验。
  statusPath.write(originalStatus)
end

# 任务级摘要必须同时满足“其他任务稳定”和“当前任务变化失效”。
runTaskGuardDigestIsolationCase(FRAMEWORK_ROOT)

# 局部校验应服务日常恢复，但不能改变无参数全局治理结果。
runScopedValidationIsolationCase(FRAMEWORK_ROOT)

# 待确认问题在状态中包含完整标题和推荐回复时，plan / blocked 应保持可恢复。
runSuccessCase(FRAMEWORK_ROOT, "pending question is fully visible") do |caseRoot|
  # 合成轮次只在临时副本中退回计划阶段。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 完整问题标题和推荐回复同时进入 next_action。
  preparePendingQuestionFixture(
    iterationPath,
    nextAction: "请确认 Q99 是否采用安全迁移顺序；推荐先删外键再删表；如同意请回复“Q99 按推荐做”"
  )
  # 等待计划问题时只读取访谈、当前方案和风险，不再加载八份计划正文。
  pendingFiles = %w[design-interview.md implementation-plan.md risks.md]
  assertFixtureReadNext(caseRoot, iterationPath, pendingFiles)
end

# 全部任务完成后可以停在 implement 的统一审核窗口，尚未生成审核证据不应被误判为越过门禁。
runSuccessCase(FRAMEWORK_ROOT, "implementation review window before verify") do |caseRoot|
  # 合成基线默认已经进入 verify，改回全部任务完成后的 implement 状态。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 去掉已经生成的统一审核记录，模拟刚完成最后一条任务。
  capabilityLogPath = iterationPath.join("capability-log.md")
  # 数据行按能力名精确删除，保留日志头和其他能力记录。
  capabilityLogPath.write(capabilityLogPath.readlines.reject { |line| line.include?("| code-review |") }.join)
  # 统一审核窗口没有具体 current_task，但仍属于 implement 活动阶段。
  statusPath = iterationPath.join("status.md")
  # 一次改回阶段、状态和下一步，任务清单仍保持全部勾选。
  statusContent = statusPath.read
    .sub(/^- phase: verify$/, "- phase: implement")
    .sub(/^- current_task: .+$/, "- current_task: 无")
    .sub(/^- work_state: .+$/, "- work_state: ready")
    .sub(/^- checkpoint: .+$/, "- checkpoint: 全部任务已经实现完成")
    .sub(/^- next_action: .+$/, "- next_action: 执行迭代级统一检查与代码审核")
  # 只写临时副本中的状态。
  statusPath.write(statusContent)
end

# 已完成历史轮次仍接受旧的逐任务审核证据，避免新规则要求伪造过去的统一审核。
runSuccessCase(FRAMEWORK_ROOT, "historical done with legacy task review") do |caseRoot|
  # 先按新流程建立完整完成态和最终能力证据。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # done 后才启用历史兼容分支。
  markFixtureDone(iterationPath)
  # 把统一审核证据复制成旧版逐任务证据路径。
  unifiedEvidencePath = iterationPath.join("evidence", "reviews", "implementation-review.md")
  # 历史日志引用的文件必须真实存在。
  taskEvidencePath = iterationPath.join("evidence", "reviews", "T-01.md")
  # 复用相同合成内容，不制造第二套审核结论。
  FileUtils.cp(unifiedEvidencePath, taskEvidencePath)
  # 只把能力行的 task 和证据路径改成旧协议格式。
  capabilityLogPath = iterationPath.join("capability-log.md")
  # 精确替换 code-review 行，其他最终能力记录保持不变。
  legacyLines = capabilityLogPath.readlines.map do |line|
    line.include?("| code-review |") ? line.sub("| 无 |", "| T-01 |").sub("evidence/reviews/implementation-review.md", "evidence/reviews/T-01.md") : line
  end
  # 写回临时历史夹具。
  capabilityLogPath.write(legacyLines.join)
end

# 新规则不能要求已经完成的旧轮次补造当时不存在的浅功能回归证据。
runSuccessCase(FRAMEWORK_ROOT, "historical done without shallow regression policy") do |caseRoot|
  # 先定位仍处于 verify 的合成轮次，再移除新协议标记和全部 SR 产物。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 旧测试策略没有协议标记，也不登记 SR 范围。
  resolveFixtureFile(iterationPath, "test-strategy.md").write("# 测试策略\n\n## 自动\n\n- `ruby -v`\n")
  # 历史用例只保留正式验收对应的 TC。
  resolveFixtureFile(iterationPath, "test-cases.md").write("# 测试用例\n\n## TC-01 校验夹具\n\n1. 运行夹具。\n\n期望：得到受控结果。\n")
  # 历史日志同样只保留正式测试结果。
  resolveFixtureFile(iterationPath, "test-log.md").write("# 测试记录\n\n| 用例 | 日期 | 结果 | 现象 |\n|---|---|---|---|\n| TC-01 | 2020-01-01 | 豁免 | 用户确认仅测试夹具；残余风险仅限夹具 |\n")
  # 该兼容场景代表新能力与审批协议采用前已经进入验收的旧轮次。
  markFixtureAsHistoricalVerifyMigration(iterationPath)
  # 完成态能力摘要会按无标记旧协议计算，因此应继续通过。
  markFixtureDone(iterationPath)
end

# 旧版完成轮可能已经使用 SR 编号，但四列表并不等于后来引入的 bounded-v1 协议。
runSuccessCase(FRAMEWORK_ROOT, "historical done with legacy shallow regression table") do |caseRoot|
  # 从合法 verify 夹具开始，只替换浅回归策略为旧版四列表。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 旧表第二列直接保存功能描述，没有“直接/相邻”类型列。
  legacyStrategy = "# 测试策略\n\n## 受控浅功能回归\n\n| 编号 | 覆盖 | 纳入理由 | 停止边界 |\n|---|---|---|---|\n| SR-01 | 校验器主路径 | 本轮直接变更 | 只检查退出码 |\n| SR-02 | 总览刷新 | 共享状态输入 | 不检查其他系统 |\n"
  # 写入旧策略后，将夹具声明为从 verify 才采用能力日志的历史迁移轮。
  resolveFixtureFile(iterationPath, "test-strategy.md").write(legacyStrategy)
  # 历史迁移边界允许此前阶段不回补新协议证据。
  markFixtureAsHistoricalVerifyMigration(iterationPath)
  # 完成态摘要必须沿用旧五文件集合，不能因旧 SR 编号被迫重写历史能力行。
  markFixtureDone(iterationPath)
end

# v1 完成档案允许验收文档在收尾时发生非结构变化，不要求伪造新的历史能力记录。
runSuccessCase(FRAMEWORK_ROOT, "legacy done keeps recorded final capability evidence") do |caseRoot|
  # 合成基线使用 capability-gates-v1，先按当时协议生成真实完成记录。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 正常进入 done，确保测试和交付能力记录真实存在。
  markFixtureDone(iterationPath)
  # 追加不改变测试表结构的归档说明，模拟最终报告后整理文档造成摘要漂移。
  testLogPath = resolveFixtureFile(iterationPath, "test-log.md")
  # v1 仍须通过正文一致性门禁；这里只制造摘要变化，不制造缺失或伪通过。
  testLogPath.write("#{testLogPath.read}\n归档说明：保留原验证结论。\n")
end

# v2 完成档案仍必须绑定当前验证摘要，不能借 v1 兼容路径绕过内容漂移。
runFailureCase(FRAMEWORK_ROOT, "current done rejects stale final capability digest", "test-verification 输入摘要已过期") do |caseRoot|
  # 先以完整摘要生成完成记录，再把日志策略升级为当前 v2。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 能力记录生成时验收文档尚未变化。
  markFixtureDone(iterationPath)
  # 只切换日志策略边界；最终能力摘要算法本身保持相同。
  capabilityLogPath = iterationPath.join("capability-log.md")
  # v2 表示当前轮次不得使用历史摘要冻结兼容。
  capabilityLogPath.write(capabilityLogPath.read.sub("<!-- capability-log-policy: capability-gates-v1 -->", "<!-- capability-log-policy: task-guard-digest-v2 -->"))
  # 追加归档说明制造确定的摘要漂移，正文结构仍然合法。
  testLogPath = resolveFixtureFile(iterationPath, "test-log.md")
  # 当前协议必须发现这次变化并要求重新验证。
  testLogPath.write("#{testLogPath.read}\n归档说明：当前协议摘要变化。\n")
end

# 计划重批后的当前统一审核可以补偿 done 归档中无法追溯重做的旧事前守卫。
runSuccessCase(FRAMEWORK_ROOT, "done replan review covers stale implementation guard") do |caseRoot|
  # 合成 verify 轮先切到 v2，并把迁移任务声明为采用门禁时仍处于 ready。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # v2 才会计算任务级守卫摘要，本案例不影响 v1 历史兼容。
  capabilityLogPath = iterationPath.join("capability-log.md")
  # ready 表示 T-01 必须保留真实事前守卫行。
  upgradedLog = capabilityLogPath.read
    .sub("<!-- capability-log-policy: capability-gates-v1 -->", "<!-- capability-log-policy: task-guard-digest-v2 -->")
    .sub("- migration_task_state: in_progress", "- migration_task_state: ready")
  # 写入升级后的日志头，再按当前任务正文计算守卫摘要。
  capabilityLogPath.write(upgradedLog)
  # v2 任务守卫只读取 workspace 的稳定计划区，旧夹具需补上边界标记。
  workspacePath = resolveFixtureFile(iterationPath, "workspace.md")
  # 本案例的 workspace 全文都是静态夹具，可整体作为计划区而不引入运行期抖动。
  workspacePath.write("<!-- plan-approval-scope:start -->\n#{workspacePath.read}<!-- plan-approval-scope:end -->\n")
  # 先记录计划修订前真实有效的 T-01 守卫。
  initialGuardDigest = CapabilityDigestSupport.implementationGuardDigest(iterationPath, "T-01")
  # 证据文件已由模板提供，日志只追加索引。
  appendFixtureCapability(iterationPath, id: "C-010", capability: "implementation-guard", phase: "implement", task: "T-01", digest: initialGuardDigest, evidence: "evidence/reviews/T-01.md")
  # 修改任务文件范围，模拟实现后发现计划需要修订；旧守卫因此确定过期。
  tasksPath = resolveFixtureFile(iterationPath, "tasks.md")
  # 只改变 T-01 自身写入范围，不增加第二个任务或额外测试成本。
  tasksPath.write(tasksPath.read.sub("文件：`fixture.txt`", "文件：`fixture-updated.txt`"))
  # 真实审批命令只允许在 plan 阶段执行，因此先按协议退回计划门禁。
  statusPath = iterationPath.join("status.md")
  # 临时夹具没有并发写入，精确替换阶段即可表达重批流程。
  statusPath.write(statusPath.read.sub(/^- phase: verify$/, "- phase: plan"))
  # 使用真实审批入口重新绑定修改后的计划摘要。
  recordApproval(caseRoot, iterationPath, "plan", "开始处理，计划审批通过")
  # 审批完成后恢复 verify，后续 markFixtureDone 才能沿真实阶段切换。
  statusPath.write(statusPath.read.sub(/^- phase: plan$/, "- phase: verify"))
  # 状态恢复后同步系统投影，避免成功案例被 overview 漂移干扰。
  refreshOverview(caseRoot, iterationPath.parent.parent)
  # 当前统一审核尚未追加时，旧守卫摘要过期必须继续阻断，证明补偿路径没有自动放宽 done。
  _preReviewOutput, preReviewError, preReviewStatus = Open3.capture3("ruby", "scripts/validate-framework.rb", chdir: caseRoot.to_s)
  # 失败原因必须明确来自旧守卫，其他偶然错误不能冒充本断言通过。
  unless !preReviewStatus.success? && preReviewError.include?("T-01 实施守卫无效：implementation-guard 输入摘要已过期")
    # 抛出实际输出方便定位夹具或门禁行为漂移。
    raise "stale guard unexpectedly passed without current unified review: #{preReviewError}"
  end
  # 计划重批后追加一次覆盖全部最终差异的当前统一审核。
  currentPlanDigest = StageApproval.digest(iterationPath, "plan")
  # 该记录晚于旧守卫且绑定当前计划，是完成归档兼容的补偿性控制。
  appendFixtureCapability(iterationPath, id: "C-011", capability: "code-review", phase: "implement", task: "无", digest: currentPlanDigest, evidence: "evidence/reviews/implementation-review.md")
  # 最终能力证据仍按当前验收文档生成，然后进入 done。
  markFixtureDone(iterationPath)
end

# 旧模板创建但仍活动的轮次补入 SR 后，done 必须继续使用新协议而不是历史豁免。
runSuccessCase(FRAMEWORK_ROOT, "markerless active iteration adopts shallow regression") do |caseRoot|
  # 合成轮次保留完整 SR 范围，只模拟旧模板没有协议标记。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 移除标记会改变需求摘要，因此把该夹具声明成 verify 才采用能力策略的历史活动轮。
  strategyPath = resolveFixtureFile(iterationPath, "test-strategy.md")
  # SR 行保持不变，用于证明校验器不会仅依赖标记。
  strategyPath.write(strategyPath.read.sub("<!-- shallow-regression-policy: bounded-v1 -->\n", ""))
  # 转换迁移边界后，最终能力摘要应自动包含测试策略。
  markFixtureAsHistoricalVerifyMigration(iterationPath)
  # 两条 SR 都通过时应合法完成；若错误走旧协议，后续失败测试会暴露终态漏洞。
  markFixtureDone(iterationPath)
end

# 历史完成轮次没有新审批文件时允许免追溯，避免伪造过去的用户确认。
runSuccessCase(FRAMEWORK_ROOT, "historical done without approval record") do |caseRoot|
  # 先把具备完整新审批的夹具合法切到完成态。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 完成态仍先经过既有验收门禁。
  markFixtureDone(iterationPath)
  # 再移除审批文件，模拟双审批规则引入前已经完成的历史轮次。
  FileUtils.rm(iterationPath.join("stage-approvals.md"))
  # 同一历史轮也没有后来引入的能力日志，避免构造半迁移状态。
  FileUtils.rm(iterationPath.join("capability-log.md"))
end

# 能力门禁引入前的完成轮不要求追补后来新增的逐文件 workspace 证据。
runSuccessCase(FRAMEWORK_ROOT, "historical done without workspace baseline details") do |caseRoot|
  # 先生成完整完成态，再移除能力日志以建立清晰的历史兼容边界。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 合法进入 done，确保兼容规则不是替活动轮绕过阶段门禁。
  markFixtureDone(iterationPath)
  # 无能力日志表示该轮完成时尚未采用当前能力和 workspace 追溯协议。
  FileUtils.rm(iterationPath.join("capability-log.md"))
  # 保留旧档案的真实缺口：既有占位基线，也没有 dirty 明细章节。
  workspacePath = resolveFixtureFile(iterationPath, "workspace.md")
  # 精确替换一项基线值并移除章节标题，避免案例引入无关结构错误。
  workspacePath.write(workspacePath.read.sub("fixture-head", "尚未采集").sub("## 接管前 dirty 明细", "## 接管前状态摘要"))
end

# 活动轮次缺少审批记录必须被阻断。
runFailureCase(FRAMEWORK_ROOT, "active iteration missing approval record", "缺少 stage-approvals.md") do |caseRoot|
  # 合成轮次默认处于 verify，因此属于活动轮次。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 仅移除审批文件，保持其他夹具完全合法。
  FileUtils.rm(iterationPath.join("stage-approvals.md"))
end

# 显式未知档位不能退回兼容默认值，避免拼写错误绕过三级流程。
runFailureCase(FRAMEWORK_ROOT, "invalid workflow profile", "workflow_profile 非法") do |caseRoot|
  # 合成历史夹具默认没有档位字段；追加未知值模拟手工写错。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 字段放在状态标题后，解析器仍按行首稳定读取。
  statusPath = iterationPath.join("status.md")
  # 只增加一个错误条件，其他阶段和审批保持合法。
  statusPath.write(statusPath.read.sub("# 状态\n", "# 状态\n\n- workflow_profile: ultra\n"))
end

# 根能力登记中的档位节点必须是映射，结构写坏时应返回诊断而不是 Ruby 调用栈。
runFailureCase(FRAMEWORK_ROOT, "malformed workflow profile config", "工作流档位配置非法：standard") do |caseRoot|
  # 合成夹具建立后再损坏配置，避免审批准备阶段提前拦截本案例。
  registryPath = caseRoot.join("capabilities.yml")
  # 只把 standard 的映射替换为字符串，其他根配置保持合法。
  registryContent = registryPath.read
  # 非贪婪范围止于 strict 档位，确保案例只改变一个档位节点。
  malformedContent = registryContent.sub(/    standard:\n.*?(?=    strict:\n)/m, "    standard: broken\n")
  # 模板结构漂移时不能静默保留原配置并产生假阳性。
  raise "workflow profile fixture missing" if malformedContent == registryContent
  # 只写临时副本，由校验器验证人可读失败路径。
  registryPath.write(malformedContent)
end

# 能力证据不能通过软链接跳出本轮 evidence/ 边界。
runFailureCase(FRAMEWORK_ROOT, "capability evidence symlink escape", "evidence 不能包含软链接") do |caseRoot|
  # 找到代码审核证据和轮次外的替代文件。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 删除模板准备时建立的真实证据。
  reviewEvidencePath = iterationPath.join("evidence", "reviews", "implementation-review.md")
  FileUtils.rm(reviewEvidencePath)
  # 外部文件仍在临时框架内，但不属于本轮证据边界。
  outsideEvidencePath = caseRoot.join("outside-review.md")
  outsideEvidencePath.write("# 外部伪证据\n")
  # 用软链接模拟路径文本看似合法但真实目标越界。
  File.symlink(outsideEvidencePath, reviewEvidencePath)
end

# 活动 verify 必须持有覆盖全部任务差异的统一审核，旧逐任务记录不能继续跨过新门禁。
runFailureCase(FRAMEWORK_ROOT, "verify with legacy task review", "迭代级统一代码审核无效") do |caseRoot|
  # 当前合成轮处于 verify，直接把统一记录降级成旧逐任务记录。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 能力证据仍存在，但 task 不再是统一审核要求的“无”。
  capabilityLogPath = iterationPath.join("capability-log.md")
  # 只改变 task 单元格，证明门禁不是单纯检查能力名存在。
  capabilityLogPath.write(capabilityLogPath.read.sub("| code-review | implement | 无 |", "| code-review | implement | T-01 |"))
end

# 没有返工增量链时，过期的首次统一审核摘要不能单独放行。
runFailureCase(FRAMEWORK_ROOT, "stale unified review without rework chain", "摘要过期且无有效增量审核") do |caseRoot|
  # 合成基线仍处于 verify，只损坏统一审核绑定的计划摘要。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 64 位合法格式确保失败来自语义过期，不是日志结构损坏。
  logPath = iterationPath.join("capability-log.md")
  # C-001 是基线唯一的 task=无 审核记录。
  logPath.write(logPath.read.lines.map { |line| line.start_with?("| C-001 |") ? line.sub(/[a-f0-9]{64}/, "b" * 64) : line }.join)
end

# 整轮审核之后新增的返工守卫必须有更晚的同任务增量审核。
runFailureCase(FRAMEWORK_ROOT, "rework guard without incremental review", "增量代码审核未覆盖：T-01") do |caseRoot|
  # 把迁移任务声明为规则采用时尚未开始，使它进入守卫与审核覆盖集合。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 只改变迁移状态，保留原统一审核作为返工前有效基线。
  logPath = iterationPath.join("capability-log.md")
  logPath.write(logPath.read.sub("- migration_task_state: in_progress", "- migration_task_state: ready"))
  # 新守卫追加在统一审核之后，模拟验收失败后开始修复。
  planDigest = StageApproval.digest(iterationPath, "plan")
  appendFixtureCapability(iterationPath, id: "C-900", capability: "implementation-guard", phase: "implement", task: "T-01", digest: planDigest, evidence: "evidence/reviews/T-01-rework.md")
end

# 同任务增量审核位于返工守卫之后时，不要求重新生成 task=无 的全量审核。
runSuccessCase(FRAMEWORK_ROOT, "rework guard with incremental review") do |caseRoot|
  # 与失败案例使用相同返工边界，只增加一条真正覆盖它的审核记录。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # ready 表示守卫是本次返工必须具备的前置证据。
  logPath = iterationPath.join("capability-log.md")
  logPath.write(logPath.read.sub("- migration_task_state: in_progress", "- migration_task_state: ready"))
  # v1 合成日志的任务审核继续绑定产生时的计划摘要。
  planDigest = StageApproval.digest(iterationPath, "plan")
  appendFixtureCapability(iterationPath, id: "C-900", capability: "implementation-guard", phase: "implement", task: "T-01", digest: planDigest, evidence: "evidence/reviews/T-01-rework.md")
  # 审核行的追加顺序晚于守卫，因此覆盖链应允许继续 verify。
  appendFixtureCapability(iterationPath, id: "C-901", capability: "code-review", phase: "implement", task: "T-01", digest: planDigest, evidence: "evidence/reviews/implementation-review.md")
  # 模拟返工追加任务后当前计划摘要变化；增量链应延续而非重做旧整轮审核。
  logContent = logPath.read
  # 只把首次统一审核的旧摘要改成另一合法摘要，增量审核仍绑定当前任务输入。
  staleBaseDigest = "a" * 64
  # 精确定位 C-001，避免同时改动守卫或增量记录。
  logPath.write(logContent.lines.map { |line| line.start_with?("| C-001 |") ? line.sub(planDigest, staleBaseDigest) : line }.join)
end

# next_action 只写 Q 编号和回复口令时，用户仍看不到问题正文，必须失败。
runFailureCase(FRAMEWORK_ROOT, "pending question uses bare id", "next_action 未同屏写出 Q99 问题全文") do |caseRoot|
  # 建立合法 pending 问题，但故意省略完整标题。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 裸编号正是本次修复的回归场景。
  preparePendingQuestionFixture(iterationPath, nextAction: "请回复“Q99 按推荐做”")
end

# next_action 有问题标题和回复口令但没有推荐内容时，仍不算全文同屏。
runFailureCase(FRAMEWORK_ROOT, "pending question hides recommendation", "next_action 未同屏写出 Q99 推荐方案") do |caseRoot|
  # 建立合法 pending 问题，只故意省略推荐答案正文。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 问题标题和口令均存在，失败必须精确来自推荐方案缺失。
  preparePendingQuestionFixture(
    iterationPath,
    nextAction: "请确认 Q99 是否采用安全迁移顺序；如同意请回复“Q99 按推荐做”"
  )
end

# 存在 pending 问题时不能继续保留已批准计划。
runFailureCase(FRAMEWORK_ROOT, "pending question retains approved plan", "未决问题仍保留 plan approved 审批") do |caseRoot|
  # 计划审批保持合成基线的 approved，其他状态按等待问题构造。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 完整问题可见，失败应只来自审批冲突。
  preparePendingQuestionFixture(
    iterationPath,
    nextAction: "请确认 Q99 是否采用安全迁移顺序；如同意请回复“Q99 按推荐做”",
    preservePlanApproval: true
  )
end

# 未保存用户原话时，手工把 pending 改成 resolved 也不能通过结构校验。
runFailureCase(FRAMEWORK_ROOT, "resolved question without user evidence", "resolved 问题缺少用户确认原话：Q99") do |caseRoot|
  # 先建立合法的待确认问题和 pending 审批。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 状态包含完整问题，排除可见性噪音。
  preparePendingQuestionFixture(
    iterationPath,
    nextAction: "请确认 Q99 是否采用安全迁移顺序；如同意请回复“Q99 按推荐做”"
  )
  # 再伪造 resolved，但确认依据仍为“无”。
  interviewPath = iterationPath.join("design-interview.md")
  # 同时改未决计数，证明门禁不只依赖 unresolved_count。
  invalidContent = interviewPath.read
    .sub("- unresolved_count: 1", "- unresolved_count: 0")
    .sub("| Q99 是否采用安全迁移顺序 | 先删外键再删表 | 待确认 | pending | 无 |", "| Q99 是否采用安全迁移顺序 | 先删外键再删表 | 按推荐做 | resolved | 无 |")
  # 写入临时伪证据。
  interviewPath.write(invalidContent)
end

# current_task=无 只允许全部任务已实现完成后的统一审核窗口。
runFailureCase(FRAMEWORK_ROOT, "implementation review window with pending task", "统一审核前仍有未完成任务") do |caseRoot|
  # 将 verify 改回 implement 统一审核窗口。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 留下一条未完成任务，制造状态与清单冲突。
  tasksPath = resolveFixtureFile(iterationPath, "tasks.md")
  # 合成夹具只有一条任务，精确恢复为未勾选。
  tasksPath.write(tasksPath.read.sub("- [x] T-01", "- [ ] T-01"))
  # 统一审核窗口固定使用 current_task=无。
  statusPath = iterationPath.join("status.md")
  # 切回 implement 但不指定任务编号。
  statusContent = statusPath.read
    .sub(/^- phase: verify$/, "- phase: implement")
    .sub(/^- current_task: .+$/, "- current_task: 无")
    .sub(/^- next_action: .+$/, "- next_action: 执行迭代级统一审核")
  # 写回临时副本。
  statusPath.write(statusContent)
end
