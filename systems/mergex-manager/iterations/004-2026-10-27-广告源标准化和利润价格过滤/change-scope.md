# 改动范围

## 可以改

### mergex-manager

- `sql/` 下新增 `dsp_place.app_std` 的 ALTER 脚本（只入库文件，不代跑正式库）
- `model/entity/budget/dsp/DspPlace.java` 及广告源保存/详情相关 VO（如 `DspPlaceSaveVo`、`DspPlaceSaveForAddVo`、`DspPlaceSaveForUpdateVo` 等）
- `DspPlaceService` / `DspPlaceServiceImpl`、`DspPlaceMapper` / `DspPlaceMapper.xml` 读写 `app_std`
- 利润策略保存路径中对 `bidFilterType` 的处理（`PriceStrategyServiceImpl.batchUpdatePrice`），对所有 type 固定为媒体底价 `1`

### mediatom-web（仅 MergeX）

- `viewsForManage/Budget/EditSource/BaseInfoForm`（及添加广告源同表单）：「请求参数过滤」下增加「应用名称标准化」开关，默认关
- 广告源保存/回显字段映射
- `Operation/UpdateLinkConfig`：连接管理利润策略去掉价格过滤
- `FunctionList/ConfigABTest`：AB 实验利润策略去掉价格过滤；提交固定 `bidFilterType=1`

## 不许改

- Mediatom 半边页面、`mergex-web-react`、`mergex-datasyn` 建表脚本
- 正式库数据（无明确授权不跑迁移、不批量刷数）
- 网关库、BFF 密钥相关（本轮无关）
