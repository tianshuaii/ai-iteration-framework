# 跟踪表

| 需求要点 | 验收 | 用例 | 主要文件 |
|---|---|---|---|
| 两个头都通过时按该用户返回，不校验 token | AC-01 | TC-01 | `ViewInterceptor.java`、`TokenUtil.java` |
| 只带 token 时走原来的校验 | AC-02 | TC-02 | `ViewInterceptor.java` |
| 密钥不对就拒绝，不退回 token | AC-03 | TC-03 | `ViewInterceptor.java`、`ConstantUtil.java` |
| 用户编号无效、不存在或已停用就拒绝 | AC-04 | TC-04 | `ViewInterceptor.java` |
| 只带其中一个头就拒绝 | AC-05 | TC-05 | `ViewInterceptor.java` |
| 登录成功返回 token 和 userId | AC-06 | TC-06 | `UserController.java`、`LoginResultVo.java` |
| 页面只存储 token 字符串 | AC-07 | TC-07 | `src/store/modules/user.js` |
| 登录后仍能取当前用户 | 无，浅回归不绑 AC | SR-01 | `src/store/modules/user.js` |
| 旧 token 仍能打开需要登录的列表 | 无，浅回归不绑 AC | SR-02 | `ViewInterceptor.java` |
