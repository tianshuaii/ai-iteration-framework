import { createHash, randomBytes } from 'node:crypto';
import { mkdtemp, readFile, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createRequire } from 'node:module';

// 版本化脚本只保存键级迁移规则，绝不保存远端正文或凭据。
// YAML 依赖复用 BFF 仓库已经锁定的版本，避免临时安装新依赖。
// 回滚正文仅写入权限为 0600 的临时目录，不进入迭代证据或 Git。
const require = createRequire(import.meta.url);
const YAML = require('/Users/mrzater/docker/adx/adx-bff-backend/node_modules/yaml');

// --dry-run 只做六份读取、漂移校验和目标内容计算。
// --apply 才调用 Nacos 3 Admin API；其他模式直接拒绝，避免误写。
const mode = process.argv[2];
if (!['--dry-run', '--apply'].includes(mode)) {
  throw new Error('Usage: node publish-nacos-configs.mjs --dry-run|--apply');
}

// 发布顺序固定为 test→dev，每个环境内部固定 SSO→Admin→BFF。
// expectedSha 绑定 T-01 和本轮恢复前再次确认的远端正文。
// service 只用于选择键级规则，不参与远端资源定位。
const targets = [
  {
    service: 'sso',
    environment: 'test',
    envPath: '/Users/mrzater/docker/adx/adx-sso-backend/.env.test',
    expectedSha: '431af342fdac46fa40e45da61b312f64652654b028eed4e6aaba98de89f8ea99',
  },
  {
    service: 'admin',
    environment: 'test',
    envPath: '/Users/mrzater/docker/adx/adx-admin-backend/.env.test',
    expectedSha: '3a17fd54b22e127930a75dbedc45479ae32d9d7a4f019a5f71db1d7558c2d3d0',
  },
  {
    service: 'bff',
    environment: 'test',
    envPath: '/Users/mrzater/docker/adx/adx-bff-backend/.env.test',
    expectedSha: 'bd4792dd598e9c5d36194ba3b454390ad45793ebea7f58d4d32a5d25446f8d1c',
  },
  {
    service: 'sso',
    environment: 'dev',
    envPath: '/Users/mrzater/docker/adx/adx-sso-backend/.env',
    expectedSha: 'fb2725c89e003cdbd7123ff2025e216548e194d4bcb94b5521bb6f2b783a44e9',
  },
  {
    service: 'admin',
    environment: 'dev',
    envPath: '/Users/mrzater/docker/adx/adx-admin-backend/.env',
    expectedSha: '9fe91f478d87f115103c744f08f9989f8884c4d32aab2b9cf8853e368b919d54',
  },
  {
    service: 'bff',
    environment: 'dev',
    envPath: '/Users/mrzater/docker/adx/adx-bff-backend/.env',
    expectedSha: '0568bbc2eabdfb4711aa580ab9c845ccaaf3c11487c6725fcc942151de25e623',
  },
];

// 这些键已证明等于稳定代码默认，或在首次远端拉取前就必须确定。
// 删除列表不包含跨服务目标、监听端口、地址、开关或任何敏感值。
const commonDeleteKeys = [
  'NODE_ENV',
  'HTTP_MAX_PARAM_LENGTH',
  'LOG_LEVEL',
  'NACOS_APP_NAME',
  'NACOS_CLIENT_TRANSPORT',
  'NACOS_CLUSTER_NAME',
  'NACOS_CONFIG_GROUP',
  'NACOS_CONFIG_TIMEOUT_MS',
  'NACOS_EPHEMERAL',
  'NACOS_FAIL_FAST',
  'NACOS_GROUP',
  'NACOS_METADATA_JSON',
  'NACOS_WEIGHT',
];

// BFF 的 HTTP 身份和注册名不同，因此它保留 NACOS_SERVICE_NAME。
// Admin/SSO 的注册名与 SERVICE_NAME 重复，删除后由强类型代码派生。
const serviceDeleteKeys = {
  bff: [],
  admin: ['NACOS_SERVICE_NAME'],
  sso: ['NACOS_SERVICE_NAME'],
};

// 新增项全部保持改造前默认行为，允许未来按环境覆盖。
// 平台主密钥只在 test BFF 缺失时由进程内随机数生成，不写入日志。
// dev BFF 已有主密钥和响应上限，迁移必须原样保留。
const bffRuntimeValues = {
  LOGIN_RATE_LIMIT_FAIL_WINDOW_SECONDS: 900,
  LOGIN_RATE_LIMIT_FAIL_THRESHOLD: 5,
  LOGIN_RATE_LIMIT_BACKOFF_BASE_SECONDS: 30,
  LOGIN_RATE_LIMIT_BACKOFF_MAX_SECONDS: 900,
  SESSION_AUTHORIZED_TENANT_REFRESH_INTERVAL_SECONDS: 120,
  RUNTIME_INTERFACE_CACHE_MAX_ENTRIES: 200,
  RUNTIME_INTERFACE_RECONCILE_INTERVAL_SECONDS: 120,
  RUNTIME_INTERFACE_CACHE_PUBLISH_TIMEOUT_MS: 500,
};

