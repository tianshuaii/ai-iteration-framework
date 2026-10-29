#!/usr/bin/env ruby

# 本模块只负责运行校验器案例和断言公开结果。
# 夹具构造由 validator-test-fixture-support.rb 统一提供。
# 通过原参数数组调用子进程，继续避免 shell 拼接用户原话。
# 本文件只在框架自身回归中加载，不参与业务迭代恢复。

require_relative "validator-test-fixture-support"
require_relative "capability-digest-support"

# 在独立临时副本中运行一个预期失败的案例。
def runFailureCase(_frameworkRoot, caseName, expectedText)
  # 每个案例使用自己的临时父目录，避免互相污染。
  Dir.mktmpdir("ai-iteration-validator-") do |temporaryRoot|
    # caseRoot 是校验器推导框架根目录时看到的真实目录。
    caseRoot = Pathname.new(temporaryRoot).realpath.join("framework")
    # 从只读合法基线复制，省去每个案例重复的两次审批和一次总览刷新。
    copyPreparedFixture(caseRoot)
    # 由调用方只修改这个临时副本。
    yield(caseRoot)
    # 捕获标准输出、错误输出和退出码。
    stdout, stderr, status = Open3.capture3("ruby", "scripts/validate-framework.rb", chdir: caseRoot.to_s)
    # 失败案例若返回零，说明门禁已经失效。
    raise "#{caseName}: validator unexpectedly passed" if status.success?
    # 合并输出后检查人可读错误信息。
    combinedOutput = "#{stdout}\n#{stderr}"
    # 错误文本缺失会降低定位能力，也视为测试失败。
    raise "#{caseName}: missing #{expectedText.inspect}\n#{combinedOutput}" unless combinedOutput.include?(expectedText)
  end
end

# 在独立临时副本中运行一个预期成功的案例。
def runSuccessCase(_frameworkRoot, caseName)
  # 每个案例使用自己的临时目录，成功夹具也不会污染真实框架。
  Dir.mktmpdir("ai-iteration-validator-") do |temporaryRoot|
    # caseRoot 保持与失败案例相同的目录层级。
    caseRoot = Pathname.new(temporaryRoot).realpath.join("framework")
    # 成功案例与失败案例共享同一合法起点，但后续修改仍在独立副本中。
    copyPreparedFixture(caseRoot)
    # 在案例可能把唯一活动轮次切成 done 前先保存系统路径。
    systemPath, _iterationPath = locateActiveIteration(caseRoot)
    # 调用方创建需要被允许的场景。
    yield(caseRoot)
    # 成功夹具新增轮次或修改状态后，按框架要求刷新派生总览。
    # 统一在断言前刷新，避免每个合法并发场景重复手写生命周期步骤。
    refreshOverview(caseRoot, systemPath)
    # 捕获校验结果，避免成功输出刷满回归日志。
    stdout, stderr, status = Open3.capture3("ruby", "scripts/validate-framework.rb", chdir: caseRoot.to_s)
    # 非零退出说明合法场景仍被错误阻断。
    raise "#{caseName}: validator unexpectedly failed: #{stdout}\n#{stderr}" unless status.success?
  end
end

