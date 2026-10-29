import { readFile } from 'node:fs/promises';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';

const run = promisify(execFile);

// 标题和结果文件里的名字对齐。缺一段就说明报告漏了一条转发方式。
const titles = {
  whitelist: '白名单直通',
  login: '要登录的直通',
  one: '单发',
  batch: '批量',
};

// 只核对这五个仓库有没有混进压测脚本。别的未提交改动不是这一轮的失败条件。
const repositories = [
  '/Users/mrzater/docker/adx/adx-bff-backend',
  '/Users/mrzater/docker/adx/adx-bff-frontend',
  '/Users/mrzater/docker/adx/adx-sso-backend',
  '/Users/mrzater/docker/adx/adx-admin-backend',
  '/Users/mrzater/docker/adx/adx-admin-frontend',
];

const report = await readFile(new URL('../report.md', import.meta.url), 'utf8');
const results = JSON.parse(await readFile(new URL('./load-results.json', import.meta.url), 'utf8'));

if (!Array.isArray(results.results) || results.results.length !== 4) {
  throw new Error('原始结果不是四种转发');
}

for (const item of results.results) {
  const title = titles[item.name];
  if (!title) throw new Error(`不认识的转发方式：${item.name}`);
  const start = report.indexOf(`## ${title}`);
  // 只在这一节里找数字，避免别的小节里的相同样本数蒙混过关。
  const next = report.indexOf('\n## ', start + 1);
  // 没有下一节时要保留到文末。写成 -1 会把最后一个字裁掉。
  const section = start < 0 ? '' : report.slice(start, next < 0 ? undefined : next);
  if (!section.includes(item.path)) throw new Error(`${title} 缺少路径`);
  const decided = item.knee
    ? item.steps.find((step) => step.concurrency === item.knee.concurrency)
    : item.steps.at(-1);
  if (!decided) throw new Error(`${title} 没有对上的那一档`);
  // 必须是「样本」旁边的数字。单独找 8 会误中 283 这类耗时。
  const samplePattern = new RegExp(`样本(?:只有)?\\s*${decided.total}(?!\\d)`);
  if (!samplePattern.test(section)) throw new Error(`${title} 缺少样本 ${decided.total}`);
  if (item.knee) {
    if (!section.includes(String(item.knee.concurrency))) throw new Error(`${title} 缺少阈值档位`);
    if (!section.includes(item.knee.reason)) throw new Error(`${title} 缺少阈值原因`);
  } else if (!section.includes('没有按翻倍规则停下')) {
    throw new Error(`${title} 没有写明未触发阈值`);
  }
}

// 建议必须明确这一轮不改代码。写成已经改过，检查就不能过。
if (!report.includes('没有改产品代码')) throw new Error('报告没有写明没有改产品代码');
if (/已经改了代码|已修改产品代码/.test(report)) throw new Error('报告把建议写成了已经改代码');
if (!report.includes('先不要做')) throw new Error('报告没有写下一步不要做什么');

for (const repository of repositories) {
  const { stdout } = await run('git', ['-C', repository, 'status', '--short']);
  // 压测脚本只能留在本轮目录。出现在产品仓库里就算这一轮改了产品。
  if (/load-once|run-load|fake-upstream|load-results/.test(stdout)) {
    throw new Error(`产品仓库里出现了压测文件：${repository}`);
  }
}

console.log('报告核对通过');