// 解析 bootstrap 文件时只认顶层 KEY=VALUE；值仅保存在进程内。
// 引号会被剥离，密码中的 # 不会被当成注释截断。
function parseEnv(source) {
  return Object.fromEntries(
    source
      .split(/\r?\n/)
      .map((line) => line.trim())
      .filter((line) => line && !line.startsWith('#') && line.includes('='))
      .map((line) => {
        const delimiter = line.indexOf('=');
        const key = line.slice(0, delimiter).trim();
        let value = line.slice(delimiter + 1).trim();
        if (
          (value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'"))
        ) {
          value = value.slice(1, -1);
        }
        return [key, value];
      }),
  );
}

// SHA-256 只用于漂移、读回和回滚确认，不暴露正文。
function sha256(content) {
  return createHash('sha256').update(content).digest('hex');
}

// 键数只统计顶层全大写运行配置，忽略注释和空行。
function keyCount(content) {
  return [...content.matchAll(/^([A-Z][A-Z0-9_]*):(?:\s|$)/gm)].length;
}

// Nacos 可能规范化末尾换行等文本细节；键值语义相同不应触发误回滚。
// JSON 字符串只在内存中比较，不输出任何字段值或远端正文。
function yamlSemanticallyEqual(left, right) {
  return JSON.stringify(YAML.parse(left)) === JSON.stringify(YAML.parse(right));
}

// 使用 Nacos 现有登录端点换取短期 token。
// 错误消息只包含 HTTP 状态，不拼账号、密码或响应正文。
async function login(baseUrl, env) {
  const url = new URL('/nacos/v1/auth/login', baseUrl);
  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      username: env.NACOS_USERNAME,
      password: env.NACOS_PASSWORD,
    }),
  });
  if (!response.ok) {
    throw new Error(`Nacos login HTTP ${response.status}`);
  }
  const payload = await response.json();
  if (!payload?.accessToken) {
    throw new Error('Nacos login response missing access token');
  }
  return payload.accessToken;
}

