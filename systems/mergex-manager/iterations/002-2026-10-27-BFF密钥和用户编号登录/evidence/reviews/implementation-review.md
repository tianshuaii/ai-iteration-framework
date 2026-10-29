# 整轮代码审核

- reviewer: code-review-skill
- reviewed_at: 2026-10-27T15:26:00+08:00
- input_digest: 7ff3f8e64be5d8d7e5ab94201ce5a7bd93fba197fdb9ca15a3cc421e2d4c5ef5
- result: passed
- task: 无

范围是这次工作区里的功能改动。管理端 HEAD `4d67ad96980bf938807b85dc39c7ef774fd0cf6a`，页面 HEAD `14c4ecc686e48bf92f2de6526c29ee52b35de362`。`application.yml` 和 `build/env/development/adx.js` 是改代码前就有的环境文件，没有算进这次功能。

看过的文件：`ViewInterceptor.java`、`TokenUtil.java`、`ConstantUtil.java`、`UserController.java`、`LoginResultVo.java`、`BffHeaderDecisionTest.java`、`src/store/modules/user.js`。

## 检查命令

| 仓库 | 命令 | 时间 | 退出码 | 结果 |
|---|---|---|---|---|
| mergex-manager | 任务 T-01 的编译和测试控制台 | 2026-10-27T15:26:00+08:00 | 0 | 5 条全过 |
| mediatom-web | 任务 T-02 的页面取值检查 | 2026-10-27T15:24:00+08:00 | 0 | `pages ok` |

## 发现

| 编号 | 级别 | 发现 | 处置 |
|---|---|---|---|
| R-01 | P2 | 密钥写在常量类里 | 已处置。这是用户定的。日志、报错和迭代文档都不写这串值 |
| R-02 | P2 | 登录存储文件本来就超过 300 行 | 已处置。只改了登录取值，没有拆文件 |
| R-03 | P2 | 停用用户原先还会再查一次角色 | 已修复。用户不存在或已停用时直接拒绝，不再查角色。头判断测试复跑仍是 5 条通过 |

没有 P0、P1。未关闭的 P2 为 0。

核对过：两个头都没带才走原来的 token；头不齐或密钥不对直接回 50008，不看 token；通过后用这个用户自己的角色和时区，不看登录会话；登录成功只返回 token 和用户编号；页面在对象里只存 token，字符串仍整段存储；开放接口的 `x-api-key` 没改。

本审核不代替页面验收，也不授权提交或启动服务。
