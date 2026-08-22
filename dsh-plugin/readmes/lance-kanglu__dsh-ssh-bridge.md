# dsh-ssh-bridge

[English](README.en.md)

本地 SSH 桥接服务：**浏览器页面输入目标主机 (user@host[:port]) 与密码 → 本机桥接进程 → SSH 加密通道 → 目标主机**，密码全程不经过聊天记录。主要作为 DSH (DeepSeek Harness) 插件使用，agent 经 `router_exec` 等工具在本机执行远端命令，任意 SSH 目标均可使用，无需预设主机；桥接核心不依赖 DSH，也可独立运行。

> 当前版本：**v0.4.2**

## 部署流程

### 依赖说明

| 程序 | 版本 | 说明 |
| --- | :-: | --- |
| DSH | 0.1.0-rc 系列 | 宿主 (插件模式) |
| pnpm | — | 依赖安装 (由 `dsh plugin` 转发) |
| Node.js | ≥18 | 运行环境 |
| `ssh2` | ^1.17 | SSH 客户端库 (npm install 自动安装) |
| `@deepseek-ai/schemastery` | ^3.18 | 插件配置 schema (npm install 自动安装) |
| `@deepseek-ai/cordis` | ^4.0 | DSH 宿主运行时 (peer 依赖, 由宿主提供, 可选) |

### 具体步骤

```bash
# 1. 安装插件 (从 npm registry)
dsh plugin --profile web add dsh-ssh-bridge

# 2. 重启 DSH
dsh web
```

> **注意：** pnpm 11 默认拦截 `ssh2`/`cpu-features` 的原生构建脚本 (node-gyp)，`dsh plugin add` 会以非零码退出、依赖装上了但插件不会挂载。需先在该 profile 的 `pnpm-workspace.yaml` 放行，再重跑安装：
>
> ```yaml
> allowBuilds:
>   cpu-features: true
>   ssh2: true
> ```

其他安装来源 (GitHub / 本地 tgz)：

```bash
# GitHub (tag 与 npm 版本一致)
dsh plugin --profile web add github:lance-kanglu/dsh-ssh-bridge#v0.4.2

# 本地 tgz (可从 GitHub Releases 下载)
dsh plugin --profile web add /path/to/dsh-ssh-bridge-0.4.2.tgz
```

`dsh plugin add` 会把包追加到 profile 的 `dsh.profile.bundles` 列表，重启 DSH 后插件自动挂载，无需手改配置；工具注册在全局层，所有会话的 agent 均可调用。

部署验证：`dsh --profile web --dump-config` 的组合配置树中应出现：

```
- id: ssh-bridge
  name: dsh-ssh-bridge/plugin
  config:
    basePort: 23991
```

手动方式 (本地开发调试，不经过 bundle)：把包放到部署的 `profiles/node_modules` 下 (可直接 `junction` 指向本项目目录)，再在 `$DSH_HOME` 的 cordis patch / 预设中加入一行：

```yaml
- id: ssh-bridge
  name: dsh-ssh-bridge/plugin
  config:
    basePort: 23991
```

> **提示：** 预设场景可用 `agentPresets.standingKeyFor('<预设id>')` 做 mount 校验 (会真实挂载整棵插件树)。

### 独立运行 (可选)

桥接核心不依赖 DSH，也可独立运行：

```bash
# 1. 安装依赖
npm install

# 2. 启动服务
npm start
# 等价于: node bridge.cjs

# 3. 打开页面
# 浏览器访问 http://127.0.0.1:23991
```

部署验证：启动日志输出如下，且浏览器可打开页面：

```
[ssh-bridge] 已启动: http://127.0.0.1:23991
```

## 使用说明

### 浏览器页面

1. 打开 `http://127.0.0.1:23991`，输入目标主机 (`user@host[:port]`) 与密码，点「连接」或回车；
2. 状态变为「已连接」后，下方输入框即目标主机的交互终端 (支持 ANSI 颜色渲染)，标题栏出现「断开连接」按钮；
3. 在终端输入 `exit` 会结束整个 SSH 会话 (与常规 SSH 客户端一致)；也可点「断开连接」按钮；
4. 断开后目标主机保留、密码清空，可重新输入密码连接；
5. 页面底部日志面板实时显示连接与请求状态，出错时可见具体原因。

### 命令执行 API (供代理 / 脚本调用)

每次启动生成随机 token 并打印在启动日志 (`[ssh-bridge] token=xxxx`)，调用以下接口需携带：

