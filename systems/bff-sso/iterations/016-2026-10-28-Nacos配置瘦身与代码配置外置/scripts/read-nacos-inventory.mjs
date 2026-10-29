import { createHash } from 'node:crypto';
import { readFile } from 'node:fs/promises';

// 该脚本只输出配置键名与正文摘要，禁止输出任何配置值。
// 它直接读取指定 bootstrap 文件，避免把 dev/test 凭证写入命令行。
// 返回的 SHA-256 用作 revision 不可用时的稳定漂移判据。

const [envPath] = process.argv.slice(2);
if (!envPath) {
  throw new Error('Usage: node read-nacos-inventory.mjs <env-file>');
}

// 本轮 bootstrap 文件只使用普通 KEY=VALUE；这里仍处理成对引号，
// 使密码或地址里出现 # 时不会被错误截断。解析结果只保存在进程内。
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

// Nacos 集群地址按代码现有策略顺序尝试；盘点失败只返回节点和状态，
// 不把请求参数、账号、密码或 access token 拼进错误消息。
async function fetchFromCluster(env) {
  const nodes = env.NACOS_SERVER_ADDR.split(',')
    .map((node) => node.trim())
    .filter(Boolean)
    .map((node) => (/^https?:\/\//.test(node) ? node : `http://${node}`));

  let lastError;
  for (const baseUrl of nodes) {
    try {
      let accessToken;
      if (env.NACOS_USERNAME && env.NACOS_PASSWORD) {
        const loginUrl = new URL('/nacos/v1/auth/login', baseUrl);
        const loginResponse = await fetch(loginUrl, {
          method: 'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body: new URLSearchParams({
            username: env.NACOS_USERNAME,
            password: env.NACOS_PASSWORD,
          }),
        });
        if (!loginResponse.ok) {
          throw new Error(`login HTTP ${loginResponse.status}`);
        }
        const login = await loginResponse.json();
        accessToken = login.accessToken;
      }

      const group = env.NACOS_CONFIG_GROUP || 'MERGEX_FRONTEND_CONFIG_GROUP';
      const configUrl = new URL('/nacos/v3/client/cs/config', baseUrl);
      configUrl.searchParams.set('dataId', env.NACOS_CONFIG_DATA_ID);
      configUrl.searchParams.set('groupName', group);
      if (env.NACOS_NAMESPACE && env.NACOS_NAMESPACE !== 'public') {
        configUrl.searchParams.set('namespaceId', env.NACOS_NAMESPACE);
      }
      if (accessToken) {
        configUrl.searchParams.set('accessToken', accessToken);
      }

      const response = await fetch(configUrl, {
        headers: {
          'User-Agent': 'Nacos-Node-Client:v1.0.0',
          'Client-Version': 'Nacos-Node-Client:v1.0.0',
        },
      });
      if (!response.ok) {
        throw new Error(`config HTTP ${response.status}`);
      }
      const payload = await response.json();
      const content = payload?.data?.content;
      if (payload?.code !== 0 || typeof content !== 'string' || !content.trim()) {
        throw new Error('config response invalid');
      }
      return { content, group };
    } catch (error) {
      lastError = error;
    }
  }
  throw new Error(`Nacos inventory failed: ${lastError?.message ?? 'unknown'}`);
}

// 远端模板当前是扁平大写键；只匹配顶层键可以避免 YAML 值进入输出。
// 若未来出现嵌套结构，键数异常会触发人工复核，而不是静默打印正文。
const env = parseEnv(await readFile(envPath, 'utf8'));
const { content, group } = await fetchFromCluster(env);
const keys = [...content.matchAll(/^([A-Z][A-Z0-9_]*):(?:\s|$)/gm)]
  .map((match) => match[1])
  .sort();

// 比较只返回布尔值，既能证明“等于默认/同义同值”，又不会泄漏正文。
// 这里只处理本轮审计的简单标量；复杂值继续按消费者人工分类。
const scalars = Object.fromEntries(
  [...content.matchAll(/^([A-Z][A-Z0-9_]*):\s*(.*?)\s*$/gm)].map(
    ([, key, rawValue]) => {
      let value = rawValue.trim();
      if (
        (value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))
      ) {
        value = value.slice(1, -1);
      }
      return [key, value];
    },
  ),
);
const stableDefaults = {
  NACOS_CONFIG_GROUP: 'MERGEX_FRONTEND_CONFIG_GROUP',
  NACOS_CONFIG_TIMEOUT_MS: '5000',
  NACOS_CLIENT_TRANSPORT: 'grpc',
  NACOS_GROUP: 'MERGEX_FRONTEND_CONFIG_GROUP',
  NACOS_CLUSTER_NAME: 'DEFAULT',
  NACOS_WEIGHT: '1',
  NACOS_EPHEMERAL: 'true',
  NACOS_FAIL_FAST: 'false',
  NACOS_METADATA_JSON: '{}',
  NACOS_REGISTER_ENABLED: 'true',
  HTTP_MAX_PARAM_LENGTH: '1000',
  LOG_LEVEL: 'info',
};
const defaultMatches = Object.fromEntries(
  Object.entries(stableDefaults)
    .filter(([key]) => key in scalars)
    .map(([key, expected]) => [key, scalars[key] === expected]),
);
const relations = {
  appNameMatchesNacosService:
    'NACOS_APP_NAME' in scalars &&
    scalars.NACOS_APP_NAME === scalars.NACOS_SERVICE_NAME,
  serviceNameMatchesNacosService:
    'SERVICE_NAME' in scalars &&
    scalars.SERVICE_NAME === scalars.NACOS_SERVICE_NAME,
};

console.log(
  JSON.stringify({
    dataId: env.NACOS_CONFIG_DATA_ID,
    namespace: env.NACOS_NAMESPACE,
    group,
    contentSha256: createHash('sha256').update(content).digest('hex'),
    keyCount: keys.length,
    keys,
    defaultMatches,
    relations,
  }),
);
