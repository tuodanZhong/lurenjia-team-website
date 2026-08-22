# dsh-hud

> 给 DeepSeek Harness 加一套游戏式 HP / MP / TIME 状态 HUD。

**HP** · 当前会话还能聊多少
**MP** · 当前 Provider 还能用多少
**TIME** · 当前工作区已经干了多久

> 直接嵌入 Harness 侧边栏，无需额外 Dashboard。

[English](./README_EN.md)

## 效果预览

![dsh-hud-hero](docs/assets/dsh-hud-hero.png)

> dsh-hud 直接运行在 DeepSeek Harness 侧边栏中。

## 安装

### BigFish 用户

从 [Releases](https://github.com/yuanliangxiannan/dsh-hud/releases) 下载 `dsh-hud-0.1.0.tgz`，然后：

```bash
dsh plugin --profile web add ./dsh-hud-0.1.0.tgz
```

`dsh plugin` 会自动把 `dsh-hud` 加入 `dsh.profile.bundles`。完全退出并重启 BigFish 后生效。

### 原生 DeepSeek Harness 用户

```bash
dsh plugin add ./dsh-hud-0.1.0.tgz
```

### 从源码构建

```bash
npm install
npm run build
npm pack          # 产出 dsh-hud-0.1.0.tgz
```

## HP · MP · TIME

![dsh-hud-status](docs/assets/dsh-hud-status.png)

- **HP** — 当前 Session 剩余上下文容量，快见底时可以考虑 `/compact`
- **MP** — 当前 Provider 剩余资源
- **TIME** — 当前 Workspace 跨 Session 累计的 Agent 工作时间

> HP 看上下文，MP 看资源，TIME 看工作区累计时间。

## Provider-aware MP

![dsh-hud-provider](docs/assets/dsh-hud-provider.png)

> MP 会跟随当前实际使用的 Provider，而不是简单根据模型名称判断。

当前支持：

```text
DeepSeek Official
→ API Balance

OpenCode Go
→ 5H / Weekly / Monthly quota
```

OpenCode Go 的 HUD 主值使用当前最紧张的 quota window。

> OpenCode Go 的 5H / Weekly / Monthly 配额详情。

## 56px Rail

![dsh-hud-rail](docs/assets/dsh-hud-rail.png)

> Harness 侧边栏收窄后，HP / MP / TIME 会自动切换成 Mini HUD，不占用额外空间。

> 56px Rail 下仍然保留 HP / MP / TIME 状态。

## 详细功能

### 三个仪表

- **HP** — 数据来自 Harness 的 `contextPressure` projection（`projectedTokens` / `contextWindow`），`HP% = clamp(100 × (1 − projectedTokens / contextWindow))`；颜色随容量分级：绿 → 黄绿 → 金 → 橙 → 红。
- **MP** — 判断依据是 **Provider 路由（provider route）**，绝不是 model 名——同一个 model 名在不同 Provider 下会显示不同的资源。
- **TIME** — 以 `turn/start` → `turn/end` 为区间，对所有 session 做 interval union 去重（重叠区间不重复计数）；进行中的 turn 计到当前时刻。

### Provider-aware MP 细节

| Provider | 资源 | 数据源 |
| --- | --- | --- |
| DeepSeek Official（`deepseek-official`） | 账户余额（¥） | `GET /user/balance` |
| OpenCode Go（`opencode-go`） | 5H / Weekly / Monthly quota | `GET /zen/go/v1/usage` |
| 其它 | `--`（`NO QUOTA DATA`） | 无适配器 |

- **DeepSeek Official**：MP 显示账户总余额（如 `¥10.73`），进度条相对 `mpMaxBalance`（默认 50 CNY，超过则满格并显示真实金额）。
- **OpenCode Go**：每个窗口 `remaining = clamp(100 − usagePercent)`；主 MP 值取 **bottleneck**：`min(rolling, weekly, monthly)`，即最先可能耗尽的资源；主进度条同样使用 bottleneck。

### HUD 折叠 / 展开

宽侧边栏的完整 HUD 可手动折叠成单个图标按钮（约 34px），再次点击恢复。

- 偏好保存在 `localStorage`，key 为 `dsh-hud:collapsed`。
- 默认展开；收起后刷新/重启仍保持；切换 Session / Workspace 不改变该偏好。

### 配置

可选 `hud:` 配置段，写入 `$DSH_HOME/settings.yaml`（有 schema 注册，缺省使用安全默认值）：

```yaml
hud:
  mpMaxBalance: 50            # 余额折算为满格 MP 条的金额（CNY）
  balanceRefreshMinutes: 5    # Host 侧资源刷新间隔（分钟）
```

## 架构

标准 **Host + Client** 插件，无动态（creative-mode）机制，无 Harness 发行版补丁，无 `node_modules` 手术。

- **Host**（`src/host/`）— 插件入口 `lib/host/index.js`：
  - workspace 身份解析（session cwd → workspaceRegistry），
  - TIME 聚合（FIFO turn 配对 + interval union，5s TTL 缓存 + turn 边界失效），
  - provider-aware 资源适配器（`deepseek-official` 余额 + `opencode-go` 官方 usage endpoint），凭证在进程内通过 `ctx.credentials` 解析，绝不跨 RPC 传输，
  - 私有 JSON-RPC 通道 `/dsh-hud`（官方 Connection seam），
  - 可选 settings 配置（namespace `hud`）。
- **Client**（`src/client/`）— bundle `lib/client.js`：
  - 注册进 `sidebar.footer.action`（wide 行 + 56px rail 两种模式），
  - HP 来自框架 `contextPressure` projection mirror，跟随 session 切换并即时重绘，
  - MP/TIME 通过私有 RPC 通道；进行中的 turn 在本地 tick，
  - 可点击 popover 查看详情、手动刷新，以及官方 COMPACT 动作（`ctx.compaction.compactNow`）。

所有共享 wire 词汇在 `src/shared/types.ts`——纯 JSON，天然无密钥。

## Build

```bash
npm install
npm run build                  # tsc (strict) host + esbuild client bundle → lib/
npm run typecheck              # 仅 strict 类型检查
node scripts/verify-host.mjs   # host 逻辑验证（真实历史测试可选，见下）
```

构建会从已安装的 BigFish 发行版解析 `@deepseek-ai/*` 类型声明；可用 `DSH_TYPES_ROOT` 覆盖位置。

`verify-host.mjs` 的真实历史聚合测试是可选的：设置 `DSH_HOME`（默认 `~/.dsh`）与 `DSH_HUD_VERIFY_WORKSPACE`（要验证的 workspace 绝对路径）后才会执行；未设置时跳过该段，纯逻辑测试始终运行。

## Compatibility

- DeepSeek Harness / BigFish：`@deepseek-ai/*` `0.1.0-rc.6`（见 `package.json` peerDependencies）
- Node.js：≥ 20（构建使用 Node 22 验证）
- 平台：Web profile（浏览器）

## Security

Provider 的凭证只在 **Harness Host 进程内**通过 `ctx.credentials.resolve()` 解析：

- 凭证以“环境变量名 / credential 引用”的形式出现，例如 `DEEPSEEK_API_KEY`、`OPENCODE_GO_API_KEY`；源码中绝无真实 Key / Token。
- 解析后的密钥值**绝不**进入：
  - Client bundle
  - RPC DTO
  - `localStorage`
  - README
  - 日志
- OpenCode Go 的凭证引用由 `llm-pi-ai` 配置的 `apiKeyEnv` 决定，dsh-hud 只复用该 Provider 已有的凭证，不要求重复填写。

## Known Limitations

- v0.1.0 仅内置两个资源适配器：DeepSeek Official 与 OpenCode Go；选择其它 Provider（GLM、OpenRouter、自定义 Provider 等）时 MP 显示 `--`。
- Rail 模式不显示数字，仅 mini 竖条 + tooltip。
- 无 EXP / 等级 / 成就 / 统计图 / 历史记录等扩展功能。
- HUD 折叠为纯手动操作，不做基于 Workspace 数量或 overflow 的自动判断。

## License

[MIT](./LICENSE)
