# 测试记录

自动测试：T-01 实现检查已完成。管理端仓库的既有 `pom.xml` 固定跳过测试，且 Surefire 2.22.2 与当前 JUnit Platform 不对齐；实跑使用本机已有 Surefire 3.5.4，运行前后临时切换 `skipTests`，最终 `pom.xml` 已完全恢复。

## 自动检查与复用记录

相同代码、依赖、配置和生成物输入下，已通过的检查可以复用；引用原记录并写清输入基线和未失效原因。任一输入变化时只让受影响记录失效，不机械重跑其他仓库或模块。

| 记录 | 任务/阶段 | 仓库/范围 | 命令或证据 | 输入基线 | 结果 | 复用说明 |
|---|---|---|---|---|---|---|
| AUTO-01 | T-01 | `mergex-manager` | Surefire 3.5.4 实跑指定 3 个测试类 | HEAD `43371ee5` + T-01 工作区；排除接管前 `application.yml` | 通过；9 条全过 | 实跑后 `pom.xml` 无差异 |
| AUTO-02 | T-01 | `mediatom-web` | `pnpm test:unit -- --runTestsByPath tests/unit/viewsForManage/Budget/EditPlatAccount/trafficTargeting.spec.js` | HEAD `a5d7cd61` + T-01 工作区；排除接管前 `adx.js` | 通过；3 条全过 | 默认值、回显转换、权限/导出维度 |
| AUTO-03 | T-01 | `mediatom-web` | EditPlatAccount eslint + `pnpm check:imports:mergex` | 同 AUTO-02 | 通过 | MergeX 边界已通过 |
| AUTO-04 | 统一审核 | 两仓 | `xmllint`、`git diff --check`、广告位排除文件扫描 | 同 AUTO-01/AUTO-02 | 通过 | 产品差异不含广告位相关文件 |
| AUTO-05 | verify | `mergex-manager` | `mvn -DskipTests=false -Dtest=... maven-surefire-plugin:3.5.4:test` | HEAD `43371ee5` + T-01 工作区；排除接管前 `application.yml` | 未通过；退出码 0 但显示 `Tests are skipped` | 2026-10-28T19:39:28+08:00；不能把 0 条测试记为通过 |
| AUTO-06 | verify | `mergex-manager` | `mvn test-compile` + JUnit Platform Console 1.12.2 定向执行 3 个测试类 | 同 AUTO-05；未修改 `pom.xml` | 通过；退出码 0，9/9 成功 | 2026-10-28T19:40:36+08:00；覆盖专用 level/type/账号挂载、开关关闭与空规则回显、原请求字段校验基线 |
| AUTO-07 | verify | `mediatom-web` | `pnpm test:unit -- --runTestsByPath tests/unit/viewsForManage/Budget/EditPlatAccount/trafficTargeting.spec.js` | HEAD `a5d7cd61` + T-01 工作区；排除接管前 `adx.js` | 通过；退出码 0，3/3 成功 | 2026-10-28T19:39:28+08:00；默认值、回显转换、`platform:` 与导出维度 9 |
| AUTO-08 | verify | `mediatom-web` | 目标文件 ESLint + `pnpm check:imports:mergex` | 同 AUTO-07 | 通过；两条命令退出码均为 0 | 2026-10-28T19:39:28+08:00 |
| AUTO-09 | verify | 两仓静态结构与范围 | `git diff --check`、`xmllint`、迁移 DML 扫描、广告位/预算过滤/共享组件差异扫描 | AUTO-06/AUTO-07 基线 | 通过；退出码 0 | 2026-10-28T19:41:00+08:00；迁移只新增 `plat_account_id` 与唯一索引，无数据改写；目标排除路径及共享 `TrafficDirectionV4` 无差异 |
| AUTO-10 | verify | 本机运行态前置 | 只读检查激活 profile、8800/3306 监听、管理端 HTTP 与 `mediatom-web` 监听 | 本机 2026-10-28T19:42:00+08:00 | 阻塞；管理端 HTTP 000，无管理端、页面或本地 MySQL 监听，激活 profile 为 `prod` | 未连接数据库、未启动服务、未执行迁移；正式 TC/SR 不得以静态检查替代 |
| AUTO-11 | verify | 轮次框架校验 | `ruby scripts/validate-framework.rb --iteration systems/mergex-manager/iterations/005-...` | 2026-10-28T19:43:00+08:00 的轮次文档 | 未通过；退出码 1 | `test-cases.md` 的 SR 标题使用三级标题，校验器按二级标题识别，报告 SR-01～SR-04 缺少用例；验收阶段未越权修改已审批测试用例正文 |
| AUTO-12 | verify 恢复 | 测试环境、测试库与页面 | 监听/HTTP 只读检查、`information_schema`、`policy_manage`/关联表只读查询、Chrome 新老新增/编辑页 | 2026-10-29T10:43～10:46+08:00；管理端 `feat-20261028-traffic-filter@43371ee5` 工作区，页面 `feat-20261028-traffic-filter@a5d7cd61` 工作区 | 通过；管理端 8901、页面 2023 均 HTTP 200；字段和唯一索引存在；页面可用 | 账号 13859：level=9/type=1 独立主记录 1 条、关联 4 条、place/dspPlace 均为空，编辑页完整回显；账号 11279：开关关闭且无账号维度策略；旧维度 10 类、93816 条仍可只读查询 |
| AUTO-13 | implement 返工 | `mergex-manager` 迁移 SQL | `! rg -n -i 'index|unique|key' sql/policy_manage_plat_account_id.sql`；`git diff --check -- sql/policy_manage_plat_account_id.sql`；人工核对完整 SQL | HEAD `43371ee5` + 既有 T-01 工作区；本次只改未跟踪迁移文件 | 通过；两条命令退出码均为 0 | 2026-10-29T11:03:37+08:00；脚本只新增 `plat_account_id BIGINT NULL` 及字段注释，以分号结束，不含索引 DDL；未连接数据库、未删除测试库索引 |
| AUTO-14 | verify | 测试环境新老接口与数据隔离 | Chrome 实跑新老 add/update/getById，JDBC 只读核对 `policy_manage`/关联表，关闭一个账号后重查其他账号 | 管理端 `feat-20261028-traffic-filter@43371ee5` + 工作区；页面 `feat-20261028-traffic-filter@a5d7cd61` + 工作区 | 通过 | 2026-10-29T11:08～11:15+08:00；新老编辑均回显开关、QPS 与包名规则；三个账号分别形成 level=9/type=1 主记录，关联数为 2/1/1，publisher/place/dspPlace 均为 null；关闭账号 13865 后其他账号和策略不变 |
| AUTO-15 | verify | 关闭态回归、无索引迁移与清理 | Chrome 实跑新老 add/getById（流量筛选关闭、QPS 分别为 5/6）；`rg` 无索引扫描；`git diff --check`；HTTP 200；JDBC 清理后核对 | 同 AUTO-14；不执行迁移 DDL，不删除测试库既有索引 | 通过 | 2026-10-29T11:15～11:19+08:00；新老关闭态账号基础字段与 QPS 完整回显，均无 level=9/type=1 主记录；迁移脚本仅新增 nullable BIGINT 字段且不含 `index|unique|key`；管理端/WEB 均 HTTP 200；8 个 `mpd-auto-*` 最终全部逻辑删除，策略、手动 QPS、自动 QPS 残留均为 0；旧维度仍为 10 类/93816 条 |