| 接口 | 方法 | 参数 | 说明 |
| --- | :-: | --- | --- |
| `/api/auth` | POST | `{password, target?}` | 提交目标与密码建立 SSH 连接 (密码不写日志、不落盘；目标格式 `user@host[:port]`) |
| `/api/exec` | POST | `{cmd, token}` | 在目标主机执行一条命令，返回 `{code, stdout, stderr}` |
| `/api/input` | POST | `{line, token}` | 向交互终端写入一行命令 (写 `exit` 会结束整个会话) |
| `/api/ping` | POST | `{token}` | 查询连接状态 `{ok, connected}` |
| `/api/disconnect` | POST | `{token}` | 断开 SSH 连接 (等价于页面「断开连接」按钮) |
| `/api/reconnect` | POST | `{token}` | 复用页面认证时保存的凭据重新连接；未认证过返回 409 |

示例 (PowerShell)：

```powershell
$body = @{ token = '<启动日志中的 token>'; cmd = 'uname -a' } | ConvertTo-Json
Invoke-RestMethod -Uri http://127.0.0.1:23991/api/exec -Method Post -ContentType 'application/json' -Body $body
```

> **安全：** 服务只监听 `127.0.0.1`，外部网络无法访问；密码只在浏览器 → 本机进程 → SSH 加密通道之间流转。
> **注意：** 端口 `23991` 被占用时自动顺延 (`23992`、`23993`...)，以启动日志为准。
> **提示：** 更新页面代码后需强制刷新 (Ctrl+F5) 避免旧缓存；交互终端需在真实 SSH 会话中使用，网页终端仅回车可用。

## DSH 插件化

### 机制

DSH 插件即 cordis 插件 (npm 包)：加载器 (`@deepseek-ai/cordis-plugin-loader`) 按包名导入插件、应用配置，行声明于 `cordis.yml` 或 patch 文件；模型工具经 `tools` 注册表挂载执行器，schema 自动注入提示词 (`tool-pwsh`、`tool-bash` 同机制)。

### 插件适配器

`plugin/index.cjs` 为 cordis 插件对象 (已对照 DSH 0.1.0-rc 实际运行时源码校准)：

- `Config` (schemastery) 声明配置并做默认值校验 — cordis 只读 `Config` 字段，`schema` 会被忽略；
- `inject: ['tools']` 声明硬依赖，否则 `ctx.tools` 属性访问会抛 `cannot get property ... without inject`；
- 只经 `tools.register()` 注册执行器 (definition 必须含 `output: { schema, render }`，否则 register 直接抛 TypeError)。工具 schema 由 DSH 的 `ToolRuntime.wireSchemas` 从注册表自动注入 prompt，**不要再调用 `systemPrompt.tools()` 重复注册**，否则模型请求报 `Tool names must be unique` (INVALID_REQUEST 400)；
- 清理经 `ctx.effect()` 注册 — cordis 对函数声明形式的 `apply` 用 `new` 调用，apply 返回值会被当作类实例丢弃，不能用于 dispose。

注册三个工具：

| 工具 | 作用 |
| --- | --- |
| `router_exec` | 在目标主机执行一条命令；描述中携带桥接页面地址，并明确要求 agent 不索取/重复对话中的登录信息 |
| `router_disconnect` | 断开 SSH 连接 (等价于页面「断开连接」) |
| `router_reconnect` | 复用页面认证时保存的凭据重新连接 (密码仅存进程内存) |

已含三个契约/端到端测试：`node test-plugin.cjs` (cordis 注入/Config/register 契约，含「不得重复注册 schema」回归断言) 与 `node test-mount.cjs` (真实 SystemPrompt/ToolRuntime + scoped ctx 端到端，断言三个工具进入 scoped 层、prompt assemble 中恰好出现一次且工具名全局唯一)，以及 `node test-e2e.cjs` (真实本地 ssh2 服务器：认证 → exec → 断开 → 重连 → `exit` 结束会话)。

#### 配置项

| 配置 | 默认值 | 说明 |
| --- | :-: | --- |
| `bindHost` | `127.0.0.1` | 监听地址，保持回环 |
| `basePort` | `23991` | 起始端口，占用自动顺延 |
| `execTimeoutMs` | `60000` | 单条命令超时 |

> **说明：** 目标主机不预设，在桥接页面认证时输入 `user@host[:port]` 即可；CLI 模式可用环境变量提供默认目标，仅作页面预填。

注意：插件 ABI 目前为 `0.1.0-rc` 系列，第三方暂无公开文档；本适配器已按上述契约校准并测试通过。

### 代码结构

