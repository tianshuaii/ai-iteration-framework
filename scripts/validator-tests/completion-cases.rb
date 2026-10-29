# 验收、完成态与 worktree 回归

# 覆盖风险测试、验收豁免、完成态证据和临时 worktree 生命周期。
# 本文件由统一测试入口在同一 Ruby 进程中加载，共享一次准备好的合法夹具。
# 案例只修改临时副本，不读取或改写真实业务轮次。

# 浅功能回归必须同时包含直接功能和一层相邻功能。
runFailureCase(FRAMEWORK_ROOT, "shallow regression missing adjacent scope", "浅功能回归缺少相邻功能") do |caseRoot|
  # 只删除策略中的相邻范围行，保留对应用例和日志以验证范围门禁优先可见。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 定位测试策略的 SR-02 行。
  strategyPath = resolveFixtureFile(iterationPath, "test-strategy.md")
  # 删除一条相邻范围，不改正式 TC 或直接功能。
  strategyPath.write(strategyPath.readlines.reject { |line| line.start_with?("| SR-02 ") }.join)
end
# 采用风险策略的新轮次不能遗漏任何实现任务。
runFailureCase(FRAMEWORK_ROOT, "risk strategy missing task", "风险测试策略缺少任务：T-01") do |caseRoot|
  # 基线策略已经采用 adaptive-v1，只删除任务行制造单一缺失条件。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 其他自动测试与浅回归范围保持不变。
  strategyPath = resolveFixtureFile(iterationPath, "test-strategy.md")
  strategyPath.write(strategyPath.readlines.reject { |line| line.start_with?("| T-01 ") }.join)
end

# done 前每条浅功能回归必须通过或取得完整受控豁免。
runFailureCase(FRAMEWORK_ROOT, "done with untested shallow regression", "done 浅功能回归未全部通过或受控豁免") do |caseRoot|
  # 先按正常流程生成 done 能力证据。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 完成态触发 SR 结果门禁。
  markFixtureDone(iterationPath)
  # 把一条 SR 从通过改回未测。
  testLogPath = resolveFixtureFile(iterationPath, "test-log.md")
  # 只修改直接功能项，其他记录保持合法。
  testLogPath.write(testLogPath.read.sub("| SR-01 | 2020-01-01 | 通过 |", "| SR-01 | 2020-01-01 | 未测 |"))
end

# 旧模板没有协议标记时，只要活动轮已经补入 SR，也不能在 done 绕过结果门禁。
runFailureCase(FRAMEWORK_ROOT, "markerless done with untested shallow regression", "done 浅功能回归未全部通过或受控豁免") do |caseRoot|
  # 保留两条 SR，只移除新模板的协议标记。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 先把摘要变化归入 verify 迁移边界，再生成匹配的最终能力证据。
  strategyPath = resolveFixtureFile(iterationPath, "test-strategy.md")
  # 真正采用新规则的事实由 SR 行表达。
  strategyPath.write(strategyPath.read.sub("<!-- shallow-regression-policy: bounded-v1 -->\n", ""))
  # 历史活动轮无需回补早期审批，但未来 done 门禁不能豁免。
  markFixtureAsHistoricalVerifyMigration(iterationPath)
  # 先生成与 markerless 新协议匹配的能力摘要。
  markFixtureDone(iterationPath)
  # 再把一条直接功能结果改回未测，必须阻断完成态。
  testLogPath = resolveFixtureFile(iterationPath, "test-log.md")
  # 只改变 SR-01，确保失败来自终态结果而非范围缺失。
  testLogPath.write(testLogPath.read.sub("| SR-01 | 2020-01-01 | 通过 |", "| SR-01 | 2020-01-01 | 未测 |"))
end

# 在迁移时仍为 ready 的任务开始写入前必须留下 implementation guard。
runFailureCase(FRAMEWORK_ROOT, "migrated ready task missing implementation guard", "当前任务实施守卫无效") do |caseRoot|
  # 合成夹具默认是 verify 且任务已完成，退回到同一任务的实施开始状态。
  systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 迁移元数据改为 ready，表示守卫门禁采用时尚未错过。
  logPath = iterationPath.join("capability-log.md")
  logPath.write(logPath.read.sub("- migration_task_state: in_progress", "- migration_task_state: ready"))
  # 当前任务必须恢复为未完成。
  tasksPath = iterationPath.join("tasks.md")
  tasksPath.write(tasksPath.read.sub("- [x] T-01", "- [ ] T-01"))
  # 状态切回正在实施的 T-01。
  statusPath = iterationPath.join("status.md")
  statusContent = statusPath.read
    .sub("- phase: verify", "- phase: implement")
    .sub("- current_task: 无", "- current_task: T-01")
    .sub("- work_state: blocked", "- work_state: in_progress")
  statusPath.write(statusContent)
  # 更新派生视图，让失败只来自能力守卫。
  refreshOverview(caseRoot, systemPath)
