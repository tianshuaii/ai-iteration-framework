#!/usr/bin/env ruby

# 为一个已登记轮次和产品仓库创建受控 Git worktree。
# 临时源码只能落在框架根目录 .worktrees/<system>/<iteration>/<repo>/。
# 原仓库路径只从系统 overview.md 读取，不接受任意来源目录参数。
# 分支名必须显式提供；不存在时创建，存在时复用而不覆盖。
# 起点默认使用原仓库当前 HEAD，也可以显式传入合法 commit-ish。
# 创建成功后同时更新 workspace.md 的产品路径和生命周期记录。
# 脚本不提交、不推送、不启动服务，也不会删除任何已有分支。
# 原仓库存在 dirty 文件不构成创建理由，只在 workspace.md 留基线。
# 只有同系统另一 implement/verify 轮次登记同一仓库时才允许创建。
# 安全边界一：轮次必须是当前框架 systems/ 下的直接轮次目录。
# 安全边界二：原仓库必须来自 overview.md 且不能位于框架内部。
# 安全边界三：仓库名只能形成一个安全路径段，不能包含目录跳转。
# 安全边界四：目标路径完全由脚本计算，命令行不能覆盖它。
# 一致性边界一：Git 创建和 workspace 发布在同一把框架锁内执行。
# 一致性边界二：文档失败会撤销新 worktree，但保留可能创建的分支。
# 恢复边界：已删除记录可以重新创建，其他生命周期必须先处理。

require_relative "worktree-support"

# 参数保持简短且不依赖当前工作目录。
unless (3..4).cover?(ARGV.length)
  # 明确列出可选起点，避免 Agent 猜测参数顺序。
  abort "用法：ruby scripts/create-worktree.rb <轮次目录> <仓库名> <分支名> [起点ref]"
end

