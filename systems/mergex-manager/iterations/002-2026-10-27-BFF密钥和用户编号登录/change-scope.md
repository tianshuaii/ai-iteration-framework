# 改动范围

仓库绝对路径写在这套系统的 `overview.md`。两个仓库当前都在 `feat-20261027-bff`。系统名：mergex-manager。

## 要改的项目

| 项目 | 这一轮它负责什么 |
|---|---|
| mergex-manager | 登录成功返回 `token` 和 `userId`。需要登录的接口认 `X-BFF-Secret` 和 `X-BFF-User-Id` |
| mediatom-web | 登录成功后，对象里只取出 token 存储。字符串结果照旧 |

## 页面上要改的位置

| 位置 | 现在 | 改完 |
|---|---|---|
| 登录成功后保存凭证 | 整个 `data` 当成 token | `data` 是对象时只存 `data.token`。仍是字符串时整段存储 |
| 登录页外观 | 账号、密码、验证码 | 不改 |

## 大致文件

### mergex-manager

- `src/main/java/com/ydmob/mergex/managerserver/controller/user/UserController.java`：登录成功改为返回 `token` 和 `userId`
- `src/main/java/com/ydmob/mergex/managerserver/model/vo/sys/LoginResultVo.java`：新增，只有这两个字段
- `src/main/java/com/ydmob/mergex/managerserver/common/config/interceptor/ViewInterceptor.java`：两个新头的判断
- `src/main/java/com/ydmob/mergex/managerserver/common/utils/TokenUtil.java`：放行后，当前用户、角色、角色类型和时区读这个用户
- `src/main/java/com/ydmob/mergex/managerserver/common/utils/ConstantUtil.java`：放生成的密钥和两个头的名字
- 新增一个不连库的测试，挡住「没带头走 token、头不齐或密钥错就拒绝」

### mediatom-web

- `src/store/modules/user.js`：登录成功只把 token 字符串存起来

### 补测试

- 管理端用现有单测方式跑这条鉴权判断。页面登录取值用现有页面检查能覆盖到的范围；点页面仍按用例手工看。

## 明确不动

| 项目 | 为什么不动 |
|---|---|
| mergex-datasyn | 定时任务不参与这次登录 |
| Mediatom 登录页 | 只改共用的登录存储，不改那一页的布局 |
| `application.yml` 和页面开发地址 | 那是本地环境开关，不是这次功能 |
| 开放接口的 `x-api-key` | 用户没要求改这条入口 |