end

# 审批文件出现重复字段时必须整体拒绝，不能选择其中一条继续运行。
runFailureCase(FRAMEWORK_ROOT, "duplicate approval field", "stage-approvals.md 格式无效") do |caseRoot|
  # 定位合成轮次和审批文件。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 在需求审批段重复 status，模拟手工拼接产生歧义。
  approvalPath = iterationPath.join("stage-approvals.md")
  # 只替换第一处，计划段保持原样。
  approvalPath.write(approvalPath.read.sub("- status: approved", "- status: approved\n- status: pending"))
end

# 审批时间必须带时区，不能依赖运行机器的本地时区猜测。
runFailureCase(FRAMEWORK_ROOT, "approval timestamp missing timezone", "requirements 审批无效：审批时间非法") do |caseRoot|
  # 定位合成轮次和审批文件。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 只把需求审批时间改成没有偏移的 ISO 外观字符串。
  approvalPath = iterationPath.join("stage-approvals.md")
  # 第一处 approved_at 属于需求审批。
  approvalPath.write(approvalPath.read.sub(/- approved_at: .+/, "- approved_at: 2020-01-01T00:00:00"))
end

# 需求审批后改变规格正文必须使摘要失效。
runFailureCase(FRAMEWORK_ROOT, "requirement approval invalidated by document change", "requirements 审批无效：审批后文档已变化") do |caseRoot|
  # 定位合成 verify 轮次。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 只追加一条需求语义，不改审批记录。
  requirementsPath = resolveFixtureFile(iterationPath, "requirements.md")
  # 旧摘要必须无法覆盖新规格。
  requirementsPath.write("#{requirementsPath.read}\n新增规格约束。\n")
end

# 计划审批后改变实现计划必须使摘要失效。
runFailureCase(FRAMEWORK_ROOT, "plan approval invalidated by document change", "plan 审批无效：审批后文档已变化") do |caseRoot|
  # 定位合成 verify 轮次。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 只追加一条实现步骤，不改需求或状态。
  planPath = resolveFixtureFile(iterationPath, "implementation-plan.md")
  # 旧计划审批不能继续放行产品阶段。
  planPath.write("#{planPath.read}\n新增实现步骤。\n")
end

# plan 阶段不能在需求审批仍 pending 时存在。
runFailureCase(FRAMEWORK_ROOT, "plan without requirement approval", "plan 阶段缺少有效需求审批") do |caseRoot|
  # 找到当前 verify 轮次并退回 plan。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 用标准模板恢复双 pending，模拟试图跳过第一道门。
  FileUtils.cp(caseRoot.join("templates", "stage-approvals.md"), iterationPath.join("stage-approvals.md"))
  # plan 没有当前任务，原夹具已满足该字段约束。
  statusPath = iterationPath.join("status.md")
  # 只改阶段，其他活动状态仍合法。
  statusPath.write(statusPath.read.sub(/^- phase: verify$/, "- phase: plan"))
end

# 完整记录用户确认与残余风险的验收和测试豁免允许进入 done。
runSuccessCase(FRAMEWORK_ROOT, "controlled waiver in done") do |caseRoot|
  # 合成夹具默认处于 verify。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 豁免证据保持不变，只把阶段切换为完成态。
  markFixtureDone(iterationPath)
end

# 已清理 worktree、恢复原路径并保留最终 HEAD 的轮次允许进入 done。
runSuccessCase(FRAMEWORK_ROOT, "managed worktree cleaned in done") do |caseRoot|
  # 找到合成系统和 verify 轮次。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 原仓库目录是准备夹具时创建的稳定路径。
  sourcePath = caseRoot.join("validator-checkout")
  # 目标按受控目录规则计算，但不创建，用来表示已经删除。
  targetPath = caseRoot.join(".worktrees", "validator-example", iterationPath.basename, "validator-checkout")
  # 写入完整已删除生命周期记录。
  writeManagedWorkspace(iterationPath, sourcePath: sourcePath, targetPath: targetPath, state: "已删除")
  # 完成态同时启用验收和 worktree 收口门禁。
  markFixtureDone(iterationPath)