// 集群地址逐个尝试，成功节点会绑定到当前目标后续读写。
// 失败不输出 URL 查询参数或凭据，避免 access token 泄漏。
async function connect(env) {
  const nodes = env.NACOS_SERVER_ADDR.split(',')
    .map((node) => node.trim())
    .filter(Boolean)
    .map((node) => (/^https?:\/\//.test(node) ? node : `http://${node}`));

  let lastError;
  for (const baseUrl of nodes) {
    try {
      const accessToken = await login(baseUrl, env);
      return { baseUrl, accessToken };
    } catch (error) {
      lastError = error;
    }
  }
  throw new Error(`Nacos connection failed: ${lastError?.message ?? 'unknown'}`);
}

// Client API 只负责读取单份配置；官方文档明确发布应使用 Admin API。
// 返回正文只在进程内流转，调用方只输出摘要和键数。
async function readConfig(target) {
  const url = new URL('/nacos/v3/client/cs/config', target.baseUrl);
  url.searchParams.set('dataId', target.env.NACOS_CONFIG_DATA_ID);
  url.searchParams.set(
    'groupName',
    target.env.NACOS_CONFIG_GROUP || 'MERGEX_FRONTEND_CONFIG_GROUP',
  );
  if (target.env.NACOS_NAMESPACE !== 'public') {
    url.searchParams.set('namespaceId', target.env.NACOS_NAMESPACE);
  }
  const response = await fetch(url, {
    headers: {
      accessToken: target.accessToken,
      'User-Agent': 'Nacos-Node-Client:v1.0.0',
      'Client-Version': 'Nacos-Node-Client:v1.0.0',
    },
  });
  if (!response.ok) {
    throw new Error(`Nacos read HTTP ${response.status}`);
  }
  const payload = await response.json();
  const content = payload?.data?.content;
  if (payload?.code !== 0 || typeof content !== 'string') {
    throw new Error('Nacos read response invalid');
  }
  return content;
}

// Admin GET 读取配置存储的权威内容，避免刚发布时 Client API 命中旧缓存。
// 它与发布使用同一权限边界，仍然只返回单个已知 Data ID。
async function readAdminConfig(target) {
  const url = new URL('/nacos/v3/admin/cs/config', target.baseUrl);
  url.searchParams.set('dataId', target.env.NACOS_CONFIG_DATA_ID);
  url.searchParams.set(
    'groupName',
    target.env.NACOS_CONFIG_GROUP || 'MERGEX_FRONTEND_CONFIG_GROUP',
  );
  url.searchParams.set('namespaceId', target.env.NACOS_NAMESPACE || 'public');
  const response = await fetch(url, {
    headers: { accessToken: target.accessToken },
  });
  if (!response.ok) {
    throw new Error(`Nacos admin read HTTP ${response.status}`);
  }
  const payload = await response.json();
  const content = payload?.data?.content;
  if (payload?.code !== 0 || typeof content !== 'string') {
    throw new Error('Nacos admin read response invalid');
  }
  return content;
}

// Client API 缓存刷新不是同步完成；轮询只针对刚发布的单份配置。
// 5 秒内仍未出现目标语义就视为发布失败，交给当前环境批次回滚。
async function waitForClientContent(target, expectedContent) {
  for (let attempt = 0; attempt < 20; attempt += 1) {
    const content = await readConfig(target);
    if (yamlSemanticallyEqual(content, expectedContent)) {
      return content;
    }
    await new Promise((resolve) => setTimeout(resolve, 250));
  }
  throw new Error(
    `${target.environment}/${target.service} client cache did not converge`,
  );
}

// Nacos 3 Admin API 接受 form-urlencoded，并要求 namespace 写权限。
// type 固定 yaml，确保控制台与客户端继续按 YAML 展示和解析。
async function publishConfig(target, content) {
  const url = new URL('/nacos/v3/admin/cs/config', target.baseUrl);
  const body = new URLSearchParams({
    dataId: target.env.NACOS_CONFIG_DATA_ID,
    groupName:
      target.env.NACOS_CONFIG_GROUP || 'MERGEX_FRONTEND_CONFIG_GROUP',
    namespaceId: target.env.NACOS_NAMESPACE || 'public',
    content,
    type: 'yaml',
  });
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      accessToken: target.accessToken,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body,
  });
  if (!response.ok) {
    throw new Error(`Nacos publish HTTP ${response.status}`);
  }
  const payload = await response.json();
  if (payload?.code !== 0 || payload?.data !== true) {
    throw new Error('Nacos publish response invalid');
  }
}

// 使用 YAML Document 做键级删除/新增，远端未涉及的值和注释均原样保留。
// test BFF 的新主密钥只由调用方传入当前进程，不进入返回摘要。
function buildDesiredContent(target, currentContent, generatedTestMasterKey) {
  const document = YAML.parseDocument(currentContent);
  for (const key of [
    ...commonDeleteKeys,
    ...serviceDeleteKeys[target.service],
  ]) {
    document.delete(key);
  }

  if (target.service === 'bff') {
    for (const [key, value] of Object.entries(bffRuntimeValues)) {
      document.set(key, value);
    }
    if (target.environment === 'test') {
      document.set('ACCESS_PLATFORM_SECRET_MASTER_KEY', generatedTestMasterKey);
      document.set('PLATFORM_LOGIN_RESPONSE_MAX_BYTES', 1_048_576);
    }
  }

  const content = String(document);
  if (document.errors.length > 0 || !content.trim()) {
    throw new Error('Desired YAML is invalid');
  }
  return content;
}

// 先连接和读取全部目标；任何摘要漂移都会在第一笔写入前终止。
// 随机密钥在 dry-run/apply 当前进程内生成，输出永远不含密钥值。
const generatedTestMasterKey = randomBytes(32).toString('base64');
const prepared = [];
for (const definition of targets) {
  const env = parseEnv(await readFile(definition.envPath, 'utf8'));
  const connection = await connect(env);
  const target = { ...definition, ...connection, env };
  const beforeContent = await readConfig(target);
  const beforeSha = sha256(beforeContent);
  if (beforeSha !== definition.expectedSha) {
    throw new Error(
      `${definition.environment}/${definition.service} drifted before publish`,
    );
  }
  const desiredContent = buildDesiredContent(
    target,
    beforeContent,
    generatedTestMasterKey,
  );
  prepared.push({
    target,
    beforeContent,
    beforeSha,
    beforeKeyCount: keyCount(beforeContent),
    desiredContent,
    desiredSha: sha256(desiredContent),
    desiredKeyCount: keyCount(desiredContent),
  });
}