# 验证托管 CI 能在没有个人产品仓库和知识库目标时执行同一条全局命令。
def runPortableValidationCase(_frameworkRoot)
  # 案例继续使用独立临时副本，不触碰真实外部目录。
  Dir.mktmpdir("ai-iteration-portable-validator-") do |temporaryRoot|
    # 临时框架沿用其他案例的目录层级和合法基线。
    caseRoot = Pathname.new(temporaryRoot).realpath.join("framework")
    # 复制准备好的档案，确保只改变外部实体可用性这一项。
    copyPreparedFixture(caseRoot)
    # 找到合成系统和产品检出，后续只移除临时实体。
    systemPath, _iterationPath = locateActiveIteration(caseRoot)
    # 删除产品检出模拟 GitHub 托管 runner 没有用户机器上的仓库。
    FileUtils.remove_entry(caseRoot.join("validator-checkout"))
    # 建立指向不存在外部目录的绝对软链接，模拟知识库不会随 Git 仓库分发。
    systemPath.join("knowledge-base").make_symlink(Pathname.new("/missing/ai-iteration-framework-knowledge"))
    # overview 中的链接让断链检查真实经过这个外部软链接。
    overviewPath = systemPath.join("overview.md")
    # 追加稳定说明不会改变自动生成状态投影。
    overviewPath.write("#{overviewPath.read}\n知识库：[外部说明](./knowledge-base/README.md)\n")
    # 本机完整模式必须继续发现缺失外部实体，证明默认门禁没有被放宽。
    # 显式删除父进程可能带入的 CI 变量，保证本断言始终覆盖本机默认模式。
    localEnvironment = { "AI_ITERATION_FRAMEWORK_PORTABLE_VALIDATION" => nil }
    # 环境清理与命令参数都通过 spawn 接口传递，不依赖 shell 展开。
    _localOutput, _localError, localStatus = Open3.capture3(localEnvironment, "ruby", "scripts/validate-framework.rb", chdir: caseRoot.to_s)
    # 如果默认模式通过，说明 CI 兼容逻辑意外影响了本机校验。
    raise "local validator unexpectedly ignored missing external paths" if localStatus.success?
    # 可移植模式只通过显式环境变量启用，命令本身与 README 四条命令一致。
    portableEnvironment = { "AI_ITERATION_FRAMEWORK_PORTABLE_VALIDATION" => "1" }
    # 参数数组和环境 Hash 都不经过 shell，测试不引入命令注入面。
    portableOutput, portableError, portableStatus = Open3.capture3(portableEnvironment, "ruby", "scripts/validate-framework.rb", chdir: caseRoot.to_s)
    # 非零退出表示托管 CI 仍被本机外部实体耦合。
    raise "portable validator unexpectedly failed: #{portableOutput}\n#{portableError}" unless portableStatus.success?
    # 成功文案必须显式标记可移植模式，不能伪装成本机完整校验。
    raise "portable validator omitted its scope" unless portableOutput.include?("OK: portable framework validation passed")
    # 再制造一个不经过外部软链接的仓库内部断链，验证 CI 模式没有跳过普通错误。
    overviewPath.write("#{overviewPath.read}\n内部：[缺失说明](./missing-internal.md)\n")
    # 同一可移植环境下重新执行，唯一新增变量是内部断链。
    internalOutput, internalError, internalStatus = Open3.capture3(portableEnvironment, "ruby", "scripts/validate-framework.rb", chdir: caseRoot.to_s)
    # 如果仍然通过，说明兼容逻辑错误扩大成了全局断链豁免。
    raise "portable validator ignored internal broken link" if internalStatus.success?
    # 错误必须明确指向断链，避免由其他无关门禁造成假阳性。
    raise "portable broken-link diagnostic missing: #{internalOutput}\n#{internalError}" unless "#{internalOutput}\n#{internalError}".include?("断链")
  end
end

# 调用临时框架自己的恢复入口，并精确断言最后一行读取建议。
def assertFixtureReadNext(caseRoot, iterationPath, expectedFiles, intent: nil)
  # 参数数组直接传给 Open3，不经过 shell 拼接，测试也遵守用户原话安全边界。
  arguments = ["ruby", "scripts/iteration-context.rb", iterationPath.to_s]
  # 只有案例明确提供原话时才启用意图路由，纯恢复继续覆盖单参数兼容路径。
  arguments += ["--intent", intent] if intent
  # 子进程从复制后的框架根执行，确保 require 和路径约束与真实调用一致。
  stdout, stderr, status = Open3.capture3(*arguments, chdir: caseRoot.to_s)
  # 命令失败时保留完整诊断，不能把缺失输出误报成读取集合不一致。
  raise "iteration context failed: #{stdout}\n#{stderr}" unless status.success?
  # read_next 是稳定的末端公开契约，但按前缀查找可容忍后续增加其他摘要字段。
  readLine = stdout.lines.find { |line| line.start_with?("- read_next: ") }
  # 缺失字段属于入口契约破坏，单独给出比空数组比较更清楚的错误。
  raise "iteration context omitted read_next: #{stdout}" unless readLine
  # 空集合使用与生产脚本一致的中文哨兵，非空集合保持传入顺序。
  expectedSummary = expectedFiles.empty? ? "无" : expectedFiles.join(", ")
  # 精确比较可同时发现多读、漏读和顺序漂移。
  actualSummary = readLine.sub("- read_next: ", "").strip
  # 失败信息同时展示期望和实际，定位时不需要重跑整套回归。
  raise "unexpected read_next: expected #{expectedSummary.inspect}, got #{actualSummary.inspect}" unless actualSummary == expectedSummary
end

