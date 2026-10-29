import { createServer } from 'node:http';
import { readFile, writeFile } from 'node:fs/promises';

const statePath = '/tmp/bff-sso-iter012-state.json';
const observationPath = '/tmp/bff-sso-iter012-observation.json';

async function readJsonBody(request) {
  const chunks = [];
  for await (const chunk of request) chunks.push(Buffer.from(chunk));
  const text = Buffer.concat(chunks).toString('utf8');
  return text ? JSON.parse(text) : {};
}

function send(response, statusCode, body, headers = {}) {
  response.writeHead(statusCode, {
    'content-type': 'application/json; charset=utf-8',
    ...headers,
  });
  response.end(typeof body === 'string' ? body : JSON.stringify(body));
}

const server = createServer(async (request, response) => {
  const state = JSON.parse(await readFile(statePath, 'utf8'));
  const url = new URL(request.url ?? '/', 'http://127.0.0.1');
  if (url.pathname === '/login' || url.pathname === '/legacy-login') {
    const input = await readJsonBody(request);
    if (input.mode === 'failure') {
      return send(response, 422, { code: 401, msg: 'fixture denied' }, {
        'x-iter012-upstream': 'failure',
      });
    }
    if (input.mode === 'invalid') {
      return send(response, 200, { code: 200, data: {} });
    }
    const userId = input.mode === 'number' ? 123 : state.platformAccountId;
    return send(response, 200, { code: 200, data: { userId }, upstream: true });
  }
  if (url.pathname === '/business') {
    const observation = {
      secretMatches: request.headers['x-bff-secret'] === state.requestSecret,
      platformAccountId: request.headers['x-bff-user-id'] ?? null,
      clientSecretIgnored: request.headers['x-bff-secret'] !== 'client-forged',
    };
    await writeFile(observationPath, JSON.stringify(observation), { mode: 0o600 });
    return send(response, 200, { code: 200, data: observation });
  }
  if (url.pathname === '/public') {
    return send(response, 200, {
      code: 200,
      data: {
        hasSecret: Boolean(request.headers['x-bff-secret']),
        hasUserId: Boolean(request.headers['x-bff-user-id']),
      },
    });
  }
  if (url.pathname === '/stream') {
    response.writeHead(200, { 'content-type': 'text/plain; charset=utf-8' });
    response.write('chunk-1|');
    setTimeout(() => response.end('chunk-2'), 20);
    return;
  }
  send(response, 404, { code: 404, msg: 'fixture not found' });
});

server.listen(19012, '127.0.0.1', () => {
  console.log('iteration-012 mock upstream ready on 127.0.0.1:19012');
});
