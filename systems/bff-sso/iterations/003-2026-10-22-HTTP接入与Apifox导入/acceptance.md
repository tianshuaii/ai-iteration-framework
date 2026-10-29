# 验收标准

| 编号 | 对应测试 | 标准 | 结果 |
|---|---|---|---|
| AC-01 | TC-01 | 新建接口项目默认 HTTP。不填原接口 Apifox 项目 ID 不能保存。填了之后只保存，不向 Apifox 拉取 | 通过 |
| AC-02 | TC-02 | 新建时改选 gRPC，不要求原接口 Apifox 项目 ID。导入仍要 Proto 地址，按钮仍是「导入 Proto」 | 通过 |
| AC-03 | TC-03 | HTTP 项目点「导入接口」不填地址，用已保存的 ID 拉全部接口，并展示和现有原接口的新增、修改、删除。未确认前不改改造和整合 | 通过 |
| AC-04 | TC-04 | Apifox 拉取失败时工作区保持原样。只改项目名称或这个 ID 时也不拉取 | 通过 |
| AC-05 | TC-05 | 已有接口项目打开后仍是 gRPC，仍用「导入 Proto」。接口类型不能改成 HTTP | 通过 |
| AC-06 | TC-06 | 新建接入服务默认 HTTP，页面上没有原接口 Apifox 项目 ID。原来的推送用 Apifox 项目 ID 仍可空 | 通过 |
| AC-07 | TC-07 | 已有接入服务仍显示 gRPC。把它改成 HTTP 后，转发走 HTTP，直连地址拼成 `http://ip:端口`。Nacos 没有 `httpPort` 时失败，不改用 gRPC 端口 | 通过 |
| AC-08 | TC-08 | gRPC 接入服务的转发仍不使用 method，仍走 gRPC。平台内建 SSO 不能改通信方式 | 通过 |
| AC-09 | TC-09 | 推送正在使用的运行包仍用接入服务上的 `apifoxPushProjectId`，不用接口项目上的 `sourceApifoxProjectId` | 通过 |
