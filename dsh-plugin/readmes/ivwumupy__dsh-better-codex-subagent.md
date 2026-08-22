# dsh-better-codex-subagent

[English](README.md) | 中文

固定 `codex` subagent provider([`@deepseek-ai/dsh-subagent-codex`](../../packages/subagent/subagent-codex/README.md))的 drop-in 替代品,额外把 Codex app-server 的信息流镜像到 harness 子会话。因此每次 Codex run 都会像普通的一次性 subagent 一样呈现在会话树与 Web UI 中:在委派会话下出现可发现的子节点,包含委派任务、助手回答与工具执行(命令与文件变更)的完整对话记录。

该 provider 注册在相同的 `codex` 名下,`tool-subagent-codex` 工具行(`provider: codex`)无需改动即可继续使用。与 `@deepseek-ai/dsh-subagent-codex` 同时加载会因 provider 重名而 fail loud——组合二选一。

## 启动与所有权

`start(request)` 从父会话推导子级 cwd,通过 `dsh-subprocess` spawn 固定命令 `codex app-server --stdio`,依次执行 `initialize` → `initialized` → `thread/start { cwd, ephemeral }`。只有 app-server 返回与请求一致的生命周期线程后,provider 才会创建投影子会话、写入种子事件(descriptor、turn 开始、用户任务)并发布 run。发布前失败会关闭通信链路、终止受管进程树并等待退出后拒绝 `start()`——不会留下孤儿子会话。

已发布 run 的结果契约与基础 provider 完全一致:单回合、以权威的 `turn/completed` 终止通知为准,取 `phase: "final_answer"`(无显式阶段时回退 `phase: null`)的最新 `agentMessage` 作为返回答案。本地取消映射为 `aborted`,`contextWindowExceeded` 映射为 `max-tokens`,其余远程失败映射为 `error`。`dispose()` 幂等并收敛到整树静默。run 结算后投影会话保留在 store 中,作为终态、只读的一次性子会话;Web UI 已原生支持 one-shot subagent 会话的只读展示。

## 投影

子会话通过有状态的 transcript 镜像 app-server 通知流:

| app-server 通知 | 投影会话事件 |
|---|---|
| `item/agentMessage/delta` | 按 item id 累积 |
| `item/completed`(`agentMessage`,`final_answer` 或 `null` 阶段) | `assistant/message`,内容为累积或完成文本 |
| `item/started` / `item/completed`(`commandExecution`) | `tool/call`(`exec_command`,含 `command`/`cwd`)+ `tool/result`(`aggregatedOutput`,退而求其次用退出码、再其次用状态) |
| `item/started` / `item/completed`(`fileChange`) | `tool/call`(`fileChange`,path/kind 变更摘要)+ `tool/result`(路径摘要) |
| run 结算 | `turn/end`(`completed` / `aborted` / `max-tokens` / `error`) |

transcript 刻意宽容:未知的通知方法、item 类型与 agent-message 阶段会被忽略,因此 app-server 引入新 item 类型不会导致 run 失败;已知类型的畸形载荷降级为跳过写入。基础 provider 的 fail-closed 姿态在关键处保留:未知的服务端*请求*(需要应答)与终止通知中的线程/回合作用域不匹配仍会使 run 失败。

## 配置

| 键 | 默认值 | 含义 |
|---|---|---|
| `env` | `{}` | 显式子级环境,叠加在 subprocess 缝的凭据清洗父环境之上。 |
| `disposeGraceMs` | `3000` | 正有限宽限毫秒数,不得超过 [`MAX_TIMER_DELAY_MS`](../../packages/util/timeout/README.md),用于共享进程树所有者的终止层级之间。 |
| `ephemeral` | `true` | 传给 `thread/start` 的线程生命周期。`false` 会将 Codex 会话持久化到 `CODEX_HOME/sessions` 下,可供之后 `codex resume`;`true` 保持基础 provider 的临时线程契约。 |

```yaml
- id: better-codex-subagent
  name: 'dsh-better-codex-subagent'
  config:
    env:
      OPENAI_API_KEY: !!js process.env.OPENAI_API_KEY
    ephemeral: false

- id: tool-subagent-codex
  name: '@deepseek-ai/dsh-tool-subagent'
  config:
    provider: codex
    toolName: subagent_codex
    maxDepth: provider-managed
```