# 验证任务级摘要只对当前任务和共享写入上界敏感，不再绑定整份任务清单。
def runTaskGuardDigestIsolationCase(_frameworkRoot)
  # 使用临时框架和合成轮次，测试不会修改真实业务档案。
  Dir.mktmpdir("ai-iteration-task-digest-") do |temporaryRoot|
    # 目录层级与其他校验器夹具保持一致，所有相对路径仍能正常解析。
    caseRoot = Pathname.new(temporaryRoot).realpath.join("framework")
    # 摘要案例同样从准备好的合法基线开始，避免无关 CLI 启动成本。
    copyPreparedFixture(caseRoot)
    # 取得合成轮次，摘要算法只读取本轮文件。
    _systemPath, iterationPath = locateActiveIteration(caseRoot)
    # 合成迁移夹具的运行期 workspace 没有计划区；本案例改用新模板结构。
    FileUtils.cp(caseRoot.join("templates", "workspace.md"), iterationPath.join("workspace.md"))
    # 首次摘要代表 T-01 写入前的稳定输入。
    originalDigest = CapabilityDigestSupport.implementationGuardDigest(iterationPath, "T-01")
    # 新增另一任务模拟计划返工追加 T-02，不改变 T-01 自身或共享范围。
    tasksPath = iterationPath.join("tasks.md")
    tasksPath.write("#{tasksPath.read}- [ ] T-02 另一项独立工作。依赖：无。文件：`other.txt`。检查：`ruby -v`\n")
    # T-01 摘要必须保持不变，否则仍会出现跨任务连锁失效。
    raise "unrelated task changed T-01 guard digest" unless CapabilityDigestSupport.implementationGuardDigest(iterationPath, "T-01") == originalDigest
    # 改动范围属于所有任务共享的写入上界，变化后必须要求守卫重新执行。
    changeScopePath = iterationPath.join("change-scope.md")
    # 保存原文，单变量断言完成后恢复，避免影响后面的任务正文案例。
    originalChangeScope = changeScopePath.read
    # 在范围末尾增加一项明确边界，模拟审批后共享写入范围变化。
    changeScopePath.write("#{originalChangeScope}\n范围摘要回归变更。\n")
    # 共享范围变化后旧摘要不能继续放行写入。
    raise "change scope did not invalidate task guard digest" if CapabilityDigestSupport.implementationGuardDigest(iterationPath, "T-01") == originalDigest
    # 恢复范围后摘要必须回到原值，证明计算没有隐藏状态。
    changeScopePath.write(originalChangeScope)
    # workspace 只绑定计划审批区，先保存完整模板供断言后恢复。
    workspacePath = iterationPath.join("workspace.md")
    # 只改计划区中的目标分支占位，不触碰运行期 HEAD 或 dirty 字段。
    originalWorkspace = workspacePath.read
    changedWorkspace = originalWorkspace.sub("|  |  | 独立 worktree / 共享检出 |  |", "| 示例仓库 | /tmp/example | 共享检出 | main |")
    # 计划检出决定变化同样必须使当前任务守卫失效。
    workspacePath.write(changedWorkspace)
    raise "workspace plan scope did not invalidate task guard digest" if CapabilityDigestSupport.implementationGuardDigest(iterationPath, "T-01") == originalDigest
    # 恢复 workspace 后再验证任务自己的变化，保持每个断言只有一个变量。
    workspacePath.write(originalWorkspace)
    # 修改 T-01 自身的文件范围，证明精简没有放松当前任务的过期检测。
    tasksPath.write(tasksPath.read.sub("文件：`fixture.txt`", "文件：`fixture-updated.txt`"))
    # 自身语义变化后旧守卫必须失效。
    raise "current task change did not invalidate guard digest" if CapabilityDigestSupport.implementationGuardDigest(iterationPath, "T-01") == originalDigest
  end
end

# 验证局部校验只深入目标轮次，同时继续检查通用框架契约。
def runScopedValidationIsolationCase(_frameworkRoot)
  # 每次使用独立临时副本，确保故障轮次不会污染其他回归案例。
  Dir.mktmpdir("ai-iteration-scoped-validator-") do |temporaryRoot|
    # 建立与真实命令相同的框架根目录布局。
    caseRoot = Pathname.new(temporaryRoot).realpath.join("framework")
    # 局部与全局校验都基于同一合法快照，只额外制造一个无关坏轮次。
    copyPreparedFixture(caseRoot)
    # 保存局部命令应检查的目标轮次。
    systemPath, iterationPath = locateActiveIteration(caseRoot)
    # 复制一轮并损坏 phase，模拟同系统中与当前工作无关的历史档案问题。
    brokenPath = systemPath.join("iterations", "999-2099-12-31-无关坏轮次")
    FileUtils.cp_r(iterationPath, brokenPath)
    # 非法阶段会稳定阻断无参数全局校验。
    brokenStatusPath = brokenPath.join("status.md")
    brokenStatusPath.write(brokenStatusPath.read.sub(/^- phase: .+$/, "- phase: broken"))
    # 局部命令必须只深入目标轮次并输出明确的范围成功文案。
    scopedOutput, scopedError, scopedStatus = Open3.capture3("ruby", "scripts/validate-framework.rb", "--iteration", iterationPath.to_s, chdir: caseRoot.to_s)
    # 任何失败都说明局部模式仍被无关档案污染。
    raise "scoped validator unexpectedly failed: #{scopedOutput}\n#{scopedError}" unless scopedStatus.success?
    # 成功文案必须防止调用方把局部绿色误报成全局绿色。
    raise "scoped validator did not label its scope" unless scopedOutput.include?("OK: scoped iteration validation passed")
    # 无参数校验必须继续发现坏轮次，证明局部入口没有放宽全局治理。
    _globalOutput, _globalError, globalStatus = Open3.capture3("ruby", "scripts/validate-framework.rb", chdir: caseRoot.to_s)
    # 如果全局也通过，说明测试没有真正制造隔离场景。
    raise "global validator unexpectedly ignored unrelated broken iteration" if globalStatus.success?
  end
end
