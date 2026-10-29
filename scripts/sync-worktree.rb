#!/usr/bin/env ruby

# 把受控 worktree 的最终提交同步到 overview.md 登记的真实仓库目录。
# 本脚本不合并功能分支，也不推送；这些动作仍需单独明确授权。
# 调用前应先把成果分支合入目标分支并推送到目标分支的上游。
# 脚本要求真实仓库已经检出显式目标分支，绝不自动切换分支。
# 真实仓库和 worktree 任一处有 dirty 文件时都会阻断同步。
# 拉取固定使用 git pull --ff-only，拒绝隐式合并提交和历史改写。
# 拉取完成后还要证明 worktree 最终 HEAD 是真实仓库 HEAD 的祖先。
# 验证通过后同时记录目标分支、两端 HEAD、同步时间和固定状态。
# 删除动作仍由 cleanup-worktree.rb 执行，防止同步失败时副本消失。
# 路径、仓库名和生命周期身份全部沿用受控 worktree 公共校验。
# 网络认证或上游缺失会原样阻断，不写伪造的同步完成记录。
# 同步记录只写入 workspace.md，不在 overview.md 复制动态分支状态。
# 目标分支来自命令参数，适配不同仓库使用的发布分支命名。
# 同一仓库重复同步会刷新证据，但不会放宽目录或分支检查。
# 拉取完成但文档写入失败时保留 worktree，重试仍能安全验证。
# 所有 Git 参数均以数组传递，不让分支名进入 shell 解释环境。
# 本地目标分支包含成果但上游未包含时仍判定失败，防止漏推送。
# 上游检查复用目标分支既有 tracking 配置，不接受额外远端参数。
# 同步完成只代表代码已进入真实检出，不代表部署或发布已经完成。
# 任一检查失败都不修改 worktree 生命周期状态，也不会删除目录。

require_relative "worktree-support"

# 目标分支必须显式传入，不能默认 main、master 或原仓库当前分支。
unless ARGV.length == 3
  # 命令接口把同步和删除拆开，便于分别取得外部 Git 操作授权。
  abort "用法：ruby scripts/sync-worktree.rb <轮次目录> <仓库名> <目标分支>"
end

