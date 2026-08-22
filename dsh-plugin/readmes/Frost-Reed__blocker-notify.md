# dsh-blocker-notify

[English](README.en.md) | 简体中文

**DeepSeek Harness（DSH）阻塞提醒插件**：当 Agent 在工作中被卡住、需要用户介入时，在**网页端实时提醒**，让你不用一直盯着屏幕等待操作。

![示例](./assets/show_fullscreen.png)

触发提醒的三类"阻塞"信号：

| 信号 | 说明 |
|---|---|
| **提权 / 审批**（`approval/request`） | Agent 请求提升沙箱权限、或需要审批时（如 read-only 下 `write` 提权）→ **提醒** |
| **沙箱拒绝**（`FS_SANDBOX_DENIED`） | write/edit 在 read-only / workspace-write 模式下被拒 → 仅 Host 记录（诊断用），**不打扰用户** |
| **等待用户交互**（`question` / `plan-review`） | Agent 在等你回答提问、审阅计划 → **提醒** |

> **只提醒需要你操作的事件**（审批 / 提问 / 计划审阅）。沙箱拒绝是已完结事件、无可操作项，保持静默（即使审批策略是 `never` 也不会弹出打扰）。

## 四种提醒方式

| 方式 | 效果 |
|---|---|
| **全局消息（横幅）** | 右上角琥珀色横幅，列出所有被阻塞的会话；每行只显示**会话标题 + 状态**（不写工具名/原因）；**点击条目 = 跳转会话 + 该条立即移除**（不依赖审批结果）；✕ 关闭整个横幅；新阻塞到达时重新出现 |
| **工作区条目标黄并闪烁** | 左侧工作区会话条目上的黄色状态点 **1.1s 闪烁**——黄色标记是 DSH 自带的（"等待用户"状态），本插件加上闪烁动画；阻塞解决后自动停止 |
| **提示音（声响）** | **新增**阻塞出现时，页面播放两声短提示音（Web Audio 合成，无需音频文件）；只在阻塞集合变化（有新阻塞）时响，页面加载时已有的阻塞不响；浏览器未解锁自动播放或环境不支持时静默降级 |
| **操作系统级通知** | **新增**阻塞出现时，浏览器通过 Notification API 弹出**系统通知**（Windows 操作中心 / macOS 通知中心）；点击通知可聚焦 DSH 页面（单个阻塞时直接打开对应会话）；单个阻塞显示「会话标题 — 类别（工具名 — 原因）」，多个阻塞合并为一条；权限**已开启**时横幅标题栏显示小 🔔 图标（点击弹测试通知），**未开启/被拒绝**时横幅显示操作行（一键开启 / 去浏览器设置修复） |

## 怎么用

### 方式一：动态插件（快速启用，5 分钟，推荐先试）

不需要安装任何东西，不需要重启 DSH。**缺点**：进程内存态，DSH 重启后需重新启用。

1. 获取本仓库源码：`git clone https://github.com/Frost-Reed/blocker-notify`（或直接在 GitHub 页面下载）。
2. 打开任意会话（建议 **cordis / 创造模式**），把下面这段指令发给 Agent（把 `<仓库路径>` 换成你本地克隆的路径）：

   ```text
   请把 dsh-blocker-notify 启用为动态插件：
   1. 用 read 工具读取 <仓库路径>/dynamic/host.js 和 <仓库路径>/dynamic/client.js（分别是 code.host 与 code.client 的函数体，直接使用文件内容）。
   2. 调用 cordis_define：plugin: { kind: "new", idPrefix: "ntfy" }；name: "blocker-notify"；purpose 一句话；code.host = host.js 内容；code.client = client.js 内容。
   3. 用 cordis_define 返回的 pluginId/packageId 调用 cordis_run（mode: "run"）。
   4. 运行请求可能需要用户在网页端批准 Client 半；等待批准结果，不要重复请求。
   5. 完成后用 cordis_inspect_self(pluginId, packageId) 确认 host/client 均为 running。
   ```

3. 在网页端**批准** Client 半的运行请求（一次即可）。
4. 立即验证（见下文"验证"）。

### 方式二：正式 bundle 安装（持久生效，v0.2.0）

按 DSH 的正式插件规范打包（`dsh.bundle` + `dsh.client`），安装后跨重启生效。

> 若 `dsh` 不在 PATH（例如从源码仓构建运行、或未全局安装），把下面命令里的 `dsh` 换成 `pnpm dsh`（在源码仓根目录）或 `npx @deepseek-ai/dsh`。

**从 GitHub 安装**（已发布，推荐）：

```powershell
dsh plugin --profile web add github:Frost-Reed/blocker-notify
```

**从本地源码安装**（开发调试）：

```powershell
dsh plugin --profile web add file:<本地克隆路径>
```

安装后：

```powershell
# 确认进入层栈
Get-Content $env:USERPROFILE\.dsh\profiles\web\package.json   # 应看到 dsh-blocker-notify 出现在 dsh.profile.bundles
# 确认配置树里有行
dsh --dump-config --profile web | Select-String "dsh-blocker-notify"
# 新增依赖/层需要重启进程
dsh web
```

> `lib/` 是**已提交的构建产物**（由 `src/` 经 tsdown 生成）。git 安装会运行 `prepare` 构建脚本，pnpm 需在 `allowBuilds` 授权一次；也可用 npm 包 / `pnpm pack` tarball 安装（预构建产物，无需授权）。

### 验证（两种方式通用）

