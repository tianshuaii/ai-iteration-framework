#!/usr/bin/env ruby

# 本模块只校验测试策略中的任务风险分级，不执行产品测试或修改记录。
# 测试档位描述验证深度，影响范围描述验证宽度，两者不能互相替代。
# 一行代码仍可因权限、迁移或共享契约进入高档位，避免按行数降级。
# 旧轮次没有策略标记时保持兼容，新模板从计划阶段开始强制填写。

# 风险测试策略使用独立命名空间，供主校验器和后续脚本复用。
module RiskTestSupport
  # 显式标记避免用日期或自然语言猜测轮次是否采用新协议。
  POLICY_MARKER = "<!-- risk-based-testing-policy: adaptive-v1 -->"
  # 五档从无运行影响到高风险；档位名称保持短小，便于表格和日志引用。
  PROFILES = %w[T0 T1 T2 T3 T4].freeze
  # 七列共同保存任务、深度、理由、范围、必跑项、复用项和升级条件。
  COLUMN_COUNT = 7

  # 读取风险表中的任务行，忽略表头、分隔线和其他 Markdown 表格。
  def self.rows(content)
    # 只读取明确章节，避免其他表格里恰好以 T-xx 开头的记录被误判。
    inRiskSection = false
    # 每行独立解析，避免跨章节的贪婪匹配。
    content.each_line.each_with_object([]) do |line, parsedRows|
      # 二级标题开始风险策略区，后续任意同级或更高标题结束该区。
      if line.match?(/^## 任务风险分级\s*$/)
        inRiskSection = true
        next
      elsif inRiskSection && line.match?(/^\#{1,2}\s+/)
        inRiskSection = false
      end
      # 只有第一格是稳定任务编号的行才属于风险表。
      next unless inRiskSection && line.match?(/^\|\s*T-\d+\s*\|/)
      # 保留空单元格，校验器需要识别未填写字段。
      cells = line.strip.split("|", -1)[1...-1].map(&:strip)
      # 返回原始数组，由 validation 给出统一错误。
      parsedRows << cells
    end
  end

  # 校验当前任务集合都有唯一、完整且合法的风险策略。
  def self.validation(content, taskIds:, phase:)
    # 没有标记表示历史策略，调用方继续执行原有测试门禁。
    return { valid: true, adopted: false } unless content.include?(POLICY_MARKER)
    # specify 阶段任务尚未形成，不提前要求风险表完整。
    return { valid: true, adopted: true } if phase == "specify"
    # 解析所有任务行并先检查列数，避免后续索引误读。
    strategyRows = rows(content)
    invalidWidth = strategyRows.select { |row| row.length != COLUMN_COUNT }.map(&:first)
    # 列数不对时无法可靠判断影响范围和复用依据。
    return { valid: false, reason: "风险测试策略列数非法：#{invalidWidth.join(', ')}" } unless invalidWidth.empty?
    # 同一任务只能有一个当前策略，不能靠表格顺序选择较宽松的一行。
    duplicateIds = strategyRows.group_by(&:first).select { |_taskId, values| values.length > 1 }.keys
    # 一次报告全部重复编号。
    return { valid: false, reason: "风险测试策略任务重复：#{duplicateIds.join(', ')}" } unless duplicateIds.empty?
    # 每个实现任务都必须明确测试深度，避免漏项被默认为 T0。
    strategyIds = strategyRows.map(&:first)
    missingIds = taskIds - strategyIds
    # 计划进入实施前必须补齐全部任务。
    return { valid: false, reason: "风险测试策略缺少任务：#{missingIds.join(', ')}" } unless missingIds.empty?
    # 已删除任务的旧策略会让 verify 继续执行无关测试，应及时清理。
    extraIds = strategyIds - taskIds
    # 防止测试范围随着历史行只增不减。
    return { valid: false, reason: "风险测试策略包含未知任务：#{extraIds.join(', ')}" } unless extraIds.empty?
    # 档位必须属于固定五档，禁止用“低风险”等模糊文本绕过规则。
    invalidProfiles = strategyRows.reject { |row| PROFILES.include?(row[1]) }.map(&:first)
    # 返回任务编号比返回原始单元格更容易定位。
    return { valid: false, reason: "风险测试档位非法：#{invalidProfiles.join(', ')}" } unless invalidProfiles.empty?
    # 理由、范围、必跑项、复用项和升级条件都必须有实际内容。
    incompleteIds = strategyRows.select do |row|
      # “待填写”与空值都不能作为可执行策略；“无（首次执行）”属于明确复用结论。
      row[2..6].any? { |value| value.empty? || value == "待填写" }
    end.map(&:first)
    # 缺一列都会让 Agent 回到主观扩大或缩小测试范围。
    return { valid: false, reason: "风险测试策略内容不完整：#{incompleteIds.join(', ')}" } unless incompleteIds.empty?
    # 返回结构化行，后续能力可以继续读取而不重复解析。
    { valid: true, adopted: true, rows: strategyRows }
  end
end