begin
  # 框架边界从脚本真实位置推导，不依赖调用目录。
  frameworkRoot = WorktreeSupport.frameworkRoot(__dir__)
  # 轮次必须是当前框架中已经登记且带 workspace.md 的真实目录。
  systemPath, iterationPath, workspacePath = WorktreeSupport.resolveIteration(frameworkRoot, ARGV[0])
  # 仓库名只用于 overview 和生命周期记录的精确匹配。
  repositoryName = ARGV[1]
  # 目标分支来自本次明确命令，不写死任何项目默认分支。
  targetBranch = ARGV[2]
  # overview.md 仍是项目真实位置的唯一事实源。
  sourcePath = WorktreeSupport.resolveRepository(systemPath, repositoryName)
  # 原仓库必须恰好是 Git 根目录，不能登记内部子目录。
  WorktreeSupport.validateRepositoryRoot(sourcePath)
  # 让 Git 自己验证目标分支名，避免 Ruby 复制一套不完整规则。
  WorktreeSupport.runGit(sourcePath, "check-ref-format", "--branch", targetBranch)
  # 受控目标路径必须由框架、系统、轮次和仓库名共同计算。
  worktreesRoot, expectedTargetPath = WorktreeSupport.worktreePaths(frameworkRoot, systemPath, iterationPath, repositoryName)
  # 同步只处理已经存在的受控根目录，不负责隐式创建 worktree。
  raise WorktreeSupport::LifecycleError, ".worktrees 不存在，没有可同步目标" unless worktreesRoot.directory?
  # 根目录若是软链接，所有后续路径身份都不再可信。
  raise WorktreeSupport::LifecycleError, ".worktrees 不能是软链接" if worktreesRoot.symlink?
  # 创建、同步和清理共用同一把本机锁，避免 workspace 交叉写入。
  lockPath = worktreesRoot.join(".worktree.lock")
  # 锁只串行化短时生命周期动作，不保存业务状态。
  File.open(lockPath, File::RDWR | File::CREAT, 0o600) do |lockFile|
    # 外部程序改宽权限后，每次调用都恢复最小权限。
    lockFile.chmod(0o600)
    # 从读取生命周期到发布同步证据都处于同一临界区。
    lockFile.flock(File::LOCK_EX)
    # 生命周期表是允许本脚本操作哪个 worktree 的授权清单。
    lifecycleRecord = WorktreeSupport.readLifecycle(workspacePath, repositoryName)
    # 只有仍在使用的副本可以同步；待清理表示删除流程已经开始。
    unless lifecycleRecord[:state] == "使用中"
      # 已删除、待清理和保留状态都需要先人工核对，不自动倒退状态。
      raise WorktreeSupport::LifecycleError, "worktree 生命周期状态不可同步：#{lifecycleRecord[:state]}"
    end
    # 生命周期原仓库必须继续与 overview.md 指向同一个实体。
    recordedSourcePath = Pathname.new(lifecycleRecord[:sourcePath]).expand_path
    # 目录存在后用 realpath 消除正常别名并阻断登记漂移。
    unless recordedSourcePath.directory? && recordedSourcePath.realpath == sourcePath
      # 不一致可能意味着系统登记已改，不能继续拉取未知仓库。
      raise WorktreeSupport::LifecycleError, "生命周期原仓库路径与 overview.md 不一致"
    end
    # 临时路径必须精确等于固定算法结果，不能只靠相似前缀。
    recordedTargetPath = Pathname.new(lifecycleRecord[:targetPath]).expand_path
    # workspace 被手工改到其他目录时立即停止。
    unless recordedTargetPath == expectedTargetPath
      # 错误保留实际记录路径，便于用户修正文档。
      raise WorktreeSupport::LifecycleError, "生命周期临时路径不符合 .worktrees 规则：#{recordedTargetPath}"
    end
    # 同步前 worktree 必须存在且不能被替换成软链接。
    raise WorktreeSupport::LifecycleError, "worktree 目录不存在，无法同步" unless recordedTargetPath.directory?
    # 软链接目标可能逃出受控根目录，拒绝跟随。
    raise WorktreeSupport::LifecycleError, "worktree 目标不能是软链接" if recordedTargetPath.symlink?
    # Git 登记表用于证明目标不是同名普通目录。
    worktreeList, = WorktreeSupport.runGit(sourcePath, "worktree", "list", "--porcelain")
    # porcelain 的每个工作区都由绝对 worktree 路径行开头。
    registeredPaths = worktreeList.scan(/^worktree (.+)$/).flatten.map { |path| Pathname.new(path).expand_path }
    # 没有登记时保留目录供人工判断，不把它当作成果 worktree。
    raise WorktreeSupport::LifecycleError, "目标不是该仓库登记的 Git worktree" unless registeredPaths.include?(recordedTargetPath)
    # Git 根目录必须仍然就是登记目标，不能是内部子目录或替换后的仓库。
    actualRootOutput, = WorktreeSupport.runGit(recordedTargetPath, "rev-parse", "--show-toplevel")
    # realpath 比较消除正常路径别名，同时阻断目标身份漂移。
    unless Pathname.new(actualRootOutput.strip).realpath == recordedTargetPath.realpath
      # 不对身份异常目录执行状态读取、拉取或文档写入。
      raise WorktreeSupport::LifecycleError, "worktree 目标路径身份已变化"
    end
    # worktree 必须已经提交全部 tracked 与 untracked 成果。
    worktreeDirty, = WorktreeSupport.runGit(recordedTargetPath, "status", "--porcelain")
    # dirty 状态下记录 final HEAD 会遗漏尚未提交内容，因此必须阻断。
    raise WorktreeSupport::LifecycleError, "worktree 仍有未提交或未跟踪文件，拒绝同步" unless worktreeDirty.empty?
    # status 之后再次拒绝软链接，缩小路径检查与后续 Git 查询间的竞态窗口。
    raise WorktreeSupport::LifecycleError, "worktree 目标在同步期间变成软链接" if recordedTargetPath.symlink?
    # worktree 应继续位于创建时登记的成果分支上。
    worktreeBranchOutput, _worktreeBranchError, worktreeBranchStatus = WorktreeSupport.runGit(
      recordedTargetPath,
      "symbolic-ref",
      "--quiet",
      "--short",
      "HEAD",
      allowedStatuses: [0, 1]
    )
    # detached HEAD 无法提供稳定成果分支，不能进入自动同步流程。
    raise WorktreeSupport::LifecycleError, "worktree 处于 detached HEAD，拒绝同步" unless worktreeBranchStatus.zero?
    # 分支被切换后生命周期记录已经失真，要求先人工修正。
    unless worktreeBranchOutput.strip == lifecycleRecord[:branchName]
      # 同时显示实际和登记值，便于定位误操作。
      raise WorktreeSupport::LifecycleError, "worktree 当前分支与生命周期记录不一致：#{worktreeBranchOutput.strip}"
    end
    # 最终提交是后续祖先关系验证的源端证据。
    finalHeadOutput, = WorktreeSupport.runGit(recordedTargetPath, "rev-parse", "HEAD")
    # 原仓库也必须干净，pull 不能覆盖或夹带用户正在做的修改。
    sourceDirty, = WorktreeSupport.runGit(sourcePath, "status", "--porcelain")
    # tracked 和 untracked 任一状态都要求用户先处理。
    raise WorktreeSupport::LifecycleError, "真实仓库仍有未提交或未跟踪文件，拒绝拉取" unless sourceDirty.empty?
    # 原仓库必须已经位于调用方显式指定的目标分支。
    sourceBranchOutput, _sourceBranchError, sourceBranchStatus = WorktreeSupport.runGit(
      sourcePath,
      "symbolic-ref",
      "--quiet",
      "--short",
      "HEAD",
      allowedStatuses: [0, 1]
    )
    # detached HEAD 或错误分支都不允许脚本自行 checkout。
    unless sourceBranchStatus.zero? && sourceBranchOutput.strip == targetBranch
      # 错误消息明确要求用户选择正确目录状态后重试。
      actualBranch = sourceBranchStatus.zero? ? sourceBranchOutput.strip : "(detached)"
      raise WorktreeSupport::LifecycleError, "真实仓库当前分支不是目标分支 #{targetBranch}：#{actualBranch}"
    end
    # pull 前先确认目标分支配置了明确上游，防止 Git 猜测远端。
    upstreamOutput, _upstreamError, upstreamStatus = WorktreeSupport.runGit(
      sourcePath,
      "rev-parse",
      "--abbrev-ref",
      "--symbolic-full-name",
      "@{upstream}",
      allowedStatuses: [0, 1, 128]
    )
    # 没有上游时不能满足“在真实位置拉取代码”的要求。
    raise WorktreeSupport::LifecycleError, "目标分支没有配置上游，无法执行受控拉取" unless upstreamStatus.zero? && !upstreamOutput.strip.empty?
    # 固定快进拉取，目标分支分叉时停止而不是生成自动合并提交。
    WorktreeSupport.runGit(sourcePath, "pull", "--ff-only")
    # 拉取后读取真实仓库最终 HEAD，作为目标端同步证据。
    sourceHeadOutput, = WorktreeSupport.runGit(sourcePath, "rev-parse", "HEAD")
    # Git 祖先判断状态 1 表示未包含，由本脚本转成人可执行阻断。
    _ancestorOutput, _ancestorError, ancestorStatus = WorktreeSupport.runGit(
      sourcePath,
      "merge-base",
      "--is-ancestor",
      finalHeadOutput.strip,
      sourceHeadOutput.strip,
      allowedStatuses: [0, 1]
    )
    # 仅拉取成功不代表成果分支已经合入目标分支。
    unless ancestorStatus.zero?
      # 保留 worktree，提示先完成推送和合并后再次同步。
      raise WorktreeSupport::LifecycleError, "目标分支拉取后仍不包含 worktree 最终提交；请先完成成果分支的推送与合并"
    end
    # 本地目标分支包含成果还不够，上游也必须已经包含该提交。
    upstreamHeadOutput, = WorktreeSupport.runGit(sourcePath, "rev-parse", upstreamOutput.strip)
    # 祖先检查证明目标分支的远端跟踪引用已经接收成果。
    _upstreamAncestorOutput, _upstreamAncestorError, upstreamAncestorStatus = WorktreeSupport.runGit(
      sourcePath,
      "merge-base",
      "--is-ancestor",
      finalHeadOutput.strip,
      upstreamHeadOutput.strip,
      allowedStatuses: [0, 1]
    )
    # 避免本地未推送合并被误记为“通过拉取完成同步”。
    unless upstreamAncestorStatus.zero?
      # worktree 继续保留，用户推送目标分支后可以安全重试。
      raise WorktreeSupport::LifecycleError, "目标分支上游仍不包含 worktree 最终提交；请先推送目标分支"
    end
    # 一次取时间，生命周期与同步记录使用同一个核验时点。
    syncedAt = Time.now.iso8601
    # 先把真实最终 HEAD 写回生命周期表，供清理脚本逐项比对。
    syncedLifecycle = lifecycleRecord.merge(finalHead: finalHeadOutput.strip)
    # 更新生命周期时也会把历史 v1 文档升级到 v2。
    updatedContent = WorktreeSupport.upsertLifecycle(workspacePath.read, syncedLifecycle)
    # 同步表保存目标分支、两端 HEAD、时间和固定通过状态。
    updatedContent = WorktreeSupport.upsertSync(
      updatedContent,
      repository: repositoryName,
      targetBranch: targetBranch,
      finalHead: finalHeadOutput.strip,
      sourceHead: sourceHeadOutput.strip,
      syncedAt: syncedAt,
      state: "已同步验证"
    )
    # 两张表准备完整后再原子发布，避免只落一半证据。
    WorktreeSupport.writeWorkspace(workspacePath, updatedContent)
  end
  # 输出真实仓库、目标分支和同步后 HEAD，便于过程汇报复核。
  syncRecord = WorktreeSupport.readSync(workspacePath, repositoryName)
  # 单行稳定输出也方便自动测试断言。
  puts "#{sourcePath} #{syncRecord[:targetBranch]} #{syncRecord[:sourceHead]}"
rescue WorktreeSupport::LifecycleError => error
  # 预期输入、Git 或状态错误只输出一行人可读原因。
  warn error.message
  # 非零退出码阻止 Agent 在同步失败后继续调用清理脚本。
  exit 1
end
