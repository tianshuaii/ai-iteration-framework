#!/usr/bin/env ruby

# 本模块只解析 workspace 隔离信息并校验受控 worktree 生命周期。
# 主校验器负责发现系统和轮次，本模块只处理调用方传入的单轮或系统记录。
# 路径检查保持只读，不进入产品仓库执行 Git、构建或清理命令。
# v1 与 v2 生命周期兼容语义、错误文案和检查顺序保持原样。
# 并发检查只比较已解析的检出路径和运行资源，不重新读取轮次文件。
# 保持 Ruby 2.6 兼容，不引入依赖、缓存或新的每轮产物。
# 独立职责使 worktree 安全规则无需继续扩大主命令入口。

require "pathname"

# workspace 和并发隔离门禁集中在独立命名空间。
module WorkspaceValidation
  # 暴露三个只读入口，同时避免辅助方法污染全局对象。
  module_function

  # 工作区校验按“解析、单轮生命周期、跨轮冲突、物理反查”分层。
  # 解析结果在主入口复用，避免为每项门禁重复读取 workspace.md。
  # 产品仓库只比较路径与登记值，不进入仓库执行任何 Git 命令。
  # 物理反查只报告未知目录，绝不自动清理可能含有用户代码的副本。

  # 将 workspace 问题追加到主校验器的统一错误集合。
  def addError(errors, message)
    # 错误仍由主入口统一输出，模块不直接打印或退出。
    errors << message
  end

