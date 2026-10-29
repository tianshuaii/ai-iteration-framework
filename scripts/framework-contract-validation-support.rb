#!/usr/bin/env ruby

# 本模块校验框架入口契约、本地链接和历史文件映射。
# 拆分只收拢重复规则，不增加轮次步骤、证据文件或额外命令。
# 所有检查保持只读，错误继续写入主入口提供的共享数组。
# 直接依赖在模块内显式加载，避免隐藏的 require 顺序。
# 代码保持 Ruby 2.6 兼容，不使用项目外第三方依赖。

require "uri"

# 框架级稳定契约与历史兼容解析集中在同一支持模块。
module FrameworkContractValidation
  # 暴露无状态模块方法，调用方不需要创建校验对象。
  module_function

  # 将错误追加到主入口的共享集合，保留完整批量报告。
  def addError(errors, message)
    # 具体方法负责提供可定位的标签和路径。
    errors << message
  end

  # 检查 Agent 入口是否完整声明用户可见的过程汇报契约。
  def validateProgressReportingContract(errors, agentPath, label, requiredProgressLabels)
    # 文件缺失由入口检查负责，这里避免重复报告同一个根因。
    return unless agentPath.file?

    # 规则必须集中在独立章节，避免四个词散落在别处造成假通过。
    sectionMatch = agentPath.read.match(/^## 过程汇报\s*$\n(.*?)(?=^## |\z)/m)
    # 没有章节时，Agent 不会把这条规则当成稳定协作协议。
    unless sectionMatch
      addError(errors, "#{label} 缺少过程汇报章节")
      return
    end

    # 只检查章节正文，确保结果和用户协作标签都在同一契约里。
    sectionContent = sectionMatch[1]
    # 每个缺失标签单独报告，方便一次补齐而不是反复运行。
    requiredProgressLabels.each do |progressLabel|
      # 缺少任一标签都会再次出现“只报状态”或“不说是否要用户介入”。
      addError(errors, "#{label} 缺少过程汇报标签：#{progressLabel}") unless sectionContent.include?(progressLabel)
    end
  end

  # 检查入口是否明确要求通过创建脚本取得系统级并发锁。
  def validateIterationCreationContract(errors, policyPath, label, requiredMarkers)
    # 文件缺失由各入口自己的结构检查报告，这里不重复制造噪音。
    return unless policyPath.file?

    # 整份入口都属于创建契约，不强制文案必须放在某个固定章节。
    policyContent = policyPath.read
    # 两个稳定标记分别防止脚本入口和禁止绕过规则被后续编辑删掉。
    requiredMarkers.each do |policyMarker|
      # 缺少任一标记都意味着 Agent 仍可能手工创建并绕开文件锁。
      addError(errors, "#{label} 缺少强制创建规则：#{policyMarker}") unless policyContent.include?(policyMarker)
    end
  end

  # 检查入口是否完整声明受控 worktree 的创建、位置和清理命令。
  def validateWorktreePolicyContract(errors, policyPath, label, requiredMarkers)
    # 文件缺失由各入口自己的结构检查负责，这里不重复报告。
    return unless policyPath.file?

    # 整份入口都属于 worktree 使用契约，不限制具体章节名称。
    policyContent = policyPath.read
    # 四个标记共同阻止 Agent 手工创建、跳过同步或遗忘清理。
    requiredMarkers.each do |policyMarker|
      # 每个缺失项单独报告，便于一次补齐创建和收口规则。
      addError(errors, "#{label} 缺少 worktree 生命周期规则：#{policyMarker}") unless policyContent.include?(policyMarker)
    end
  end

  # 检查入口是否完整声明需求和计划的强制用户审批门禁。
  def validateApprovalPolicyContract(errors, policyPath, label, requiredMarkers)
    # 文件缺失由入口结构检查负责，这里不重复报告同一根因。
    return unless policyPath.file?

    # 审批契约允许位于边界或阶段锁章节，不强制具体标题。
    policyContent = policyPath.read
    # 四个标记共同保证记录位置、唯一命令和明确证据都不会被删掉。
    requiredMarkers.each do |policyMarker|
      # 每个缺失项单独报告，方便一次补齐而不是反复试错。
      addError(errors, "#{label} 缺少双审批门禁规则：#{policyMarker}") unless policyContent.include?(policyMarker)
    end
  end

  # 检查入口是否完整声明能力登记、执行证据和总控边界。
  def validateCapabilityPolicyContract(errors, policyPath, label, requiredMarkers)
    # 缺失入口由结构检查负责，这里避免重复同一根因。
    return unless policyPath.file?

    # 能力契约允许放在阶段锁或通用边界，不强制标题位置。
    policyContent = policyPath.read
    # 四个标记共同防止 Agent 只说使用过 Skill 而没有耐久证据。
    requiredMarkers.each do |policyMarker|
      # 每个缺失项单独报告，方便一次补齐所有启动入口。
      addError(errors, "#{label} 缺少能力门禁规则：#{policyMarker}") unless policyContent.include?(policyMarker)
    end
  end

  # 历史轮次可用本地映射把标准名指向同一轮里的旧文件名。
  def readFileMap(iterationPath, errors, label, requiredFiles)
    # 默认没有兼容映射，新轮次直接使用标准英文名。
    fileMap = {}
    # 映射文件只属于当前轮次，不污染通用 prompts。
    mapPath = iterationPath.join("file-map.md")
    # 文件不存在时返回空映射。
    return fileMap unless mapPath.file?

    # 表格两列都使用反引号，降低误解析普通正文的概率。
    mapPath.read.each_line do |line|
      # 只接受“标准文件 -> 实际文件”的简单映射行。
      match = line.match(/^\|\s*`([^`]+)`\s*\|\s*`([^`]+)`\s*\|/)
      # 表头和说明行直接跳过。
      next unless match
      # 分别取标准名和实际名，后续逐项做范围限制。
      standardName = match[1]
      # 实际文件只能是本轮目录下的直接子文件，不能包含路径片段。
      actualName = match[2]
      # status 始终使用固定名称；其他键必须属于标准文档集合。
      allowedNames = requiredFiles - ["status.md"]
      # 未知标准名说明映射表拼错，不能静默忽略。
      unless allowedNames.include?(standardName)
        addError(errors, "#{label} file-map 包含未知标准文件：#{standardName}")
        next
      end
      # 同一个标准名重复出现会让实际解析结果依赖行顺序。
      if fileMap.key?(standardName)
        addError(errors, "#{label} file-map 重复映射：#{standardName}")
        next
      end
      # 禁止绝对路径、斜杠、点目录和上级目录逃逸。
      if actualName != File.basename(actualName) || %w[. ..].include?(actualName)
        addError(errors, "#{label} file-map 目标必须是本轮直接子文件：#{actualName}")
        next
      end
      # 通过范围检查后才保存映射。
      fileMap[standardName] = actualName
    end
    # 返回当前轮次自己的映射结果。
    fileMap
  end

  # 将标准文件名解析为当前轮次里的真实文件名。
  def resolveIterationFile(iterationPath, fileMap, standardName)
    # 历史轮次优先使用本地映射。
    actualName = fileMap.fetch(standardName, standardName)
    # 返回 Pathname，后续检查保持同一种路径类型。
    iterationPath.join(actualName)
  end

  # 检查框架内 Markdown 本地链接，局部模式只深入目标轮次。
  # 判断缺失链接是否经过指向框架外部的软链接。
  # 托管 CI 没有个人知识库目标，但仍要拒绝框架内部真实断链。
  def externalSymlinkAncestor?(frameworkRoot, targetPath)
    # 从目标向框架根逐级回溯，才能识别 knowledge-base/README.md 这类子路径。
    currentPath = targetPath
    # 到达框架根后停止，框架根本身不允许作为外部软链接处理。
    until currentPath == frameworkRoot || currentPath.root?
      # 只有真实软链接祖先才可能把目标转到框架之外。
      if currentPath.symlink?
        # 框架只允许 systems/<system>/knowledge-base 作为外部知识库入口。
        relativeParts = currentPath.relative_path_from(frameworkRoot).each_filename.to_a
        # 其他任意外部软链接仍按普通断链处理，不能借 CI 模式扩大豁免面。
        registeredKnowledgeLink = relativeParts.length == 3 && relativeParts.first == "systems" && relativeParts.last == "knowledge-base"
        # 当前软链接不是登记知识库时立即拒绝豁免，不继续猜测其他祖先。
        return false unless registeredKnowledgeLink
        # 绝对链接直接使用；相对链接则以软链接所在目录解析。
        rawTarget = Pathname.new(currentPath.readlink)
        # 统一展开路径后再判断边界，避免 ../ 片段绕过前缀检查。
        resolvedTarget = rawTarget.absolute? ? rawTarget.expand_path : currentPath.dirname.join(rawTarget).expand_path
        # 目标等于框架根或位于根目录内时仍属于本仓库契约。
        insideFramework = resolvedTarget == frameworkRoot || resolvedTarget.to_s.start_with?("#{frameworkRoot}/")
        # 只把明确指向框架外部的软链接视为可移植依赖。
        return !insideFramework
      end
      # 当前层不是软链接时继续检查父目录。
      currentPath = currentPath.parent
    end
    # 没有外部软链接祖先说明这是普通仓库内断链。
    false
  end

  def validateLocalMarkdownLinks(errors, frameworkRoot, scopedIterationPath, validateExternalPaths: true)
    # Markdown 本地链接必须存在，避免模板复制后留下断链。
    frameworkRoot.glob("**/*.md").each do |markdownPath|
      # 不跟随 knowledge-base 等指向框架外部的目录软链接。
      next unless markdownPath.file?
      # .worktrees 是临时产品源码，不属于框架 Markdown 断链检查范围。
      next if markdownPath.relative_path_from(frameworkRoot).each_filename.first == ".worktrees"
      # 局部模式不扫描其他业务轮次的 Markdown；通用框架、模板和系统入口仍全部检查。
      if scopedIterationPath
        # 只有 systems/<system>/iterations/<iteration>/... 属于可跳过的轮次档案。
        relativeParts = markdownPath.relative_path_from(frameworkRoot).each_filename.to_a
        # 目标轮次本身继续执行完整链接检查，其他轮次留给最终全局校验。
        insideIterationArchive = relativeParts.length >= 5 && relativeParts.first == "systems" && relativeParts[2] == "iterations"
        # 路径前缀比较使用 expand_path，不跟随已被禁止的轮次目录软链接。
        next if insideIterationArchive && !markdownPath.expand_path.to_s.start_with?("#{scopedIterationPath}/")
      end
      # 只扫描标准 Markdown 行内链接。
      markdownPath.read.scan(/\[[^\]]*\]\(([^)]+)\)/).flatten.each do |rawTarget|
        # 远程链接、邮件和页内锚点不属于本地文件校验范围。
        next if rawTarget.match?(/\A(?:https?:|mailto:|#)/)
        # 去掉锚点，只验证链接对应的文件或目录。
        localTarget = rawTarget.split("#", 2).first
        # Markdown 允许用尖括号包裹含中文、空格或括号的链接目标。
        localTarget = localTarget[1...-1] if localTarget.start_with?("<") && localTarget.end_with?(">")
        # 自动总览使用百分号编码保护路径特殊字符，存在性检查前还原真实文件名。
        localTarget = URI::DEFAULT_PARSER.unescape(localTarget)
        # 空目标只代表当前页锚点，不需要检查。
        next if localTarget.empty?
        # 相对链接始终以当前 Markdown 所在目录解析。
        resolvedTarget = markdownPath.dirname.join(localTarget).expand_path
        # 用框架相对路径报告来源，避免输出冗长的用户目录。
        sourceName = markdownPath.relative_path_from(frameworkRoot)
        # 目标存在时无需进入任何 CI 兼容分支。
        next if resolvedTarget.exist?
        # 托管 CI 只忽略经过框架外软链接的目标，不放宽仓库内部链接。
        next if !validateExternalPaths && externalSymlinkAncestor?(frameworkRoot, resolvedTarget)
        # 普通缺失目标仍按原契约报告断链。
        addError(errors, "断链：#{sourceName} -> #{rawTarget}")
      end
    end
  end

end