end

# v2 声称已经删除时必须有真实仓库目标分支同步记录。
runFailureCase(FRAMEWORK_ROOT, "managed worktree cleaned without sync", "已删除 worktree 缺少成果同步记录") do |caseRoot|
  # 找到合成系统和 verify 轮次。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 原仓库路径仍由夹具 overview 登记。
  sourcePath = caseRoot.join("validator-checkout")
  # 临时目标不存在，表示目录删除动作本身已经发生。
  targetPath = caseRoot.join(".worktrees", "validator-example", iterationPath.basename, "validator-checkout")
  # 显式关闭默认同步证据，制造绕过同步门禁的完成记录。
  writeManagedWorkspace(iterationPath, sourcePath: sourcePath, targetPath: targetPath, state: "已删除", includeSync: false)
  # 切到 done 后必须被同步证据门禁阻断。
  markFixtureDone(iterationPath)
end

# 生命周期最终 HEAD 与同步表不一致时不能证明被删除成果已经拉取。
runFailureCase(FRAMEWORK_ROOT, "managed worktree sync head mismatch", "最终 HEAD 与同步记录不一致") do |caseRoot|
  # 定位合成轮次和稳定原仓库。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 原仓库目录继续存在。
  sourcePath = caseRoot.join("validator-checkout")
  # 目标目录不创建，保持已删除文件系统事实。
  targetPath = caseRoot.join(".worktrees", "validator-example", iterationPath.basename, "validator-checkout")
  # 仅把同步表最终 HEAD 改成另一值，其他证据保持完整。
  writeManagedWorkspace(iterationPath, sourcePath: sourcePath, targetPath: targetPath, state: "已删除", syncFinalHead: "different-final")
  # 完成态必须发现两张表的证据矛盾。
  markFixtureDone(iterationPath)
end

# 用户明确确认并写明保留原因时，存在的 worktree 可以作为终态例外。
runSuccessCase(FRAMEWORK_ROOT, "managed worktree retained by user") do |caseRoot|
  # 合成轮次仍从 verify 切换到 done。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 原仓库保持存在。
  sourcePath = caseRoot.join("validator-checkout")
  # 保留目录必须真实存在且位于固定 .worktrees 层级。
  targetPath = caseRoot.join(".worktrees", "validator-example", iterationPath.basename, "validator-checkout")
  # 校验器只检查生命周期事实，不要求这里是真 Git 仓库。
  FileUtils.mkdir_p(targetPath)
  # 状态同时包含用户确认和保留原因两个证据词。
  retainState = "用户确认保留：用户确认用于后续复核；保留原因尚未合并"
  # 清理时间尚未发生，保持无。
  writeManagedWorkspace(iterationPath, sourcePath: sourcePath, targetPath: targetPath, state: retainState, cleanedAt: "无")
  # 合法保留允许完成态通过。
  markFixtureDone(iterationPath)
end

# 验收豁免缺少残余风险时不能进入 done。
runFailureCase(FRAMEWORK_ROOT, "acceptance waiver missing evidence", "验收豁免缺少用户确认或残余风险") do |caseRoot|
  # 取得临时 verify 轮次并切到 done。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 完成态会启用严格豁免门禁。
  markFixtureDone(iterationPath)
  # 按本轮映射定位验收文件。
  acceptancePath = resolveFixtureFile(iterationPath, "acceptance.md")
  # 找到第一条受控豁免，只移除“残余风险”证据词。
  waiverLine = acceptancePath.readlines.find { |line| line.include?("| 豁免：") }
  # 没有豁免行说明合成夹具已经漂移。
  raise "acceptance waiver fixture missing" unless waiverLine
  # 保留用户确认，确保案例只验证残余风险缺失。
  acceptancePath.write(acceptancePath.read.sub(waiverLine, waiverLine.sub("残余风险", "剩余问题")))
end

