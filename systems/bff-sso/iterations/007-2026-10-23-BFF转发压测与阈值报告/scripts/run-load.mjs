import { writeFile } from 'node:fs/promises';
import { startFakeUpstream, fixedBody } from './fake-upstream.mjs';

// 地址、账号都从环境来。脚本里不写死密码，也不把直连地址打到结果文件。
const gatewayOrigin = process.env.GATEWAY_ORIGIN?.trim() || 'http://127.0.0.1:3000';
const adminUser = process.env.LOAD_ADMIN_USER?.trim() || 'superadmin';
const adminPassword = process.env.LOAD_ADMIN_PASSWORD?.trim() || '';
const serviceCodeHint = process.env.SERVICE_CODE?.trim() || '';
// 每一档只跑一小段，好让直连尽快改回去。
const stepMs = Number(process.env.STEP_MS || 2000);
const requestTimeoutMs = Number(process.env.PROBE_TIMEOUT_MS || 5000);
// 到这一档还没变陡就停。再往上主要是把本机打满，不是新的转发结论。
const concurrencySteps = [1, 2, 4, 8, 16, 32, 64, 128];

if (!adminPassword) {
  console.error('缺少 LOAD_ADMIN_PASSWORD');
  process.exit(1);
}

function unwrap(body) {
  // 管理接口外面包了一层 code/data。没有 data 时就用本体。
  if (body && typeof body === 'object' && 'data' in body) return body.data;
  return body;
}

async function api(path, token, options = {}) {
  const headers = { ...(options.headers ?? {}) };
  if (token) headers.authorization = `Bearer ${token}`;
  if (options.body) headers['content-type'] = 'application/json';
  const response = await fetch(`${gatewayOrigin}${path}`, {
    method: options.method ?? 'GET',
    headers,
    body: options.body ? JSON.stringify(options.body) : undefined,
    signal: AbortSignal.timeout(requestTimeoutMs),
  });
  const text = await response.text();
  const parsed = text ? JSON.parse(text) : null;
  // 业务失败也是 HTTP 200。不看 code 的话，地址没改成功也会被当成改成了。
  const businessCode = parsed && typeof parsed === 'object' ? parsed.code : undefined;
  if (!response.ok || (businessCode !== undefined && businessCode !== 200 && businessCode !== 0)) {
    throw new Error(`${options.method ?? 'GET'} ${path} -> ${businessCode ?? response.status}`);
  }
  return unwrap(parsed);
}

async function login() {
  const data = await api('/api/admin/auth/login', '', {
    method: 'POST',
    body: { username: adminUser, password: adminPassword },
  });
  const token = data?.accessToken;
  if (!token) throw new Error('登录没有返回令牌');
  return token;
}

function routeKey(method, path) {
  return `${method.toUpperCase()} ${path}`;
}

function pickRoutes(upstream, whitelist) {
  const allowed = new Set(whitelist.map((item) => routeKey(item.method, item.path)));
  const usable = upstream.filter((item) => item.method && item.path);
  // 白名单优先用 GET，这样试打不用准备请求体。
  const open = usable.find((item) => item.method.toUpperCase() === 'GET' && allowed.has(routeKey(item.method, item.path)))
    ?? usable.find((item) => allowed.has(routeKey(item.method, item.path)));
  // 非白名单也优先 GET。它必须在原接口里，否则网关会在打上游之前拒绝。
  const closed = usable.find((item) => item.method.toUpperCase() === 'GET' && !allowed.has(routeKey(item.method, item.path)))
    ?? usable.find((item) => !allowed.has(routeKey(item.method, item.path)));
  if (!open || !closed) throw new Error('生效包里找不到白名单和非白名单各一条原接口');
  return { open, closed };
}

async function findTarget(token) {
  const services = await api('/api/admin/services', token);
  const rows = Array.isArray(services) ? services : [];
  const matches = [];
  for (const service of rows) {
    if (serviceCodeHint && service.serviceCode !== serviceCodeHint) continue;
    if (service.transportType !== 'http' || service.accessType !== 'direct') continue;
    const active = await api(`/api/admin/sub-services/${service.serviceCode}/runtime-packages/active`, token);
    if (!active?.publicPath || !active?.id) continue;
    matches.push({ service, active });
  }
  // 多家都有对外路径时不猜，避免改错正在用的直连。
  if (matches.length !== 1) {
    throw new Error(`需要唯一的 HTTP 直连生效包，实际 ${matches.length} 个`);
  }
  const { service, active } = matches[0];
  const inventory = await api(
    `/api/admin/sub-services/${service.serviceCode}/runtime-packages/${active.id}/inventory`,
    token,
  );
  const routes = pickRoutes(inventory?.upstream ?? [], inventory?.package?.whitelist ?? active.whitelist ?? []);
  return {
    id: String(service.id),
    serviceCode: service.serviceCode,
    transportType: service.transportType,
    directAddress: service.directAddress,
    publicPath: active.publicPath,
    routes,
  };
}

