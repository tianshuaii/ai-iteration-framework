#!/usr/bin/env ruby

# 本模块只负责能力输入摘要，不解析日志、审批状态或阶段进度。
# 摘要职责从 capability-support.rb 拆出，避免核心解析器继续膨胀。
# 新任务守卫只绑定当前任务和共享写入上界，防止跨任务连锁失效。
# 最终测试与交付能力仍可复用通用多文档摘要，保持现有证据协议。
# 所有路径都通过阶段审批模块解析，历史 file-map 仍然有效。
# 摘要只读取轮次文件，不执行外部命令，也不修改任何状态。

require "digest"
require "pathname"

# 能力证据使用的稳定摘要算法集中在同一命名空间。
module CapabilityDigestSupport
  # 能力日志策略显式区分旧的整轮计划摘要和新的任务级守卫摘要。
  # 旧轮次继续按 v1 读取，避免框架升级要求已经完成的任务补造证据。
  LOG_POLICY_MARKERS = {
    "capability-gates-v1" => "<!-- capability-log-policy: capability-gates-v1 -->",
    "task-guard-digest-v2" => "<!-- capability-log-policy: task-guard-digest-v2 -->"
  }.freeze
  # 新轮次固定采用任务级摘要；兼容只发生在已经落盘的旧日志中。
  DEFAULT_LOG_POLICY = "task-guard-digest-v2"

  # 计算单条实现任务的守卫摘要，避免其他任务变化使已完成守卫连锁过期。
  def self.implementationGuardDigest(iterationPath, taskId)
    # 延迟加载审批模块，避免摘要工具在启动时形成双向依赖。
    require_relative "stage-approval-support"
    # 任务编号属于机器协议，先拒绝自然语言或路径片段进入正则。
    raise "实施守卫任务编号非法：#{taskId}" unless taskId.to_s.match?(/\AT-\d+\z/)
    # 历史轮次仍通过自己的 file-map 定位任务正文。
    tasksPath = StageApproval.resolveIterationFile(iterationPath, "tasks.md")
    # 缺少任务文件时无法证明守卫覆盖了哪个写入单元。
    raise "实施守卫摘要缺少文件：tasks.md" unless tasksPath.file?
    # 只接受唯一的任务行；重复编号不能靠文件顺序选择其中一条。
    taskPattern = /^- \[[ xX]\]\s+#{Regexp.escape(taskId)}\b.*$/
    # 保留完整任务正文，使依赖、文件范围和定向检查变化都会令本任务守卫过期。
    taskLines = tasksPath.read.scan(taskPattern)
    # 找不到或重复都属于任务清单结构错误，不能生成看似稳定的摘要。
    raise "实施守卫摘要要求唯一任务：#{taskId}" unless taskLines.length == 1
    # 完成勾选是执行进度，不应让写入前产生的守卫在任务完成后立即失效。
    canonicalTaskLine = taskLines.first.sub(/^(- )\[[ xX]\]/, '\\1[ ]')

    # 改动范围是所有任务共享的写入上界；范围变化必须重新执行相关守卫。
    changeScopePath = StageApproval.resolveIterationFile(iterationPath, "change-scope.md")
    # 缺少范围正文时不允许仅凭任务行放行产品写入。
    raise "实施守卫摘要缺少文件：change-scope.md" unless changeScopePath.file?
    # workspace 只取计划审批区，运行期 HEAD、dirty 和同步记录不会制造摘要抖动。
    workspacePath = StageApproval.resolveIterationFile(iterationPath, "workspace.md")
    # 产品检出和资源预留是实现前隔离判断的一部分，必须真实存在。
    raise "实施守卫摘要缺少文件：workspace.md" unless workspacePath.file?
    # 复用审批模块的标记边界，不在摘要模块复制另一套 workspace 解析规则。
    workspaceScope = StageApproval.canonicalize("workspace.md", workspacePath.read, policyName: StageApproval::DEFAULT_POLICY)

    # 文件名、任务编号和正文使用 NUL 分隔，避免普通文本拼接出现边界碰撞。
    digestInput = [
      ["task", taskId, canonicalTaskLine].join("\0"),
      ["change-scope.md", changeScopePath.read].join("\0"),
      ["workspace.md", workspaceScope].join("\0")
    ].join("\0\0")
    # 输出继续使用能力日志既有的 64 位小写 SHA-256 格式。
    Digest::SHA256.hexdigest(digestInput)
  end

  # 对任意一组轮次文件计算稳定摘要，供验证和交付证据绑定。
  def self.documentsDigest(iterationPath, standardNames)
    # 延迟加载避免摘要模块反向成为审批模块的强制循环依赖。
    require_relative "stage-approval-support"
    # 文件名和完整内容共同进入摘要，移动内容不能保留旧证据。
    digestInput = standardNames.map do |standardName|
      # 历史轮次仍按自己的 file-map 解析实际文件。
      documentPath = StageApproval.resolveIterationFile(iterationPath, standardName)
      # 缺失文件不能产生可用摘要。
      raise "能力摘要缺少文件：#{standardName}" unless documentPath.file?
      # NUL 分隔名称与内容，避免普通拼接边界碰撞。
      [standardName, documentPath.read].join("\0")
    end.join("\0\0")
    # 统一输出小写 SHA-256 十六进制。
    Digest::SHA256.hexdigest(digestInput)
  end
end
