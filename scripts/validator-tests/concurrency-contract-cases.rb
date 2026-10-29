# 并发、框架契约与总览回归

# 覆盖活动轮次隔离、Agent 入口契约、文档结构和状态投影一致性。
# 本文件由统一测试入口在同一 Ruby 进程中加载，共享一次准备好的合法夹具。
# 案例只修改临时副本，不读取或改写真实业务轮次。

# 另一轮仍在 verify 时，新轮可以停在 specify，不应被唯一活动轮次规则阻断。
runSuccessCase(FRAMEWORK_ROOT, "multiple active documentation iterations") do |caseRoot|
  # 从合成活动轮次复制完整档案，保证必需文件都存在。
  systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 新目录使用独立的测试名称，不依赖真实业务序号。
  secondPath = systemPath.join("iterations", "998-2099-12-30-validator-specify")
  # 复制后只调整动态状态，其他文档在 specify 阶段允许继续完善。
  FileUtils.cp_r(iterationPath, secondPath)
  # 新轮从 specify 和 ready 开始。
  statusPath = secondPath.join("status.md")
  # phase 改成文档阶段，不进入产品资源冲突检查。
  statusPath.write(statusPath.read.sub(/^- phase: .+$/, "- phase: specify"))
  # specify 没有代码任务。
  statusPath.write(statusPath.read.sub(/^- current_task: .+$/, "- current_task: 无"))
  # 新轮尚未开始写规格。
  statusPath.write(statusPath.read.sub(/^- work_state: .+$/, "- work_state: ready"))
  # 断点只记录已经建立轮次目录。
  statusPath.write(statusPath.read.sub(/^- checkpoint: .+$/, "- checkpoint: 新轮次已经创建，规格尚未编写"))
  # 下一步明确进入规格阶段。
  statusPath.write(statusPath.read.sub(/^- next_action: .+$/, "- next_action: 编写本轮需求和验收标准"))
end
# 两个产品活动轮次完成检出路径和独占资源隔离后应允许并行。
runSuccessCase(FRAMEWORK_ROOT, "isolated active product iterations") do |caseRoot|
  # 复制当前 verify 轮次，形成第二个需要产品与环境的活动轮次。
  systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 独立测试目录避免依赖真实业务序号。
  secondPath = systemPath.join("iterations", "996-2099-12-28-validator-isolated")
  # 保留完整验收档案，只调整隔离身份。
  FileUtils.cp_r(iterationPath, secondPath)
  # 统一解析轮次文件，兼容未来给夹具加入 file-map 的情况。
  workspacePath = resolveFixtureFile(secondPath, "workspace.md")
  # 为每个产品仓库创建不同且存在的模拟 worktree。
  isolatedLines = workspacePath.readlines.map do |line|
    # 只匹配产品基线表，不修改运行资源表。
    rowMatch = line.match(/\A(\|\s*`([^`]+)`\s*\|\s*)`\/[^`]+`/)
    # 非产品行只修改资源标识后缀，确保独占资源也互相隔离。
    next line.gsub("`validator-runtime`", "`validator-runtime-isolated`") unless rowMatch
    # 每个仓库取得独立且真实存在的目录。
    isolatedPath = caseRoot.join("validator-isolated-worktrees", rowMatch[2])
    # 校验器只读检查存在性，不要求临时目录本身是 Git 仓库。
    FileUtils.mkdir_p(isolatedPath)
    # 替换产品检出路径，其余基线证据原样保留。
    line.sub(rowMatch[0], "#{rowMatch[1]}`#{isolatedPath}`")
  end
  # 写回临时副本，第一轮保持完全不变。
  workspacePath.write(isolatedLines.join)
end

# 两个接触产品的活动轮次不能复用同一检出目录。
runFailureCase(FRAMEWORK_ROOT, "shared checkout across active iterations", "活动轮次复用了产品检出路径") do |caseRoot|
  # 当前夹具已经处于 verify，复制后会形成第二个产品活动轮次。
  systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 保留相同 workspace，精确制造检出路径冲突。
  secondPath = systemPath.join("iterations", "998-2099-12-30-validator-checkout-conflict")
  # 完整复制可确保错误只来自跨轮隔离，而不是缺文件。
  FileUtils.cp_r(iterationPath, secondPath)
end

