import { spawn } from 'node:child_process';
import { appendFile, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { randomUUID } from 'node:crypto';
import { createConnection } from 'node:net';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

// 只允许固定的内部计时阶段进入样本；日志详情中的快照一律丢弃。
const SAFE_STAGE = /^(?:http|passthrough|inventory|session|forward|batch)\.[a-z][a-z0-9.]*$/;
const VALID_SCENARIOS = new Set(['whitelist', 'login-passthrough', 'one', 'batch']);

// 最近秩定义避免不同统计软件插值差异；不足 30 个有效样本不报告 P95。
export function percentile(values, fraction) {
  if (!values.length) return null;
  const sorted = [...values].sort((left, right) => left - right);
  return sorted[Math.max(0, Math.ceil(fraction * sorted.length) - 1)];
}

// 只有可确认的独立重启、固定上游与完整日志能进入主组。
export function classify(sample) {
  if (typeof sample.refreshMs === 'number') return 'refresh';
  if (!sample.freshProcess || !sample.healthReady || !sample.firstBusiness)
    return 'exploratory';
  if (!sample.fixedUpstream || sample.preflight || sample.warmupStatus === 'unknown')
    return 'exploratory';
  if (!sample.logComplete || sample.status < 200 || sample.status >= 400)
    return 'exploratory';
  return 'main';
}

// 统计先按场景和组别过滤；重复进程 ID 不能冒充独立重启。
export function summarize(samples, minimum = 30) {
  const result = {};
  for (const phase of ['baseline', 'optimized']) for (const scenario of VALID_SCENARIOS) {
    const group = samples.filter((row) => row.scenario === scenario && row.phase === phase);
    const ids = new Set();
    const main = group.filter((row) => {
      if (classify(row) !== 'main' || ids.has(row.processId)) return false;
      ids.add(row.processId);
      return true;
    });
    const values = main.map((row) => row.totalMs);
    result[`${phase}:${scenario}`] = {
      attempts: group.length,
      valid: main.length,
      refresh: group.filter((row) => classify(row) === 'refresh').length,
      exploratory: group.length - main.length - group.filter((row) => classify(row) === 'refresh').length,
      p50Ms: values.length >= minimum ? percentile(values, 0.5) : null,
      p95Ms: values.length >= minimum ? percentile(values, 0.95) : null,
      minMs: values.length >= minimum ? Math.min(...values) : null,
      maxMs: values.length >= minimum ? Math.max(...values) : null,
    };
  }
  return result;
}

// 只从日志里拣阶段名和整数毫秒，拒绝任意正文、地址、令牌和快照。
export function safeStages(detail) {
  const events = detail?.events;
  if (!Array.isArray(events)) return {};
  return Object.fromEntries(events
    .filter((event) => SAFE_STAGE.test(event?.stage) && Number.isFinite(event?.durationMs))
    .map((event) => [event.stage, Math.max(0, Math.round(event.durationMs))]));
}

// 流式直通不会稳定带回 X-Request-ID，只能在本次请求时间窗内反查日志索引。
export function selectTraceId(items, bffPath, requestStartedAt) {
  // 只接受本次 BFF 路径和请求开始前 100 ms 之后的记录，排除旧进程样本。
  const candidates = (Array.isArray(items) ? items : []).filter((item) =>
    item?.bffPath === bffPath && Number.isFinite(item?.startedAt) &&
    item.startedAt >= requestStartedAt - 100,
  );
  // 最接近请求起点的记录最可能是刚发出的唯一业务请求。
  candidates.sort((left, right) =>
    Math.abs(left.startedAt - requestStartedAt) - Math.abs(right.startedAt - requestStartedAt),
  );
  // Trace ID 仍需满足详情接口的安全字符集合，异常值不能拼进 URL。
  const traceId = candidates[0]?.traceId;
  return typeof traceId === 'string' && /^[a-zA-Z0-9-]{1,100}$/.test(traceId)
    ? traceId
    : null;
}

// 普通 JSON 响应以 http.response 收口，流式 hijack 直通则以 span.end 收口。
export function isTraceComplete(detail) {
  // 总耗时必须已经写入，单独看到子 Span 结束不能冒充整条请求完成。
  if (!Number.isFinite(detail?.summary?.durationMs)) return false;
  // 两类终止事件任选其一，兼容直通与单发/批量而不依赖响应头。
  return detail.events?.some((event) =>
    event?.stage === 'http.response' || event?.stage === 'span.end',
  ) === true;
}

// 直通返回固定正文；单发与批量会保留既有响应包装，只校验唯一替身标记。
export function matchesExpectedBody(body, config) {
  // 两种模式必须由调用方二选一，避免空字符串意外放行任意上游。
  if (typeof config.expectedBody === 'string' && config.expectedBody.length > 0)
    return body === config.expectedBody;
  // 包装响应只认非空固定标记，不解析或保存真实业务正文。
  if (typeof config.expectedBodyIncludes === 'string' && config.expectedBodyIncludes.length > 0)
    return body.includes(config.expectedBodyIncludes);
  // 缺少可验证标记的请求不能进入固定上游主组。
  return false;
}

// 标记使用子进程写入的状态和墙钟时间，不把启动日志或业务数据带回样本。
export function classifyWarmupMarker(content, healthReadyAt) {
  // pending 表示健康就绪时仍未完成，直接作为可确认状态返回。
  if (content === 'pending') return 'pending';
  // complete:<毫秒时间戳> 用于判断完成发生在健康就绪之前还是之后。
  const match = /^complete:(\d+)$/.exec(content);
  // 无效、缺失或未来扩展的状态都保持 unknown，不能进入正式主组。
  if (!match) return 'unknown';
  // 完成晚于健康就绪时，首请求触发点的真实状态仍是 pending。
  // 同一毫秒无法证明先后，保守归为 pending，不能把边界竞争误报成已预热。
  return Number(match[1]) < healthReadyAt ? 'complete' : 'pending';
}

// 采样侧用 Node 预加载钩子观察既有 warmAllActivePackages Promise 生命周期。
export async function createWarmupProbe(configuredNodeOptions = '') {
  // 临时目录只保存 pending/complete 与时间戳，不保存环境变量或请求数据。
  const directory = await mkdtemp(join(tmpdir(), 'bff-cold-warmup-'));
  // 钩子和状态文件都属于本次子进程，finally 会统一删除。
  const hookPath = join(directory, 'probe.cjs');
  const markerPath = join(directory, 'state');
  // JSON 字面量安全承载系统生成路径，避免拼接成可执行命令。
  const markerLiteral = JSON.stringify(markerPath);
  // 钩子只包裹目标方法并保留返回值、异常和原有异步语义。
  const hookSource = [
    "const Module = require('node:module');",
    "const { writeFileSync } = require('node:fs');",
    `const markerPath = ${markerLiteral};`,
    "const safeWrite = (value) => { try { writeFileSync(markerPath, value, { mode: 0o600 }); } catch {} };",
    'const originalLoad = Module._load;',
    'Module._load = function(request, parent, isMain) {',
    '  const loaded = originalLoad.apply(this, arguments);',
    "  if (typeof request !== 'string' || !request.includes('runtime-interface-resolver.service')) return loaded;",
    '  const Resolver = loaded && loaded.RuntimeInterfaceResolver;',
    "  if (!Resolver || Resolver.prototype.__coldWarmupObserved) return loaded;",
    '  const originalWarmup = Resolver.prototype.warmAllActivePackages;',
    '  Resolver.prototype.warmAllActivePackages = function(...args) {',
    "    safeWrite('pending');",
    '    let result;',
    '    try { result = originalWarmup.apply(this, args); }',
    "    catch (error) { safeWrite(`complete:${Date.now()}`); throw error; }",
    "    Promise.resolve(result).then(() => safeWrite(`complete:${Date.now()}`), () => safeWrite(`complete:${Date.now()}`));",
    '    return result;',
    '  };',
    '  Module._load = originalLoad;',
    '  return loaded;',
    '};',
  ].join('\n');
  // 文件权限限制为当前用户；NODE_OPTIONS 只传给采样器亲自启动的 BFF。
  await writeFile(hookPath, hookSource, { mode: 0o600 });
  // 追加而不是覆盖调用方已有 Node 启动参数，避免改变调试或 source-map 行为。
  const nodeOptions = [configuredNodeOptions, `--require=${hookPath}`].filter(Boolean).join(' ');
  return {
    env: { NODE_OPTIONS: nodeOptions },
    // 业务请求结束后再读标记，以健康就绪时刻还原当时的预热状态。
    read: async (healthReadyAt) => {
      try {
        return classifyWarmupMarker((await readFile(markerPath, 'utf8')).trim(), healthReadyAt);
      } catch {
        return 'unknown';
      }
    },
    // 删除范围固定为 mkdtemp 返回的单次目录，不接受外部路径。
    cleanup: async () => {
      // 探针清理失败不能覆盖真实请求样本；目录只含无敏感状态标记。
      try { await rm(directory, { recursive: true, force: true }); } catch {}
    },
  };
}

// 执行前必须看到端口空闲；脚本不会替用户停止已在运行的 BFF。
async function assertHealthPortFree(url) {
  const target = new URL(url);
  // 采样器只能碰本机 BFF；不允许把健康检查或业务请求指向远端。
  if (target.protocol !== 'http:' || !target.port ||
      !['127.0.0.1', 'localhost', '[::1]'].includes(target.hostname))
    throw new Error('只允许本机健康检查地址');
  const occupied = await new Promise((resolve, reject) => {
    const socket = createConnection(Number(target.port), target.hostname.replace(/^\[|\]$/g, ''));
    socket.setTimeout(500);
    socket.once('connect', () => { socket.destroy(); resolve(true); });
    socket.once('timeout', () => { socket.destroy(); reject(new Error('端口探测超时')); });
    socket.once('error', (error) => {
      socket.destroy();
      if (error.code === 'ECONNREFUSED') resolve(false);
      else reject(error);
    });
  });
  if (occupied) throw new Error('健康检查地址已有监听进程，请先完成资源隔离');
}

// 等 /health 首次成功后立刻发唯一一条业务请求，不等待异步预热。
async function waitHealth(url, child, timeoutMs) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    if (child.exitCode !== null) throw new Error('BFF 在健康就绪前退出');
    try {
      const response = await fetch(url, { signal: AbortSignal.timeout(500) });
      if (response.ok) return true;
    } catch {
      // 启动期间连接被拒是预期状态。
    }
    await new Promise((resolve) => setTimeout(resolve, 50));
  }
  throw new Error('BFF 健康检查超时');
}