# done 之前仍为使用中的临时 worktree 必须阻断收口。
runFailureCase(FRAMEWORK_ROOT, "managed worktree still active in done", "done 前仍有未清理 worktree") do |caseRoot|
  # 定位合成轮次并准备受控目录。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 原仓库保持为 overview 登记目录。
  sourcePath = caseRoot.join("validator-checkout")
  # 使用中目标必须真实存在，确保错误只来自终态门禁。
  targetPath = caseRoot.join(".worktrees", "validator-example", iterationPath.basename, "validator-checkout")
  # 创建精确固定路径。
  FileUtils.mkdir_p(targetPath)
  # 使用中记录没有最终 HEAD 和清理时间。
  writeManagedWorkspace(iterationPath, sourcePath: sourcePath, targetPath: targetPath, state: "使用中", finalHead: "无", cleanedAt: "无")
  # 切到 done 触发未清理检查。
  markFixtureDone(iterationPath)
end

# 标记已删除但目录仍存在时，文档不能替代真实清理动作。
runFailureCase(FRAMEWORK_ROOT, "managed worktree falsely deleted", "标记已删除但目录仍存在") do |caseRoot|
  # 定位临时轮次和两个路径。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 原仓库目录继续存在。
  sourcePath = caseRoot.join("validator-checkout")
  # 故意保留一个本应删除的受控目标。
  targetPath = caseRoot.join(".worktrees", "validator-example", iterationPath.basename, "validator-checkout")
  # 创建目录制造文档与文件系统不一致。
  FileUtils.mkdir_p(targetPath)
  # 生命周期文本声称已经删除。
  writeManagedWorkspace(iterationPath, sourcePath: sourcePath, targetPath: targetPath, state: "已删除")
end

# 目录已删除后，产品基线仍指向临时路径也不能完成收口。
runFailureCase(FRAMEWORK_ROOT, "managed worktree pointer not restored", "已删除 worktree 未恢复原仓库产品路径") do |caseRoot|
  # 定位轮次及固定原、临时路径。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # overview 登记的原仓库仍然存在。
  sourcePath = caseRoot.join("validator-checkout")
  # 临时目录不创建，符合生命周期“已删除”的文件系统事实。
  targetPath = caseRoot.join(".worktrees", "validator-example", iterationPath.basename, "validator-checkout")
  # 先写一份合法已删除记录。
  writeManagedWorkspace(iterationPath, sourcePath: sourcePath, targetPath: targetPath, state: "已删除")
  # 只破坏产品基线行，让它错误地继续指向临时路径和独立模式。
  workspacePath = iterationPath.join("workspace.md")
  # 精确替换七列表格中的路径与模式，不改生命周期原路径。
  brokenContent = workspacePath.read.sub("| `validator-checkout` | `#{sourcePath}` | 共享检出 |", "| `validator-checkout` | `#{targetPath}` | 独立 worktree |")
  # 写回临时夹具后触发双向一致性门禁。
  workspacePath.write(brokenContent)
end

# 保留例外缺少保留原因时不能绕过完成态清理门禁。
runFailureCase(FRAMEWORK_ROOT, "managed worktree retention missing evidence", "保留缺少用户确认或保留原因") do |caseRoot|
  # 定位轮次并创建真实保留目录。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 原仓库仍是恢复路径。
  sourcePath = caseRoot.join("validator-checkout")
  # 目标使用固定受控层级。
  targetPath = caseRoot.join(".worktrees", "validator-example", iterationPath.basename, "validator-checkout")
  # 保留状态要求目录存在。
  FileUtils.mkdir_p(targetPath)
  # 状态只有用户确认，没有“保留原因”证据词。
  writeManagedWorkspace(iterationPath, sourcePath: sourcePath, targetPath: targetPath, state: "用户确认保留：用户确认稍后处理", cleanedAt: "无")
  # done 同时验证保留证据完整性。
  markFixtureDone(iterationPath)
end

# 新版 workspace 的独立 worktree 行必须有对应生命周期记录。
runFailureCase(FRAMEWORK_ROOT, "managed worktree missing lifecycle record", "独立 worktree 缺少生命周期记录") do |caseRoot|
  # 取得合成轮次的 workspace。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 在旧夹具正文前加入 v2 策略标记和两个空受控章节。
  workspacePath = iterationPath.join("workspace.md")
  # 原产品行已经是独立 worktree，但表中不增加任何九列数据行。
  workspacePath.write("<!-- workspace-policy: managed-worktree-v2 -->\n#{workspacePath.read}\n## 临时 worktree 生命周期\n\n| 仓库 | 原仓库路径 | 临时 worktree 路径 | 分支 | 创建 HEAD | 最终 HEAD | 创建时间 | 状态 | 清理时间 |\n|---|---|---|---|---|---|---|---|---|\n\n## worktree 成果同步\n\n| 仓库 | 目标分支 | worktree 最终 HEAD | 原仓库同步 HEAD | 同步时间 | 状态 |\n|---|---|---|---|---|---|\n")