# implement / ready 尚未写代码，也必须先声明将占用的工作区。
runFailureCase(FRAMEWORK_ROOT, "ready implementation without reservation", "产品检出路径尚未登记") do |caseRoot|
  # 只在当前合成轮次上切换阶段，避免其他活动轮次引入额外冲突。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 第二条未完成任务是 implement 阶段的合法 current_task。
  tasksPath = iterationPath.join("tasks.md")
  # 保留已完成的 T-01，并追加有检查命令的 T-02。
  tasksPath.write("#{tasksPath.read}- [ ] T-02 检查预留。依赖：T-01。文件：`fixture.txt`。检查：`ruby -v`\n")
  # 阶段切换本身不应掩盖缺少工作区预留的问题。
  statusPath = iterationPath.join("status.md")
  # 三个状态字段同步变化，构成合法的待开始实现状态。
  statusPath.write(statusPath.read.sub("- phase: verify", "- phase: implement").sub("- current_task: 无", "- current_task: T-02").sub("- work_state: blocked", "- work_state: ready"))
  # 计划阶段留下的空模板应被 implement / ready 门禁拒绝。
  workspacePath = iterationPath.join("workspace.md")
  # 仅修改临时夹具，不触碰真实业务轮次的 workspace。
  workspacePath.write(caseRoot.join("templates", "workspace.md").read)
end

# 即使还没把 work_state 改为 in_progress，预留同一检出也必须被拒绝。
runFailureCase(FRAMEWORK_ROOT, "ready implementation checkout conflict", "活动轮次复用了产品检出路径") do |caseRoot|
  # 原有 verify 轮次继续占有检出，第二轮从其完整档案复制。
  systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 测试目录仅存在于临时副本，保持第一轮原样。
  secondPath = systemPath.join("iterations", "995-2099-12-27-validator-ready")
  # 完整复制使冲突只来自检出路径，而不是缺文件。
  FileUtils.cp_r(iterationPath, secondPath)
  # 增加合法的未完成任务，供第二轮 implement 绑定。
  tasksPath = secondPath.join("tasks.md")
  # T-01 已完成，T-02 可成为新的 current_task。
  tasksPath.write("#{tasksPath.read}- [ ] T-02 检查预留。依赖：T-01。文件：`fixture.txt`。检查：`ruby -v`\n")
  # 第二轮尚在 ready，也必须参加与 verify 的并发检查。
  statusPath = secondPath.join("status.md")
  # 工作区故意保持与第一轮相同，制造可复现冲突。
  statusPath.write(statusPath.read.sub("- phase: verify", "- phase: implement").sub("- current_task: 无", "- current_task: T-02").sub("- work_state: blocked", "- work_state: ready"))
end

# 产品检出目录隔离后，相同独占运行资源仍然必须阻止并发。
runFailureCase(FRAMEWORK_ROOT, "exclusive runtime across active iterations", "活动轮次争用独占运行资源") do |caseRoot|
  # 复制当前 verify 轮次，保留同名运行资源。
  systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 第二轮使用单独的测试目录名。
  secondPath = systemPath.join("iterations", "997-2099-12-29-validator-runtime-conflict")
  # 先复制完整轮次，再把每个产品检出路径改成真实存在的独立目录。
  FileUtils.cp_r(iterationPath, secondPath)
  # 统一解析轮次文件，避免测试与校验器使用不同路径。
  workspacePath = resolveFixtureFile(secondPath, "workspace.md")
  # 逐行替换产品基线表里的绝对检出路径。
  isolatedLines = workspacePath.readlines.map do |line|
    # 只匹配“仓库名 + 绝对路径”开头的数据行，不碰正文和资源表。
    rowMatch = line.match(/\A(\|\s*`([^`]+)`\s*\|\s*)`\/[^`]+`/)
    # 非产品记录原样保留。
    next line unless rowMatch
    # 每个仓库创建一个不同且存在的模拟 worktree 目录。
    isolatedPath = caseRoot.join("validator-worktrees", rowMatch[2])
    # 校验器要求活动产品轮次的检出路径真实存在。
    FileUtils.mkdir_p(isolatedPath)
    # 只替换第二列路径，其他基线证据保持不变。
    line.sub(rowMatch[0], "#{rowMatch[1]}`#{isolatedPath}`")
  end
  # 写回临时副本，运行资源仍与第一轮相同。
  workspacePath.write(isolatedLines.join)
end

# 每个系统入口都必须把下一步显式带到用户可见的过程更新里。
runFailureCase(FRAMEWORK_ROOT, "missing progress next step label", "缺少过程汇报标签：下一步：") do |caseRoot|
  # 动态定位首个已登记系统，不把业务系统名写进测试。
  systemPath, _iterationPath = locateActiveIteration(caseRoot)
  # 只破坏过程汇报章节里的标签，其他启动规则保持有效。
  agentPath = systemPath.join("AGENTS.md")
  # 使用精确替换，确保夹具确实覆盖到新契约。
  replaceOnce(agentPath, "下一步：", "后续：")
