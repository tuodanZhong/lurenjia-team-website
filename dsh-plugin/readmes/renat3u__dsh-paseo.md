# dsh-paseo

**把 dsh（DeepSeek Harness）作为 Paseo 的 ACP provider：在 Paseo 界面里并行运行和管理多个 dsh agent，并稳定地拉起 dsh。**

[English](README.en.md)

---

## 特性

- **Paseo**：dsh 注册为 Paseo 的 ACP provider（Agent Client Protocol over stdio JSON-RPC），在 Paseo 的桌面 / Web / 手机客户端里直接选择 "DSH (DeepSeek Harness)" 创建会话。
- **并行 agent**：每个 dsh 会话是一个独立 dsh 进程（独立会话日志、独立 workspace、独立取消路径），Paseo 的 attach / logs / send / stop / delete 全部可用。
- **稳定拉起**：launcher 自动解析 dsh 安装、自愈初始化 `paseo` profile、转发信号、保持 stdout 协议纯净；Paseo 杀进程 / 断连都能干净收尾。
- **不改 dsh 源码**：dsh 侧通过官方 profile bundle 机制注入一个 ACP 桥插件，只消费公开接缝（`ctx.agents` / `ctx.sessions` / `ctx.approval`）。
- **模型可组合**：默认继承所连接 dsh 服务的默认模型；通过派生 provider + 环境变量可显式覆盖出任意模型 / 端点配置（flash、pro、自定义 baseURL 等）。
- **权限可控**：默认 `workspace-write` 沙箱 + 一次性权限询问（Paseo 界面 allow-once / reject），可选 `danger-full-access`。

## 架构

```
Paseo daemon（桌面 / Web / 手机 / CLI 客户端）
   │  每个 dsh 会话 spawn 一个进程，ACP over stdio（JSON-RPC 2.0）
   ▼
bin/dsh-paseo-launch.mjs        ← 稳定拉起：解析 dsh → 自愈 profile → 信号转发
   （位于 bundle 包内：packages/dsh-paseo/bin/）
   ▼
dsh --profile paseo             ← bundles: [@deepseek-ai/dsh-base, @deepseek-ai/dsh-paseo]
   └─ paseo-acp 桥插件           ← initialize / session/new / prompt / cancel / request_permission
```

## 环境要求

| 依赖 | 版本 | 说明 |
|---|---|---|
| Node.js | ≥ 22.19 | launcher 与构建脚本 |
| pnpm | 11.x | `dsh plugin` 内部转发（profile 安装）；dsh 源码仓库根运行 `pnpm dsh web` 启动 Web 界面 |
| dsh | 当前 rc | 源码快照（仓库根 `pnpm dsh web` 启动 Web 界面）；launcher 解析 `dsh` 可执行：PATH → `~/.dsh/source/current` |
| Paseo | ≥ 0.3 | `@getpaseo/cli`（`npm install -g @getpaseo/cli`）或桌面版 |
| DeepSeek API Key | — | 走 dsh 侧凭据：环境变量 / `~/.dsh/.env` / `~/.dsh/.credentials.yaml` |

## 安装

```sh
# 1) 构建 bundle（把 vendored @deepseek-ai/cordis / dsh seam / ACP SDK 链接进 node_modules）
cd <dsh-paseo 仓库根>
node scripts/build.mjs

# 2) 注册 Paseo provider（幂等，带备份；写入 $PASEO_HOME/config.json，默认 ~/.paseo）
node packages/dsh-paseo/scripts/install-paseo-provider.mjs

# 3) 安装 dsh 侧 profile（launcher 首次拉起时会自动做，也可手动；在 dsh 源码仓库根执行）
pnpm dsh plugin --profile paseo add <dsh-paseo 仓库根>/packages/dsh-paseo
pnpm dsh --profile paseo --dump-config | grep -A5 paseo-acp   # 验证组合配置

# 4) 启动 / 重启 Paseo daemon
paseo start --relay --listen 0.0.0.0:6767 --hostnames true
```

> **注意**：`paseo restart` 不会保留 `--listen` 等启动参数（会退回 `127.0.0.1`，手机将无法直连）。重启请使用完整参数：`paseo restart --relay --listen 0.0.0.0:6767 --hostnames true`。

