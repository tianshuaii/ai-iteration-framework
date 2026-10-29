#!/usr/bin/env ruby

# 本文件集中保存受控 worktree 的路径解析和 workspace.md 更新逻辑。
# 创建与清理入口共用这里的校验，避免两个脚本逐渐形成不同边界。
# 所有目标都从框架根目录、系统目录和 overview.md 动态推导。
# 产品仓库名称、轮次名称和用户目录不会写死在脚本中。
# 外部命令始终使用参数数组调用，不经过 shell 字符串插值。
# workspace.md 使用同目录临时文件原子替换，避免留下半行状态。
# 调用方只负责 Git 动作，本模块负责可审计的生命周期记录。

require "fileutils"
require "open3"
require "pathname"
require "tempfile"
require "time"

# 受控 worktree 的公共实现只暴露模块函数，不保存跨调用全局状态。
module WorktreeSupport
  # 明确的异常类型让命令入口只输出人可读错误，不泄露 Ruby 堆栈。
  class LifecycleError < StandardError; end

  # v1 只管理创建和删除；保留常量是为了把已有文档原位升级。
  LEGACY_POLICY_MARKER = "<!-- workspace-policy: managed-worktree-v1 -->"
  # v2 增加“真实仓库已同步并包含成果提交”的强制清理门禁。
  POLICY_MARKER = "<!-- workspace-policy: managed-worktree-v2 -->"
  # 生命周期表标题固定，校验器和两个写入脚本共享同一结构契约。
  LIFECYCLE_HEADING = "## 临时 worktree 生命周期"
  # 生命周期表列名集中定义，避免创建与清理脚本各写一份表头。
  LIFECYCLE_HEADER = "| 仓库 | 原仓库路径 | 临时 worktree 路径 | 分支 | 创建 HEAD | 最终 HEAD | 创建时间 | 状态 | 清理时间 |"
  # 分隔行列数与表头保持一致，便于 Markdown 阅读和稳定解析。
  LIFECYCLE_DIVIDER = "|---|---|---|---|---|---|---|---|---|"
  # 同步记录与目录生命周期分表保存，避免把删除状态和 Git 集成状态混为一谈。
  SYNC_HEADING = "## worktree 成果同步"
  # 目标分支必须显式记录，不能从 main、master 或当前目录状态猜测。
  SYNC_HEADER = "| 仓库 | 目标分支 | worktree 最终 HEAD | 原仓库同步 HEAD | 同步时间 | 状态 |"
  # 六列结构足以证明目标分支、两个提交和验证结果。
  SYNC_DIVIDER = "|---|---|---|---|---|---|"
  # 只有会接触产品检出的两个阶段可以构成 worktree 并行依据。
  PRODUCT_PHASES = %w[implement verify].freeze

  module_function

  # 从脚本目录反推框架根目录，框架移动后仍可正常使用。
  def frameworkRoot(scriptDirectory)
    # realpath 同时消除脚本目录上的软链接，形成唯一的路径边界。
    Pathname.new(scriptDirectory).join("..").realpath
  end

  # 校验并解析一个真实轮次目录，拒绝框架外路径和嵌套子目录。
  def resolveIteration(frameworkRoot, requestedPath)
    # 先展开用户输入，错误信息保留用户实际传入的目标。
    expandedPath = Pathname.new(requestedPath).expand_path
    # 生命周期脚本只处理已经创建且包含 workspace.md 的轮次。
    raise LifecycleError, "轮次目录不存在：#{expandedPath}" unless expandedPath.directory?
    # realpath 防止通过软链接把目标伪装成框架内轮次。
    iterationPath = expandedPath.realpath
    # 轮次必须是某个系统 iterations/ 的直接子目录。
    iterationsPath = iterationPath.parent
    # 目录层级错误时不继续推导系统名或产品路径。
    raise LifecycleError, "目标必须是 systems/<system>/iterations/<iteration>" unless iterationsPath.basename.to_s == "iterations"
    # 系统目录就是 iterations/ 的父目录。
    systemPath = iterationsPath.parent
    # 所有登记系统都必须直接位于框架 systems/ 下。
    systemsRoot = frameworkRoot.join("systems").realpath
    # 精确父级比较可以阻止相似前缀路径绕过边界。
    raise LifecycleError, "目标必须属于当前框架的已登记系统" unless systemPath.parent.realpath == systemsRoot
    # 系统入口和 overview 是解析仓库身份所必需的稳定文件。
    raise LifecycleError, "系统登记不完整：缺少 AGENTS.md 或 overview.md" unless systemPath.join("AGENTS.md").file? && systemPath.join("overview.md").file?
    # workspace.md 是创建、使用和清理状态的唯一记录位置。
    raise LifecycleError, "轮次缺少 workspace.md" unless iterationPath.join("workspace.md").file?
    # 返回后续命令需要的三个确定路径。
    [systemPath, iterationPath, iterationPath.join("workspace.md")]
  end

  # 去掉 Markdown 单元格外层反引号，同时保留普通中文说明。
  def unwrapCell(cell)
    # trim 先消除表格为了对齐加入的空格。
    value = cell.to_s.strip
    # 仅在首尾都为反引号时去壳，避免破坏正文中的单个符号。
    value.match?(/\A`[^`]*`\z/) ? value[1...-1] : value
  end

  # 把 Markdown 表格行拆成纯文本单元格；非表格行返回 nil。
  def tableCells(line)
    # 标准表格行必须同时包含首尾竖线。
    return nil unless line.strip.start_with?("|") && line.strip.end_with?("|")
    # split 保留中间空单元格，再统一去除首尾空白。
    line.strip.split("|", -1)[1...-1].map(&:strip)
  end

  # 根据 overview.md 的仓库名解析唯一原仓库绝对路径。
  def resolveRepository(systemPath, repositoryName)
    # 仓库名还会成为 .worktrees 下的一层目录，必须是安全单段名称。
    unless repositoryName.match?(/\A[A-Za-z0-9][A-Za-z0-9._-]*\z/)
      # 禁止斜杠、上级目录和控制字符进入目标路径。
      raise LifecycleError, "仓库名必须是安全的单段名称"
    end
    # overview.md 是系统仓库地址的唯一事实源。
    overviewPath = systemPath.join("overview.md")
    # 收集同名记录，重复登记不能靠取第一条静默解决。
    matchingPaths = overviewPath.readlines.each_with_object([]) do |line, paths|
      # 只有至少四列的仓库表数据行才可能匹配。
      cells = tableCells(line)
      # 表头、分隔行和其他表格直接跳过。
      next unless cells && cells.length >= 4
      # 第一列是登记仓库名，兼容有无反引号的历史写法。
      next unless unwrapCell(cells[0]) == repositoryName
      # 第二列必须是反引号包裹的绝对路径，避免误读普通说明。
      pathMatch = cells[1].match(/\A`(\/[^`]+)`\z/)
      # 不完整登记由“未找到有效记录”统一报告。
      next unless pathMatch
      # 展开路径但不在这里读取仓库内容。
      paths << Pathname.new(pathMatch[1]).expand_path
    end
    # 同名多行会让清理时无法证明原仓库身份。
    raise LifecycleError, "overview.md 中仓库登记不唯一：#{repositoryName}" unless matchingPaths.length == 1
    # 产品仓库必须仍然存在，不能从失效记录创建工作区。
    sourcePath = matchingPaths.first
    # realpath 在存在性确认后再调用，避免抛出底层系统异常。
    raise LifecycleError, "产品仓库路径不存在：#{sourcePath}" unless sourcePath.directory?
    # 返回消除软链接后的唯一源仓库路径。
    sourcePath.realpath
  end

  # 找出同一系统内正在实现或验收、且登记了同一仓库的其他轮次。
  def parallelProductIterations(systemPath, currentIterationPath, repositoryName)
    # 并行资格只从本系统自己的 iterations 目录读取，不跨系统猜测。
    iterationsPath = systemPath.join("iterations")
    # 已登记系统应始终有该目录；缺失时按没有并行轮次处理。
    return [] unless iterationsPath.directory?

    # 使用真实路径排除当前轮次，避免路径别名把自己误判为并行者。
    currentRealPath = currentIterationPath.realpath
    # 稳定排序让错误诊断和回归结果不受文件系统遍历顺序影响。
    # 软链接轮次可能指向系统外，不能成为创建临时源码的授权证据。
    iterationsPath.children.select { |path| path.directory? && !path.symlink? }.sort.each_with_object([]) do |candidatePath, matches|
      # 当前轮自身不能为自己提供创建 worktree 的理由。
      next if candidatePath.realpath == currentRealPath
      # 状态和工作区缺任一项都不能证明它正在使用产品仓库。
      statusPath = candidatePath.join("status.md")
      workspacePath = candidatePath.join("workspace.md")
      next unless statusPath.file? && workspacePath.file?
      # 只读取唯一动态状态源中的 phase，不从目录名或任务正文推断。
      phaseMatch = statusPath.read.match(/^- phase:\s*(implement|verify)\s*$/)
      # specify、plan、done 都不构成产品检出的并行占用。
      next unless phaseMatch && PRODUCT_PHASES.include?(phaseMatch[1])
      # 产品基线表固定为七列；其他计划表和生命周期表不会被误读。
      usesRepository = workspacePath.readlines.any? do |line|
        cells = tableCells(line)
        # 仓库名和非空绝对检出路径共同证明该轮已经登记使用该仓库。
        cells && cells.length == 7 && unwrapCell(cells[0]) == repositoryName && unwrapCell(cells[1]).start_with?("/")
      end
      # 只保存轮次名，避免把绝对路径写进面向用户的判断结果。
      matches << candidatePath.basename.to_s if usesRepository
    end
  end

  # 执行一条 Git 命令并返回输出；非预期退出码转换为稳定错误。
  def runGit(repositoryPath, *arguments, allowedStatuses: [0])
    # 参数数组阻止分支名、路径或 ref 被 shell 解释。
    stdout, stderr, processStatus = Open3.capture3("git", "-C", repositoryPath.to_s, *arguments)
    # 某些查询允许状态 1 表示“未找到”，由调用方继续判断。
    return [stdout, stderr, processStatus.exitstatus] if allowedStatuses.include?(processStatus.exitstatus)
    # 错误只保留 Git 的人可读说明，并去掉多余换行。
    details = stderr.strip.empty? ? stdout.strip : stderr.strip
    # 所有失败都带原子命令名称，便于用户定位到哪个阶段。
    raise LifecycleError, "Git #{arguments.first} 失败：#{details}"
  end

  # 确认 overview 指向仓库根目录，而不是仓库内部子目录。
  def validateRepositoryRoot(sourcePath)
    # rev-parse 只读取 Git 元数据，不修改源仓库。
    stdout, = runGit(sourcePath, "rev-parse", "--show-toplevel")
    # Git 输出的根目录同样解析 realpath，消除路径别名。
    gitRoot = Pathname.new(stdout.strip).realpath
    # 子目录登记会导致 worktree 管理落到意外仓库，必须阻断。
    raise LifecycleError, "overview.md 登记的路径不是 Git 仓库根目录：#{sourcePath}" unless gitRoot == sourcePath
  end

  # 计算唯一受控目标，不接受调用方自定义临时目录。
  def worktreePaths(frameworkRoot, systemPath, iterationPath, repositoryName)
    # 所有临时产品代码都集中在框架根目录的隐藏目录中。
    worktreesRoot = frameworkRoot.join(".worktrees")
    # 系统名和轮次名来自已经通过层级校验的真实目录。
    targetPath = worktreesRoot.join(systemPath.basename, iterationPath.basename, repositoryName)
    # 返回根目录和精确目标，锁文件由命令入口放在根目录。
    [worktreesRoot, targetPath]
  end

  # 创建受控目录前拒绝已有软链接，避免写入框架外位置。
  def prepareWorktreesRoot(worktreesRoot, targetPath)
    # 根目录若已是软链接，realpath 边界就不再等于用户看到的位置。
    raise LifecycleError, ".worktrees 不能是软链接" if worktreesRoot.symlink?
    # 同名普通文件会让 mkdir_p 抛出底层异常，先转换成稳定阻断信息。
    if worktreesRoot.exist? && !worktreesRoot.directory?
      # 脚本不覆盖或删除这个未知文件。
      raise LifecycleError, ".worktrees 必须是目录"
    end
    # 0700 避免同机其他用户读取临时产品代码。
    FileUtils.mkdir_p(worktreesRoot, mode: 0o700)
    # 已存在根目录也要收紧权限，保持和创建锁相同的最小权限原则。
    File.chmod(0o700, worktreesRoot)
    # 目标的系统与轮次父目录都由脚本创建，不能预先替换为软链接。
    targetPath.ascend.take_while { |path| path != worktreesRoot }.reverse_each do |path|
      # 只检查已经存在的父目录；目标不存在是正常创建前状态。
      raise LifecycleError, "受控 worktree 路径包含软链接：#{path}" if path.exist? && path.symlink?
    end
  end

  # 使用同目录临时文件原子更新 workspace.md。
  def writeWorkspace(workspacePath, content)
    # 临时文件与目标同盘，rename 不会退化为复制后删除。
    Tempfile.create(["workspace-", ".md"], workspacePath.dirname.to_s) do |temporaryFile|
      # 写入完整新内容后立即刷新，避免只落入进程缓冲区。
      temporaryFile.write(content)
      # flush 保证 rename 前文件描述符已看到全部字节。
      temporaryFile.flush
      # 沿用原文件权限，不把轮次文档意外改成私有或可执行。
      temporaryFile.chmod(workspacePath.stat.mode & 0o777)
      # 原子替换让另一个 Agent 只会看到旧版或新版完整文件。
      File.rename(temporaryFile.path, workspacePath)
    end
  end

  # 把历史 v1 标记升级成 v2；无标记文档则在开头补入当前策略。
  def upgradePolicy(content)
    # 已经是 v2 时移除可能残留的 v1 标记，避免能力版本出现歧义。
    if content.include?(POLICY_MARKER)
      # 只删除旧标记本身和紧随换行，不改正文其他内容。
      return content.gsub("#{LEGACY_POLICY_MARKER}\n", "").gsub(LEGACY_POLICY_MARKER, "")
    end
    # v1 文档保留原正文，只替换能力标记。
    return content.sub(LEGACY_POLICY_MARKER, POLICY_MARKER) if content.include?(LEGACY_POLICY_MARKER)
    # 更早的历史文档没有策略标记，由受控脚本首次接管时补齐。
    "#{POLICY_MARKER}\n#{content}"
  end

  # 找到产品基线表中的指定仓库行，只扫描 dirty 明细之前的区域。
  def baselineRowIndex(lines, repositoryName)
    # 产品表位于文档开头，dirty 标题之后可能再次出现仓库名。
    boundaryIndex = lines.index { |line| line.start_with?("## 接管前 dirty 明细") } || lines.length
    # 逐行检查第一列和标准七列结构。
    lines[0...boundaryIndex].each_with_index do |line, index|
      # 非表格行与空占位行不会匹配仓库名。
      cells = tableCells(line)
      # 产品基线至少七列；生命周期表尚未进入扫描范围。
      next unless cells && cells.length >= 7
      # 返回第一个精确仓库名记录。
      return index if unwrapCell(cells[0]) == repositoryName
    end
    # nil 表示当前轮尚未为该仓库建立产品基线行。
    nil
  end

  # 新增或替换产品基线行，保留任务文件范围与已有接管说明。
  def upsertBaseline(content, repositoryName:, checkoutPath:, isolationMode:, branchName:, headValue:, statusNote:, preserveStatus: true)
    # 保留换行数组便于精确替换单行，不重排用户正文。
    lines = content.lines
    # 先定位可能存在的仓库行。
    rowIndex = baselineRowIndex(lines, repositoryName)
    # 已有行的最后两列属于人工记录，应在路径切换时继续保留。
    existingCells = rowIndex ? tableCells(lines[rowIndex]) : nil
    # 接管前状态没有人工内容时使用调用方给出的真实说明。
    takeoverState = preserveStatus && existingCells && !unwrapCell(existingCells[5]).empty? ? existingCells[5] : statusNote
    # 当前任务涉及文件若尚未规划，明确留待任务阶段补充。
    taskFiles = existingCells && !unwrapCell(existingCells[6]).empty? ? existingCells[6] : "待按任务补充"
    # 路径、分支和 HEAD 统一加反引号，保证校验器稳定解析。
    newRow = "| `#{repositoryName}` | `#{checkoutPath}` | #{isolationMode} | `#{branchName}` | `#{headValue}` | #{takeoverState} | #{taskFiles} |\n"
    if rowIndex
      # 已登记仓库原位替换，不改变表格顺序。
      lines[rowIndex] = newRow
    else
      # 新模板带一条空占位行，优先原位替换可保持 Markdown 表格连续。
      boundaryIndex = lines.index { |line| line.start_with?("## 接管前 dirty 明细") }
      # 缺少标准章节说明 workspace 已损坏，不能猜插入位置。
      raise LifecycleError, "workspace.md 缺少接管前 dirty 明细章节" unless boundaryIndex
      # 只在产品区域寻找七列空仓库占位，不碰后续表格。
      placeholderIndex = lines[0...boundaryIndex].each_index.find do |index|
        # 分隔行第一列不是空字符串，因此不会被误替换。
        cells = tableCells(lines[index])
        # 第一列为空且列数满足产品表结构才是模板占位。
        cells && cells.length >= 7 && unwrapCell(cells[0]).empty?
      end
      if placeholderIndex
        # 第一个真实仓库复用占位行。
        lines[placeholderIndex] = newRow
      else
        # 已有其他仓库时，在产品表最后一行后追加，不能隔着空行插入。
        tableIndexes = lines[0...boundaryIndex].each_index.select do |index|
          # 七列产品表头、分隔和数据都用于确定表格尾部。
          cells = tableCells(lines[index])
          # 其他短表不会进入候选集合。
          cells && cells.length >= 7
        end
        # 找不到产品表说明 workspace 结构已经损坏。
        raise LifecycleError, "workspace.md 缺少产品仓库基线表" if tableIndexes.empty?
        # 紧跟最后一行追加，保持 Markdown 正常渲染。
        lines.insert(tableIndexes.max + 1, newRow)
      end
    end
    # 返回完整正文，真正写盘由调用方统一完成。
    lines.join
  end

  # 生成一条生命周期表记录；所有路径都保留为绝对路径。
  def lifecycleRow(record)
    # 空的最终 HEAD 与清理时间使用“无”，避免空单元格难以审计。
    "| `#{record.fetch(:repository)}` | `#{record.fetch(:sourcePath)}` | `#{record.fetch(:targetPath)}` | `#{record.fetch(:branchName)}` | `#{record.fetch(:createdHead)}` | `#{record.fetch(:finalHead, '无')}` | #{record.fetch(:createdAt)} | #{record.fetch(:state)} | #{record.fetch(:cleanedAt, '无')} |\n"
  end

  # 新增或替换生命周期记录，并为历史 workspace 补上版本标记。
  def upsertLifecycle(content, record)
    # 历史文档首次进入受控脚本时升级为带同步门禁的当前格式。
    upgradedContent = upgradePolicy(content)
    # 按行修改可以保留产品基线和人工说明的原始排版。
    lines = upgradedContent.lines
    # 找到生命周期章节；不存在时在文末创建标准表格。
    headingIndex = lines.index { |line| line.strip == LIFECYCLE_HEADING }
    unless headingIndex
      # 文末确保只有一个空行，再附加标准章节。
      suffix = upgradedContent.end_with?("\n") ? "\n" : "\n\n"
      return "#{upgradedContent}#{suffix}#{LIFECYCLE_HEADING}\n\n#{LIFECYCLE_HEADER}\n#{LIFECYCLE_DIVIDER}\n#{lifecycleRow(record)}"
    end
    # 生命周期章节只扫描到下一个二级标题，避免误改其他表格。
    sectionEnd = ((headingIndex + 1)...lines.length).find { |index| lines[index].start_with?("## ") } || lines.length
    # 查找同仓库的唯一记录。
    matchingIndexes = (headingIndex...sectionEnd).select do |index|
      # 九列表格且第一列仓库名匹配才是生命周期记录。
      cells = tableCells(lines[index])
      # 表头和分隔行自然被过滤。
      cells && cells.length == 9 && unwrapCell(cells[0]) == record.fetch(:repository)
    end
    # 重复记录会让清理脚本无法判断哪一条是真实状态。
    raise LifecycleError, "workspace.md 中 worktree 生命周期记录重复：#{record.fetch(:repository)}" if matchingIndexes.length > 1
    if matchingIndexes.one?
      # 状态变化只替换这一仓库的记录。
      lines[matchingIndexes.first] = lifecycleRow(record)
    else
      # 新仓库行插在当前章节末尾，不影响其他仓库顺序。
      lines.insert(sectionEnd, lifecycleRow(record))
    end
    # 返回待原子写入的完整正文。
    lines.join
  end

  # 生成一条真实仓库同步记录，保留 worktree 与目标分支两端的提交证据。
  def syncRow(record)
    # 状态只由同步脚本写入固定值，避免人工“看起来已同步”的模糊描述。
    "| `#{record.fetch(:repository)}` | `#{record.fetch(:targetBranch)}` | `#{record.fetch(:finalHead)}` | `#{record.fetch(:sourceHead)}` | #{record.fetch(:syncedAt)} | #{record.fetch(:state)} |\n"
  end

  # 新增或替换指定仓库的同步记录，并自动补齐历史文档缺少的同步章节。
  def upsertSync(content, record)
    # 任何写入同步证据的文档都必须启用 v2 门禁。
    upgradedContent = upgradePolicy(content)
    # 按行更新可以保留人工填写的运行资源和 dirty 明细。
    lines = upgradedContent.lines
    # 同步章节不存在时附加标准空表和首条记录。
    headingIndex = lines.index { |line| line.strip == SYNC_HEADING }
    unless headingIndex
      # 文末只补一个空行，避免连续运行产生越来越多空白。
      suffix = upgradedContent.end_with?("\n") ? "\n" : "\n\n"
      # 返回完整正文，调用方仍通过 writeWorkspace 原子发布。
      return "#{upgradedContent}#{suffix}#{SYNC_HEADING}\n\n#{SYNC_HEADER}\n#{SYNC_DIVIDER}\n#{syncRow(record)}"
    end
    # 只在当前二级章节范围内寻找六列表格记录。
    sectionEnd = ((headingIndex + 1)...lines.length).find { |index| lines[index].start_with?("## ") } || lines.length
    # 同一仓库只能有一条当前同步证据。
    matchingIndexes = (headingIndex...sectionEnd).select do |index|
      # 六列和精确仓库名共同避免误改其他 Markdown 表格。
      cells = tableCells(lines[index])
      # 表头和分隔行不会匹配真实仓库名。
      cells && cells.length == 6 && unwrapCell(cells[0]) == record.fetch(:repository)
    end
    # 重复记录时不能猜哪一条对应本次清理。
    raise LifecycleError, "workspace.md 中 worktree 同步记录重复：#{record.fetch(:repository)}" if matchingIndexes.length > 1
    if matchingIndexes.one?
      # 重复同步同一仓库时原位刷新目标 HEAD 与时间。
      lines[matchingIndexes.first] = syncRow(record)
    else
      # 首次同步紧跟当前章节末尾追加一条记录。
      lines.insert(sectionEnd, syncRow(record))
    end
    # 返回待写正文，不在公共方法中隐式写盘。
    lines.join
  end

  # 读取指定仓库唯一的同步记录，供清理脚本再次验证真实仓库状态。
  def readSync(workspacePath, repositoryName)
    # 先限定固定同步章节，避免误读轮次正文里的其他六列表格。
    content = workspacePath.read
    # 没有章节表示真实仓库尚未进入受控同步流程。
    sectionMatch = content.match(/^#{Regexp.escape(SYNC_HEADING)}\s*$\n(.*?)(?=^## |\z)/m)
    # 缺少章节时使用与空表相同的稳定阻断信息。
    raise LifecycleError, "未找到 worktree 成果同步记录：#{repositoryName}" unless sectionMatch
    # 只接受章节内六列表格数据行，其他工作区表格不会进入候选。
    records = sectionMatch[1].lines.each_with_object([]) do |line, syncRecords|
      # 非表格行和其他列数的表格直接跳过。
      cells = tableCells(line)
      # 精确六列是同步记录的稳定结构标识。
      next unless cells && cells.length == 6
      # 第一列仓库名必须与当前清理目标一致。
      next unless unwrapCell(cells[0]) == repositoryName
      # 转成命名字段，调用方不依赖 Markdown 列位置。
      syncRecords << {
        repository: unwrapCell(cells[0]),
        targetBranch: unwrapCell(cells[1]),
        finalHead: unwrapCell(cells[2]),
        sourceHead: unwrapCell(cells[3]),
        syncedAt: unwrapCell(cells[4]),
        state: unwrapCell(cells[5])
      }
    end
    # 缺少记录表示真实仓库尚未通过受控同步，必须保留 worktree。
    raise LifecycleError, "未找到 worktree 成果同步记录：#{repositoryName}" if records.empty?
    # 多条记录会让目标分支和最终提交不唯一，同样阻断删除。
    raise LifecycleError, "worktree 成果同步记录不唯一：#{repositoryName}" unless records.length == 1
    # 返回唯一、可再次验证的同步证据。
    records.first
  end

  # 读取指定仓库的生命周期记录，供清理命令恢复原路径。
  def readLifecycle(workspacePath, repositoryName)
    # 没有章节说明该 worktree 不由受控脚本管理。
    content = workspacePath.read
    # 只解析标准九列表格行。
    records = content.lines.each_with_object([]) do |line, lifecycleRecords|
      # 非标准行和其他表格不会进入候选集合。
      cells = tableCells(line)
      # 九列是生命周期表与产品基线表的区分条件。
      next unless cells && cells.length == 9
      # 第一列必须精确匹配用户指定仓库。
      next unless unwrapCell(cells[0]) == repositoryName
      # 转成命名字段，调用方不再依赖数字下标。
      lifecycleRecords << {
        repository: unwrapCell(cells[0]),
        sourcePath: unwrapCell(cells[1]),
        targetPath: unwrapCell(cells[2]),
        branchName: unwrapCell(cells[3]),
        createdHead: unwrapCell(cells[4]),
        finalHead: unwrapCell(cells[5]),
        createdAt: unwrapCell(cells[6]),
        state: unwrapCell(cells[7]),
        cleanedAt: unwrapCell(cells[8])
      }
    end
    # 缺失和重复都不能安全删除任何目录。
    # 没有记录时，创建入口可以安全追加第一条生命周期。
    raise LifecycleError, "未找到受控 worktree 生命周期记录：#{repositoryName}" if records.empty?
    # 重复记录必须阻断，不能被创建入口当成普通缺失。
    raise LifecycleError, "受控 worktree 生命周期记录不唯一：#{repositoryName}" unless records.length == 1
    # 返回唯一记录。
    records.first
  end

  # 清理成功后尝试移除空的仓库、轮次和系统目录，不触碰根锁文件。
  def removeEmptyParents(targetPath, worktreesRoot)
    # git worktree remove 已经移除目标目录，从它的父级开始向上收缩。
    currentPath = targetPath.parent
    # .worktrees 根目录保存并发锁，不在这里删除。
    while currentPath != worktreesRoot
      # 目录不存在或仍有其他 worktree 时立即停止。
      break unless currentPath.directory? && currentPath.children.empty?
      # rmdir 只允许空目录，比递归删除安全。
      Dir.rmdir(currentPath)
      # 继续检查上一层是否也变为空目录。
      currentPath = currentPath.parent
    end
  end
end