end

# 四个词不能散落在其他章节里，契约本身必须有稳定入口。
runFailureCase(FRAMEWORK_ROOT, "missing progress reporting section", "缺少过程汇报章节") do |caseRoot|
  # 使用框架根入口覆盖通用规则，不依赖任何业务系统名称。
  agentPath = caseRoot.join("AGENTS.md")
  # 只改章节名，四个标签仍保留，用来验证章节边界检查。
  replaceOnce(agentPath, "## 过程汇报", "## 进度说明")
end

# 根入口必须明确禁止人工创建，否则 Agent 仍能绕过系统级文件锁。
runFailureCase(FRAMEWORK_ROOT, "missing manual creation prohibition", "缺少强制创建规则：禁止人工创建") do |caseRoot|
  # 根入口对所有启动目录提供最终兜底规则。
  agentPath = caseRoot.join("AGENTS.md")
  # 只删除稳定标记，脚本名称和其他边界仍保持不变。
  replaceOnce(agentPath, "禁止人工创建", "不建议人工创建")
end

# 实际新建入口必须点名唯一创建脚本，不能只保留抽象说明。
runFailureCase(FRAMEWORK_ROOT, "missing creation script command", "缺少强制创建规则：create-iteration.rb") do |caseRoot|
  # prompt 是 Agent 收到新建请求后直接执行的入口。
  promptPath = caseRoot.join("prompts", "01-open-iteration.md")
  # 替换该入口中的全部脚本名，确保案例真正移除了稳定标记。
  promptPath.write(promptPath.read.gsub("create-iteration.rb", "manual-create.rb"))
end

# 验收入口必须点名清理脚本，避免 done 后遗留临时源码目录。
runFailureCase(FRAMEWORK_ROOT, "missing worktree cleanup command", "缺少 worktree 生命周期规则：cleanup-worktree.rb") do |caseRoot|
  # verify 是实际执行清理和完成态切换的直接入口。
  promptPath = caseRoot.join("prompts", "05-verify.md")
  # 移除全部稳定标记，确保契约检查真实触发。
  promptPath.write(promptPath.read.gsub("cleanup-worktree.rb", "manual-cleanup.rb"))
end

# 验收入口必须点名同步脚本，不能直接从已提交跳到删除临时副本。
runFailureCase(FRAMEWORK_ROOT, "missing worktree sync command", "缺少 worktree 生命周期规则：sync-worktree.rb") do |caseRoot|
  # verify 是真实仓库拉取和清理顺序的直接入口。
  promptPath = caseRoot.join("prompts", "05-verify.md")
  # 移除全部稳定标记，确保契约检查不是被其他段落偶然满足。
  promptPath.write(promptPath.read.gsub("sync-worktree.rb", "manual-sync.rb"))
end

# 活动阶段没有下一步时必须阻断恢复。
runFailureCase(FRAMEWORK_ROOT, "missing next action", "next_action 不能为无") do |caseRoot|
  # 动态定位当前 status。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 当前夹具处于活动阶段，替换现有下一步即可。
  statusPath = iterationPath.join("status.md")
  # 正则保留字段格式，只把值改成无。
  statusPath.write(statusPath.read.sub(/^- next_action: .+$/, "- next_action: 无"))
end

# 真实轮次的更新时间必须可解析且包含时区。
runFailureCase(FRAMEWORK_ROOT, "invalid updated at", "updated_at 不是带时区的 ISO 8601 时间") do |caseRoot|
  # 动态定位当前 status。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 用无时区日期替换完整时间，模拟手工简写。
  statusPath = iterationPath.join("status.md")
  # 精确替换当前字段，避免影响测试记录里的日期。
  statusPath.write(statusPath.read.sub(/^- updated_at: .+$/, "- updated_at: 2026-10-22"))
end

# file-map 不能通过上级目录读取轮次外文件。
runFailureCase(FRAMEWORK_ROOT, "file map escape", "file-map 目标必须是本轮直接子文件") do |caseRoot|
  # 当前合成轮次默认没有 file-map，单独加入非法映射验证路径限制。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 把 requirements 的目标写成上级路径，模拟误写或逃逸。
  mapPath = iterationPath.join("file-map.md")
  # 每个案例只改临时副本中的一份映射文件。
  mapPath.write("| 标准文件 | 实际文件 |\n|---|---|\n| `requirements.md` | `../requirements.md` |\n")