// dry-run 到这里结束；只输出资源身份、摘要和键数。
if (mode === '--dry-run') {
  console.log(
    JSON.stringify({
      mode: 'dry-run',
      targets: prepared.map((item) => ({
        environment: item.target.environment,
        service: item.target.service,
        dataId: item.target.env.NACOS_CONFIG_DATA_ID,
        beforeSha: item.beforeSha,
        beforeKeyCount: item.beforeKeyCount,
        desiredSha: item.desiredSha,
        desiredKeyCount: item.desiredKeyCount,
      })),
    }),
  );
  process.exit(0);
}

// apply 模式为回滚正文创建进程外临时副本，文件权限固定为 0600。
// 路径可用于本轮后续验收失败时回滚，但正文永不输出。
const rollbackDir = await mkdtemp(join(tmpdir(), 'iteration-016-nacos-'));
const publishedByEnvironment = new Map();
let activeEnvironment;

try {
  for (const item of prepared) {
    const environment = item.target.environment;
    // 显式记录当前批次，失败处理不能用 Map 最后一项猜测环境。
    activeEnvironment = environment;
    const rollbackPath = join(
      rollbackDir,
      `${environment}-${item.target.service}.yml`,
    );
    await writeFile(rollbackPath, item.beforeContent, { mode: 0o600 });

    // 发布前再次读取，关闭全批次预检与当前写入之间的并发窗口。
    const latestContent = await readAdminConfig(item.target);
    if (sha256(latestContent) !== item.beforeSha) {
      throw new Error(
        `${environment}/${item.target.service} drifted during publish`,
      );
    }

    // 发请求前先登记回滚项。若服务端已落库但网络响应丢失，调用方无法
    // 判断写入结果；把这种不确定结果也恢复为原文，比遗漏回滚更安全。
    const environmentItems = publishedByEnvironment.get(environment) ?? [];
    environmentItems.push(item);
    publishedByEnvironment.set(environment, environmentItems);
    await publishConfig(item.target, item.desiredContent);

    // Admin 存储和 Client 缓存必须都达到目标语义，才允许进入下一项。
    const adminReadBackContent = await readAdminConfig(item.target);
    if (!yamlSemanticallyEqual(adminReadBackContent, item.desiredContent)) {
      throw new Error(
        `${environment}/${item.target.service} admin read-back mismatch`,
      );
    }
    const readBackContent = await waitForClientContent(
      item.target,
      item.desiredContent,
    );
    const readBackSha = sha256(readBackContent);
    const exactMatch = readBackSha === item.desiredSha;
    if (!exactMatch && !yamlSemanticallyEqual(readBackContent, item.desiredContent)) {
      throw new Error(
        `${environment}/${item.target.service} read-back mismatch`,
      );
    }
    // 后续证据记录 Nacos 实际保存的摘要，而不是本地序列化前的摘要。
    item.afterSha = readBackSha;
    item.afterKeyCount = keyCount(readBackContent);
    item.exactReadBackMatch = exactMatch;

  }
} catch (error) {
  // 失败只回滚当前环境已经发布的 Data ID，按逆序恢复并逐份读回。
  // 已完整通过的 test 批次不会因 dev 单项故障被误回滚。
  const rollbackItems = activeEnvironment
    ? [...(publishedByEnvironment.get(activeEnvironment) ?? [])].reverse()
    : [];
  for (const item of rollbackItems) {
    await publishConfig(item.target, item.beforeContent);
    // 先核对 Admin 权威存储，不能把 Client API 尚未刷新的旧缓存当成
    // 回滚成功；之后再等待运行实例所用的 Client 缓存同步到原文。
    const restoredAdminContent = await readAdminConfig(item.target);
    if (!yamlSemanticallyEqual(restoredAdminContent, item.beforeContent)) {
      throw new Error(
        `${item.target.environment}/${item.target.service} admin rollback mismatch`,
        { cause: error },
      );
    }
    const restoredContent = await waitForClientContent(
      item.target,
      item.beforeContent,
    );
    if (sha256(restoredContent) !== item.beforeSha) {
      throw new Error(
        `${item.target.environment}/${item.target.service} rollback mismatch`,
        { cause: error },
      );
    }
  }
  throw error;
}

// 成功输出只含摘要、键数和受控回滚目录，不含任何配置正文。
console.log(
  JSON.stringify({
    mode: 'apply',
    rollbackDir,
    targets: prepared.map((item) => ({
      environment: item.target.environment,
      service: item.target.service,
      dataId: item.target.env.NACOS_CONFIG_DATA_ID,
      beforeSha: item.beforeSha,
      beforeKeyCount: item.beforeKeyCount,
      afterSha: item.afterSha,
      afterKeyCount: item.afterKeyCount,
      exactReadBackMatch: item.exactReadBackMatch,
    })),
  }),
);
