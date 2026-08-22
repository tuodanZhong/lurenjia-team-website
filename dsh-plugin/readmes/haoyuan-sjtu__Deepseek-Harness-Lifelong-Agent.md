# DSH 治理记忆

[English](README.md)

`dsh-governed-memory` 是一个可选安装的 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) 独立 bundle。它通过自己的 `cordis.patch.yml` 添加一个 Cordis Host 插件；不 fork Harness，也不携带 Harness 源码。

## 安装

把仓库安装到一个 DSH profile，随后重启该 profile：

```sh
dsh plugin --profile web add https://github.com/haoyuan-sjtu/Deepseek-Harness-Lifelong-Agent.git
```

包的清单声明了 `dsh.bundle.patch`，DSH 会自动把 patch 层加入选中的 profile。把 `web` 换成 `headless` 即可安装到 headless profile。

## 行为

bundle 挂载一个 `agent/pre-step` waterfall 监听器。它先调用 `next()`，再读取 registry，只有选中至少一条记录时才追加一条带插件来源的用户消息。DSH agent loop 会把获准的消息记录为普通 `user/message` 事件，并保留其来源和渲染快照。

记录写入原子 JSON registry。插件不会注册模型可调用的捕获或晋升工具：

- `capture()` 总是写入 `quarantine`。
- `promote()` 需要受信任 Host 调用方、明确批准和已验证的 A/B 级证据。
- 检索仅允许已晋升、范围和隐私允许、未过期且未到复审期、无冲突、相关并且未超 token 预算的记录。
- `revoke()` 会让之后的检索拒绝该记录。

技术预览只支持 `local` 和 `project` 范围。`user` 与 `team` 配置会被拒绝，直到 Host 提供身份、成员资格和共享存储授权。

## 配置

包的 patch 会插入下列行。profile 或 home 的 `cordis.patch.yml` 可以替换完整的 `config` 对象。

```yaml
- id: governed-memory
  name: dsh-governed-memory
  config:
    registryPath: !!js process.env.DSH_GOVERNED_MEMORY_REGISTRY
    scope: project
    allowedPrivacy: [public, internal]
    tokenBudget: 512
    queryTags: []
```

环境变量不存在时，`registryPath` 默认是 `$DSH_HOME/governed-memory.json`。registry 以 `0600` 权限和原子 rename 写入。应放在本地存储；当前版本不提供备份物理删除、多进程锁或共享团队访问语义。

## 受信任 Host 操作

启动时插件把 registry 暴露为 `ctx.governedMemory`，只供同一 DSH 进程内另一个受信任的 Host 插件使用。它没有浏览器 UI、HTTP 端点、CLI 命令或模型工具，因此模型请求不能伪造晋升。

```js
await ctx.governedMemory.capture(candidate, 'admin-ui')
await ctx.governedMemory.promote(candidate.id, true, 'admin-ui')
await ctx.governedMemory.revoke(candidate.id, 'admin-ui')
```

候选记录必须包含 `id`、`text`、`scope`、`privacy`、`canonicalKey`、`tags`、`evidence`、ISO-8601 格式的 `createdAt` / `reviewBy` / `expiresAt`、零到一之间的 `confidence` 与正数 `maxTokens`。每条证据须包含 `uri`、`locator`、等级（`A`、`B` 或 `C`）和 `verified`。

## 验证 checkout

```sh
npm run check
npm pack --dry-run
```

测试覆盖 waterfall 委托、持久化捕获/晋升、模型消息注入、卸载和不安全记录的默认拒绝。

## 技术预览限制

这是一个本地单进程插件。它尚未完成全部 DSH 版本的干净 profile 安装验证、代表性 C0–C3 评测、备份删除验证或共享授权。不要存储凭据、原始私密会话或任何不应进入模型提示词的材料。

## 许可证

MIT，见 [LICENSE](LICENSE)。