end

# 每个系统必须保留会话级轮次绑定说明。
runFailureCase(FRAMEWORK_ROOT, "missing binding instructions", "缺少 agent/README.md") do |caseRoot|
  # 动态定位首个登记系统，不依赖业务名称。
  systemPath, _iterationPath = locateActiveIteration(caseRoot)
  # 只删除临时副本里的绑定说明。
  FileUtils.rm(systemPath.join("agent", "README.md"))
end

# 登记模板也必须提供同一份会话级轮次绑定说明。
runFailureCase(FRAMEWORK_ROOT, "missing binding template", "缺少轮次绑定模板") do |caseRoot|
  # 只删除临时副本中的模板，不影响已经登记的系统。
  templatePath = caseRoot.join("system-template", "agent", "README.md")
  # 校验器应在下次登记前发现模板缺口。
  FileUtils.rm(templatePath)
end

# verify 不能带着未完成实现任务继续。
runFailureCase(FRAMEWORK_ROOT, "pending task in verify", "verify 仍有未完成任务") do |caseRoot|
  # 找到当前任务清单的真实文件名。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 统一解析任务文件，避免测试绕开兼容路径。
  tasksPath = resolveFixtureFile(iterationPath, "tasks.md")
  # 把第一条完成任务恢复为未完成。
  tasksPath.write(tasksPath.read.sub(/^- \[x\] (T-\d+)/, '- [ ] \\1'))
end

# verify 不能用空验收表绕过编号集合一致性检查。
runFailureCase(FRAMEWORK_ROOT, "empty acceptance in verify", "verify 没有验收标准") do |caseRoot|
  # 定位当前轮次映射后的验收文件。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 统一解析验收文件，避免测试绕开兼容路径。
  acceptancePath = resolveFixtureFile(iterationPath, "acceptance.md")
  # 只删除 AC 数据行，保留标题和表头结构。
  remainingLines = acceptancePath.readlines.reject { |line| line.match?(/^\|\s*AC-\d+/) }
  # 写回临时副本，真实框架不会受到影响。
  acceptancePath.write(remainingLines.join)
end

# 产品工作已经开始时不能保留未采集的仓库基线。
runFailureCase(FRAMEWORK_ROOT, "missing workspace baseline", "产品仓库基线尚未采集") do |caseRoot|
  # 当前轮已进入 verify，因此一定要求真实基线。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 将更新时间改回模板占位符即可触发门禁。
  workspacePath = iterationPath.join("workspace.md")
  # 其他证据保持不变，确保案例只验证基线占位符。
  workspacePath.write(workspacePath.read.sub(/^更新时间：.+$/, "更新时间：尚未采集"))
end

# 只写 dirty 数量不足以保护接管前的逐文件改动。
runFailureCase(FRAMEWORK_ROOT, "missing workspace dirty details", "产品仓库基线缺少 dirty 明细") do |caseRoot|
  # 当前轮已进入 verify，因此要求可追溯的逐文件基线。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 把标准标题改掉，模拟只有汇总表而没有文件清单。
  workspacePath = iterationPath.join("workspace.md")
  # 使用精确替换，让夹具格式变化时立即失败。
  replaceOnce(workspacePath, "## 接管前 dirty 明细", "## 接管前状态摘要")
end

# 同一轮重复声明运行资源会让占用方式产生歧义。
runFailureCase(FRAMEWORK_ROOT, "duplicate runtime resource", "运行资源重复") do |caseRoot|
  # 合成 verify 轮次已经有独占运行资源记录。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 统一解析资源文件，避免测试绕开兼容路径。
  workspacePath = resolveFixtureFile(iterationPath, "workspace.md")
  # 复制第一条资源数据行，其他工作区证据保持不变。
  resourceLine = workspacePath.readlines.find { |line| line.match?(/^\| `[^`]+` \| (?:独占|共享) \|/) }
  # 夹具格式漂移时立即失败，避免案例没有真正制造重复。
  raise "runtime resource fixture missing" unless resourceLine
  # 附加重复行，由校验器报告具体资源标识。
  workspacePath.write("#{workspacePath.read}#{resourceLine}")
end

# 任务检查命令为空时不能通过实现阶段门禁。
runFailureCase(FRAMEWORK_ROOT, "missing task check", "缺少可执行检查命令") do |caseRoot|
  # 找到当前任务清单。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 解析兼容映射后的实际路径。
  tasksPath = resolveFixtureFile(iterationPath, "tasks.md")
  # 清空第一条检查命令，保留字段本身。
  tasksPath.write(tasksPath.read.sub(/检查：`[^`]+`/, "检查："))