| 场景 | 操作 | 预期 |
|---|---|---|
| 提问自测 | 让 Agent 调用一次 `ask_user_question` | 提问弹窗出现时：横幅「等待回答」+ 提示音 + 系统通知；点击横幅行跳转并移除该条 |
| 提权审批 | 设置里把审批策略设为 `ask`、沙箱设为 `read-only`，让 Agent 尝试带 `sandbox_permissions` 的写入 | 审批卡片出现时：横幅「等待授权」+ 提示音 + 系统通知（含工具名与原因）；点击横幅行跳转并移除（批准与否都移除） |
| 沙箱拒绝 | 让 Agent 不带提权参数写入被拒文件 | **静默**（无横幅、无提示音、无系统通知；仅 Host 日志记录供诊断） |

## 工作原理

```
Host 半（进程内，未打 scope 标签 → 观察所有 agent 的审批/工具结果）
  ├─ ctx.on('approval/request', (req, next) => …)   // waterfall，仅观察，必须 return next()
  └─ ctx.on('tools/result', …)                       // 检测 FS_SANDBOX_DENIED
        │  写入进程内告警日志（按 key 去重、10 分钟 TTL、上限 60 条）
        ▼
  详情通道：正式版 = webServer 路由 GET /api/dsh-blocker-notify/alerts
             动态版 = harness.handle('blocker-notify/alerts') RPC
        ▼
Client 半（浏览器页面，根作用域）
  ├─ useSessions（shell.overlay 标准 prop）→ 实时发现 pendingInteraction（approval / plan-review / question）
  ├─ 轮询详情（fetch / host.call）→ 合并审批详情（工具名 / 原因）
  ├─ CSS 注入 → 让 [data-state="warning"] 黄点闪烁
  ├─ Web Audio → 新增可操作阻塞出现时播放提示音（首次交互预热 AudioContext）
  └─ Notification API → 新增可操作阻塞出现时弹系统通知（横幅内一键开启/测试，点击通知跳回页面）
```

- **Host 半**：捕获阻塞信号、维护进程内告警日志（纯 JS，无 UI）；沙箱拒绝只记录、不参与提醒。
- **Client 半**：只展示**挂起中的可操作阻塞**（审批/提问/审阅，解决或点击即消失）；沙箱拒绝静默。数据来自 `shell.overlay` 的标准 prop `useSessions`（快照 `{ ids, byId, … }`，`byId` 条目带 `id` / `title` / `pendingInteraction`）+ Host 详情轮询。
- 正式版与动态版共用同一套逻辑；仅"详情通道"不同（webServer 路由 vs. 动态 RPC），见 `docs/ROUTE-B.md`。

## 常见问题

| 现象 | 处理 |
|---|---|
| 什么提示都没有 | 确认确实存在**可操作**阻塞（提问/审批/审阅；沙箱拒绝已静默）；动态版确认 `cordis_inspect_self` 里 host/client 均 running；刷新页面重试 |
| 只有闪烁、没有横幅 | 横幅数据来自 `useSessions` 的 `{ ids, byId }` 结构，确认用的是 **pkg-4 / v0.2.0 及以后**的版本 |
| 只有横幅、没有闪烁 | 闪烁是 CSS 动画（`span[data-state=warning]`），确认用的是 **pkg-3 / v0.2.0 及以后**的版本 |
| 动态版重启后失效 | 正常——动态插件是进程内存态；改走方式二（正式安装） |
| 正式安装后 GUI 看不到 | 新增依赖/层需重启 `dsh web`；插件列表在设置页，重新打开刷新 |
| `dsh plugin add github:...` 第一次失败 | 包有 `prepare` 构建脚本（tsdown），pnpm 需要授权：把报错给出的包键加进 `$DSH_HOME/profiles/web/pnpm-workspace.yaml` 的 `allowBuilds` 后重跑；`lib/` 已提交，也可用 npm 包或 `pnpm pack` tarball 安装（预构建，无需授权） |

## 开发与构建

- `src/` 是 **TypeScript 源码**（按源码仓官方方法编写）；`lib/` 是 **tsdown 构建产物**（已提交）——`pnpm build`（tsdown，复刻官方 `clientBundle` 约定）从 `src/` 生成 `lib/index.js`（ESM 命名导出插件）与 `lib/client.js`（官方 `window.__ModuleLoader__.load({ id, factory })` 格式 web bundle）。
- 提交 `lib/` 使 git 安装无需构建授权；`prepare` 脚本（= tsdown）会在 git 安装时重建产物。
- 离线冒烟测试：`node scripts/smoke.mjs`（校验两半导出、`inject`、事件监听、路由 JSON、CSS 注入、槽位注册、渲染、中文文案）。
- `dynamic/` 是动态插件函数体（方式一使用），与 `lib/` 逻辑一致、通道不同。
- 转正路线 B 的完整调研与实施记录：`docs/ROUTE-B.md`；新部署启用指南：`docs/ENABLE.md`。

## 源码结构

```
dsh-blocker-notify/
├── LICENSE               # MIT
├── package.json          # bundle（dsh.bundle）+ client（dsh.client）双 manifest
├── README.en.md          # English readme
├── cordis.patch.yml      # bundle patch：插入 Host 行
├── src/                  # TypeScript 源码（源码仓官方方法）
│   ├── index.ts          # Host 半（ESM name/inject/apply + webServer 路由）
│   └── client/index.ts   # Client 半（构建为 ModuleLoader web bundle）
├── tsdown.config.ts      # 构建配置（复刻官方 clientBundle 约定）
├── tsconfig.json
├── lib/                  # tsdown 构建产物（已提交）
│   ├── index.js          # Host 半
│   └── client.js         # Client 半（ModuleLoader 格式）
├── scripts/
│   └── smoke.mjs         # 离线冒烟测试
├── dynamic/              # 动态插件函数体（方式一）
│   ├── host.js
│   └── client.js
└── docs/
    ├── ENABLE.md         # 全新部署启用指南
    └── ROUTE-B.md        # 转正路线 B 实施记录
```

## License

[MIT](LICENSE)