async function putAddress(token, id, directAddress, transportType) {
  // 必须带上接入方式和通信方式。
  // 只传地址时，已经是直连的服务不会改这一列；不带通信方式时，网址会被当成 gRPC 拒绝。
  await api(`/api/admin/services/${id}`, token, {
    method: 'PUT',
    body: { accessType: 'direct', transportType, directAddress },
  });
}

async function readAddress(token, id) {
  const services = await api('/api/admin/services', token);
  const rows = Array.isArray(services) ? services : [];
  const found = rows.find((item) => String(item.id) === id);
  if (!found) throw new Error('改完地址后找不到原来的接入服务');
  return found.directAddress ?? '';
}

async function timed(run) {
  const startedAt = performance.now();
  try {
    const outcome = await run();
    return { ok: outcome, durationMs: performance.now() - startedAt };
  } catch {
    // 超时和连不上都算这一次失败，档位统计才不会少样本。
    return { ok: false, durationMs: performance.now() - startedAt };
  }
}

function percentile(values, ratio) {
  if (values.length === 0) return 0;
  const sorted = [...values].sort((left, right) => left - right);
  const index = Math.min(sorted.length - 1, Math.max(0, Math.ceil(sorted.length * ratio) - 1));
  return Math.round(sorted[index]);
}

async function runStep(concurrency, send) {
  const deadline = performance.now() + stepMs;
  const durations = [];
  let success = 0;
  let errors = 0;
  const startedAt = performance.now();
  async function worker() {
    while (performance.now() < deadline) {
      const result = await timed(send);
      durations.push(result.durationMs);
      if (result.ok) success += 1;
      else errors += 1;
    }
  }
  // 同一档的并发一起跑。档与档之间不重叠，拐点才对得上并发数。
  await Promise.all(Array.from({ length: concurrency }, () => worker()));
  const elapsedMs = Math.round(performance.now() - startedAt);
  const total = success + errors;
  return {
    concurrency,
    success,
    errors,
    throughput: Number((success / (elapsedMs / 1000)).toFixed(1)),
    p50: percentile(durations, 0.5),
    p95: percentile(durations, 0.95),
    p99: percentile(durations, 0.99),
    elapsedMs,
    total,
  };
}

function kneeReason(previous, current) {
  if (!previous || previous.total === 0 || current.total === 0) return '';
  const previousRate = previous.errors / previous.total;
  const currentRate = current.errors / current.total;
  // 错误比上一档高出一截，就停。偶发的一两个失败不算拐点。
  if (currentRate >= 0.05 && currentRate >= previousRate + 0.05) return '错误升高';
  // 耗时相对上一档翻倍，并且上一档已经不是个位数抖动。
  if (previous.p95 >= 20 && current.p95 >= previous.p95 * 2) return '耗时变陡';
  return '';
}

async function ladder(send) {
  const cold = await timed(send);
  // 先打几下把生效包名单放进内存，后面的档位才不是冷启动。
  for (let index = 0; index < 5; index += 1) await timed(send);
  const steps = [];
  let reason = '';
  for (const concurrency of concurrencySteps) {
    const step = await runStep(concurrency, send);
    steps.push(step);
    reason = kneeReason(steps.at(-2), step);
    if (reason) break;
  }
  return {
    coldMs: Math.round(cold.durationMs),
    coldOk: cold.ok,
    steps,
    knee: reason ? { concurrency: steps.at(-1).concurrency, reason } : null,
  };
}

function containsFixed(text) {
  return text.includes(fixedBody.slice(1, -1).split(':')[0]) && text.includes('bff-load-fake');
}

