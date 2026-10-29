#!/usr/bin/env ruby

# 清理一轮已经登记的受控 Git worktree，并恢复 workspace.md 当前路径。
# 删除目标只能来自生命周期表且必须等于框架计算出的 .worktrees 路径。
# worktree 有未提交或未跟踪文件时立即阻断，不使用 --force。
# 清理前要求同步脚本已经拉取目标分支并证明它包含最终 HEAD。
# 再次验证真实仓库分支、HEAD 和工作区，避免同步后状态被改动。
# Git worktree remove 成功后执行 prune，并只移除空的父目录。
# 产品基线行恢复为 overview.md 的原仓库路径和它当前的分支、HEAD。
# 功能分支只保留不删除；提交、推送、合并和删分支仍需各自明确授权。
# 删除边界一：临时路径必须同时匹配生命周期记录和固定目录算法。
# 删除边界二：目标必须仍是原仓库登记的 Git worktree，而非普通目录。
# 删除边界三：tracked 与 untracked 变更都会阻断，不提供强制开关。
# 恢复边界一：删除前先写最终分支、HEAD 和“待清理”状态。
# 恢复边界二：目录已删但文档未收口时，可重复命令完成最终更新。
# 文档边界：当前产品路径恢复原仓库，临时路径只留作历史证据。
# 分支边界：删除 worktree 不等于删除分支，脚本不会扩大授权。
# 同步边界：只认 sync-worktree.rb 写入的固定状态和两端 HEAD。
# 分支边界：真实仓库必须保持在记录的目标分支，脚本不做 checkout。
# 版本边界：目标分支可以继续前进，但不能丢失已验证的同步提交。
# 中断边界：目录删除后仍可凭待清理记录完成文档恢复。

require_relative "worktree-support"

# 清理只需要轮次和仓库，临时路径不允许由调用方自由传入。
unless ARGV.length == 2
  # 精简接口可以降低误删其他目录的可能性。
  abort "用法：ruby scripts/cleanup-worktree.rb <轮次目录> <仓库名>"
end

