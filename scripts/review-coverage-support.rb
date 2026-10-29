#!/usr/bin/env ruby

# 本模块只判断代码审核记录是否覆盖当前任务集合，不读取或修改产品仓库。
# 首次实现完成后仍要求一次 task=无 的整轮审核，保持统一审核门禁。
# verify 返工新增任务时，只要求该任务的守卫之后存在增量审核。
# 已被整轮审核覆盖且输入没有失效的旧任务不会因新增任务而重新审核。
# 记录顺序使用 capability-log.md 的追加顺序，不依赖容易漂移的自然语言时间。
# 结构、证据路径和严重发现仍由 CapabilitySupport.parseLog 统一校验。
# 审批摘要变化仍会使整轮审核基线失效，本模块不会绕过计划门禁。
# 新守卫出现在基线之后时，只有更晚的审核记录才能覆盖它。
# 同任务审核只覆盖该任务，不能顺带覆盖其他返工任务。
# 后续 task=无 审核可以重新建立覆盖全部现有守卫的新基线。
# 每种覆盖记录都必须是 passed，且阻断级发现已经清零。
# 最新适用结论优先，不能用更早的通过掩盖后续失败。
# 日志行号只表示证据追加顺序，不代表代码提交或部署顺序。
# 调用方负责传入已经完成且确实要求守卫的任务集合。
# 返回结果只用于门禁诊断，不写 status、证据或产品文件。

# 审核覆盖链使用独立命名空间，避免继续扩大主校验器。
module ReviewCoverageSupport
  # 判断一条审核记录能否作为通过证据。
  def self.passedReview?(row)
    # passed 之外的 failed、superseded 和 pending 都不能覆盖任务。
    return false unless row[:status] == "passed"
    # P0、P1 或开放 P2 任一非零都必须先处置。
    [row[:p0], row[:p1], row[:p2_open]].all? { |value| value == "0" }
  end

  # 校验整轮基线审核与后续增量审核是否共同覆盖全部任务。
  def self.validation(rows:, taskIds:, guardRows:, taskDigests:, unifiedDigest:)
    # 保存稳定行号，后续比较“守卫之后”不依赖时间字符串。
    indexedRows = rows.each_with_index.to_a
    # task=无 是首次整轮审核；没有它就会退回逐任务审核模式。
    unifiedReviews = indexedRows.select do |row, _index|
      row[:capability] == "code-review" && row[:task] == "无"
    end
    # 最新整轮记录必须通过；旧通过后又被 superseded 不能继续放行。
    latestUnified = unifiedReviews.last
    # 统一审核不仅要通过，还必须绑定当前有效计划，防止计划变化后沿用旧基线。
    unless latestUnified && passedReview?(latestUnified.first)
      return { valid: false, reason: "缺少有效的迭代级统一代码审核" }
    end
    # 先保存基线是否仍与当前计划一致；返工链完整时可以延续旧基线。
    unifiedDigestCurrent = latestUnified.first[:input_digest] == unifiedDigest
    # 只有真正采用了守卫后的任务级审核，才证明计划变化来自受控增量。
    incrementalReviewUsed = false

    # 收集没有被整轮基线或后续增量审核覆盖的任务及原因。
    uncovered = taskIds.each_with_object([]) do |taskId, missingTasks|
      # 守卫由主校验器按当前策略验证，这里只使用它的日志位置。
      guardRow = guardRows[taskId]
      # 缺守卫时主校验器会给出更具体错误；覆盖链仍不能假装通过。
      unless guardRow
        missingTasks << "#{taskId}(缺少有效守卫)"
        next
      end
      # 使用记录 id 定位可避免 Hash 内容相同导致 index 误命中。
      guardIndex = rows.index { |row| row[:id] == guardRow[:id] }
      # 日志损坏时不猜测顺序。
      unless guardIndex
        missingTasks << "#{taskId}(守卫顺序无效)"
        next
      end

      # 守卫之后的整轮审核或同任务增量审核都可以覆盖当前任务。
      candidates = indexedRows.select do |row, rowIndex|
        rowIndex > guardIndex && row[:capability] == "code-review" && ["无", taskId].include?(row[:task])
      end
      # 最新适用记录代表最近一次审核结论，失败不能被更早的通过掩盖。
      reviewRow = candidates.last&.first
      unless reviewRow
        missingTasks << "#{taskId}(守卫后无审核)"
        next
      end
      unless passedReview?(reviewRow)
        missingTasks << "#{taskId}(最新审核未通过)"
        next
      end
      # 增量记录绑定任务摘要；后续整轮记录仍必须绑定当前计划摘要。
      expectedDigest = taskDigests[taskId]
      if reviewRow[:task] == taskId && expectedDigest && reviewRow[:input_digest] != expectedDigest
        missingTasks << "#{taskId}(增量审核摘要过期)"
        next
      end
      # task=无 记录覆盖其前方守卫；摘要是否可延续在全任务覆盖完成后统一判断。
      # 同任务记录通过了摘要和顺序检查，证明本任务使用了真实增量审核。
      incrementalReviewUsed = true if reviewRow[:task] == taskId
      # 没有追加缺失原因表示该任务已经被有效审核覆盖。
    end
    # 一次报告全部遗漏任务，避免逐轮修一个再重跑。
    return { valid: false, reason: "增量代码审核未覆盖：#{uncovered.join(', ')}" } unless uncovered.empty?
    # 没有受控增量链时，计划摘要变化仍要求重建整轮审核基线。
    unless unifiedDigestCurrent || incrementalReviewUsed
      return { valid: false, reason: "迭代级统一代码审核摘要过期且无有效增量审核" }
    end
    # 返回基线记录，调用方可写入诊断或测试证据。
    { valid: true, base_review: latestUnified.first }
  end
end
