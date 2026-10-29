import { createHash, randomBytes, randomUUID } from 'node:crypto';
import { chmod, readFile, unlink, writeFile } from 'node:fs/promises';
import { PrismaService } from '/Users/mrzater/docker/adx/adx-bff-backend/src/prisma/prisma.service';
import { SessionService } from '/Users/mrzater/docker/adx/adx-bff-backend/src/session/session.service';
import { AccessPlatformSecretService } from '/Users/mrzater/docker/adx/adx-bff-backend/src/proxy/access-platform-secret.service';

const statePath = '/tmp/bff-sso-iter012-state.json';
const observationPath = '/tmp/bff-sso-iter012-observation.json';

type FixtureState = {
  serviceId: string;
  serviceCode: string;
  packageId: string;
  platformId: string;
  legacyPlatformId: string;
  bindingId: string;
  accountId: string;
  accountUid: string;
  platformAccountId: string;
  requestSecret: string;
  adminToken: string;
  platformToken?: string;
  temporaryAccountId?: string;
  duplicateRejected: boolean;
};

/** 测试状态只放在权限收紧的临时文件，验收结束后立即删除。 */
async function writeState(state: FixtureState) {
  await writeFile(statePath, JSON.stringify(state), { mode: 0o600 });
  await chmod(statePath, 0o600);
}

async function readState(): Promise<FixtureState> {
  return JSON.parse(await readFile(statePath, 'utf8')) as FixtureState;
}

/** route 快照使用与运行包相同的内容哈希定位，不依赖完整 OpenAPI 文档。 */
function hash(value: unknown) {
  return createHash('sha256').update(JSON.stringify(value)).digest('hex');
}

/** 平台 CRUD 通过运行包文档回查接口，路由快照之外还需一份最小 OpenAPI。 */
function fixtureOpenapiDocument() {
  return {
    openapi: '3.0.0',
    info: { title: 'Iteration 012 fixture', version: '1.0.0' },
    paths: {
      '/login': { post: { operationId: 'iter012Login', responses: { 200: { description: 'ok' } } } },
      '/legacy-login': { post: { operationId: 'iter012LegacyLogin', responses: { 200: { description: 'ok' } } } },
      '/business': { get: { operationId: 'iter012Business', responses: { 200: { description: 'ok' } } } },
      '/public': { get: { operationId: 'iter012Public', responses: { 200: { description: 'ok' } } } },
      '/stream': { get: { operationId: 'iter012Stream', responses: { 200: { description: 'ok' } } } },
    },
  };
}

async function ensureDocument(prisma: PrismaService, packageId: bigint) {
  const document = fixtureOpenapiDocument();
  const blobHash = hash(document);
  await prisma.runtimeUpstreamBlob.upsert({
    where: { blobHash },
    update: { contentJson: document, yn: 1 },
    create: { blobHash, contentJson: document },
  });
  await prisma.runtimeUpstreamItem.upsert({
    where: { packageId_objectKey: { packageId, objectKey: 'doc:openapi' } },
    update: { blobHash, objectHash: blobHash, yn: 1 },
    create: {
      packageId,
      objectKey: 'doc:openapi',
      blobHash,
      objectHash: blobHash,
    },
  });
}

