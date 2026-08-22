# dsh-mcp-bridge

![ci](https://github.com/Chhlafiu4312/dsh-mcp-bridge/actions/workflows/ci.yml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**Connect the entire [MCP](https://modelcontextprotocol.io) ecosystem to [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) with one file. Zero dependencies. No SDK.**

Your DSH agent gets every tool from any MCP server — filesystem, GitHub, databases, search, memory, and thousands of community servers — as native tools it can call directly:

```
You: Create a GitHub PR for the changes in ./app
Agent: [calls mcp_github_create_pull_request] ✓ PR #42 created
```

![architecture](assets/architecture.svg)

## ✨ Why people use it

| | |
|---|---|
| 🔌 **One line to 1000+ tools** | The MCP ecosystem is the largest tool catalog for agents. This bridge plugs all of it into DSH. |
| 🪶 **Zero dependencies** | Raw JSON-RPC 2.0 over stdio, ~400 lines of plain JavaScript. No SDK, no native modules. |
| 🌐 **stdio + HTTP/SSE** | Local servers via `command`, remote servers via `url` (bridged through `mcp-remote`). |
| 🔁 **Auto-registration** | Every tool becomes `mcp_<server>_<tool>` the moment the server connects. |
| 🧹 **Clean lifecycle** | Child processes are terminated when the plugin stops or updates. |
| 🛡️ **Honest boundaries** | Unsupported JSON-Schema keywords degrade to open inputs — the MCP server stays the authority. |

## 🚀 Quick start

**A. `dsh plugin add` (recommended — the repo is a `dsh.bundle`)**

```bash
dsh plugin --profile web add "github:Chhlafiu4312/dsh-mcp-bridge#main"
```

Then restart `dsh web` and configure servers via `DSH_MCP_SERVERS` (see below).

**B. Dynamic plugin (one session, no files)**

Open a DSH session, ask your agent to run the bridge via `cordis_define` (paste the code from `plugin.js`), or define it yourself — then talk to it:

```js
// code.host body — minimal form
return {
  inject: ['subprocess', 'tools', 'timer'],
  apply(ctx) {
    // ... paste the body of plugin.js here ...
  },
}
```

**C. Permanent (agent preset)**

```bash
# 1. create your preset directory
mkdir -p ~/.dsh/.agent-presets/mcp-agent

# 2. copy the repo files in
cp plugin.js ~/.dsh/.agent-presets/mcp-agent/
cp agent.cordis.yml.example ~/.dsh/.agent-presets/mcp-agent/agent.cordis.yml
cp preset.yml.example ~/.dsh/.agent-presets/mcp-agent/preset.yml

# 3. (optional) configure your servers
export DSH_MCP_SERVERS='[
  {"id":"filesystem","command":"npx","args":["-y","@modelcontextprotocol/server-filesystem","~/projects"]},
  {"id":"github","command":"npx","args":["-y","@modelcontextprotocol/server-github"],"env":{"GITHUB_PERSONAL_ACCESS_TOKEN":"your_github_token"}}
]'

# 4. start a session on the `mcp-agent` preset — done
```

The agent instantly sees tools like `mcp_filesystem_list_directory`, `mcp_github_create_issue`, … plus `mcp_status` to inspect every connection.

## 🔧 Configuration

Servers are a JSON array. Each entry is either **stdio** or **url**:

```jsonc
{
  "id": "my-server",                // tool prefix: mcp_<id>_<tool>
  "command": "npx",                 // executable (stdio only)
  "args": ["-y", "server-pkg"],     // argv after the executable
  "cwd": "/abs/path",               // optional working directory
  "env": { "KEY": "value" },        // optional environment
  "url": "https://x.example/mcp",   // or: remote HTTP/SSE via mcp-remote
  "disabled": false,                // keep configured but inactive
  "allowTools": ["search_*"],       // optional: register only these tools
  "denyTools": ["delete_*"],        // optional: hide these tools
  "timeoutMs": 120000               // optional per-server call timeout
}
```

| Field | Type | Meaning |
|---|---|---|
| `id` | string, required | tool prefix — tools become `mcp_<id>_<tool>` |
| `command` + `args` | string + string[] | stdio server executable and its argv |
| `url` | string | remote server (HTTP/SSE, bridged through `mcp-remote`) |
| `cwd` | string | working directory (default: the process cwd) |
| `env` | object | extra environment variables |
| `disabled` | boolean | listed in `mcp_status` but never connected or validated |
| `allowTools` / `denyTools` | string[] | exact-name filters, combinable — hide destructive tools |
| `timeoutMs` | number | per-server call timeout in ms (default 120000) |

Set the array through `DSH_MCP_SERVERS` (JSON), or edit the defaults in `resolveServers()` inside `plugin.js`. Ready-made examples: [`examples/servers.json`](examples/servers.json) — filesystem, GitHub, fetch, memory, Postgres, remote.

## 🧠 How it works

Detailed walkthrough in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md):