end

# 已归档轮次也必须保留完整的通过证据，不能只检查活动轮次。
runFailureCase(FRAMEWORK_ROOT, "archived done with untested acceptance", "done 验收未全部通过") do |caseRoot|
  # 从当前完整轮次复制一个归档夹具，保留原活动轮次不变。
  systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 归档目录名称不写死业务系统或真实轮次编号。
  archivedPath = systemPath.join("iterations", "999-2099-12-31-validator-archive")
  # 复制后的全部文档仍属于新归档轮次。
  FileUtils.cp_r(iterationPath, archivedPath)
  # 使用精确替换辅助函数，夹具漂移时立即失败。
  statusPath = archivedPath.join("status.md")
  # phase 进入 done。
  replaceOnce(statusPath, "- phase: verify", "- phase: done")
  # done 的工作状态必须同步完成，不依赖当前轮处于进行中还是阻塞。
  statusPath.write(statusPath.read.sub(/^- work_state: .+$/, "- work_state: done"))
  # done 不允许留下后续动作。
  statusPath.write(statusPath.read.sub(/^- next_action: .+$/, "- next_action: 无"))
  # 定位归档轮次自己的验收文件，不依赖中英文文件名。
  acceptancePath = resolveFixtureFile(archivedPath, "acceptance.md")
  # 取第一条验收数据行，把合法终态改成普通“收口”。
  acceptanceLine = acceptancePath.readlines.find { |line| line.match?(/^\|\s*AC-\d+/) }
  # 找不到验收行说明测试夹具已经漂移，不能产生假阳性。
  raise "archived acceptance fixture missing" unless acceptanceLine
  # “收口”不是受控豁免，必须被 done 门禁拒绝。
  closedLine = acceptanceLine.sub(/[^|]+(?=\|\s*$)/, " 收口 ")
  # 只修改复制出的归档轮次。
  acceptancePath.write(acceptancePath.read.sub(acceptanceLine, closedLine))
end

# 系统登记表不能复制当前轮次和阶段状态。
runFailureCase(FRAMEWORK_ROOT, "dynamic registry state", "复制了动态迭代状态") do |caseRoot|
  # 登记表属于 systems 根目录。
  registryPath = caseRoot.join("systems", "README.md")
  # 在说明末尾加入动态状态短语。
  registryPath.write("#{registryPath.read}\n当前一轮：待开发\n")
end

# 系统 overview 的管理块之外不能通过调整列位置另存动态状态。
runFailureCase(FRAMEWORK_ROOT, "overview status column", "复制了迭代状态列") do |caseRoot|
  # 找到登记系统的稳定说明文件。
  systemPath, _iterationPath = locateActiveIteration(caseRoot)
  # 附加一个状态列在第二列以外的表格，验证检查与列位置无关。
  overviewPath = systemPath.join("overview.md")
  # 临时表只用于触发门禁，不改变真实系统说明。
  overviewPath.write("#{overviewPath.read}\n| 轮次 | 摘要 | 状态 |\n|---|---|---|\n")
end

# 修改权威 status.md 后若未刷新，校验器必须阻止陈旧总览继续流通。
runFailureCase(FRAMEWORK_ROOT, "stale overview projection", "迭代状态视图已过期") do |caseRoot|
  # 定位合成轮次并只改变一个动态字段，不调用刷新脚本。
  _systemPath, iterationPath = locateActiveIteration(caseRoot)
  # 新时间合法但与 overview 现有投影不同，精确制造过期视图。
  statusPath = iterationPath.join("status.md")
  # 使用精确替换避免同时触发无关字段错误。
  replaceOnce(statusPath, "- updated_at: 2020-01-01T00:00:00+00:00", "- updated_at: 2020-01-02T00:00:00+00:00")
end

# 删除管理块标记后刷新器无法确定安全写入范围，校验器必须明确阻断。
runFailureCase(FRAMEWORK_ROOT, "missing overview projection", "缺少唯一自动生成的迭代状态视图") do |caseRoot|
  # 找到合成系统总览，只移除开始标记保留其他内容。
  systemPath, _iterationPath = locateActiveIteration(caseRoot)
  # 单边标记模拟人工误删，不能被当成合法静态说明。
  overviewPath = systemPath.join("overview.md")
  # 精确删除一次，确保案例只验证标记契约。
  replaceOnce(overviewPath, "<!-- iteration-status-view:start -->\n", "")
end