begin
  # 框架边界从脚本位置动态解析。
  frameworkRoot = WorktreeSupport.frameworkRoot(__dir__)
  # 轮次必须真实存在且属于当前框架。
  systemPath, iterationPath, workspacePath = WorktreeSupport.resolveIteration(frameworkRoot, ARGV[0])
  # 仓库名用于同时核对 overview 和生命周期记录。
  repositoryName = ARGV[1]
  # 当前 overview 登记仍然是原仓库路径的事实源。
  sourcePath = WorktreeSupport.resolveRepository(systemPath, repositoryName)
  # 只允许从 Git 仓库根目录管理 worktree。
  WorktreeSupport.validateRepositoryRoot(sourcePath)
  # 受控目标必须由固定目录规则重新计算，不能只信 Markdown 字符串。
  worktreesRoot, expectedTargetPath = WorktreeSupport.worktreePaths(frameworkRoot, systemPath, iterationPath, repositoryName)
  # .worktrees 不存在说明当前没有可清理的受控副本。
  raise WorktreeSupport::LifecycleError, ".worktrees 不存在，没有可清理目标" unless worktreesRoot.directory?
  # 根目录若被替换成软链接则停止，不跟随到框架外删除。
  raise WorktreeSupport::LifecycleError, ".worktrees 不能是软链接" if worktreesRoot.symlink?
  # 创建与清理共享同一把锁，避免并发更新同一生命周期表。
  lockPath = worktreesRoot.join(".worktree.lock")
  # 锁的临界区包含 Git 删除，防止另一个 Agent 同时重建相同目标。
  # 锁文件不保存状态，只负责串行化短时危险操作。
  File.open(lockPath, File::RDWR | File::CREAT, 0o600) do |lockFile|
    # 每次使用都恢复最小权限。
    lockFile.chmod(0o600)
    # 锁覆盖状态预写、Git 删除和最终路径恢复。
    lockFile.flock(File::LOCK_EX)
    # 生命周期表提供创建时原路径、临时路径和成果分支。
    lifecycleRecord = WorktreeSupport.readLifecycle(workspacePath, repositoryName)
    # 表格是删除目标的授权清单，不从目录扫描结果猜测要删哪一个。
    # 已删除状态重复执行不会再碰文件系统，只报告无需操作。
    if lifecycleRecord[:state] == "已删除"
      # 幂等返回让中断后的 Agent 可以安全复核。
      puts "已删除：#{lifecycleRecord[:targetPath]}"
      # 使用 throw 不合适，这里正常结束整个进程。
      exit 0
    end
    # 用户确认保留表示明确例外，清理前必须先把状态改回待清理。
    if lifecycleRecord[:state].start_with?("用户确认保留")
      # 不把一次普通清理请求解释成撤销保留决定。
      raise WorktreeSupport::LifecycleError, "worktree 已记录为用户确认保留；请先在 workspace.md 撤销保留状态"
    end
    # 只有使用中或上次删除中断留下的待清理状态可以继续。
    unless %w[使用中 待清理].include?(lifecycleRecord[:state])
      # 未知状态必须人工核对，不能猜成可删除。
      raise WorktreeSupport::LifecycleError, "worktree 生命周期状态不可清理：#{lifecycleRecord[:state]}"
    end
    # 生命周期表中的原路径必须仍与 overview.md 指向同一个仓库。
    recordedSourcePath = Pathname.new(lifecycleRecord[:sourcePath]).expand_path
    # 原仓库不存在时 resolveRepository 已经阻断；这里可以安全 realpath。
    unless recordedSourcePath.directory? && recordedSourcePath.realpath == sourcePath
      # 路径漂移可能意味着系统登记被修改，必须先人工确认。
      raise WorktreeSupport::LifecycleError, "生命周期原仓库路径与 overview.md 不一致"
    end
    # 临时路径必须精确等于固定计算结果，不接受相似前缀。
    recordedTargetPath = Pathname.new(lifecycleRecord[:targetPath]).expand_path
    unless recordedTargetPath == expectedTargetPath
      # 这条检查是删除动作最重要的路径边界。
      raise WorktreeSupport::LifecycleError, "生命周期临时路径不符合 .worktrees 规则：#{recordedTargetPath}"
    end
    # 删除前必须存在由同步脚本写入的唯一目标分支和 HEAD 证据。
    syncRecord = WorktreeSupport.readSync(workspacePath, repositoryName)
    # 人工填写其他状态不能替代真实 Git 拉取和祖先关系检查。
    unless syncRecord[:state] == "已同步验证"
      # 保留 worktree 供重新同步，不进入删除流程。
      raise WorktreeSupport::LifecycleError, "worktree 成果尚未通过同步验证：#{syncRecord[:state]}"
    end
    # 真实仓库必须保持干净，防止清理过程掩盖同步后的新修改。
    sourceDirty, = WorktreeSupport.runGit(sourcePath, "status", "--porcelain")
    # tracked 和 untracked 变更都要求先由用户处理。
    raise WorktreeSupport::LifecycleError, "真实仓库仍有未提交或未跟踪文件，拒绝清理" unless sourceDirty.empty?
    # 真实仓库当前分支必须仍是同步记录中的显式目标分支。
    sourceBranchOutput, _sourceBranchError, sourceBranchStatus = WorktreeSupport.runGit(
      sourcePath,
      "symbolic-ref",
      "--quiet",
      "--short",
      "HEAD",
      allowedStatuses: [0, 1]
    )
    # 清理脚本绝不自动切换原仓库分支。
    unless sourceBranchStatus.zero? && sourceBranchOutput.strip == syncRecord[:targetBranch]
      # detached 或切换到其他分支时都要求重新确认目标目录状态。
      actualBranch = sourceBranchStatus.zero? ? sourceBranchOutput.strip : "(detached)"
      raise WorktreeSupport::LifecycleError, "真实仓库当前分支不再是已同步目标分支 #{syncRecord[:targetBranch]}：#{actualBranch}"
    end
    # 读取当前真实仓库 HEAD，用于发现同步后被回退或替换的分支。
    currentSourceHeadOutput, = WorktreeSupport.runGit(sourcePath, "rev-parse", "HEAD")
    # 记录的同步 HEAD 和 worktree 最终 HEAD 都必须仍包含在当前分支中。
    [syncRecord[:sourceHead], syncRecord[:finalHead]].each do |requiredHead|
      # 状态 1 是正常的“不包含”，由下一行转换为明确阻断。
      _ancestorOutput, _ancestorError, ancestorStatus = WorktreeSupport.runGit(
        sourcePath,
        "merge-base",
        "--is-ancestor",
        requiredHead,
        currentSourceHeadOutput.strip,
        allowedStatuses: [0, 1]
      )
      # 任何一端证据失效都保留 worktree，不继续不可逆删除。
      raise WorktreeSupport::LifecycleError, "真实仓库目标分支已不再包含同步提交：#{requiredHead}" unless ancestorStatus.zero?
    end
    # 上次可能已完成 Git 删除但没来得及发布最终 Markdown。
    targetExists = recordedTargetPath.directory?
    if targetExists
      # 删除前拒绝目标本身变成软链接，避免跟随到其他目录读取状态。
      raise WorktreeSupport::LifecycleError, "worktree 目标不能是软链接" if recordedTargetPath.symlink?
      # worktree 必须仍登记在当前源仓库，不能删除同名普通目录。
      worktreeList, = WorktreeSupport.runGit(sourcePath, "worktree", "list", "--porcelain")
      # porcelain 每个工作区以绝对路径行开头。
      registeredPaths = worktreeList.scan(/^worktree (.+)$/).flatten.map { |path| Pathname.new(path).expand_path }
      # 没有登记的目录交给用户人工判断，脚本不递归删除。
      raise WorktreeSupport::LifecycleError, "目标不是该仓库登记的 Git worktree" unless registeredPaths.include?(recordedTargetPath)
      # 任何 tracked 或 untracked 变更都阻断清理。
      dirtyOutput, = WorktreeSupport.runGit(recordedTargetPath, "status", "--porcelain")
      # 不使用 --force，确保未保存成果不会随目录消失。
      raise WorktreeSupport::LifecycleError, "worktree 仍有未提交或未跟踪文件，拒绝清理" unless dirtyOutput.empty?
      # status 之后再次核对目标没有被替换成软链接，缩小检查与删除竞态。
      raise WorktreeSupport::LifecycleError, "worktree 目标在清理期间变成软链接" if recordedTargetPath.symlink?
      # Git 根目录必须仍然就是登记目标，不能是内部子目录或路径替身。
      actualRootOutput, = WorktreeSupport.runGit(recordedTargetPath, "rev-parse", "--show-toplevel")
      # realpath 比较消除正常路径别名，同时拒绝目标切换到其他仓库。
      unless Pathname.new(actualRootOutput.strip).realpath == recordedTargetPath.realpath
        # 路径身份变化时停止，不调用 worktree remove。
        raise WorktreeSupport::LifecycleError, "worktree 目标路径身份已变化"
      end
      # 删除前保存真实分支；detached HEAD 使用固定可读值。
      branchOutput, _branchError, branchStatus = WorktreeSupport.runGit(
        recordedTargetPath,
        "symbolic-ref",
        "--quiet",
        "--short",
        "HEAD",
        allowedStatuses: [0, 1]
      )
      # 状态 1 表示 detached，不把空字符串误写成分支名。
      finalBranch = branchStatus.zero? ? branchOutput.strip : "(detached)"
      # 最终 HEAD 是目录删除后仍可追踪成果的关键证据。
      finalHeadOutput, = WorktreeSupport.runGit(recordedTargetPath, "rev-parse", "HEAD")
      # 同步之后 worktree 又产生新提交时，旧同步证据立即失效。
      unless finalHeadOutput.strip == syncRecord[:finalHead] && lifecycleRecord[:finalHead] == syncRecord[:finalHead]
        # 用户需重新运行同步脚本，让真实仓库取得新的最终提交。
        raise WorktreeSupport::LifecycleError, "worktree 最终 HEAD 与同步记录不一致；请重新同步"
      end
      # 清理时间先写入待清理状态，支持 Git 删除后文档发布中断恢复。
      cleanedAt = Time.now.iso8601
      # 使用创建时间保持原始证据，不因清理而覆盖。
      pendingRecord = lifecycleRecord.merge(
        branchName: finalBranch,
        finalHead: finalHeadOutput.strip,
        state: "待清理",
        cleanedAt: cleanedAt
      )
      # 先落盘最终 HEAD，再执行不可逆的目录删除。
      pendingContent = WorktreeSupport.upsertLifecycle(workspacePath.read, pendingRecord)
      # 原子写入保证中断时至少有可恢复证据。
      WorktreeSupport.writeWorkspace(workspacePath, pendingContent)
      # Git 原生命令只移除干净 worktree，不使用强制参数。
      WorktreeSupport.runGit(sourcePath, "worktree", "remove", recordedTargetPath.to_s)
      # 清理已经失效的 worktree 管理记录。
      WorktreeSupport.runGit(sourcePath, "worktree", "prune")
      # 删除完成后收缩空父目录，不碰根锁文件。
      WorktreeSupport.removeEmptyParents(recordedTargetPath, worktreesRoot)
      # 后续最终文档更新复用刚写入的确定记录。
      lifecycleRecord = pendingRecord
    else
      # 目标已不存在时只允许从“待清理”恢复，避免掩盖外部手工删除。
      unless lifecycleRecord[:state] == "待清理"
        # 使用中目录凭空消失需要人工确认 Git 和成果状态。
        raise WorktreeSupport::LifecycleError, "worktree 目录不存在但状态仍为使用中"
      end
      # 即使目录已经删除，也补一次 prune 清除残余管理记录。
      WorktreeSupport.runGit(sourcePath, "worktree", "prune")
      # 恢复中断流程时，生命周期最终 HEAD 仍必须与同步证据一致。
      unless lifecycleRecord[:finalHead] == syncRecord[:finalHead]
        # 不一致说明文档被改动，不能发布伪造的已删除终态。
        raise WorktreeSupport::LifecycleError, "待清理记录的最终 HEAD 与同步记录不一致"
      end
    end
    # 原仓库当前分支用于恢复“产品检出路径”行的真实语义。
    sourceBranchOutput, _sourceBranchError, sourceBranchStatus = WorktreeSupport.runGit(
      sourcePath,
      "symbolic-ref",
      "--quiet",
      "--short",
      "HEAD",
      allowedStatuses: [0, 1]
    )
    # 原仓库也可能处于 detached HEAD，保持可读状态。
    sourceBranch = sourceBranchStatus.zero? ? sourceBranchOutput.strip : "(detached)"
    # 读取原仓库当前 HEAD，不把 feature 分支误写成原目录当前版本。
    sourceHeadOutput, = WorktreeSupport.runGit(sourcePath, "rev-parse", "HEAD")
    # 产品基线行恢复为 overview 中的真实仓库路径。
    restoredContent = WorktreeSupport.upsertBaseline(
      workspacePath.read,
      repositoryName: repositoryName,
      checkoutPath: sourcePath,
      isolationMode: "共享检出",
      branchName: sourceBranch,
      headValue: sourceHeadOutput.strip,
      statusNote: "临时 worktree 已删除；真实仓库目标分支已同步并包含最终 HEAD",
      preserveStatus: false
    )
    # 历史记录保留临时路径、成果分支和最终 HEAD，只把状态改成已删除。
    completedRecord = lifecycleRecord.merge(state: "已删除")
    # 若恢复自待清理，清理时间已经在第一次写入时保留。
    completedRecord[:cleanedAt] = Time.now.iso8601 if completedRecord[:cleanedAt] == "无"
    # 同步生命周期终态后一次原子发布。
    restoredContent = WorktreeSupport.upsertLifecycle(restoredContent, completedRecord)
    # 最终写盘完成后，done 门禁可以验证目录确实不存在。
    WorktreeSupport.writeWorkspace(workspacePath, restoredContent)
  end
  # 输出已清理的精确路径，便于过程汇报和审计。
  puts expectedTargetPath
rescue WorktreeSupport::LifecycleError => error
  # 预期阻断只输出安全且可执行的原因。
  warn error.message
  # 非零退出码确保 Agent 不会误报清理完成。
  exit 1
end