### 手机连接（可选）

1. 手机安装 Paseo app（App Store / Google Play 搜索 "Paseo"）。
2. 在 daemon 机器上生成配对码：`paseo daemon pair`（输出 QR / 配对链接）。
3. 手机打开配对链接（或扫码）完成配对，即可在手机上看到这台 host 并操作 dsh agent。

`--relay` 开启后手机与 daemon 无需同一网络（端到端加密走 `relay.paseo.sh`）；`--listen 0.0.0.0:6767` 供局域网直连。

## 快速开始

```sh
# 在 Paseo 里跑一个 dsh agent
paseo run --provider dsh "实现用户认证"

# 或：GUI / 手机 app 里新建会话 → provider 选 "DSH (DeepSeek Harness)" → 输入任务
```

首次拉起时 launcher 会自动完成 dsh 侧 profile 安装，无需手工步骤。

## 使用

### 并行运行

每开一个 dsh 会话 = 一个独立 dsh 进程。`paseo ls` 查看所有 agent，`paseo attach <id>` 流式查看输出，`paseo send <id> "任务"` 跟进，`paseo stop <id>` 中断（实测：工具调用被 ABORTED，turn 以 `aborted/user` 收尾）。

### 模型选择

模型路由由 **dsh 侧配置决定**（单一事实源），与所连接的 dsh 服务保持一致：
**未显式覆盖时，Paseo agent 继承 dsh 服务的默认模型选择**（`agent-default-model`
行 → `$DSH_HOME/settings.yaml` / Web Models 页，默认 `deepseek-v4-flash`）。
需要单独选模型时，Paseo 侧用派生 provider + 环境变量显式覆盖：

```jsonc
// ~/.paseo/config.json —— command 由 `node packages/dsh-paseo/scripts/install-paseo-provider.mjs`
// 自动写入 launcher 绝对路径（Windows 为 [node, launcher]）；以下为示意
{
  "agents": { "providers": {
    "dsh":        { "extends": "acp", "label": "DSH (DeepSeek Harness)",
                     "command": ["/absolute/path/to/dsh-paseo/packages/dsh-paseo/bin/dsh-paseo-launch.mjs"],
                     "params": { "supportsMcpServers": false } },
    "dsh-pro":    { "extends": "acp", "label": "DSH Pro",
                     "command": ["/absolute/path/to/dsh-paseo/packages/dsh-paseo/bin/dsh-paseo-launch.mjs"],
                     "params": { "supportsMcpServers": false },
                     "env": { "DSH_PASEO_MODEL": "deepseek-v4-pro" } }
  } }
}
```

改完配置后重启 daemon（带完整参数）。实测：默认 `dsh` provider 的 agent 自报
`deepseek-v4-flash`（跟随服务默认）；`env.DSH_PASEO_MODEL` 显式覆盖后自报对应模型。

### 权限模式

| 模式 | 行为 |
|---|---|
| `workspace-write`（默认） | bash / 文件工具被沙箱围栏在工作区内；越界触发一次性权限询问（Paseo 界面 allow-once / reject，可开 Auto Accept） |
| `danger-full-access` | 完全访问（仅可信机器）；在 provider 的 `env` 里设 `DSH_PERMISSION_MODE=danger-full-access` |

### 会话与日志

- dsh 会话日志落在 `$DSH_HOME/sessions/`，可被 dsh 其他界面查询 / 回放。
- ACP 桥为 fresh-sessions-only（不支持 resume / load / list，与官方 dsh-acp 一致）。
- 桥只输出**已提交的助手文本**（`agent_message_chunk`），不逐 token 流式；reasoning / 工具活动留在 dsh 会话日志。

## 配置参考

### Paseo provider 字段（`~/.paseo/config.json` → `agents.providers.dsh`）

| 字段 | 值 | 说明 |
|---|---|---|
| `extends` | `"acp"` | 泛型 ACP provider |
| `command` | launcher 绝对路径 | Paseo 每 agent spawn 一次 |
| `params.supportsMcpServers` | `false` | **必须为 false**：dsh 桥拒绝非空 `mcpServers`（Paseo 默认会注入内部工具 MCP） |
| `env` | 任意 | 透传给 dsh 进程的环境变量（模型 / 权限选择等） |
| `label` / `description` | 字符串 | 界面显示名 |