## 返工历史

- 2026-10-28：原计划 Maven 命令因 `pom.xml` 硬编码 `skipTests=true` 实际跑 0 条；临时启用后 Surefire 2.22.2 又因 JUnit Platform 版本不对齐跑 0 条。改用本机已有 Surefire 3.5.4 实跑；首次发现既有请求地址测试与“已取消校验”源码相反，修正基线用例后 9 条全过。
- 2026-10-29：用户明确取消表索引要求。原 TC-06 的“字段及唯一索引存在”通过证据保留为历史事实，但不再满足新规格；当前 TC-06 重置为未测，等待产品迁移文件移除索引 DDL 后复验。测试库已有索引未执行删除。
- 2026-10-29：用户明确接受无唯一索引下同一账号并发首次保存可能创建重复 `policy_manage` 的残余风险，保持无索引并继续；该接受只处置增量审核 R-06，不替代 TC-06 和其余验收用例。

| 用例 | 日期 | 结果 | 现象 |
|---|---|---|---|
| TC-01 | 2026-10-29 | 通过 | AUTO-12：新老新增页默认关闭；开启后可见模板、设备/安装/地区/包名及更多规则；旧接口账号 13859 已落库并在编辑页完整回显，数据库主记录及 4 条规则关联与页面一致。 |
| TC-02 | 2026-10-29 | 豁免 | AUTO-07/AUTO-09 已确认源码只使用 `platform:trafficTargeting`、`platform:more`，模板新增仍为 `function:strategytemp:add`；用户确认无权限分支接受豁免，残余风险为未使用真实低权限账号验证区块隐藏。 |
| TC-03 | 2026-10-29 | 通过 | AUTO-14/AUTO-15：新老 add/update/getById 均已实跑；开启时包名规则分别回显，关闭时无账号维度主记录；数据库与页面结果一致。 |
| TC-04 | 2026-10-29 | 通过 | AUTO-14：三个账号的 level=9/type=1/plat_account_id 主记录分别独立，关联数 2/1/1，其他维度字段均为 null；关闭其中一个账号后另外两个账号和策略不变；删除只清理各自策略。 |
| TC-05 | 2026-10-29 | 通过 | AUTO-15：流量筛选保持关闭时，新老 add/getById 均保存并回显账号名、负责人、商务负责人与 QPS（5/6），并且均无 level=9/type=1 策略记录。 |
| TC-06 | 2026-10-29 | 通过 | AUTO-13/AUTO-15：产品 SQL 只新增 nullable `BIGINT plat_account_id`，无 `index|unique|key` 且 `diff --check` 通过；测试库字段为 BIGINT/nullable，旧维度仍为 10 类/93816 条。测试库历史索引未删除，不属于本轮产品迁移内容。 |
| TC-07 | 2026-10-28 | 通过 | AUTO-09：两仓产品差异均不包含 `EditPlace`、`CreateAdPlaceVo`、`AdPlaceServerImpl`、预算过滤及共享 `TrafficDirectionV4` 文件。 |