```
DSH tools registry                    MCP server (child process)
─────────────────                    ───────────────────────────
mcp_<srv>_<tool>  ── tools/call ──▶  npx <server>        (stdio)
                  ◀── text/JSON ────  └─ or mcp-remote <url> (HTTP)
```

1. **Spawn** — each configured server starts as a managed child process.
2. **Handshake** — `initialize` + `notifications/initialized` over newline-delimited JSON-RPC 2.0.
3. **Discover** — `tools/list` returns every tool with its JSON Schema.
4. **Register** — each tool is registered on the DSH tools registry; schemas are sanitized into the DSH parameter DSL.
5. **Call** — the model calls the tool; the bridge forwards `tools/call` and renders the text content back (120 s cooperative timeout, concurrency-safe).
6. **Teardown** — stopping the plugin unregisters the tools and terminates every process.

## 🛣️ Roadmap

- [ ] Auto-reconnect with backoff
- [ ] Native streamable-HTTP client (drop the `mcp-remote` dependency for `url` servers)
- [ ] Per-server permission prompts for destructive tools

## 🔒 Security notes

- MCP servers run with **your** permissions — only connect servers you trust.
- The filesystem server is scoped: give it only the directories the agent may touch.
- API tokens travel through the `env` field; prefer a secret manager or environment variables in production.
- Full trust model and hardening advice: [SECURITY.md](SECURITY.md).

## ❓ FAQ

**Can I use my own MCP server?** Yes — anything that speaks MCP over stdio or streamable HTTP works. Point `command`/`args` at it (or `url` for remote servers) and its tools appear as `mcp_<id>_<tool>`.

**What happens when a server crashes?** The bridge retries up to 3 times with 2s/5s/10s backoff and re-registers the tools on the new connection. Check `mcp_status` for the current state.

**Do I need to restart DSH after changing config?** For the `dsh plugin`/preset install, yes — the config is read at plugin start. `disabled: true` keeps an entry configured without connecting it.

**Why not the official MCP SDK?** The SDK would drag a dependency tree into a plugin that only needs newline-delimited JSON-RPC. Zero dependencies keeps installs instant and reviewable (~400 lines).

**Does it support resources and prompts?** Yes — servers that declare those capabilities get `mcp_<server>_list_resources`, `mcp_<server>_read_resource`, `mcp_<server>_list_prompts`, and `mcp_<server>_get_prompt` tools automatically.

**Upgrading from a pre-0.7.0 install?** The npm package was renamed to `dsh-mcp-connect` — remove the old dependency once so the two layers never both activate: `dsh plugin --profile web remove dsh-mcp-bridge`.

**`npx`-based servers fail with `EPERM` / "root-owned files"?** Your npm cache was polluted by an old `sudo npm` run. Either fix it once:

