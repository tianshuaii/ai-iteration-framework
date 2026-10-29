import { createServer } from 'node:http';

// 正文固定，试打时才能认出打到的是假上游，不是后面的真实服务。
export const fixedBody = '{"source":"bff-load-fake"}';

// 只听本机，并且端口交给系统分配。
// 不写死端口，是为了不和已经开着的网关、页面抢同一个口。
export function startFakeUpstream() {
  // 任何路径都回同一段。后面比的是网关转发方式，不是路径本身。
  const server = createServer((request, response) => {
    response.writeHead(200, {
      'content-type': 'application/json; charset=utf-8',
    });
    response.end(fixedBody);
  });
  return new Promise((resolve, reject) => {
    // 监听失败要立刻抛出去，不能让试打一直等。
    server.once('error', reject);
    server.listen(0, '127.0.0.1', () => {
      const address = server.address();
      // 只接受系统分配的数字端口。管道地址不是这次要的。
      if (!address || typeof address === 'string') {
        reject(new Error('假上游没有分到端口'));
        return;
      }
      resolve({
        server,
        origin: `http://127.0.0.1:${address.port}`,
      });
    });
  });
}