begin
  # 所有路径边界都从脚本真实位置推导。
  frameworkRoot = WorktreeSupport.frameworkRoot(__dir__)
  # 解析并验证轮次必须属于当前框架。
  systemPath, iterationPath, workspacePath = WorktreeSupport.resolveIteration(frameworkRoot, ARGV[0])
  # 仓库名必须精确匹配 overview.md 中的一行。
  repositoryName = ARGV[1]
  # 分支名由用户或 Agent 明确给出，脚本不把中文主题硬编码进 Git 命名。
  branchName = ARGV[2]
  # 未提供起点时从原仓库当前 HEAD 创建。
  startRef = ARGV[3] || "HEAD"
  # 以短横线开头的 ref 可能被 Git 当成选项，直接拒绝。
  raise WorktreeSupport::LifecycleError, "起点 ref 不能以短横线开头" if startRef.start_with?("-")
  # 原仓库必须来自 overview 且恰好是 Git 根目录。
  sourcePath = WorktreeSupport.resolveRepository(systemPath, repositoryName)
  # overview 不得把框架内部目录登记成产品原仓库。
  if sourcePath.to_s.start_with?("#{frameworkRoot}#{File::SEPARATOR}")
    # 临时源码和框架文件必须保持单向关系，避免清理源仓库自身。
    raise WorktreeSupport::LifecycleError, "产品原仓库不能位于框架根目录内"
  end
  # 子目录或非 Git 路径不能参与 worktree 管理。
  WorktreeSupport.validateRepositoryRoot(sourcePath)
  # worktree 只解决并行产品迭代的仓库隔离，不作为 dirty 规避手段。
  parallelIterations = WorktreeSupport.parallelProductIterations(systemPath, iterationPath, repositoryName)
  # 没有同仓库并行轮次时必须继续使用 overview 登记的真实仓库。
  if parallelIterations.empty?
    # 错误直接说明触发条件，防止 Agent 因看到未提交文件再次尝试。
    raise WorktreeSupport::LifecycleError, "只有其他 implement/verify 轮次使用同一仓库时才能创建 worktree；未提交修改不触发：#{repositoryName}"
  end
  # Git 自己负责验证引用命名规则，不在 Ruby 中复制一套不完整正则。
  WorktreeSupport.runGit(sourcePath, "check-ref-format", "--branch", branchName)
  # 起点必须能解析成提交，避免创建到标签对象或拼错引用。
  WorktreeSupport.runGit(sourcePath, "rev-parse", "--verify", "#{startRef}^{commit}")
  # 目标路径完全由框架、系统、轮次和仓库名计算。
  worktreesRoot, targetPath = WorktreeSupport.worktreePaths(frameworkRoot, systemPath, iterationPath, repositoryName)
  # 拒绝软链接路径并准备权限受限的根目录。
  WorktreeSupport.prepareWorktreesRoot(worktreesRoot, targetPath)
  # 同一框架的创建和清理使用一把短时文件锁，避免交叉更新 workspace。
  lockPath = worktreesRoot.join(".worktree.lock")
  # 这把锁不跨机器协调；它只保护同一框架目录内的本机 Agent。
  # 锁文件只保存操作系统锁，不写动态业务状态。
  File.open(lockPath, File::RDWR | File::CREAT, 0o600) do |lockFile|
    # 已有锁权限被外部工具改宽时，每次调用都主动收紧。
    lockFile.chmod(0o600)
    # 排他锁覆盖 Git 创建与文档发布的完整临界区。
    lockFile.flock(File::LOCK_EX)
    # 取得锁后再次检查目录链，缩小创建前的软链接竞态窗口。
    WorktreeSupport.prepareWorktreesRoot(worktreesRoot, targetPath)
    # 已存在目标无论是否为空都不覆盖，防止误接管遗留目录。
    raise WorktreeSupport::LifecycleError, "worktree 目标已存在：#{targetPath}" if targetPath.exist?
    # 先确认 workspace 中没有仍在使用或待清理的同仓库记录。
    if workspacePath.read.include?(WorktreeSupport::LIFECYCLE_HEADING)
      # 没有记录是正常的新仓库；只有找到记录时才判断状态。
      begin
        existingRecord = WorktreeSupport.readLifecycle(workspacePath, repositoryName)
        # 已删除记录允许以后重新创建；其他状态都必须先人工处理。
        unless existingRecord[:state] == "已删除"
          # 不覆盖仍在使用、待清理或明确保留的历史目录。
          raise WorktreeSupport::LifecycleError, "该仓库已有未结束的 worktree 生命周期：#{existingRecord[:state]}"
        end
      rescue WorktreeSupport::LifecycleError => error
        # “未找到”只表示章节里暂时没有这个仓库，不属于阻断。
        raise unless error.message.start_with?("未找到受控")
      end
    end
    # 查询分支是否已经存在；状态 1 是正常的“不存在”。
    # 分支存在时不改它的指向，避免脚本把已有成果重置到 startRef。
    _branchOutput, _branchError, branchStatus = WorktreeSupport.runGit(
      sourcePath,
      "show-ref",
      "--verify",
      "--quiet",
      "refs/heads/#{branchName}",
      allowedStatuses: [0, 1]
    )
    # 已有分支直接挂载，不新建或重置它。
    gitArguments = branchStatus.zero? ? ["worktree", "add", targetPath.to_s, branchName] : ["worktree", "add", "-b", branchName, targetPath.to_s, startRef]
    # Git 自己检查分支是否已被其他 worktree 占用。
    WorktreeSupport.runGit(sourcePath, *gitArguments)
    begin
      # 创建成功后读取实际 HEAD，作为后续清理的证据起点。
      createdHead, = WorktreeSupport.runGit(targetPath, "rev-parse", "HEAD")
      # 一次取时间供生命周期表使用，避免同一动作出现两个时间。
      createdAt = Time.now.iso8601
      # 先更新产品基线行，把实际操作路径切到受控 worktree。
      updatedContent = WorktreeSupport.upsertBaseline(
        workspacePath.read,
        repositoryName: repositoryName,
        checkoutPath: targetPath,
        isolationMode: "独立 worktree",
        branchName: branchName,
        headValue: createdHead.strip,
        statusNote: "尚未采集"
      )
      # 再写入完整生命周期证据，状态从创建完成起为“使用中”。
      updatedContent = WorktreeSupport.upsertLifecycle(
        updatedContent,
        repository: repositoryName,
        sourcePath: sourcePath,
        targetPath: targetPath,
        branchName: branchName,
        createdHead: createdHead.strip,
        createdAt: createdAt,
        state: "使用中"
      )
      # Git 和文档都准备完成后才原子发布 workspace.md。
      WorktreeSupport.writeWorkspace(workspacePath, updatedContent)
    rescue StandardError
      # 文档发布失败时撤销刚创建且尚未使用的干净 worktree。
      WorktreeSupport.runGit(sourcePath, "worktree", "remove", targetPath.to_s)
      # prune 清理 Git 可能保留的管理记录，不删除刚创建的分支。
      WorktreeSupport.runGit(sourcePath, "worktree", "prune")
      # 清理空父目录，但保留 .worktrees 根目录和锁文件。
      WorktreeSupport.removeEmptyParents(targetPath, worktreesRoot)
      # 将原始错误继续交给统一错误出口。
      raise
    end
  end
  # 输出可直接登记或进入的绝对 worktree 路径。
  puts targetPath
rescue WorktreeSupport::LifecycleError => error
  # 预期输入或 Git 状态错误只输出一行并使用非零退出码。
  warn error.message
  # exit 1 便于 Agent 和回归测试稳定判断失败。
  exit 1
end
