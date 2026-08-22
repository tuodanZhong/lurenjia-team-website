# dsh-acp-for-bitfun

BitFun 支持 ACP deepseek-harness。

一个 [DeepSeek Harness (dsh)](https://github.com/deepseek-ai/deepseek-harness) 插件 bundle：
通过 **Agent Client Protocol (ACP) v1 over stdio** 把 [BitFun](https://github.com/GCWing/BitFun)
接入 dsh，作为 dsh 会话的 subagent。dsh 里任意会话都可以用 `subagent_bitfun`
工具把任务委托给 BitFun 执行。

- [BitFun](https://github.com/GCWing/BitFun)
- [deepseek-harness](https://github.com/deepseek-ai/deepseek-harness)

## 工作原理

```
dsh 会话 ──subagent_bitfun 工具──▶ dsh-subagent-acp (ACP 客户端)
                                        │ 每个任务 spawn 一个独立进程
                                        ▼
                              bitfun acp (ACP server, stdio JSON-RPC)
                                        │
                                        ▼
                              BitFun Agent Runtime
```

- 本 bundle 复用 dsh 官方的 [`@deepseek-ai/dsh-subagent-acp`](https://github.com/deepseek-ai/deepseek-harness/tree/main/packages/subagent/subagent-acp)
  作为 ACP 客户端：每次委托启动一个全新的 `bitfun acp` 子进程，完成
  `initialize → session/new → session/prompt` 并流式收集 `agent_message_chunk`。
- 工具通过 [`@deepseek-ai/dsh-tool-subagent`](https://github.com/deepseek-ai/deepseek-harness/tree/main/packages/subagent/tool-subagent)
  挂载，模型见到的工具名默认为 `subagent_bitfun`。
- 任务结束时关闭子进程 stdin（EOF 宽限 6s → SIGTERM → SIGKILL），BitFun 子进程
  在 SIGTERM 下立即退出，会话数据由 BitFun 自身持久化。

## 前置条件

- [BitFun CLI](https://github.com/GCWing/BitFun)：安装后确认
  `bitfun acp doctor` 通过（BitFun 的 ACP server 内置于 CLI）。
- [dsh](https://github.com/deepseek-ai/deepseek-harness)：`npx @deepseek-ai/dsh --version`，
  需要 `>= 0.1.0-rc.6`（与依赖的 subagent 包版本匹配）。
- [pnpm](https://pnpm.io/)：`dsh plugin` 通过 pnpm 安装 bundle。

## 安装

```sh
# 把 bundle 加进你的 dsh profile（从 npm 或本地目录）
dsh plugin --profile web add dsh-acp-for-bitfun

# 或者从本地 checkout 安装
dsh plugin --profile web add ./dsh-acp-for-bitfun

# 启动
dsh web
```

加载时插件会用 `bitfun --version` 探测 BitFun CLI：不在 PATH 上时启动直接失败
（fail loud），错误信息会提示安装 BitFun 或配置绝对路径。

## 配置

在 profile 的 `cordis.patch.yml`（`$DSH_HOME/profiles/<name>/cordis.patch.yml`）里
按 id 覆盖：

```yaml
- id: bitfun-acp
  name: dsh-acp-for-bitfun
  config:
    command: /absolute/path/to/bitfun   # 默认 'bitfun'（PATH 解析）
    providerName: bitfun                # 默认 'bitfun'
    toolName: subagent_bitfun           # 默认 'subagent_bitfun'
    permission: reject                  # 'reject' | 'allow'
    acpArgs: ['acp']                    # 默认 ['acp']
    env: {}                             # 传给 BitFun 子进程的额外环境变量
    checkOnStart: true                  # 加载时探测 bitfun，缺失则启动失败
```

| 配置项 | 默认值 | 说明 |
|---|---|---|
| `command` | `bitfun` | BitFun CLI 可执行文件：PATH 上的名字或绝对路径 |
| `providerName` | `bitfun` | `ctx.subagents` 上的 provider 名 |
| `toolName` | `subagent_bitfun` | 模型可见的工具名 |
| `permission` | `reject` | BitFun 权限请求的自动应答策略（`reject` / `allow`） |
| `acpArgs` | `['acp']` | 追加在 `command` 后的参数 |
| `env` | `{}` | BitFun 子进程的额外环境变量 |
| `checkOnStart` | `true` | 加载时探测 `command --version`，缺失则 fail loud |

## 验证

1. BitFun 侧自检：`bitfun acp doctor`
2. dsh 配置树里确认插件行：

   ```sh
   dsh --profile web --dump-config | grep -A 2 bitfun
   ```

3. 在 dsh 会话里让模型调用 `subagent_bitfun` 工具，委托一个简单任务
   （例如 "用 subagent_bitfun 回复 hello"），确认返回 BitFun 的输出。

## 兼容性

- BitFun `>= 0.2.17`（ACP v1 server，`bitfun acp`）。
- dsh `>= 0.1.0-rc.6`。
- deepseek-harness 目前处于 developer preview，插件依赖其 `rc` 版本，
  升级 dsh 时请同步升级本 bundle。

## License

[MIT](LICENSE)
