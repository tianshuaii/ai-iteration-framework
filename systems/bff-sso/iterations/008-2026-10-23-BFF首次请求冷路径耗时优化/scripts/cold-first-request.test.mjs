import test from 'node:test';
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { mkdtemp, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import {
  classify,
  classifyWarmupMarker,
  createWarmupProbe,
  isTraceComplete,
  matchesExpectedBody,
  percentile,
  safeStages,
  selectTraceId,
  summarize,
} from './cold-first-request.mjs';

// 所有测试样本只含非敏感字段；真实凭据仅可经运行时标准输入传递。
function sample(index, overrides = {}) {
  return {
    scenario: 'whitelist', phase: 'baseline', processId: `restart-${index}`,
    healthReady: true, freshProcess: true, firstBusiness: true,
    warmupStatus: 'pending', preflight: false, fixedUpstream: true,
    status: 200, totalMs: index, bffMs: index,
    logComplete: true, refreshMs: null, stages: {},
    ...overrides,
  };
}

test('recent-rank P50/P95 needs at least 30 independent valid restarts', () => {
  const rows = Array.from({ length: 30 }, (_, index) => sample(index + 1));
  const stats = summarize(rows)['baseline:whitelist'];
  assert.equal(stats.valid, 30);
  assert.equal(stats.p50Ms, 15);
  assert.equal(stats.p95Ms, 29);
  assert.equal(percentile([10, 20, 30], 0.95), 30);
  // 少一个有效重启，P95 必须为 null，而不是误报达标。
  assert.equal(summarize(rows.slice(1))['baseline:whitelist'].p95Ms, null);
});

test('refresh, unknown warmup, preflight and duplicate restart stay out of main group', () => {
  const rows = [
    sample(1), sample(1, { totalMs: 999 }),
    sample(2, { refreshMs: 400 }),
    sample(3, { warmupStatus: 'unknown' }),
    sample(4, { preflight: true }),
  ];
  const stats = summarize(rows)['baseline:whitelist'];
  assert.equal(stats.valid, 1);
  assert.equal(stats.refresh, 1);
  assert.equal(stats.exploratory, 3);
  assert.equal(stats.p95Ms, null);
  assert.equal(classify(sample(5, { fixedUpstream: false })), 'exploratory');
});

test('baseline and optimized samples never mix', () => {
  const rows = [sample(1), sample(2, { phase: 'optimized', totalMs: 1 })];
  assert.equal(summarize(rows)['baseline:whitelist'].valid, 1);
  assert.equal(summarize(rows)['optimized:whitelist'].valid, 1);
});

test('trace projection drops snapshot, target and all non-timing fields', () => {
  const stages = safeStages({ events: [
    { stage: 'forward.runtime.resolve', durationMs: 12.4,
      snapshot: { token: 'secret' }, target: 'http://internal' },
    { stage: 'unknown.url', durationMs: 200, target: 'http://internal' },
    { stage: 'session.touch.refresh', durationMs: 31 },
  ] });
  assert.deepEqual(stages, {
    'forward.runtime.resolve': 12,
    'session.touch.refresh': 31,
  });
  assert.ok(!JSON.stringify(stages).includes('secret'));
  assert.ok(!JSON.stringify(stages).includes('internal'));
});

test('warmup marker restores state at the exact health-ready boundary', () => {
  // 仍在执行的 Promise 可以直接判为 pending。
  assert.equal(classifyWarmupMarker('pending', 1000), 'pending');
  // 健康检查前已经完成的预热按 complete 记录。
  assert.equal(classifyWarmupMarker('complete:999', 1000), 'complete');
  // 同毫秒缺少可靠先后顺序，必须保守保持 pending。
  assert.equal(classifyWarmupMarker('complete:1000', 1000), 'pending');
  // 请求期间才完成时，健康就绪瞬间仍属于 pending。
  assert.equal(classifyWarmupMarker('complete:1001', 1000), 'pending');
  // 缺损或未知状态绝不猜测，继续落入探索组。
  assert.equal(classifyWarmupMarker('failed', 1000), 'unknown');
});

test('streaming response resolves only the nearest trace in its request window', () => {
  const items = [
    // 旧进程同路径记录不能被误选。
    { traceId: 'old-trace', bffPath: '/proxy/mergex/user/code', startedAt: 1000 },
    // 同时间的其他入口不能串到当前样本。
    { traceId: 'wrong-path', bffPath: '/proxy/one', startedAt: 2001 },
    // 两个合法候选中，应选择最接近本次请求起点的一条。
    { traceId: 'near-trace', bffPath: '/proxy/mergex/user/code', startedAt: 2002 },
    { traceId: 'far-trace', bffPath: '/proxy/mergex/user/code', startedAt: 2010 },
  ];
  assert.equal(selectTraceId(items, '/proxy/mergex/user/code', 2000), 'near-trace');
  // 非法 Trace ID 即使时间匹配也不能拼进详情 URL。
  assert.equal(selectTraceId([
    { traceId: '../secret', bffPath: '/proxy/mergex/user/code', startedAt: 2000 },
  ], '/proxy/mergex/user/code', 2000), null);
});

test('trace completion accepts normal response and streaming span terminals', () => {
  // 普通控制器在 http.response 后具备完整总耗时。
  assert.equal(isTraceComplete({
    summary: { durationMs: 12 },
    events: [{ stage: 'http.response' }],
  }), true);
  // Fastify hijack 直通没有 http.response，但最终 span.end 同样能收口。
  assert.equal(isTraceComplete({
    summary: { durationMs: 13 },
    events: [{ stage: 'span.end' }],
  }), true);
  // 只有阶段事件、尚无总耗时时仍必须等待异步日志完成。
  assert.equal(isTraceComplete({
    summary: {},
    events: [{ stage: 'span.end' }],
  }), false);
});

test('fixed upstream proof supports exact and wrapped response without retaining body', () => {
  const marker = '{"source":"bff-load-fake"}';
  // 直通响应必须和替身正文完全一致。
  assert.equal(matchesExpectedBody(marker, { expectedBody: marker }), true);
  assert.equal(matchesExpectedBody(`${marker}\n`, { expectedBody: marker }), false);
  // 单发和批量只要求既有包装里含唯一替身标记。
  assert.equal(matchesExpectedBody(`{"code":200,"data":${marker}}`, {
    expectedBodyIncludes: 'bff-load-fake',
  }), true);
  // 没有非空证明条件时不得把任意正文标为固定上游。
  assert.equal(matchesExpectedBody(marker, {}), false);
});

test('preload probe observes warmup without changing its asynchronous result', async () => {
  // 临时夹具只模拟同名 Resolver 模块，不加载产品配置或连接真实服务。
  const fixture = await mkdtemp(join(tmpdir(), 'bff-cold-probe-test-'));
  // 模块名必须包含目标后缀，才能验证真实 CommonJS 加载拦截条件。
  const resolverPath = join(fixture, 'runtime-interface-resolver.service.cjs');
  // 150 ms 的 Promise 留出 pending 与 complete 两个稳定观测窗口。
  await writeFile(resolverPath, `exports.RuntimeInterfaceResolver = class {
    async warmAllActivePackages() { await new Promise((resolve) => setTimeout(resolve, 150)); return 'ok'; }
  };`);
  // 子进程主动调用启动预热，并用退出码验证包装后仍返回原结果。
  const appPath = join(fixture, 'app.cjs');
  await writeFile(appPath, `const { RuntimeInterfaceResolver } = require(${JSON.stringify(resolverPath)});
    new RuntimeInterfaceResolver().warmAllActivePackages()
      .then((value) => process.exit(value === 'ok' ? 0 : 2), () => process.exit(3));`);
  // 探针环境仅注入本测试子进程，父进程和其他本机服务不受影响。
  const probe = await createWarmupProbe();
  const child = spawn(process.execPath, [appPath], {
    env: { ...process.env, ...probe.env },
    stdio: 'ignore',
  });
  try {
    // 轮询只等待夹具写出 pending；正式采样不会加入这段等待。
    let pending = 'unknown';
    for (let attempt = 0; attempt < 20 && pending === 'unknown'; attempt++) {
      pending = await probe.read(Date.now());
      if (pending === 'unknown') await new Promise((resolve) => setTimeout(resolve, 10));
    }
    assert.equal(pending, 'pending');
    // 记录 pending 时刻后等待子进程自然结束，不能由测试强杀掩盖返回值。
    const healthReadyAt = Date.now();
    const exitCode = await new Promise((resolve) => child.once('close', resolve));
    assert.equal(exitCode, 0);
    // 完成发生在旧健康时刻之后，回放旧边界仍必须得到 pending。
    assert.equal(await probe.read(healthReadyAt), 'pending');
    // 使用当前时刻观察同一标记时，结果应稳定转为 complete。
    assert.equal(await probe.read(Date.now()), 'complete');
  } finally {
    // 只回收本测试创建的两个临时目录，不接触产品仓库或运行数据。
    await probe.cleanup();
    await rm(fixture, { recursive: true, force: true });
  }
});
