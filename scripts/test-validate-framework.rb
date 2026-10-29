#!/usr/bin/env ruby

# 本入口只负责建立一次合法基线并按职责加载回归案例。
# 共享夹具和案例实现位于独立文件，保持单进程执行与原有命令不变。
# 所有测试只写临时目录，不修改真实框架、业务轮次或产品仓库。

require_relative "validator-test-support"

# 框架根目录从脚本位置推导，移动目录后仍可直接执行。
FRAMEWORK_ROOT = Pathname.new(__dir__).join("..").expand_path
# 整套回归只构建一次合法框架，各案例复制后再制造自己的单一变化。
validatorBaselineParent = Pathname.new(Dir.mktmpdir("ai-iteration-validator-baseline-"))
# 固定 framework 子目录，让被测脚本继续按自身位置推导根目录。
VALIDATOR_BASELINE_ROOT = validatorBaselineParent.join("framework")
# 基线通过真实审批与总览刷新入口产生，测试不绕过命令行契约。
copyFrameworkFixture(FRAMEWORK_ROOT, VALIDATOR_BASELINE_ROOT)
prepareActiveFixture(VALIDATOR_BASELINE_ROOT)
# 异常退出也清理一次性基线，避免性能优化遗留临时档案。
at_exit { FileUtils.remove_entry(validatorBaselineParent) if validatorBaselineParent.exist? }

# 先验证独立夹具，后续案例才能把失败归因到自己的单一变化。
runSuccessCase(FRAMEWORK_ROOT, "synthetic baseline") { |_caseRoot| }
# 托管 CI 模式必须保持命令不变，同时只跳过无法随仓库分发的外部实体。
runPortableValidationCase(FRAMEWORK_ROOT)
# 三组案例仍在当前进程顺序执行，继续复用同一个 prepared fixture。
require_relative "validator-tests/governance-cases"
require_relative "validator-tests/completion-cases"
require_relative "validator-tests/concurrency-contract-cases"

# 所有成功和失败路径都符合预期。
puts "OK: validator regression tests passed"