async function main() {
  const token = await login();
  const target = await findTarget(token);
  const originalAddress = target.directAddress;
  if (!originalAddress) throw new Error('当前直连地址是空的，不能临时改');
  const fake = await startFakeUpstream();
  let swapped = false;
  let restored = false;
  try {
    await putAddress(token, target.id, fake.origin, target.transportType);
    // 只要写成功就记下来。后面的检查失败也要能改回去。
    swapped = true;
    const pointed = await readAddress(token, target.id);
    // 没指到本机就不要加压，避免把压力打到原来的服务。
    if (!pointed.includes('127.0.0.1')) throw new Error('临时地址没有改到本机');
    const openUrl = `${gatewayOrigin}/proxy/${target.publicPath}${target.routes.open.path}`;
    const closedUrl = `${gatewayOrigin}/proxy/${target.publicPath}${target.routes.closed.path}`;
    const auth = { authorization: `Bearer ${token}` };
    async function hitPassthrough(url, withLogin) {
      const response = await fetch(url, {
        headers: withLogin ? auth : undefined,
        signal: AbortSignal.timeout(requestTimeoutMs),
      });
      const text = await response.text();
      return response.status === 200 && text === fixedBody;
    }
    async function hitOne() {
      const response = await fetch(`${gatewayOrigin}/proxy/one`, {
        method: 'POST',
        headers: { ...auth, 'content-type': 'application/json' },
        body: JSON.stringify({
          requestId: `load-${Date.now()}-${Math.random()}`,
          serviceCode: target.serviceCode,
          method: target.routes.open.method,
          path: target.routes.open.path,
        }),
        signal: AbortSignal.timeout(requestTimeoutMs),
      });
      const text = await response.text();
      return response.status === 200 && containsFixed(text);
    }
    async function hitBatch() {
      const response = await fetch(`${gatewayOrigin}/proxy/batch`, {
        method: 'POST',
        headers: { ...auth, 'content-type': 'application/json' },
        body: JSON.stringify([{
          requestId: `load-${Date.now()}-${Math.random()}`,
          serviceCode: target.serviceCode,
          method: target.routes.open.method,
          path: target.routes.open.path,
        }]),
        signal: AbortSignal.timeout(requestTimeoutMs),
      });
      const text = await response.text();
      return response.status === 200 && containsFixed(text);
    }
    const shapes = [
      ['whitelist', () => hitPassthrough(openUrl, false)],
      ['login', () => hitPassthrough(closedUrl, true)],
      ['one', hitOne],
      ['batch', hitBatch],
    ];
    const results = [];
    for (const [name, send] of shapes) {
      const shape = await ladder(send);
      results.push({
        name,
        method: name === 'login' ? target.routes.closed.method : target.routes.open.method,
        path: name === 'login' ? target.routes.closed.path : target.routes.open.path,
        ...shape,
      });
      // 冷的第一次都没打到假上游，继续加压没有意义。
      if (!shape.coldOk) break;
    }
    return { serviceCode: target.serviceCode, publicPath: target.publicPath, results };
  } finally {
    // 先关假上游，再改回地址。顺序反了的话，改回之前的收尾请求还会打到假上游。
    await new Promise((resolve) => fake.server.close(resolve));
    if (swapped) {
      try {
        await putAddress(token, target.id, originalAddress, target.transportType);
        const after = await readAddress(token, target.id);
        restored = after === originalAddress;
      } catch {
        restored = false;
      }
    }
    if (swapped && !restored) {
      // 只在改不回去时落盘，避免正常结果里留下真实地址。
      await writeFile(new URL('./address-restore-needed.txt', import.meta.url), `${originalAddress}\n`, { mode: 0o600 });
      throw new Error('直连没有改回去，旧地址写在 scripts/address-restore-needed.txt');
    }
  }
}

try {
  const report = await main();
  const payload = { restored: true, ...report };
  await writeFile(new URL('./load-results.json', import.meta.url), `${JSON.stringify(payload, null, 2)}\n`);
  const summary = payload.results.map((item) => ({
    name: item.name,
    steps: item.steps.length,
    knee: item.knee,
    coldOk: item.coldOk,
  }));
  console.log(JSON.stringify({ restored: true, summary }));
  if (payload.results.length !== 4 || payload.results.some((item) => !item.coldOk || item.steps.length === 0)) {
    process.exitCode = 1;
  }
} catch (error) {
  console.error(error instanceof Error ? error.message : '压测失败');
  process.exitCode = 1;
}
