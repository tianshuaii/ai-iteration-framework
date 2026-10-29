#!/usr/bin/env ruby

# 本回归只在系统临时目录创建 Git 仓库、框架副本和 worktree。
# 它覆盖固定路径创建、目标分支同步、workspace.md 记录和安全清理。
# 测试不会读取或修改任何已登记产品仓库，也不会留下功能分支。
# 所有 Git 用户信息只配置在临时仓库，避免依赖全局账号设置。
# 子进程使用参数数组运行，和真实入口保持相同的调用方式。
# 每个关键状态都同时检查文件系统、Git 元数据和迭代文档。
# 临时根目录退出后自动清理，不在真实框架创建 .worktrees。

require "fileutils"
require "open3"
require "pathname"
require "tmpdir"

# 真实框架只用于复制被测脚本和 workspace 模板。
frameworkRoot = Pathname.new(__dir__).join("..").realpath

# 执行命令并在失败时带出完整上下文。
def runCommand(*arguments, chdir:)
  # capture3 避免测试过程输出干扰最终成功信息。
  stdout, stderr, status = Open3.capture3(*arguments, chdir: chdir.to_s)
  # 调用方需要同时检查成功和预期失败，因此不在这里 raise。
  [stdout, stderr, status]
end

# 临时目录同时容纳框架副本和框架外产品仓库。
Dir.mktmpdir("ai-iteration-worktree-test-") do |temporaryRoot|
  # Pathname 让所有路径拼接保持清晰且不依赖当前 shell。
  temporaryPath = Pathname.new(temporaryRoot).realpath
  # 框架副本与产品仓库分离，验证 overview 是唯一来源。
  caseRoot = temporaryPath.join("framework")
  # 产品仓库故意放在框架外，符合真实使用边界。
  sourcePath = temporaryPath.join("product-repository")
  # 裸远端用于验证真实的 pull --ff-only，而不是伪造本地引用。
  remotePath = temporaryPath.join("product-remote.git")
  # 独立集成副本模拟功能分支已经合入并推送到目标分支。
  integratorPath = temporaryPath.join("product-integrator")
  # 合成系统和轮次都使用合法目录层级。
  systemPath = caseRoot.join("systems", "example-system")
  # 中文主题同时覆盖目标目录对非 ASCII 名称的处理。
  iterationPath = systemPath.join("iterations", "001-2026-10-23-并发开发")
  # 创建脚本、模板、系统入口和轮次目录。
  FileUtils.mkdir_p([caseRoot.join("scripts"), iterationPath])
  # 四个被测脚本保持原有相对位置，require_relative 才能生效。
  %w[worktree-support.rb create-worktree.rb sync-worktree.rb cleanup-worktree.rb].each do |scriptName|
    # 仅复制框架脚本，不复制真实系统或 .worktrees。
    FileUtils.cp(frameworkRoot.join("scripts", scriptName), caseRoot.join("scripts", scriptName))
  end
  # 系统入口只需存在，内容不参与生命周期脚本解析。
  systemPath.join("AGENTS.md").write("# 测试入口\n")
  # 先创建一个独立产品 Git 仓库。
  FileUtils.mkdir_p(sourcePath)
  # git init 的默认分支名由本机配置决定，测试后动态读取。
  _initOutput, initError, initStatus = runCommand("git", "init", chdir: sourcePath)
  # 初始化失败时立即报告环境问题。
  raise "git init failed: #{initError}" unless initStatus.success?
  # 测试身份只写临时仓库本地配置。
  runCommand("git", "config", "user.name", "Framework Test", chdir: sourcePath)
  # 邮箱同样不会写入用户全局 Git 配置。
  runCommand("git", "config", "user.email", "framework-test@example.invalid", chdir: sourcePath)
  # 初始文件用于制造和恢复 dirty worktree。
  sourcePath.join("fixture.txt").write("initial\n")
  # 提交初始版本，使 HEAD 可以成为 worktree 起点。
  runCommand("git", "add", "fixture.txt", chdir: sourcePath)
  # 初次提交失败说明测试环境不可用。
  _commitOutput, commitError, commitStatus = runCommand("git", "commit", "-m", "initial", chdir: sourcePath)
  # 把真实错误保留在断言中。
  raise "initial commit failed: #{commitError}" unless commitStatus.success?
  # 读取原仓库实际分支，不假设 main 或 master。
  sourceBranchOutput, _sourceBranchError, sourceBranchStatus = runCommand("git", "branch", "--show-current", chdir: sourcePath)
  # 普通初始化仓库应处于一个命名分支。
  raise "source branch missing" unless sourceBranchStatus.success? && !sourceBranchOutput.strip.empty?
  # 建立本地裸远端，使原仓库目标分支具备明确上游。
  _remoteInitOutput, remoteInitError, remoteInitStatus = runCommand("git", "init", "--bare", remotePath.to_s, chdir: temporaryPath)
  # 裸远端初始化失败时无法验证拉取流程。
  raise "remote init failed: #{remoteInitError}" unless remoteInitStatus.success?
  # 原仓库只登记测试远端，不依赖用户全局 remote 配置。
  runCommand("git", "remote", "add", "origin", remotePath.to_s, chdir: sourcePath)
  # 首次推送同时建立当前目标分支的 upstream。
  _initialPushOutput, initialPushError, initialPushStatus = runCommand("git", "push", "-u", "origin", sourceBranchOutput.strip, chdir: sourcePath)
  # 推送失败说明测试远端不可用。
  raise "initial push failed: #{initialPushError}" unless initialPushStatus.success?
  # overview 使用标准四列表格和绝对原仓库路径。
  systemPath.join("overview.md").write("# 测试系统\n\n| 仓库 | 绝对路径 | 职责 | 常用检查命令 |\n|---|---|---|---|\n| `product-repository` | `#{sourcePath}` | 测试 | `git status` |\n")
  # workspace 从真实模板复制，覆盖版本标记和空生命周期表。
  FileUtils.cp(frameworkRoot.join("templates", "workspace.md"), iterationPath.join("workspace.md"))
  # 入口脚本路径使用副本内绝对位置，调用目录可保持框架根。
  createScript = caseRoot.join("scripts", "create-worktree.rb").to_s
  # 清理入口与创建入口使用相同轮次参数。
  cleanupScript = caseRoot.join("scripts", "cleanup-worktree.rb").to_s
  # 同步入口显式接收目标分支，避免测试默认 main 或 master。
  syncScript = caseRoot.join("scripts", "sync-worktree.rb").to_s
  # 功能分支显式指定，验证脚本不会硬编码分支名。
  featureBranch = "iteration-001-worktree-test"
  # 先让原仓库出现未提交修改，证明 dirty 本身不能触发 worktree。
  sourcePath.join("fixture.txt").write("source dirty\n")
  # 当前没有其他产品阶段轮次，创建命令必须被新的并行门禁拒绝。
  _dirtyOnlyOutput, dirtyOnlyError, dirtyOnlyStatus = runCommand("ruby", createScript, iterationPath.to_s, "product-repository", featureBranch, chdir: caseRoot)
  # 错误要明确说明 dirty 不触发，且不能提前留下临时目录或 Git 分支。
  unless !dirtyOnlyStatus.success? && dirtyOnlyError.include?("未提交修改不触发") && !caseRoot.join(".worktrees").exist?
    # 失败说明脚本仍可能把普通未提交状态误当成隔离理由。
    raise "dirty-only worktree create was not blocked"
  end
  # 回归后续同步流程要求真实仓库干净，因此恢复测试自己制造的改动。
  _sourceRestoreOutput, sourceRestoreError, sourceRestoreStatus = runCommand("git", "checkout", "--", "fixture.txt", chdir: sourcePath)
  # 恢复失败时不继续，以免后面的同步失败掩盖并行门禁结果。
  raise "source fixture restore failed: #{sourceRestoreError}" unless sourceRestoreStatus.success?
  # 创建另一条 implement 轮次，作为同一仓库的真实并行占用证据。
  parallelIterationPath = systemPath.join("iterations", "002-2026-10-23-并发实现")
  # 只写门禁读取的两个文件，避免测试依赖完整迭代模板的无关字段。
  FileUtils.mkdir_p(parallelIterationPath)
  # status.md 是阶段唯一来源；implement 明确表示会接触产品代码。
  parallelIterationPath.join("status.md").write("# 状态\n\n- phase: implement\n")
  # 七列产品基线登记同一仓库和真实检出路径，形成允许隔离的条件。
  parallelIterationPath.join("workspace.md").write(<<~MARKDOWN)
    # 产品仓库基线

    | 仓库 | 产品检出路径 | 隔离方式 | 分支 | HEAD | 接管前状态 | 当前任务涉及的文件 |
    |---|---|---|---|---|---|---|
    | `product-repository` | `#{sourcePath}` | 共享检出 | `#{sourceBranchOutput.strip}` | `fixture` | 无 | `fixture.txt` |
  MARKDOWN
  # 创建命令应成功并输出唯一受控目标。
  createOutput, createError, createStatus = runCommand("ruby", createScript, iterationPath.to_s, "product-repository", featureBranch, chdir: caseRoot)
  # 失败信息便于直接定位脚本实现。
  raise "create worktree failed: #{createError}" unless createStatus.success?
  # 目标路径必须位于框架根目录的固定隐藏目录。
  expectedTarget = caseRoot.join(".worktrees", "example-system", iterationPath.basename, "product-repository")
  # 输出、目录和 Git 工作区三者必须一致。
  raise "unexpected worktree target" unless createOutput.strip == expectedTarget.to_s && expectedTarget.directory?
  # workspace 必须切换产品路径并记录使用中生命周期。
  workspaceContent = iterationPath.join("workspace.md").read
  # 路径和状态同时出现才算发布完成。
  raise "workspace creation record missing" unless workspaceContent.include?("`#{expectedTarget}` | 独立 worktree") && workspaceContent.include?("| 使用中 | 无 |")
  # 第一条仓库应替换模板占位行，不能在空行之后形成脱离表头的伪表格。
  raise "workspace placeholder was not replaced" if workspaceContent.include?("|  |  | 独立 worktree / 共享检出 |  |  | 尚未采集 |  |")
  # 重复创建不能覆盖已有目标或生命周期。
  _duplicateOutput, duplicateError, duplicateStatus = runCommand("ruby", createScript, iterationPath.to_s, "product-repository", featureBranch, chdir: caseRoot)
  # 非零退出且说明目标存在才是预期阻断。
  raise "duplicate create was not blocked" if duplicateStatus.success? || !duplicateError.include?("目标已存在")
  # 修改 tracked 文件制造未提交状态。
  expectedTarget.join("fixture.txt").write("dirty\n")
  # 脏 worktree 不能进入同步流程，目录必须继续保留。
  _dirtyOutput, dirtyError, dirtyStatus = runCommand("ruby", syncScript, iterationPath.to_s, "product-repository", sourceBranchOutput.strip, chdir: caseRoot)
  # 错误必须明确指出未提交或未跟踪文件。
  raise "dirty sync was not blocked" if dirtyStatus.success? || !dirtyError.include?("未提交或未跟踪") || !expectedTarget.directory?
  # 仅在临时测试 worktree 恢复 tracked 文件，为成功清理准备干净状态。
  _restoreOutput, restoreError, restoreStatus = runCommand("git", "checkout", "--", "fixture.txt", chdir: expectedTarget)
  # 恢复失败时不继续，以免把 dirty 状态误当成清理成功。
  raise "fixture restore failed: #{restoreError}" unless restoreStatus.success?
  # 新增并提交成果，验证清理后分支和最终 HEAD 都保留。
  expectedTarget.join("result.txt").write("result\n")
  # add 和 commit 都只作用于临时功能分支。
  runCommand("git", "add", "result.txt", chdir: expectedTarget)
  # 提交后的 HEAD 应与创建 HEAD 不同。
  _resultCommitOutput, resultCommitError, resultCommitStatus = runCommand("git", "commit", "-m", "result", chdir: expectedTarget)
  # 失败时保留 Git 原始信息。
  raise "result commit failed: #{resultCommitError}" unless resultCommitStatus.success?
  # 清理前保存最终 HEAD，稍后与文档记录比较。
  finalHeadOutput, _finalHeadError, finalHeadStatus = runCommand("git", "rev-parse", "HEAD", chdir: expectedTarget)
  # HEAD 查询必须成功且非空。
  raise "final head missing" unless finalHeadStatus.success? && !finalHeadOutput.strip.empty?
  # 没有同步证据时，即使 worktree 已经提交且干净也不能删除。
  _unsyncedCleanupOutput, unsyncedCleanupError, unsyncedCleanupStatus = runCommand("ruby", cleanupScript, iterationPath.to_s, "product-repository", chdir: caseRoot)
  # 错误必须指向缺少成果同步记录，且目录仍然存在。
  if unsyncedCleanupStatus.success? || !unsyncedCleanupError.include?("未找到 worktree 成果同步记录") || !expectedTarget.directory?
    # 任一条件不满足都说明清理门禁失效。
    raise "unsynced cleanup was not blocked"
  end
  # 目标上游尚未包含功能提交时，pull 成功本身不能伪装成同步成功。
  _prematureSyncOutput, prematureSyncError, prematureSyncStatus = runCommand("ruby", syncScript, iterationPath.to_s, "product-repository", sourceBranchOutput.strip, chdir: caseRoot)
  # 同步必须失败并明确要求先完成成果分支的推送与合并。
  if prematureSyncStatus.success? || !prematureSyncError.include?("仍不包含 worktree 最终提交")
    # 失败信息漂移会让 Agent 无法给出正确下一步。
    raise "premature sync was not blocked"
  end
  # 把成果分支推到测试远端，后续集成副本才能合入目标分支。
  _featurePushOutput, featurePushError, featurePushStatus = runCommand("git", "push", "-u", "origin", featureBranch, chdir: expectedTarget)
  # 功能分支推送失败时不继续伪造目标分支集成。
  raise "feature push failed: #{featurePushError}" unless featurePushStatus.success?
  # 单独克隆目标分支，避免在真实目录或受控 worktree 中切换分支。
  _cloneOutput, cloneError, cloneStatus = runCommand("git", "clone", "--branch", sourceBranchOutput.strip, remotePath.to_s, integratorPath.to_s, chdir: temporaryPath)
  # 克隆失败时无法模拟远端已经合并的真实前置条件。
  raise "integrator clone failed: #{cloneError}" unless cloneStatus.success?
  # 集成副本使用临时身份，不污染用户全局 Git 配置。
  runCommand("git", "config", "user.name", "Framework Integrator", chdir: integratorPath)
  # 邮箱同样只写在临时克隆中。
  runCommand("git", "config", "user.email", "framework-integrator@example.invalid", chdir: integratorPath)
  # 功能分支严格快进合入目标分支，本用例不制造无关合并提交。
  _mergeOutput, mergeError, mergeStatus = runCommand("git", "merge", "--ff-only", "origin/#{featureBranch}", chdir: integratorPath)
  # 快进失败表示测试提交图不符合预期。
  raise "integrator merge failed: #{mergeError}" unless mergeStatus.success?
  # 把已经包含成果提交的目标分支推回上游。
  _targetPushOutput, targetPushError, targetPushStatus = runCommand("git", "push", "origin", sourceBranchOutput.strip, chdir: integratorPath)
  # push 成功后原仓库才有可拉取的新提交。
  raise "target push failed: #{targetPushError}" unless targetPushStatus.success?
  # 受控同步应在真实目录执行快进拉取并写入验证证据。
  syncOutput, syncError, syncStatus = runCommand("ruby", syncScript, iterationPath.to_s, "product-repository", sourceBranchOutput.strip, chdir: caseRoot)
  # 输出必须同时包含真实路径、目标分支和同步后的最终 HEAD。
  unless syncStatus.success? && syncOutput.include?(sourcePath.to_s) && syncOutput.include?(sourceBranchOutput.strip) && syncOutput.include?(finalHeadOutput.strip)
    # 带出原始错误便于定位网络、分支或祖先验证问题。
    raise "sync worktree result failed: #{syncError}"
  end
  # 真实目录现在必须已经取得 worktree 中提交的文件。
  raise "source repository was not updated" unless sourcePath.join("result.txt").read == "result\n"
  # workspace 同步表必须留下目标分支、两端 HEAD 和固定通过状态。
  syncedWorkspaceContent = iterationPath.join("workspace.md").read
  # 本测试是快进合入，因此原仓库同步 HEAD 与 worktree 最终 HEAD 相同。
  unless syncedWorkspaceContent.include?("## worktree 成果同步") && syncedWorkspaceContent.include?("`#{sourceBranchOutput.strip}` | `#{finalHeadOutput.strip}` | `#{finalHeadOutput.strip}`") && syncedWorkspaceContent.include?("| 已同步验证 |")
    # 缺少任一证据都不能允许后续清理。
    raise "workspace sync record missing"
  end
  # 同步后新增未跟踪文件，验证清理脚本仍会独立复核 worktree dirty 状态。
  expectedTarget.join("late-untracked.txt").write("late\n")
  # 已有同步证据不能绕过清理时的实时状态检查。
  _lateCleanupOutput, lateCleanupError, lateCleanupStatus = runCommand("ruby", cleanupScript, iterationPath.to_s, "product-repository", chdir: caseRoot)
  # 目录必须保留，错误继续指出未提交或未跟踪文件。
  if lateCleanupStatus.success? || !lateCleanupError.include?("未提交或未跟踪") || !expectedTarget.directory?
    # 任一条件不满足都说明二次保护失效。
    raise "dirty cleanup after sync was not blocked"
  end
  # 只删除测试刚创建的未跟踪夹具，恢复可清理状态。
  FileUtils.rm(expectedTarget.join("late-untracked.txt"))
  # 同步并验证通过后，干净 worktree 才能由原生命令安全移除。
  cleanupOutput, cleanupError, cleanupStatus = runCommand("ruby", cleanupScript, iterationPath.to_s, "product-repository", chdir: caseRoot)
  # 清理失败时输出完整原因。
  raise "cleanup worktree failed: #{cleanupError}" unless cleanupStatus.success?
  # 命令输出精确目标且目录已经不存在。
  raise "worktree directory was not removed" unless cleanupOutput.strip == expectedTarget.to_s && !expectedTarget.exist?
  # Git 管理列表不能再包含已经删除的临时路径。
  worktreeListOutput, _worktreeListError, worktreeListStatus = runCommand("git", "worktree", "list", "--porcelain", chdir: sourcePath)
  # 残余注册会影响以后复用分支。
  raise "worktree registration remains" unless worktreeListStatus.success? && !worktreeListOutput.include?(expectedTarget.to_s)
  # 功能分支必须仍存在，证明清理没有扩大为删分支。
  _branchOutput, _branchError, branchStatus = runCommand("git", "show-ref", "--verify", "--quiet", "refs/heads/#{featureBranch}", chdir: sourcePath)
  # 非零状态表示成果分支被错误删除。
  raise "feature branch was deleted" unless branchStatus.success?
  # workspace 当前路径恢复原仓库，生命周期保留临时路径和最终 HEAD。
  finalWorkspaceContent = iterationPath.join("workspace.md").read
  # 三项证据一起检查，防止只删目录却没修正文档。
  unless finalWorkspaceContent.include?("`#{sourcePath}` | 共享检出") && finalWorkspaceContent.include?("临时 worktree 已删除；真实仓库目标分支已同步并包含最终 HEAD") && finalWorkspaceContent.include?("`#{finalHeadOutput.strip}`") && finalWorkspaceContent.include?("| 已删除 |")
    # 文档不完整时给出单一明确错误。
    raise "workspace cleanup record missing"
  end
  # 已删除状态重复清理应幂等成功，不再触碰目录。
  repeatOutput, repeatError, repeatStatus = runCommand("ruby", cleanupScript, iterationPath.to_s, "product-repository", chdir: caseRoot)
  # 幂等输出明确告诉 Agent 目标早已删除。
  raise "repeat cleanup was not idempotent: #{repeatError}" unless repeatStatus.success? && repeatOutput.include?("已删除")
  # 仓库名包含上级目录时必须在读取 overview 前阻断。
  _unsafeOutput, unsafeError, unsafeStatus = runCommand("ruby", createScript, iterationPath.to_s, "../product-repository", "unsafe", chdir: caseRoot)
  # 非零状态和安全名称提示共同证明路径逃逸未被接受。
  raise "unsafe repository name accepted" if unsafeStatus.success? || !unsafeError.include?("安全的单段名称")
end

# 所有生命周期场景通过后只输出一行，便于框架回归调用。
puts "OK: worktree lifecycle tests passed"