// 日志查询发生在首条业务请求之后，不污染本进程的首次请求口径。
async function readTrace(config, responseTraceId, requestStartedAt, bffPath) {
  if (!config.log?.urlPrefix) return null;
  let traceId = responseTraceId;
  // 新进程的日志管理接口自身也会走 Session 冷路径，不能沿用普通 1 秒请求超时。
  const logTimeoutMs = config.log.timeoutMs ?? 5000;
  for (let attempt = 0; attempt < 20; attempt++) {
    try {
      // 流式响应缺少头时，从同一进程的窄时间窗日志索引反查一次。
      if (!traceId && config.log.listUrl) {
        const listUrl = new URL(config.log.listUrl);
        listUrl.searchParams.set('from', String(requestStartedAt - 100));
        listUrl.searchParams.set('limit', '20');
        const listResponse = await fetch(listUrl, {
          headers: config.log.headers,
          signal: AbortSignal.timeout(logTimeoutMs),
        });
        if (listResponse.ok) {
          const listPayload = await listResponse.json();
          const page = listPayload?.data ?? listPayload;
          traceId = selectTraceId(page?.items, bffPath, requestStartedAt);
        }
      }
      // 索引尚未异步落盘时继续轮询，不能用空 ID 请求详情。
      if (!traceId) throw new Error('日志索引尚未就绪');
      const response = await fetch(`${config.log.urlPrefix}${encodeURIComponent(traceId)}`, {
        headers: config.log.headers,
        signal: AbortSignal.timeout(logTimeoutMs),
      });
      if (response.ok) {
        const payload = await response.json();
        const detail = payload?.data ?? payload;
        // 等最终响应事件和总耗时齐全；部分事件不能算完整样本。
        if (isTraceComplete(detail)) return detail;
      }
    } catch {
      // 日志异步写入会短暂查不到，超时后明确标记不完整。
    }
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  return null;
}

// 仅终止脚本亲自启动的子进程；超时后仍只针对这个 PID 强制退出。
async function stopChild(child) {
  if (child.exitCode !== null || child.signalCode !== null) return;
  const closed = new Promise((resolve) => child.once('close', resolve));
  child.kill('SIGTERM');
  const timer = setTimeout(() => child.kill('SIGKILL'), 5000);
  try { await closed; } finally { clearTimeout(timer); }
}

// 配置只从标准输入读取，允许临时凭据但绝不落盘或回显配置。
async function readConfig() {
  let raw = '';
  for await (const chunk of process.stdin) raw += chunk;
  return JSON.parse(raw);
}

// 一次运行对应一个新进程和一条业务请求；失败也留下脱敏失败样本。
async function runOnce(config, ordinal) {
  await assertHealthPortFree(config.healthUrl);
  // 预热探针先于子进程创建，保证不会错过 onModuleInit 的启动调用。
  const configuredNodeOptions = config.start.env?.NODE_OPTIONS ?? process.env.NODE_OPTIONS ?? '';
  const warmupProbe = await createWarmupProbe(configuredNodeOptions);
  const child = spawn(config.start.argv[0], config.start.argv.slice(1), {
    cwd: config.start.cwd,
    env: { ...process.env, ...config.start.env, ...warmupProbe.env },
    stdio: 'ignore',
    shell: false,
  });
  // spawn 失败也不得成为未处理事件，更不能把命令参数输出到日志。
  child.on('error', () => {});
  const processId = randomUUID();
  const startedAt = performance.now();
  let healthReady = false;
  let firstBusiness = false;
  let healthReadyAt = 0;
  try {
    if (!child.pid) throw new Error('子进程未启动');
    await waitHealth(config.healthUrl, child, config.startupTimeoutMs ?? 30000);
    healthReady = true;
    // 先记录健康就绪墙钟，再立即发业务请求；文件读取留到响应之后。
    healthReadyAt = Date.now();
    const requestStartedAtEpoch = Date.now();
    const requestStartedAt = performance.now();
    firstBusiness = true;
    const response = await fetch(config.request.url, {
      method: config.request.method,
      headers: config.request.headers,
      body: config.request.body,
      signal: AbortSignal.timeout(config.requestTimeoutMs ?? 10000),
    });
    const body = await response.text();
    const totalMs = Math.round(performance.now() - requestStartedAt);
    const detail = await readTrace(
      config,
      response.headers.get('x-request-id'),
      requestStartedAtEpoch,
      new URL(config.request.url).pathname,
    );
    const stages = safeStages(detail);
    const refreshMs = stages['session.touch.refresh'] ?? null;
    // 标记即使在请求期间变为 complete，也按 healthReadyAt 还原首请求触发态。
    const warmupStatus = await warmupProbe.read(healthReadyAt);
    // 响应正文只用于和固定上游约定值比较，不写进样本文件。
    return {
      scenario: config.scenario, ordinal, phase: config.phase,
      processId, codeVersion: config.codeVersion,
      packageVersion: config.packageVersion,
      startupMs: Math.round(requestStartedAt - startedAt),
      healthReady, freshProcess: true, firstBusiness,
      warmupStatus, preflight: false,
      fixedUpstream: matchesExpectedBody(body, config),
      status: response.status, totalMs,
      bffMs: detail?.summary?.durationMs ?? null,
      logComplete: Boolean(detail && !detail.summary?.incomplete),
      refreshMs, stages,
    };
  } catch {
    // 失败样本也只留状态和耗时；不能悄悄删去慢启动或请求异常。
    return {
      scenario: config.scenario, ordinal, phase: config.phase,
      processId, codeVersion: config.codeVersion,
      packageVersion: config.packageVersion,
      startupMs: Math.round(performance.now() - startedAt),
      healthReady, freshProcess: Boolean(child.pid), firstBusiness,
      warmupStatus: 'unknown', preflight: false, fixedUpstream: false,
      status: 0, totalMs: null, bffMs: null,
      logComplete: false, refreshMs: null, stages: {},
    };
  } finally {
    await stopChild(child);
    // 清理探针文件不依赖请求结果，失败样本也不会留下临时状态。
    await warmupProbe.cleanup();
  }
}

// 命令行不接收 Token 或正文参数；输出只含白名单筛过的采样结果。
async function main() {
  const [mode, output] = process.argv.slice(2);
  if (mode === 'summary') {
    const rows = (await readFile(output, 'utf8')).trim().split('\n')
      .filter(Boolean).map((line) => JSON.parse(line));
    console.log(JSON.stringify(summarize(rows)));
    return;
  }
  if (mode !== 'run' || !output) throw new Error('用法：run <脱敏样本.jsonl> 或 summary <脱敏样本.jsonl>');
  const config = await readConfig();
  if (!VALID_SCENARIOS.has(config.scenario) || !['baseline', 'optimized'].includes(config.phase))
    throw new Error('场景或阶段无效');
  if (!Array.isArray(config.start?.argv) || !config.start.argv.length || !config.start.cwd)
    throw new Error('缺少独立进程启动参数');
  // 地址与版本只用本机和安全短字符串；样本文件不保存目标地址。
  const healthOrigin = new URL(config.healthUrl).origin;
  if (new URL(config.request?.url).origin !== healthOrigin ||
      (config.log?.urlPrefix && new URL(config.log.urlPrefix).origin !== healthOrigin) ||
      (config.log?.listUrl && new URL(config.log.listUrl).origin !== healthOrigin))
    throw new Error('业务与日志请求必须和本机健康检查同源');
  for (const version of [config.codeVersion, config.packageVersion]) {
    if (typeof version !== 'string' || !/^[a-zA-Z0-9._-]{1,64}$/.test(version))
      throw new Error('版本标识必须是不含地址和凭据的短字符串');
  }
  // 固定上游证明只能选择完整正文或包装内唯一标记，不能同时配置两套口径。
  const expectedModes = [config.expectedBody, config.expectedBodyIncludes]
    .filter((value) => typeof value === 'string' && value.length > 0);
  if (expectedModes.length !== 1) throw new Error('必须且只能配置一种固定上游响应标记');
  if (!Number.isInteger(config.runs) || config.runs < 1 || config.runs > 30)
    throw new Error('每个短窗口只能采 1 至 30 次');
  for (let ordinal = 1; ordinal <= config.runs; ordinal++) {
    const sample = await runOnce(config, ordinal);
    await appendFile(output, `${JSON.stringify(sample)}\n`, { mode: 0o600 });
    console.log(JSON.stringify({ scenario: sample.scenario, ordinal, group: classify(sample) }));
  }
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main().catch((error) => {
    // 不回显配置、URL 或请求异常详情，避免将敏感数据写到终端日志。
    console.error(`采样中止：${error instanceof SyntaxError ? '配置格式错误' : '资源或请求失败'}`);
    process.exitCode = 1;
  });
}
