import { writeFile } from 'node:fs/promises';
import { startFakeUpstream, fixedBody } from './fake-upstream.mjs';

// 网关地址和试打路径都可以用环境变量换掉。
// 默认是本机已经开着的网关，以及当前白名单里那条不登录的直通。
const gatewayOrigin = process.env.GATEWAY_ORIGIN?.trim() || 'http://127.0.0.1:3000';
const probePath = process.env.PROBE_PATH?.trim() || '/proxy/mergex/user/code';

// 一次试打不能无限等。上游卡住时也要留下失败和已经过去的时间。
const probeTimeoutMs = Number(process.env.PROBE_TIMEOUT_MS || 5000);

async function timedFetch(url) {
  const startedAt = performance.now();
  try {
    const response = await fetch(url, { signal: AbortSignal.timeout(probeTimeoutMs) });
    // 读完正文再停表，耗时才包含把响应收回来的时间。
    const body = await response.text();
    return {
      ok: response.status >= 200 && response.status < 400,
      status: response.status,
      durationMs: Math.round(performance.now() - startedAt),
      body,
    };
  } catch (error) {
    // 连不上也要记下，不能把异常当成没有结果。
    return {
      ok: false,
      status: 0,
      durationMs: Math.round(performance.now() - startedAt),
      error: error instanceof Error ? error.name : 'error',
    };
  }
}

const fake = await startFakeUpstream();
try {
  const fakeHit = await timedFetch(`${fake.origin}/user/code`);
  // 假上游必须原样返回约定正文。对不上就说明端口被别的程序占了。
  const fakeMatched = fakeHit.ok && fakeHit.body === fixedBody;
  // 这一下走现成白名单，不改接入地址。所以它打到的仍是原来的服务，不是假上游。
  const gatewayHit = await timedFetch(`${gatewayOrigin}${probePath}`);
  // 结果里不留正文。真实服务的返回可能带业务数据，试打记录只需要成败和耗时。
  const record = {
    fake: {
      ok: fakeMatched,
      status: fakeHit.status,
      durationMs: fakeHit.durationMs,
    },
    gateway: {
      ok: gatewayHit.ok,
      status: gatewayHit.status,
      durationMs: gatewayHit.durationMs,
      error: gatewayHit.error,
    },
  };
  await writeFile(new URL('./last-probe.json', import.meta.url), `${JSON.stringify(record, null, 2)}\n`);
  console.log(JSON.stringify(record));
  // 业务错误也算记下来了。状态码是 0 表示网关没回，这次试打不能算通过。
  if (!fakeMatched || gatewayHit.status === 0) process.exitCode = 1;
} finally {
  // 试打结束就关掉，避免占着端口影响下一档。
  await new Promise((resolve) => fake.server.close(resolve));
}