| 文件 | 作用 |
| --- | --- |
| `server.cjs` | 桥接核心 `createBridge()`，CLI 与插件共用 |
| `bridge.cjs` | CLI 入口，支持环境变量配置 (`SSH_BRIDGE_PORT`、`SSH_BRIDGE_ROUTER` 等) |
| `page.js` | 浏览器页面脚本 (ANSI 渲染) |
| `plugin/index.cjs` | DSH 插件适配器 |
| `test-parser.cjs` | ANSI 渲染器测试 (`npm test`) |
| `test-plugin.cjs` | 插件 cordis 契约测试 (`node test-plugin.cjs`) |
| `test-mount.cjs` | 插件 scoped 挂载端到端测试 (`node test-mount.cjs`) |
| `test-e2e.cjs` | 桥接核心端到端测试 (本地 ssh2 服务器, `node test-e2e.cjs`) |

## 常见问题

- **`dsh plugin add` 报 `ERR_PNPM_IGNORED_BUILDS`**：pnpm 11 默认拦截 `ssh2`/`cpu-features` 的原生构建脚本，`add` 以非零码退出且插件不会挂载。先在该 profile 的 `pnpm-workspace.yaml` 配置 `allowBuilds: { cpu-features: true, ssh2: true }`，再重试。
- **页面打开无反应 / 点「连接」没反应**：强制刷新 (Ctrl+F5)；确认服务在运行。
- **终端输出出现 `[1;34m` 等原始转义码**：旧缓存所致，强制刷新即可 (已内置 ANSI 渲染器)。
- **`/api/exec` 返回 `not connected`**：先在页面完成密码认证，或让 agent 执行 `router_reconnect`。
- **终端输入 `exit` 后页面仍显示已连接**：旧版本行为，v0.4 起 `exit` 会结束整个会话；若页面缓存了旧脚本请强制刷新 (Ctrl+F5)。
- **`/api/auth` 返回 `missing target`**：请求体需带 `target`，格式为 `user@host[:port]`；插件模式下未配置默认目标时该项必填。
- **端口被占用**：服务自动顺延端口，以启动日志为准。
- **密码会泄露吗**：不会。密码仅存于进程内存，不打印、不落盘；token 仅限本机、防跨站请求。

## 更新说明

### v0.4.2

**文档**：

- README 重构为插件优先结构：部署流程改为 `dsh plugin add` 安装，独立运行降为「独立运行 (可选)」小节；
- 补充 pnpm 11 需在 `pnpm-workspace.yaml` 放行 `ssh2`/`cpu-features` 原生构建的说明。

### v0.4.1

**发布**：

- 声明 `dsh.bundle.patch` 清单，支持 `dsh plugin add dsh-ssh-bridge` 一键安装；
- README 补充 npm / GitHub / 本地 tgz 三种安装方式。

### v0.4

**连接管理**：

- 页面新增「断开连接」按钮；终端输入 `exit` 会结束整个 SSH 会话 (与常规 SSH 客户端一致)，不再停留在「已连接但无 shell」状态；
- 新增 `/api/disconnect` 与 `/api/reconnect`，agent 侧新增 `router_disconnect` 与 `router_reconnect` 工具，可依用户指令断开/重连 (重连复用页面认证时保存的凭据，密码仅存进程内存)；
- 工具描述携带桥接页面地址并明确要求 agent 不索取/重复对话中的登录信息，不假设具体主机；页面占位改为中性 `user@192.168.x.x`；
- 修复连接生命周期竞态：断开/重连后，旧连接迟到的 `close`/shell `close` 事件不再污染或误杀新连接；
- 新增 `test-e2e.cjs` (真实本地 ssh2 服务器端到端)。

### v0.3

**通用化**：

- 目标主机不再预设，改为在浏览器页面输入 `user@host[:port]` 后连接，任意 SSH 目标均可使用；
- `/api/auth` 新增 `target` 参数，插件配置移除 `routerHost`/`routerUser`/`routerPort`；
- 插件适配器按 DSH 0.1.0-rc 实际契约校准：`Config`/`inject`/`output {schema, render}`/`ctx.effect()`；
- 修复工具重复注册：插件只经 `tools.register()` 注册，不再调用 `systemPrompt.tools()` — 注册表工具由 `ToolRuntime.wireSchemas` 自动注入 prompt，重复注册导致模型请求报 `Tool names must be unique`；
- 新增 `test-plugin.cjs` 与 `test-mount.cjs` 两个插件契约测试。

### v0.2

**新增**：

- DSH 插件适配器 `plugin/index.cjs`，可注册 `router_exec` 工具 (实验性)；
- 核心重构为 `server.cjs` (`createBridge()`)，CLI 与插件共用；
- CLI 支持环境变量配置，新增 `LICENSE` (MIT)。

### v0.1

第一个正式版本。核心能力：浏览器密码认证、交互终端 (ANSI 颜色渲染)、本机 exec API、独立测试 (`npm test`)。