async function setup() {
  const prisma = new PrismaService();
  const sessions = new SessionService({} as never);
  const secrets = new AccessPlatformSecretService();
  try {
    const account = await prisma.account.findFirst({
      where: { accountType: 'SUPER_ADMIN', status: 'enabled', yn: 1 },
      orderBy: { id: 'asc' },
      select: { id: true, userUid: true, username: true, accountType: true },
    });
    if (!account) throw new Error('测试库缺少启用的超级管理员账号');

    const suffix = Date.now().toString(36);
    const serviceCode = `mpd-auto-iter012-${suffix}`;
    const publicPath = `iter012-${suffix}`;
    const requestSecret = randomBytes(24).toString('base64url');
    const platformAccountId = `platform-user-${suffix}`;
    const service = await prisma.subService.create({
      data: {
        serviceCode,
        serviceName: `mpd-auto-iter012-service-${suffix}`,
        transportType: 'http',
        accessType: 'direct',
        directAddress: '127.0.0.1:19012',
        publicServiceId: randomUUID(),
        status: 'enabled',
        serviceUsage: 'business',
        environmentCode: 'test',
        updatedAccountId: account.id,
      },
    });

    const routes = [
      { operationId: 'iter012Login', method: 'POST', path: '/login' },
      { operationId: 'iter012LegacyLogin', method: 'POST', path: '/legacy-login' },
      { operationId: 'iter012Business', method: 'GET', path: '/business' },
      { operationId: 'iter012Public', method: 'GET', path: '/public' },
      { operationId: 'iter012Stream', method: 'GET', path: '/stream' },
    ];
    const packageDigest = hash({ serviceCode, routes });
    const pkg = await prisma.subServiceRuntimePackage.create({
      data: {
        packageId: `iter012-${suffix}`,
        packageDigest,
        subServiceCode: serviceCode,
        environmentCode: 'test',
        upstreamTreeHash: hash(routes),
        facadeTreeHash: hash([]),
        compositeTreeHash: hash([]),
        interfaceKind: 'http',
        publicPath,
        description: 'mpd-auto iteration 012 runtime fixture',
        importedBy: 'iteration-012',
        updatedAccountId: account.id,
      },
    });
    for (const route of routes) {
      const blobHash = hash(route);
      await prisma.runtimeUpstreamBlob.upsert({
        where: { blobHash },
        update: { contentJson: route, yn: 1 },
        create: { blobHash, contentJson: route },
      });
      await prisma.runtimeUpstreamItem.create({
        data: {
          packageId: pkg.id,
          objectKey: `route:${route.method}:${route.path}`,
          blobHash,
          objectHash: blobHash,
        },
      });
    }
    await ensureDocument(prisma, pkg.id);
    await prisma.runtimePackageWhitelist.create({
      data: { packageId: pkg.id, method: 'GET', path: '/public' },
    });
    await prisma.subServiceRuntimeActivation.create({
      data: {
        subServiceCode: serviceCode,
        environmentCode: 'test',
        activePackageId: pkg.id,
        updatedAccountId: account.id,
      },
    });

    const platform = await prisma.accessPlatform.create({
      data: {
        name: `mpd-auto-iter012-platform-${suffix}`,
        requestSecretCiphertext: secrets.encrypt(requestSecret),
        loginSubServiceId: service.id,
        loginInterfaceKind: 'http',
        loginInterfaceKey: 'POST /login',
        loginOperationId: 'iter012Login',
        loginMethod: 'POST',
        loginPath: '/login',
        updatedAccountId: account.id,
      },
    });
    await prisma.accessPlatformSubServiceLink.create({
      data: {
        accessPlatformId: platform.id,
        subServiceId: service.id,
        updatedAccountId: account.id,
      },
    });
    const binding = await prisma.bffPlatformAccountLink.create({
      data: {
        bffAccountId: account.id,
        accessPlatformId: platform.id,
        platformAccountId,
        updatedAccountId: account.id,
      },
    });
    const legacyPlatform = await prisma.accessPlatform.create({
      data: {
        name: `mpd-auto-iter012-legacy-${suffix}`,
        loginSubServiceId: service.id,
        loginInterfaceKind: 'http',
        loginInterfaceKey: 'POST /legacy-login',
        loginOperationId: 'iter012LegacyLogin',
        loginMethod: 'POST',
        loginPath: '/legacy-login',
        updatedAccountId: account.id,
      },
    });
    await prisma.accessPlatformSubServiceLink.create({
      data: {
        accessPlatformId: legacyPlatform.id,
        subServiceId: service.id,
        updatedAccountId: account.id,
      },
    });

    let duplicateRejected = false;
    try {
      await prisma.accessPlatform.create({
        data: {
          name: `mpd-auto-iter012-duplicate-${suffix}`,
          requestSecretCiphertext: secrets.encrypt(randomBytes(16).toString('base64url')),
          loginSubServiceId: service.id,
          loginInterfaceKind: 'http',
          loginInterfaceKey: 'POST /login',
          loginMethod: 'POST',
          loginPath: '/login',
          updatedAccountId: account.id,
        },
      });
    } catch (error) {
      duplicateRejected =
        typeof error === 'object' && error !== null && 'code' in error && error.code === 'P2002';
    }

    const adminToken = randomUUID();
    await sessions.createSession({
      sessionId: adminToken,
      accountId: account.userUid,
      username: account.username,
      channel: 'admin',
      ttlSeconds: 7200,
      accountType: account.accountType,
      forwardContext: {
        gateway: { 'x-gateway-account-id': account.userUid },
        internalAuth: {
          'x-operator-account-id': account.id.toString(),
          'x-caller-channel': 'admin',
        },
        trustedRequestContext: {
          subjectId: Number(account.id),
          subjectType: 1,
          operatorDisplayName: account.username,
          authContextVersion: adminToken,
        },
        accountType: account.accountType,
        builtAtMs: Date.now(),
      },
    });
    await writeState({
      serviceId: service.id.toString(),
      serviceCode,
      packageId: pkg.id.toString(),
      platformId: platform.id.toString(),
      legacyPlatformId: legacyPlatform.id.toString(),
      bindingId: binding.id.toString(),
      accountId: account.id.toString(),
      accountUid: account.userUid,
      platformAccountId,
      requestSecret,
      adminToken,
      duplicateRejected,
    });
    console.log(JSON.stringify({
      ready: true,
      publicPath,
      duplicateRejected,
      requestSecretConfigured: true,
    }));
  } finally {
    await sessions.onModuleDestroy();
    await prisma.$disconnect();
  }
}