end

# 固定目录中存在但没有任何轮次登记的副本必须被校验器发现。
runFailureCase(FRAMEWORK_ROOT, "orphan physical worktree directory", "未登记的 .worktrees 临时目录") do |caseRoot|
  # 合成一个符合三层目录结构、但没有 workspace 生命周期记录的实体。
  orphanPath = caseRoot.join(".worktrees", "validator-example", "999-2099-12-31-中断创建", "validator-checkout")
  # 目录内容不重要；校验器只检查受控根目录的直接三层身份。
  FileUtils.mkdir_p(orphanPath)
end

# 测试豁免缺少用户确认时不能进入 done。
runFailureCase(FRAMEWORK_ROOT, "test waiver missing evidence", "测试豁免缺少用户确认或残余风险") do |caseRoot|
  # 取得临时 verify 轮次并切到 done。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 完成态会检查测试豁免现象列。
  markFixtureDone(iterationPath)
  # 按本轮映射定位测试记录。
  testLogPath = resolveFixtureFile(iterationPath, "test-log.md")
  # 找到第一条豁免测试记录。
  waiverLine = testLogPath.readlines.find { |line| line.match?(/^\| TC-\d+ .+ \| 豁免 \|/) }
  # 没有豁免行说明夹具不再覆盖该能力。
  raise "test waiver fixture missing" unless waiverLine
  # 保留残余风险，只移除用户确认关键词。
  testLogPath.write(testLogPath.read.sub(waiverLine, waiverLine.sub("用户确认", "项目决定")))
end

# 测试已豁免时，引用它的验收项不能伪装成普通通过。
runFailureCase(FRAMEWORK_ROOT, "waiver not synchronized to acceptance", "豁免测试未同步到验收") do |caseRoot|
  # 取得临时 verify 轮次并切到 done。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 完成态才要求两边的豁免严格对应。
  markFixtureDone(iterationPath)
  # 按本轮映射定位验收文件。
  acceptancePath = resolveFixtureFile(iterationPath, "acceptance.md")
  # 找到第一条豁免验收记录。
  waiverLine = acceptancePath.readlines.find { |line| line.include?("| 豁免：") }
  # 没有豁免行时测试夹具无效。
  raise "acceptance waiver fixture missing" unless waiverLine
  # 只把结果列改成通过，关联的测试仍保持合法豁免。
  passedLine = waiverLine.sub(/豁免：.*(?= \|\s*$)/, "通过")
  # 写回单边豁免场景。
  acceptancePath.write(acceptancePath.read.sub(waiverLine, passedLine))
end

# 验收已豁免时，至少一个关联测试也必须保留受控豁免证据。
runFailureCase(FRAMEWORK_ROOT, "acceptance waiver without test waiver", "验收豁免没有对应测试豁免") do |caseRoot|
  # 取得临时 verify 轮次并切到 done。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 完成态才执行验收和测试的双向对应检查。
  markFixtureDone(iterationPath)
  # 从验收豁免行动态取得其关联测试编号。
  acceptancePath = resolveFixtureFile(iterationPath, "acceptance.md")
  # 第一条豁免就是本案例要破坏的验收记录。
  waiverLine = acceptancePath.readlines.find { |line| line.include?("| 豁免：") }
  # 没有豁免行时测试夹具已经漂移。
  raise "acceptance waiver fixture missing" unless waiverLine
  # 提取关联的第一个测试编号，避免硬编码真实业务用例。
  testId = waiverLine[/TC-\d+/]
  # 受控验收必须至少引用一个测试编号。
  raise "waived acceptance has no test id" unless testId
  # 定位该轮自己的测试记录。
  testLogPath = resolveFixtureFile(iterationPath, "test-log.md")
  # 找到对应的豁免测试行。
  testLine = testLogPath.readlines.find { |line| line.start_with?("| #{testId} ") }
  # 缺少测试记录时不能继续制造单边豁免。
  raise "linked test log fixture missing" unless testLine
  # 只把结果改成普通通过，验收仍保持合法豁免。
  passedLine = testLine.sub(/\| 豁免 \|/, "| 通过 |")
  # 写回临时副本，触发反向同步门禁。
  testLogPath.write(testLogPath.read.sub(testLine, passedLine))
end
