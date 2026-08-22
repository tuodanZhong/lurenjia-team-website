# OMDSH Hub

OMDSH Hub 是面向 DeepSeek Harness 的社区扩展目录与 Profile generation 管理器。它复用 Harness 的 Profile、Bundle、Repository Plugin、Agent Preset、分层 Skill Registry、Cordis 生命周期和配置契约，并补充事务式安装、恢复、目录浏览与设置页。

本发布候选按 2026-08-13 查询到的 npm `next` 最新包校验：Cordis
`4.0.1-rc.4`，DSH Client 与 Host 契约 `0.0.1-rc.5`：

- Bundle 元数据使用 `package.json#dsh.bundle`；
- Client 元数据使用 `package.json#dsh.client`；
- Client 接入 `settings.section` slot；
- Host 接入 `webServer` 服务；
- 所有已启用 Cordis fiber 激活后才确认 Loader 就绪。

包会持续保留 `private: true`，用于阻止 npm 发布；GitHub 仓库公开不需要移除这项保护。

## 本地验证

需要 Node.js 22 或更高版本：

```bash
npm ci --ignore-scripts
npm run validate
npm run pack:check
```

`@deepseek-ai` 包需要 registry 只读权限。请按包提供方说明，通过进程环境提供短期
`NPM_TOKEN` 与本机 npm 配置；不要把真实令牌写入本仓库。`validate` 会核对精确 npm
版本与契约声明、检查 JavaScript 语法、校验内置 Registry 并运行完整 Node 测试；
`pack:check` 只检查将生成的包，不会发布，并会拒绝把本机 npm 配置带入产物。

## Harness 接入

Host 入口是 `dist/index.mjs`：提供扩展管理器、Workshop bridge 和 Agent ecosystem 服务，注册仅限 loopback 的管理 API，并安装 `official-v2` runtime-ready adapter。`official-v2` 是 OMDSH 自身的 adapter API 版本，不是快照名称。

预构建 Client 入口是 `dist/client.js`：通过标准 Client manifest 注入“扩展”设置区，支持“已安装”“发现”、合集、配方、更新和历史页面。

本候选校验时，npm registry 尚未提供 `@deepseek-ai/dsh-repository-plugin`。因此 Git source
目录项只作为引导式集成展示，OMDSH 不会声称它们能通过 npm 提供的 Repository Plugin
自动安装；本仓库也不会复制私有实现或 Git 快照来填补这个缺口。

管理 endpoint 为 `/omdsh/extensions/v1`。变更请求只接受 loopback Host，拒绝 cross-site Fetch Metadata；请求带 Origin 时还必须与 HTTP Host 匹配。

## 安全模型

- 安装和更新先写入新的物理 Profile generation。
- 默认禁用 package-manager lifecycle scripts。
- Registry 文档严格解析；远程替换需要通过已配置的 Ed25519 公钥验签。
- Candidate 只有在配置校验和运行时就绪确认后才会成为 current。
- 失败的 candidate 会被丢弃，上一代仍可恢复。

## 文档

- [架构说明](docs/architecture.zh.md)
- [Adapter 说明](docs/adapters.zh.md)
- [English README](README.md)

## 许可证

MIT