async function rememberPlatformToken() {
  const state = await readState();
  const tokenFile = '/tmp/bff-sso-iter012-platform-token';
  const token = (
    process.env.ITER012_PLATFORM_TOKEN ?? (await readFile(tokenFile, 'utf8'))
  ).trim();
  if (!token) throw new Error('缺少 ITER012_PLATFORM_TOKEN');
  await writeState({ ...state, platformToken: token });
  await unlink(tokenFile);
  console.log(JSON.stringify({ remembered: true }));
}

async function rememberRequestSecret() {
  const state = await readState();
  const requestSecret = process.env.ITER012_REQUEST_SECRET;
  if (!requestSecret) throw new Error('缺少 ITER012_REQUEST_SECRET');
  await writeState({ ...state, requestSecret });
  console.log(JSON.stringify({ secretUpdated: true }));
}

async function ensureCurrentDocument() {
  const state = await readState();
  const prisma = new PrismaService();
  try {
    await ensureDocument(prisma, BigInt(state.packageId));
    console.log(JSON.stringify({ documentReady: true }));
  } finally {
    await prisma.$disconnect();
  }
}

/**
 * 验收失效态时只切换本轮临时平台或绑定。
 * 不修改复用的超管账号，避免影响共享测试库中的其他会话。
 * 平台和绑定都使用软删除字段，恢复后可继续后续验收。
 */
async function setFixtureValidity(target: string, active: boolean) {
  const state = await readState();
  const prisma = new PrismaService();
  const updatedAccountId = BigInt(state.accountId);
  try {
    if (target === 'binding') {
      await prisma.bffPlatformAccountLink.update({
        where: { id: BigInt(state.bindingId) },
        data: { yn: active ? 1 : 0, updatedAccountId },
      });
    } else if (target === 'platform') {
      await prisma.accessPlatform.update({
        where: { id: BigInt(state.platformId) },
        data: { yn: active ? 1 : 0, updatedAccountId },
      });
    } else {
      throw new Error(`不支持的失效对象: ${target}`);
    }
    console.log(JSON.stringify({ target, active }));
  } finally {
    await prisma.$disconnect();
  }
}

/** 删除平台 Session，模拟过期后 Redis 中已不存在会话。 */
async function expirePlatformSession() {
  const state = await readState();
  const sessions = new SessionService({} as never);
  try {
    if (state.platformToken) await sessions.deleteSession(state.platformToken);
    console.log(JSON.stringify({ expired: Boolean(state.platformToken) }));
  } finally {
    await sessions.onModuleDestroy();
  }
}

/** 只输出会话结构断言，不输出 Token、密钥或完整授权上下文。 */
async function inspectPlatformSession() {
  const state = await readState();
  const sessions = new SessionService({} as never);
  try {
    const record = state.platformToken
      ? await sessions.getSession(state.platformToken)
      : null;
    console.log(JSON.stringify({
      exists: Boolean(record),
      portal: record?.channel === 'portal',
      accessPlatformMatches: record?.accessPlatformId === state.platformId,
      platformAccountMatches:
        record?.platformAccountId === state.platformAccountId,
    }));
  } finally {
    await sessions.onModuleDestroy();
  }
}

/**
 * 账号失效验收使用独立临时账号，不停用共享超管。
 * 临时账号不用于密码登录，只作为平台登录接管的绑定目标。
 * passwordHash 仍按列长填入随机占位值，验收后软删除。
 */