# 读取一轮记录的产品检出路径和运行资源，供并发冲突检查复用。
def readWorkspaceIsolation(errors, workspacePath, label, required, validatePathExistence: true)
  # 文件缺失已由标准产物检查报告，这里返回空集合避免重复异常。
  return { checkouts: [], resources: [] } unless workspacePath.file?

  # 工作区文件较小，一次读取可避免检出表和资源表各做一次磁盘访问。
  workspaceContent = workspacePath.read
  # 每条检出记录保存仓库名、绝对路径和隔离方式。
  checkouts = []
  # 产品基线只位于 dirty 明细之前，避免把生命周期九列表误读成产品行。
  baselineContent = workspaceContent.split(/^## 接管前 dirty 明细\s*$/, 2).first
  # 表格逐行解析，标题和分隔行不会符合绝对路径格式。
  baselineContent.each_line do |line|
    # Markdown 表格必须同时有首尾竖线。
    next unless line.strip.start_with?("|") && line.strip.end_with?("|")
    # 去掉首尾空单元格并清理空白。
    cells = line.strip.split("|", -1)[1...-1].map(&:strip)
    # 产品基线表至少有七列；其他表格不参与解析。
    next unless cells.length >= 7
    # 仓库名必须使用反引号，避免误把表头当成数据。
    repositoryMatch = cells[0].match(/\A`([^`]+)`\z/)
    # 产品检出路径必须是反引号包裹的绝对路径。
    checkoutMatch = cells[1].match(/\A`(\/[^`]+)`\z/)
    # 任一格式不符都表示该行不是已采集的检出记录。
    next unless repositoryMatch && checkoutMatch
    # 先展开相对片段，保证等价绝对路径使用同一表示。
    expandedCheckoutPath = Pathname.new(checkoutMatch[1]).expand_path
    # 路径存在时解析软链接，防止同一检出目录通过别名绕开冲突检查。
    # 本地校验解析真实路径防止软链接别名；可移植 CI 只比较档案中的规范绝对路径。
    checkoutPath = validatePathExistence && expandedCheckoutPath.exist? ? expandedCheckoutPath.realpath.to_s : expandedCheckoutPath.to_s
    # 隔离方式只允许两个人可读值，避免不同写法绕开审计。
    isolationMode = cells[2]
    # 非法模式无法判断本轮是不是独立工作区。
    unless ["独立 worktree", "共享检出"].include?(isolationMode)
      addError(errors, "#{label} 产品检出隔离方式非法：#{isolationMode}")
    end
    # 产品工作开始后，检出路径必须仍然存在。
    # 托管 CI 没有登记在个人机器上的产品仓库，因此只在本地完整模式检查实体。
    addError(errors, "#{label} 产品检出路径不存在：#{checkoutPath}") if validatePathExistence && required && !Pathname.new(checkoutPath).exist?
    # 保存结构化记录，系统级并发检查不再解析 Markdown。
    checkouts << { repository: repositoryMatch[1], path: checkoutPath, mode: isolationMode }
  end

  # 运行资源只解析自己的章节，避免正文示例被当成真实占用。
  resourceSection = workspaceContent.match(/^## 运行资源\s*$\n(.*?)(?=^## |\z)/m)
  # 缺少章节时使用空字符串，后续逻辑无需反复安全导航。
  resourceContent = resourceSection ? resourceSection[1] : ""
  # 每条资源保存稳定标识和共享方式。
  resources = []
  # 章节存在时逐行读取真实数据行。
  resourceContent.each_line do |line|
    # 只接受首列为反引号资源标识的三列表格行。
    next unless line.strip.start_with?("|") && line.strip.end_with?("|")
    # Markdown 单元格去除首尾空位后再判断列数。
    cells = line.strip.split("|", -1)[1...-1].map(&:strip)
    # 标准资源表固定三列。
    next unless cells.length == 3
    # 资源标识使用反引号，表头不会匹配。
    resourceMatch = cells[0].match(/\A`([^`]+)`\z/)
    # 空白占位行不会进入真实资源集合。
    next unless resourceMatch
    # 占用方式决定同名资源能否跨轮并发。
    usageMode = cells[1]
    # 未知方式必须显式修正，不能默认当作共享。
    addError(errors, "#{label} 运行资源占用方式非法：#{usageMode}") unless %w[独占 共享].include?(usageMode)
    # 保存结构化记录，后续按资源标识分组。
    resources << { id: resourceMatch[1], mode: usageMode }
  end

  # 同一轮重复资源标识会让共享方式和用途产生歧义。
  duplicateResourceIds = resources.group_by { |resource| resource[:id] }.select { |_resourceId, rows| rows.length > 1 }.keys
  # 每个重复标识单独报告，方便直接删除或合并对应行。
  duplicateResourceIds.each { |resourceId| addError(errors, "#{label} 运行资源重复：#{resourceId}") }
  # 产品工作已经开始时至少要有一个真实检出路径。
  addError(errors, "#{label} 产品检出路径尚未登记") if required && checkouts.empty?
  # 无运行资源必须使用单独一行明确声明，不能靠模板说明推断。
  noRuntimeResources = resourceContent.each_line.any? { |line| %w[无 -无].include?(line.strip.delete(" ")) }
  # 缺少章节或既无记录也无明确声明时，无法排除环境争用。
  addError(errors, "#{label} 运行资源尚未声明") if required && resources.empty? && !noRuntimeResources
  # 返回两类隔离信息供系统级检查。
  { checkouts: checkouts, resources: resources }
end

# 读取并校验新版 workspace.md 中的临时 worktree 生命周期表。
def validateManagedWorktrees(errors, workspacePath, iterationPath, label, frameworkRoot, statusFields, checkouts, policyMarkers, validatePathExistence: true)
  # 文件缺失已由档案完整性检查报告，这里避免重复异常。
  return [] unless workspacePath.file?

  # 历史轮次没有版本标记时保持只读兼容，不倒推当年的临时目录状态。
  workspaceContent = workspacePath.read
  # v2 优先于 v1，避免手工残留两个标记时绕过新增同步门禁。
  policyVersion = if workspaceContent.include?(policyMarkers.fetch(:v2))
                    # 当前能力版本必须执行目标分支同步检查。
                    :v2
                  elsif workspaceContent.include?(policyMarkers.fetch(:v1))
                    # 历史能力版本继续执行原有目录生命周期检查。
                    :v1
                  end
  # 只有被受控脚本接管的文档才启用严格门禁。
  return [] unless policyVersion

  # 新版文档必须保留固定生命周期章节，不能只留版本标记。
  lifecycleSection = workspaceContent.match(/^## 临时 worktree 生命周期\s*$\n(.*?)(?=^## |\z)/m)
  # 缺少章节会让清理状态失去唯一记录位置。
  unless lifecycleSection
    addError(errors, "#{label} 缺少临时 worktree 生命周期章节")
    return []
  end

  # 每条记录保存原仓库、临时路径、分支、两个 HEAD、时间和状态。
  records = []
  # 只在生命周期章节内解析九列表格，避免误读产品基线。
  lifecycleSection[1].each_line do |line|
    # 标准 Markdown 表格必须同时有首尾竖线。
    next unless line.strip.start_with?("|") && line.strip.end_with?("|")
    # 保留空单元格后再去除排版空白。
    cells = line.strip.split("|", -1)[1...-1].map(&:strip)
    # 九列是生命周期记录与其他表格的稳定区分条件。
    next unless cells.length == 9
    # 数据行仓库名必须使用反引号，表头和分隔行不会匹配。
    repositoryMatch = cells[0].match(/\A`([^`]+)`\z/)
    # 两个路径都必须是反引号包裹的绝对路径。
    sourceMatch = cells[1].match(/\A`(\/[^`]+)`\z/)
    # 临时路径单独解析，后续要核对受控根目录。
    targetMatch = cells[2].match(/\A`(\/[^`]+)`\z/)
    # 非数据行直接跳过，不把表头报告为格式错误。
    next unless repositoryMatch || sourceMatch || targetMatch
    # 部分匹配说明行格式损坏，不能作为清理证据。
    unless repositoryMatch && sourceMatch && targetMatch
      addError(errors, "#{label} worktree 生命周期记录格式非法")
      next
    end
    # 去掉可选反引号，分支与 HEAD 保持人可读值。
    unwrap = ->(value) { value.match?(/\A`[^`]*`\z/) ? value[1...-1] : value }
    # 保存结构化数据供重复、路径和终态检查复用。
    records << {
      repository: repositoryMatch[1],
      sourcePath: Pathname.new(sourceMatch[1]).expand_path,
      targetPath: Pathname.new(targetMatch[1]).expand_path,
      branchName: unwrap.call(cells[3]),
      createdHead: unwrap.call(cells[4]),
      finalHead: unwrap.call(cells[5]),
      createdAt: unwrap.call(cells[6]),
      state: unwrap.call(cells[7]),
      cleanedAt: unwrap.call(cells[8])
    }
  end

  # v2 把真实仓库同步证据保存在独立表格，避免与目录删除状态混淆。
  syncRecords = []
  # v1 历史文档没有同步章节，只继续执行原生命周期检查。
  if policyVersion == :v2
    # 新模板必须带固定同步章节，删除前的目标分支证据只从这里读取。
    syncSection = workspaceContent.match(/^## worktree 成果同步\s*$\n(.*?)(?=^## |\z)/m)
    unless syncSection
      # 缺少章节时所有 v2 删除记录都不具备可审计同步来源。
      addError(errors, "#{label} 缺少 worktree 成果同步章节")
    else
      # 六列表格记录目标分支、两端 HEAD、时间和固定验证状态。
      syncSection[1].each_line do |line|
        # 非 Markdown 表格行直接跳过。
        next unless line.strip.start_with?("|") && line.strip.end_with?("|")
        # 保留空单元格，格式损坏时可以稳定报告。
        cells = line.strip.split("|", -1)[1...-1].map(&:strip)
        # 六列是同步表和其他工作区表格的区分条件。
        next unless cells.length == 6
        # 仓库名必须使用反引号，表头和分隔行不会匹配。
        repositoryMatch = cells[0].match(/\A`([^`]+)`\z/)
        # 不属于数据行时继续扫描。
        next unless repositoryMatch
        # 去壳后保存结构化字段，供删除终态门禁复用。
        unwrap = ->(value) { value.match?(/\A`[^`]*`\z/) ? value[1...-1] : value }
        # 目标分支和两个 HEAD 均由同步脚本写入反引号单元格。
        syncRecords << {
          repository: repositoryMatch[1],
          targetBranch: unwrap.call(cells[1]),
          finalHead: unwrap.call(cells[2]),
          sourceHead: unwrap.call(cells[3]),
          syncedAt: unwrap.call(cells[4]),
          state: unwrap.call(cells[5])
        }
      end
      # 同一仓库出现多条同步记录时无法判断清理应相信哪一条。
      duplicateSyncRepositories = syncRecords.group_by { |record| record[:repository] }.select { |_repository, rows| rows.length > 1 }.keys
      # 每个重复仓库单独报告，方便修正文档。
      duplicateSyncRepositories.each { |repository| addError(errors, "#{label} worktree 成果同步记录重复：#{repository}") }
    end
  end

  # 一个仓库只能有一条当前生命周期记录，重复时清理目标不唯一。
  duplicateRepositories = records.group_by { |record| record[:repository] }.select { |_repository, rows| rows.length > 1 }.keys
  # 每个重复仓库单独报告。
  duplicateRepositories.each { |repository| addError(errors, "#{label} worktree 生命周期记录重复：#{repository}") }
  # 受控路径固定为 .worktrees/<system>/<iteration>/<repo>。
  worktreesRoot = frameworkRoot.join(".worktrees").expand_path
  # 逐条检查路径、状态和文件系统事实是否一致。
  records.each do |record|
    # 系统名由轮次上两级目录取得，不从表格内容猜测。
    expectedTarget = worktreesRoot.join(iterationPath.parent.parent.basename, iterationPath.basename, record[:repository]).expand_path
    # 可移植 CI 的检出根与历史记录不同，但末尾层级仍必须精确匹配受控结构。
    portableTargetSuffix = Pathname.new(".worktrees").join(iterationPath.parent.parent.basename, iterationPath.basename, record[:repository]).each_filename.to_a
    # 本地要求完整路径相同；CI 只允许根目录变化，不能放宽系统、轮次或仓库名。
    validTarget = validatePathExistence ? record[:targetPath] == expectedTarget : record[:targetPath].each_filename.to_a.last(portableTargetSuffix.length) == portableTargetSuffix
    # 相似前缀、错误层级或路径逃逸都不能成为受控删除目标。
    addError(errors, "#{label} worktree 临时路径不符合受控目录：#{record[:targetPath]}") unless validTarget
    # 临时目标本身不能是软链接，否则删除边界会指向框架外实体。
    addError(errors, "#{label} worktree 临时路径不能是软链接：#{record[:targetPath]}") if record[:targetPath].symlink?
    # 原仓库应该长期存在；失效路径无法恢复产品指向。
    # 原仓库实体属于本机运行环境；CI 仍校验绝对路径格式和记录关系。
    addError(errors, "#{label} worktree 原仓库路径不存在：#{record[:sourcePath]}") if validatePathExistence && !record[:sourcePath].directory?
    # 状态集合保持小而明确；保留例外使用带证据前缀。
    validState = %w[使用中 待清理 已删除].include?(record[:state]) || record[:state].start_with?("用户确认保留：")
    # 未知状态不能被默认为安全终态。
    addError(errors, "#{label} worktree 生命周期状态非法：#{record[:state]}") unless validState
    # 已删除必须与文件系统一致，并保留最终版本和清理时间。
    if record[:state] == "已删除"
      # 目录仍存在说明清理没有真正完成。
      # 目录是否真实删除只能由保存这些临时副本的本机确认。
      addError(errors, "#{label} worktree 标记已删除但目录仍存在：#{record[:targetPath]}") if validatePathExistence && record[:targetPath].exist?
      # 最终 HEAD 和清理时间是删除后的最低追踪证据。
      addError(errors, "#{label} 已删除 worktree 缺少最终 HEAD：#{record[:repository]}") if record[:finalHead] == "无" || record[:finalHead].empty?
      # 空清理时间无法判断目录何时收口。
      addError(errors, "#{label} 已删除 worktree 缺少清理时间：#{record[:repository]}") if record[:cleanedAt] == "无" || record[:cleanedAt].empty?
      # v2 只有在真实仓库同步证据完整时才允许删除终态。
      if policyVersion == :v2
        # 仓库名是生命周期表与同步表之间的稳定关联键。
        syncRecord = syncRecords.find { |candidate| candidate[:repository] == record[:repository] }
        if syncRecord
          # 固定状态证明记录由同步流程完成，而不是任意描述。
          addError(errors, "#{label} 已删除 worktree 同步状态未验证：#{record[:repository]}") unless syncRecord[:state] == "已同步验证"
          # 两张表的最终 HEAD 必须一致，否则无法证明被拉取的是被删除成果。
          addError(errors, "#{label} 已删除 worktree 最终 HEAD 与同步记录不一致：#{record[:repository]}") unless syncRecord[:finalHead] == record[:finalHead]
          # 目标分支、真实仓库 HEAD 和同步时间都不能留空或使用“无”。
          missingSyncEvidence = [syncRecord[:targetBranch], syncRecord[:sourceHead], syncRecord[:syncedAt]].any? { |value| value.empty? || value == "无" }
          # 缺少任一字段都不能作为清理完成证据。
          addError(errors, "#{label} 已删除 worktree 缺少目标分支同步证据：#{record[:repository]}") if missingSyncEvidence
        else
          # 缺少记录说明目录清理绕过了同步门禁。
          addError(errors, "#{label} 已删除 worktree 缺少成果同步记录：#{record[:repository]}")
        end
      end
    elsif record[:state].start_with?("用户确认保留：")
      # 保留是终态例外，必须明确写出用户确认和保留原因。
      unless record[:state].include?("用户确认") && record[:state].include?("保留原因")
        # 缺少任一证据都不能绕过 done 清理门禁。
        addError(errors, "#{label} worktree 保留缺少用户确认或保留原因：#{record[:repository]}")
      end
      # 被保留的目录必须真实存在，否则状态应改为已删除。
      # 托管 CI 不持有被用户确认保留的本机目录，只检查其耐久证据。
      addError(errors, "#{label} 用户确认保留的 worktree 不存在：#{record[:targetPath]}") if validatePathExistence && !record[:targetPath].directory?
    elsif record[:state] == "使用中"
      # 使用中的 worktree 必须仍然存在。
      # 活动目录实体仍由本机完整校验负责，CI 不伪造临时产品检出。
      addError(errors, "#{label} 使用中的 worktree 不存在：#{record[:targetPath]}") if validatePathExistence && !record[:targetPath].directory?
    end
    # 当前产品基线必须与生命周期状态指向同一份检出。
    checkoutRecord = checkouts.find { |checkout| checkout[:repository] == record[:repository] }
    # 生命周期记录没有对应产品行时，Agent 无法知道实际操作目录。
    unless checkoutRecord
      addError(errors, "#{label} worktree 生命周期缺少产品基线：#{record[:repository]}")
      next
    end
    if record[:state] == "已删除"
      # 清理后产品行必须恢复 overview 原仓库语义，不能继续指向已删目录。
      # 本地解析软链接，CI 则保留档案路径以验证两张表自身的一致性。
      resolvedSourcePath = validatePathExistence && record[:sourcePath].directory? ? record[:sourcePath].realpath.to_s : record[:sourcePath].to_s
      # 路径不存在的错误已经在上面记录，这里继续使用展开值完成一致性检查。
      unless checkoutRecord[:path] == resolvedSourcePath && checkoutRecord[:mode] == "共享检出"
        # 同时检查路径与模式，避免只改其中一列形成矛盾。
        addError(errors, "#{label} 已删除 worktree 未恢复原仓库产品路径：#{record[:repository]}")
      end
    else
      # 使用中、待清理和用户确认保留都仍应指向临时独立检出。
      unless checkoutRecord[:path] == record[:targetPath].to_s && checkoutRecord[:mode] == "独立 worktree"
        # 记录不一致时不允许靠生命周期状态推断实际目录。
        addError(errors, "#{label} 活动 worktree 与产品检出路径不一致：#{record[:repository]}")
      end
    end
  end

  # 同步表不能留下没有生命周期主体的游离仓库记录。
  syncRecords.each do |syncRecord|
    # 生命周期记录不存在时目标路径、创建 HEAD 和清理状态都无法追踪。
    unless records.any? { |record| record[:repository] == syncRecord[:repository] }
      # 单独报告仓库名，便于删除或补齐错误记录。
      addError(errors, "#{label} worktree 成果同步记录缺少生命周期：#{syncRecord[:repository]}")
    end
  end

  # 新版文档中每条独立 worktree 产品行都必须有生命周期记录。
  checkouts.select { |checkout| checkout[:mode] == "独立 worktree" }.each do |checkout|
    # 路径和仓库必须同时匹配，避免用另一条记录冒充。
    matchingRecord = records.find { |record| record[:repository] == checkout[:repository] && record[:targetPath].to_s == checkout[:path] }
    # 缺少记录意味着目录将无法在收口时安全清理。
    addError(errors, "#{label} 独立 worktree 缺少生命周期记录：#{checkout[:repository]}") unless matchingRecord
  end

  # 完成态不允许保留使用中或待清理的临时副本。
  if statusFields["phase"] == "done"
    # 收集所有尚未达到允许终态的仓库。
    unfinishedRepositories = records.reject do |record|
      # 正常终态是已删除；保留必须已经通过上面的证据检查。
      record[:state] == "已删除" || (record[:state].start_with?("用户确认保留：") && record[:state].include?("用户确认") && record[:state].include?("保留原因"))
    end.map { |record| record[:repository] }
    # 任一使用中或待清理记录都阻止 done。
    addError(errors, "#{label} done 前仍有未清理 worktree：#{unfinishedRepositories.join(', ')}") unless unfinishedRepositories.empty?
  end
  # 返回记录供未来扩展复用，当前调用方只依赖错误集合。
  records
end

# 检查同一系统中会接触产品或运行环境的活动轮次是否互相隔离。
def validateConcurrentIsolation(errors, systemName, iterationRecords)
  # implement 和 verify 都可能受共享工作区或环境变化影响。
  concurrentRecords = iterationRecords.select do |_iterationPath, record|
    # 其他阶段只写框架文档，不参与产品资源冲突。
    %w[implement verify].include?(record[:fields]["phase"])
  end

  # 按产品检出路径收集轮次归属。
  checkoutOwners = Hash.new { |hash, key| hash[key] = [] }
  # 每轮同一路径只登记一次，避免单轮重复行制造伪冲突。
  concurrentRecords.each do |iterationPath, record|
    # 取出该轮所有不同检出路径。
    record[:isolation][:checkouts].map { |checkout| checkout[:path] }.uniq.each do |checkoutPath|
      # 只保存轮次目录名，错误信息保持简洁。
      checkoutOwners[checkoutPath] << Pathname.new(iterationPath).basename.to_s
    end
  end
  # 同一路径被两轮使用时，任一轮的改动都会污染另一轮验证结果。
  checkoutOwners.each do |checkoutPath, iterationNames|
    # 单一归属不构成并发冲突。
    next unless iterationNames.uniq.length > 1
    # 报告路径和全部轮次，方便选择要迁移到 worktree 的一轮。
    addError(errors, "#{systemName} 活动轮次复用了产品检出路径：#{checkoutPath}（#{iterationNames.uniq.join(', ')}）")
  end

  # 按稳定资源标识收集轮次和占用方式。
  resourceOwners = Hash.new { |hash, key| hash[key] = [] }
  # 逐轮登记资源；同一轮重复行先去重。
  concurrentRecords.each do |iterationPath, record|
    # 资源标识和模式共同去重，保留独占与共享差异。
    record[:isolation][:resources].uniq { |resource| [resource[:id], resource[:mode]] }.each do |resource|
      # 记录轮次名称和占用方式供冲突判定。
      resourceOwners[resource[:id]] << { iteration: Pathname.new(iterationPath).basename.to_s, mode: resource[:mode] }
    end
  end
  # 同名资源只要有一方声明独占，就不能被另一轮同时使用。
  resourceOwners.each do |resourceId, owners|
    # 先取得不同轮次，单轮内部重复声明不算并发。
    iterationNames = owners.map { |owner| owner[:iteration] }.uniq
    # 至少两轮且存在独占声明才构成冲突。
    next unless iterationNames.length > 1 && owners.any? { |owner| owner[:mode] == "独占" }
    # 报告稳定资源标识，不输出真实地址或环境秘密。
    addError(errors, "#{systemName} 活动轮次争用独占运行资源：#{resourceId}（#{iterationNames.join(', ')}）")
  end
end

  # 反向扫描受控目录，发现没有 workspace 生命周期记录的物理副本。
  def validatePhysicalTargets(errors, frameworkRoot, scopedIterationPath, managedWorktreeTargets)
    # 固定根目录由框架路径推导，不接受轮次文档提供任意扫描位置。
    worktreesRoot = frameworkRoot.join(".worktrees")
    # 根目录不存在表示当前没有临时副本，不建立空目录也不报告错误。
    return unless worktreesRoot.exist?

    # 软链接可能把只读扫描引向框架外产品树，因此直接拒绝。
    if worktreesRoot.symlink?
      addError(errors, ".worktrees 不能是软链接")
      return
    end
    # 同名普通文件会阻止生命周期脚本创建目录，需作为结构错误报告。
    unless worktreesRoot.directory?
      addError(errors, ".worktrees 必须是目录")
      return
    end

    # 固定结构恰好是 system/iteration/repository 三层，不递归产品仓库内部。
    physicalTargets = worktreesRoot.glob("*/*/*").select(&:directory?)
    # 局部模式只反查目标轮次，避免日常校验被其他轮次的临时状态阻断。
    if scopedIterationPath
      # 目录层级固定，可以直接按系统名和轮次名筛选。
      physicalTargets.select! do |path|
        # 两级父目录分别对应轮次和系统。
        path.parent.basename.to_s == scopedIterationPath.basename.to_s &&
          path.parent.parent.basename.to_s == scopedIterationPath.parent.parent.basename.to_s
      end
    end
    # 路径展开后与 workspace 中已登记的活动生命周期记录比较。
    physicalTargets = physicalTargets.map { |path| path.expand_path.to_s }
    # 差集只包含中断遗留或绕过受控脚本创建的未知目录。
    orphanTargets = physicalTargets - managedWorktreeTargets.uniq
    # 校验器只报告，不自动删除任何可能包含用户代码的目录。
    orphanTargets.each { |targetPath| addError(errors, "未登记的 .worktrees 临时目录：#{targetPath}") }
  end

end
