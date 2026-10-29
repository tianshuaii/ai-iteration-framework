#!/usr/bin/env ruby

# 本入口保留校验器回归的原有 require 路径，避免测试调用方跟随内部拆分。
# 案例执行模块会按职责加载夹具，不改变命令、案例顺序或临时目录边界。
# 两个支持模块只服务框架自身回归，不增加任何业务迭代步骤。

require_relative "validator-test-case-support"