### 环境变量（dsh 进程侧）

| 变量 | 默认 | 说明 |
|---|---|---|
| `DSH_PASEO_MODEL` | 继承 dsh 服务默认 | 显式覆盖桥创建的 agent 的模型（每进程求值）；未设置时跟随 dsh 服务默认（settings.yaml / Models 页） |
| `DSH_PASEO_PROVIDER` | 继承 dsh 服务默认 | 显式覆盖 llm 路由；可改 `openai` / `anthropic` 等（llm-pi-ai） |
| `DSH_PERMISSION_MODE` | `workspace-write` | 沙箱模式（同时决定 approval ask/never） |
| `DSH_PASEO_DSH` | 自动解析 | 显式指定 dsh 可执行文件路径 |
| `DSH_HOME` | `~/.dsh` | dsh 主目录（profile / 会话 / 凭据） |
| `DEEPSEEK_API_KEY` / `DEEPSEEK_BASE_URL` | 环境 / `.env` | 密钥与 API 端点（也可在 settings.yaml 配置）。当前版本 `DEEPSEEK_BASE_URL` 只从进程环境读取，`.env` 不再允许覆盖 |

### dsh settings.yaml（热重载，无需重启）

`$DSH_HOME/settings.yaml` 的 `llm-deepseek:` 段可覆盖模型目录、默认模型、**API 地址**（`baseURL`）、思考级别等：

```yaml
llm-deepseek:
  baseURL: https://your-gateway.example/v1
  reasoningEffort: max
  models:
    - id: deepseek-v4-flash
    - id: deepseek-v4-pro
```

## 验证（端到端测试）

```sh
# 不经过 Paseo，直接验证 dsh 的 ACP 服务（隔离问题用）
node tools/acp-smoke-client.mjs          # 走 launcher
node tools/acp-smoke-client.mjs --direct # 直接 spawn dsh（不走 launcher）

# 经过 Paseo 验证
paseo run --provider dsh "Reply with exactly: PONG"
paseo logs <agent-id>                    # 应看到 [User] 提问 + PONG
paseo ls                                 # agent 状态 idle/completed

# 单测
node scripts/test.mjs
```

预期输出（实测）：smoke 打印 `PASS: full ACP round-trip succeeded`；`paseo logs` 显示 `PONG`。

## 目录结构

```
packages/dsh-paseo/          dsh 侧 Cordis bundle
  src/index.ts               ACP 桥插件（改编自 @deepseek-ai/dsh-acp，BSD-3-Clause）
  src/codec.ts               prompt 展平 / turn 结束 → stop reason 映射
  bin/dsh-paseo-launch.mjs   Paseo 的 spawn 入口（稳定拉起 dsh）
  cordis.patch.yml           注入层：paseo-acp 行 + persona 覆盖
packages/dsh-paseo/scripts/install-paseo-provider.mjs  注册 provider 到 Paseo config.json
scripts/build.mjs            构建（链接依赖 + snapshot tsc + 产物校验）
scripts/test.mjs             单测入口
paseo/provider.dsh.json      provider 配置模板
tools/acp-smoke-client.mjs   ACP 端到端冒烟客户端
docs/                        架构细节与排障文档
```

## 已知限制

- 每个 dsh agent 是一个完整 harness 进程（boot ~2-4s，内存 ~150-250MB）——进程级并行的固有成本，与 Paseo 对其他 agent 的处理一致。
- 不支持会话 resume / load / list（fresh sessions only）。
- 桥只输出已提交文本（不逐 token 流式）。
- Paseo UI 内模型选择器为 cosmetic：实际路由由 dsh 侧配置 / `DSH_PASEO_MODEL` 决定。
- 构建期依赖 dsh 快照（`~/.dsh/source/current` 或 `DSH_MONOREPO`）；换快照后需重跑 `node scripts/build.mjs`。

## 故障排查

见 [docs/troubleshooting.md](docs/troubleshooting.md)（症状速查表：provider 不显示、unavailable、MCP 报错、密钥缺失、模型不对、端口监听丢失等）。

## License

MIT（ACP 桥改编自 `@deepseek-ai/dsh-acp`，BSD-3-Clause，见文件头与 LICENSE）。