async function bindTemporaryAccount() {
  const state = await readState();
  const prisma = new PrismaService();
  const suffix = state.serviceCode.slice('mpd-auto-iter012-'.length);
  try {
    const account = await prisma.account.create({
      data: {
        userUid: `iter012-${suffix}`,
        username: `mpd-auto-iter012-user-${suffix}`,
        passwordHash: randomBytes(24).toString('hex'),
        nickname: `mpd-auto-iter012-user-${suffix}`,
        accountType: 'PLATFORM_STAFF',
      },
    });
    await prisma.bffPlatformAccountLink.update({
      where: { id: BigInt(state.bindingId) },
      data: {
        bffAccountId: account.id,
        updatedAccountId: BigInt(state.accountId),
      },
    });
    await writeState({ ...state, temporaryAccountId: account.id.toString() });
    console.log(JSON.stringify({ temporaryAccountBound: true }));
  } finally {
    await prisma.$disconnect();
  }
}

/** 只切换本轮临时账号，调用前必须已完成 bind-temporary-account。 */
async function setTemporaryAccountStatus(enabled: boolean) {
  const state = await readState();
  if (!state.temporaryAccountId) throw new Error('尚未创建临时账号');
  const prisma = new PrismaService();
  try {
    await prisma.account.update({
      where: { id: BigInt(state.temporaryAccountId) },
      data: { status: enabled ? 'enabled' : 'disabled' },
    });
    console.log(JSON.stringify({ temporaryAccountEnabled: enabled }));
  } finally {
    await prisma.$disconnect();
  }
}

async function cleanup() {
  const state = await readState();
  const prisma = new PrismaService();
  const sessions = new SessionService({} as never);
  const updatedAccountId = BigInt(state.accountId);
  try {
    await sessions.deleteSession(state.adminToken);
    if (state.platformToken) await sessions.deleteSession(state.platformToken);
    await prisma.bffPlatformAccountLink.updateMany({
      where: { accessPlatformId: BigInt(state.platformId), yn: 1 },
      data: { yn: 0, updatedAccountId },
    });
    await prisma.accessPlatformSubServiceLink.updateMany({
      where: {
        accessPlatformId: {
          in: [BigInt(state.platformId), BigInt(state.legacyPlatformId)],
        },
        yn: 1,
      },
      data: { yn: 0, updatedAccountId },
    });
    await prisma.accessPlatform.updateMany({
      where: {
        id: { in: [BigInt(state.platformId), BigInt(state.legacyPlatformId)] },
        yn: 1,
      },
      data: { yn: 0, updatedAccountId },
    });
    await prisma.runtimePackageWhitelist.updateMany({
      where: { packageId: BigInt(state.packageId), yn: 1 },
      data: { yn: 0 },
    });
    await prisma.runtimeUpstreamItem.updateMany({
      where: { packageId: BigInt(state.packageId), yn: 1 },
      data: { yn: 0 },
    });
    await prisma.subServiceRuntimePackage.update({
      where: { id: BigInt(state.packageId) },
      data: { yn: 0, updatedAccountId },
    });
    await prisma.subServiceRuntimeActivation.updateMany({
      where: { subServiceCode: state.serviceCode, environmentCode: 'test', yn: 1 },
      data: { yn: 0, updatedAccountId },
    });
    await prisma.subService.update({
      where: { id: BigInt(state.serviceId) },
      data: { yn: 0, status: 'disabled', updatedAccountId },
    });
    if (state.temporaryAccountId) {
      await prisma.account.update({
        where: { id: BigInt(state.temporaryAccountId) },
        data: { yn: 0, status: 'disabled' },
      });
    }
    await unlink(observationPath).catch(() => undefined);
    await unlink(statePath);
    console.log(JSON.stringify({ cleaned: true }));
  } finally {
    await sessions.onModuleDestroy();
    await prisma.$disconnect();
  }
}

async function main() {
  const action = process.argv[2];
  if (action === 'setup') await setup();
  else if (action === 'ensure-document') await ensureCurrentDocument();
  else if (action === 'remember-platform-token') await rememberPlatformToken();
  else if (action === 'remember-request-secret') await rememberRequestSecret();
  else if (action === 'set-validity') {
    await setFixtureValidity(process.argv[3], process.argv[4] === 'active');
  }
  else if (action === 'expire-platform-session') await expirePlatformSession();
  else if (action === 'inspect-platform-session') await inspectPlatformSession();
  else if (action === 'bind-temporary-account') await bindTemporaryAccount();
  else if (action === 'set-temporary-account-status') {
    await setTemporaryAccountStatus(process.argv[3] === 'enabled');
  }
  else if (action === 'cleanup') await cleanup();
  else throw new Error(`未知动作: ${String(action)}`);
}

void main().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
});