```bash
sudo chown -R "$(id -u):$(id -g)" ~/.npm
```

or sidestep it per server by giving `npx` a writable cache:

```json
{ "id": "filesystem", "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-filesystem", "/allowed/path"],
  "env": { "npm_config_cache": "/path/to/writable/npm-cache" } }
```

## 🤝 Contributing

Issues and PRs welcome. `node scripts/demo.mjs` prints a one-shot demo transcript against the local fixture — the raw material for a README GIF. Test fixture included: `test/mcp-http-test-server.cjs` is a minimal streamable-HTTP MCP server you can run locally to verify the HTTP path end-to-end.

## 📄 License

MIT — see [LICENSE](LICENSE).

---

# dsh-mcp-bridge（中文）

**一个文件，把整个 [MCP](https://modelcontextprotocol.io) 生态接进 DeepSeek Harness。零依赖，不用 SDK。**

你的 DSH agent 可以直接调用任何 MCP server 的全部工具——文件系统、GitHub、数据库、搜索、记忆，以及社区里成千上万的 server：

```
你：把 ./app 的改动提一个 GitHub PR
Agent：[调用 mcp_github_create_pull_request] ✓ 已创建 PR #42
```

## ✨ 亮点

- 🔌 一行配置接入 1000+ 现成工具（MCP 生态是 agent 最大的工具目录）
- 🪶 零依赖：原生 JSON-RPC 2.0 over stdio，约 400 行纯 JavaScript
- 🌐 同时支持 stdio（本地 `command`）与 HTTP/SSE（远程 `url`，经 `mcp-remote` 桥接）
- 🔁 工具自动注册为 `mcp_<server>_<tool>`
- 🧹 插件停止/更新时自动清理子进程
- 🛡️ 不支持的 JSON-Schema 关键字安全降级，MCP server 始终是最终校验方

## 🚀 快速开始

**A. 动态插件（单会话，不改文件）**：在 DSH 会话中用 `cordis_define` 粘贴 `plugin.js` 的代码并运行。

**B. 永久挂载（agent preset）**：

```bash
mkdir -p ~/.dsh/.agent-presets/mcp-agent
cp plugin.js ~/.dsh/.agent-presets/mcp-agent/
cp agent.cordis.yml.example ~/.dsh/.agent-presets/mcp-agent/agent.cordis.yml
cp preset.yml.example ~/.dsh/.agent-presets/mcp-agent/preset.yml
export DSH_MCP_SERVERS='[{"id":"filesystem","command":"npx","args":["-y","@modelcontextprotocol/server-filesystem","~/projects"]}]'
```

然后用 `mcp-agent` 预设开新会话即可。工具命名规则：`mcp_<server>_<tool>`，另有 `mcp_status` 查看每个 server 的连接状态。

## 🔧 配置

server 配置是一个 JSON 数组，每项支持 `id / command / args / cwd / env`（stdio）或 `url`（HTTP，经 mcp-remote 桥接）。通过 `DSH_MCP_SERVERS` 环境变量或编辑 `plugin.js` 里的 `DEFAULT_SERVERS` 传入。示例见 [`examples/servers.json`](examples/servers.json)。

## 🧠 工作原理

spawn 子进程 → `initialize` 握手 → `tools/list` 发现工具 → 消毒 JSON Schema 并注册为 DSH 工具 → 模型调用时转发 `tools/call` → 渲染文本结果（120 秒协作超时、并发安全）→ 插件停止时注销工具并终止进程。

## 🛣️ 路线图 / 🔒 安全提示

路线图：resources/prompts 支持、断线自动重连、原生 streamable-HTTP 客户端、危险工具的逐服务器授权确认。安全：MCP server 以你的权限运行，只连接可信 server；filesystem server 只授予必要的目录；API token 走 `env` 字段，生产环境请用密钥管理器。

## 📄 License

MIT — 见 [LICENSE](LICENSE)。