## 受控浅功能回归

按 `test-strategy.md` 的 `SR-xx` 逐条记录。每条保留日期、结果和可复核现象；范围不得临时扩展到未登记的全系统回归。

| 用例 | 日期 | 结果 | 现象 |
|---|---|---|---|
| SR-01 | 2026-10-29 | 通过 | AUTO-12：新增页默认关闭，开启后主规则/更多规则/模板可用；管理员权限下区块可见；账号 13859 的已保存规则由编辑页与数据库共同回显。停止在一个主规则和更多规则展示，不穷举组合。 |
| SR-02 | 2026-10-29 | 通过 | AUTO-14/AUTO-15：新老 add/update/getById 各执行至少一次，开启和关闭两种流量筛选载荷均得到真实页面与数据库结果。 |
| SR-03 | 2026-10-29 | 通过 | AUTO-15：新老关闭态账号的基础字段与手动 QPS（5/6）完整回显，流量筛选未创建主记录；未扩大到无关广告平台。 |
| SR-04 | 2026-10-28 | 通过 | AUTO-09：共享 `TrafficDirectionV4` 无本轮差异，按已登记停止边界复用静态证据，不扩大到连接管理全量回归。 |

结果通常使用“未测”“通过”或“未通过”。只有用户明确确认时才可写“豁免”，并在现象列同时写明“用户确认”和“残余风险”；缺少任一项都不能进入 `done`。
