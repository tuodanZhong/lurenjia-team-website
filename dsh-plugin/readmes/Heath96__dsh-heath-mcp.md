# dsh-heath-mcp

[DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (dsh) 的 **MCP 服务桥接插件** —— 一个插件连遍所有主流 MCP 服务器，Web 端可视化配置，重启零操作自动恢复。

## ✨ 核心优点

| 能力 | 说明 |
| --- | --- |
| 🔌 **三种传输协议全支持** | `stdio`（本地进程）· `streamable-http`（远程端点）· **旧版 `sse` 事件流** —— 兼容性拉满，别人连不上的旧式 SSE 端点（如 Burp Suite）我们直接连 |
| 🎯 **Burp Suite 开箱即用** | 原生支持 Burp 的 SSE 端点（`http://127.0.0.1:9876`），**无需 mcp-proxy 等任何中间代理**；也兼容代理方式（见下文专题） |
| 🧰 **模型直接调用 MCP 工具** | 每个服务器的工具注册为 `mcp__<服务名>__<工具名>`，GitHub / Burp 的工具模型立即可用 |
| 🖥️ **Web 可视化配置** | 设置 → MCP 服务：**表单新增**（自动写 JSON）或 **粘贴 JSON** 两种方式；实时状态表格、每行「测试连接 / 重连」——改配置**无需重启** |
| ♻️ **持久挂载，重启零操作** | 挂载在 profile 组合中，每次 `dsh web` 启动自动加载配置并重连（指数退避），彻底告别"重启后手动恢复" |
| 📦 **零构建、纯 ESM** | 无编译步骤，clone 即装；MIT 协议 |

## 安装（clone → 装包 → 加行 → 重启）

```sh
# 公开仓库，直接安装：
dsh plugin --profile web add github:Heath96/dsh-heath-mcp

# 或 clone 后本地安装：
git clone https://github.com/Heath96/dsh-heath-mcp
dsh plugin --profile web add ./dsh-heath-mcp
# 等价于：pnpm --dir $DSH_HOME/profiles/web add --offline ./dsh-heath-mcp
```

然后往 profile 补丁加一行（`$DSH_HOME/profiles/<name>/cordis.patch.yml`）：

```yaml
- insert:
    - id: mcp-bridge
      name: 'dsh-heath-mcp'
      config: {}
```

重启 `dsh web`。插件自动读取 `$DSH_HOME/.dsh/mcp-servers.json`（不存在则自动创建；建议直接在 Web 端配置）。

## 🎯 Burp Suite 连接专题

**方式一（推荐，免代理，插件原生支持）**

```json
{
  "servers": {
    "burpsuite": {
      "transport": "sse",
      "url": "http://127.0.0.1:9876",
      "enabled": true
    }
  }
}
```

Web 端操作：设置 → MCP 服务 → 「+ 新增服务」→ 传输类型选 **sse** → URL 填 `http://127.0.0.1:9876` → 保存。Burp 在线即连上，27 个工具（HTTP1/2 请求、Repeater、Intruder、Scanner、Collaborator 等）立即可被模型调用。

**方式二（mcp-proxy 代理，可选）**

如果你出于鉴权需要坚持用 `mcp-proxy.jar`（它会将 Burp SSE 包装为带鉴权的 HTTP 端点），先保持代理常驻运行：

```sh
java -jar <你的 mcp-proxy.jar 路径> --sse-url http://127.0.0.1:9876
```

然后把插件的配置指向代理的 HTTP 端点（`transport: "streamable-http"`）。注意：插件直连方式一不受任何代理稳定性影响。

## 配置速查（JSON / 表单通用）

| 字段 | 适用传输 | 说明 |
| --- | --- | --- |
| `transport` | 全部 | `stdio` \| `streamable-http` \| `sse` |
| `command` / `args` / `env` / `cwd` | stdio | 子进程规格（cross-spawn 自动处理 `.cmd`） |
| `url` / `headers` | http, sse | 端点 + 认证头 |
| `enabled` | 全部 | 默认 `true` |
| `toolCallTimeoutMs` | 全部 | 单次调用超时，默认 60000 |
| `reconnect.*` | 全部 | `enabled` / `initialDelayMs` / `maxDelayMs` / `maxAttempts` 指数退避，默认开启 |

完整示例：

```json
{
  "servers": {
    "github": {
      "transport": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": { "GITHUB_TOKEN": "ghp_xxx" },
      "enabled": true
    },
    "burpsuite": {
      "transport": "sse",
      "url": "http://127.0.0.1:9876",
      "enabled": true
    },
    "remote": {
      "transport": "streamable-http",
      "url": "https://example.com/mcp",
      "headers": { "Authorization": "Bearer xxx" },
      "enabled": false
    }
  }
}
```

## 连通性验证

```sh
cd dsh-heath-mcp
npm install          # 引入 @modelcontextprotocol/sdk
node scripts/verify-servers.mjs [路径/mcp-servers.json]
```

逐服务输出 `PASS` / `SKIP` / `FAIL`，任一失败即非零退出。

## 常见问题

- **`npx` on Windows**：SDK 用 cross-spawn，`.cmd` shim 自动解析。
- **服务连不上但插件正常**：连接失败不致命（默认继续后台重试），看状态表的"最近错误"列定位原因。
- **Burp 连不上**：先确认 Burp 本体在运行且 MCP 监听 9876；重启 Burp 后点该行「重连」。
- **"Failed to load plugins"**：多为 client 模块 inject 未填服务名所致——本仓库已修复为 `['slots']`，勿改回包名。
- **chrome（mcp-chrome）重启 DSH 后连不上**：该 bridge 只允许一条客户端连接，DSH 重启时连接未优雅关闭，bridge 会残留死连接拒绝新连接。修复：在 Chrome 扩展图标上「断开 → 连接」重建通道，然后到 MCP 服务页点该行「重连」。

## License

MIT — see [LICENSE](LICENSE).