## 后台执行

`codex` provider 支持一次性后台执行:工具行只需不设 `enableRunInBackground` 或设为 `true`(默认值)。模型即可传 `run_in_background: true`,Codex run 会作为后台任务启动并立即返回 job id;`job_output` 收集最终答案,`job_kill` 取消。投影会话就是该任务的孩子会话,Web UI 依然渲染运行中与已结算的 subagent 记录。`backgroundMode` 必须保持 `one-shot`(默认):`codex` provider 没有 `prepareContinuable` 能力,`continuable` 工具行会在挂载时失败。

## 安装

本包是一个 dsh **bundle**:manifest 声明了 `dsh.bundle` 并携带 patch 层(`cordis.patch.yml`)负责挂载 provider,因此 `dsh plugin` 会把它作为 bundle 安装进 profile。包随附构建产物(`lib/types/*.js` ESM + 类型声明)与源码,harness 依赖声明为 peerDependencies,只要宿主已有 harness 包即可加载——例如 dsh profile 会从已安装的 dsh 运行时解析它们。

```sh
# 在本包目录构建并生成可发布的 tarball
pnpm pack        # → dsh-better-codex-subagent-0.1.0.tgz
```

安装进 profile(`dsh plugin` 转发给 pnpm,并因 `dsh.bundle` manifest 自动把 bundle 追加到 profile 的 `dsh.profile.bundles`):

```sh
dsh plugin --profile web add ./dsh-better-codex-subagent-0.1.0.tgz
```

其他分发形式同理:发布到 npm 后 `dsh plugin --profile web add dsh-better-codex-subagent`,或从 git 安装 `dsh plugin --profile web add github:you/deepseek-harness#<sha>`——git 安装只取源码,因此包需要有 `prepare` 脚本(目前未提供)并在 profile 的 `pnpm-workspace.yaml` 里加 `allowBuilds` 条目。

如果 profile 已经挂载了基础 `@deepseek-ai/dsh-subagent-codex` provider(例如 profile 的 `cordis.patch.yml` 里手动 insert 了 `- id: subagent-codex` 行),先移除该行及其依赖再重启——两个包都注册 `codex` provider 名,重名会 fail loud:

```sh
dsh plugin --profile web remove @deepseek-ai/dsh-subagent-codex
# 并删除 ~/.dsh/profiles/web/cordis.patch.yml 中的 `- id: subagent-codex` insert 行
```

standard-codex agent preset 中的 `tool-subagent-codex` 工具行(`provider: codex`)无需改动。然后重启 `dsh web`。

## 产品兼容性与证据

wire 实现了与基础 provider 相同的 0.147.0 app-server 协议面(改编自其 `wire.ts`),将 ephemeral 生命周期参数化并增加了带校验的通知回调。开发证据钉在 `@openai/codex@0.147.0`;npm 包仅作测试依赖,部署时仍由 `PATH` 提供 `codex`。keyless real-product 测试启动真实 app-server 对接回环 Responses fixture,断言已发布 run 可通过 `ctx.subagents.listChildren` 发现,且其记录包含委派任务、答案与收尾的 `turn/end`。

## 已知限制与后续工作

- **消息粒度为完成态 item,而非逐 delta**——`item/agentMessage/delta` 流会被累积,但在 `item/completed` 时作为一条 `assistant/message` 写入;Web UI 不会实时流式显示答案。流式 `assistant/chunk` 投影留待后续。
- **工具投影仅覆盖 `commandExecution` 与 `fileChange` item**——`mcpToolCall`、`webSearch`、`collabToolCall`、`plan`、`reasoning` 等 item 暂被忽略;transcript 是它们的扩展点。
- **无续聊**——子会话是终态的一次性投影会话;通过 harness 的后续消息、冷恢复与 `codex resume` 不在范围内(设置 `ephemeral: false` 可让 Codex 会话在 Codex CLI 侧可恢复)。
- **宿主机负责产品安装与账号状态**——缺失或不兼容的 `codex`、配置错误或鉴权失败会以启动或 run 错误呈现;插件不提供安装器、登录流程或运行时版本门禁。
- **无墙钟超时或副作用回滚**——长任务由调用方取消,取消前修改的文件或外部系统状态不会恢复。
