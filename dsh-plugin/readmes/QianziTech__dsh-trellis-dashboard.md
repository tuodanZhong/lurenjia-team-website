# dsh-trellis-dashboard

[English](README.md) | **简体中文**

**Trellis × DSH 工作区仪表盘**：一个 DSH 插件，在 DeepSeek Harness Web UI 的
会话视图环上新增 **Trellis** 标签页，投影当前工作区的 `.trellis/` 状态：

1. **当前任务 + 进度** —— 任务列表 + 当前任务解析（**仅基于会话指针**，不从
   任务状态猜测 —— 未绑定的会话显示「暂无 trellis 任务」，而不是随意挑一个任务）
   + 带 `prd.md` 验收清单的任务卡片；「设为当前任务」按钮写入会话级指针。
2. **规范 / 技能使用** —— 实时规范文件读取（`fs/observed` 监听
   `.trellis/spec/**`、`.agents/skills/**`、`.dsh/skills/**`）与 `skill` 工具加载
   （`tools/result`），**按会话隔离**（`exec.agent.id`），一个会话的活动不会泄漏
   到另一个会话的仪表盘。
3. **工作区会话汇总** —— 开发者日志索引 + 最新 `journal-N.md` 摘录。

标签页内用自带轻量渲染器渲染 Markdown（标题、列表、任务清单、表格、代码、
引用块）—— 无外部运行时依赖。

---

## 安装

### 前置条件

- 已安装 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)
  （`dsh` CLI），并存在 **web** profile，例如 `dsh --profile web`。
- 目标工作区已用 [Trellis](https://github.com/mindfoldhq/trellis) 初始化：
  `trellis init --dsh`。

### 从 npm 安装（推荐）

本包分发预构建、自包含的产物 —— 无需构建步骤，无需构建授权：

```bash
npm install -g @deepseek-ai/dsh   # 若尚未安装
dsh plugin --profile web add dsh-trellis-dashboard
```

验证组合层已生效，然后重启 Web 应用：

```bash
dsh --profile web --dump-config        # 应出现 "# == dsh-trellis-dashboard" 层
# 重启 dsh web → http://127.0.0.1:3080 → 会话头部出现 Trellis 标签
```

### 从 tarball 安装

```bash
dsh plugin --profile web add ./dsh-trellis-dashboard-0.1.0.tgz
```

### 从 GitHub 安装

本包**没有构建步骤**：`lib/` 是纯 JavaScript，已直接提交到仓库，因此 git 安装
拉取的就是可运行产物，**不需要** `prepare` 脚本或 `allowBuilds` 授权：

```bash
dsh plugin --profile web add github:QianziTech/dsh-trellis-dashboard#<sha>
```

### 从本地目录安装

```bash
dsh plugin --profile web add /path/to/dsh-trellis-dashboard
```

### 卸载

```bash
dsh plugin --profile web remove dsh-trellis-dashboard
```

---

## 发布产物 vs 源码仓库

npm tarball 刻意保持最小 —— 只包含插件运行所需的内容：

```
dsh-trellis-dashboard-0.1.0.tgz
├── package.json          # dsh 插件清单（bundle patch + dsh.client）
├── cordis.patch.yml      # 向 web profile 组合插入 HOST 行
├── lib/
│   ├── index.js          # HOST 半 —— fs 读取 + 用量跟踪 + HTTP JSON API（webServer）
│   └── client.js         # CLIENT 半 —— conversation.view 标签页 + Markdown 渲染（浏览器 bundle）
├── README.md
├── README.zh.md
└── LICENSE
```

源码仓库中的其余内容 —— `.trellis/`、`.claude/`、`.codex/`、`.agents/`、
`plans/`、`docs/`、`test/`、`AGENTS.md` —— 属于**开发与个人工具状态，永不发布**。
`npm pack --dry-run` 可确认产物恰好是这六个文件。最终用户只需要
`dsh plugin add dsh-trellis-dashboard`。

## 使用

安装后打开 Web UI 的任意会话，点击会话视图环中的 **Trellis** 标签页。标签页会：

- 从 Web 应用的工作区列表解析当前工作区；
- 挂载期间每 5 秒轮询宿主 JSON API（`GET /dsh-trellis-dashboard/state`）；
- 渲染当前任务卡片、验收清单、规范/技能用量与日志汇总；
- 「设为当前任务」写入会话级指针
  （`POST /dsh-trellis-dashboard/set-current-task`）—— 这是插件唯一的写操作。

## 架构

- **HOST 半**（`lib/index.js`）通过 `ctx.fs` 读取 `.trellis/`（绝不运行
  `python task.py` 脚本），并以 `webServer` HTTP 路由暴露仪表盘 JSON API；
  订阅 `fs/observed` + `tools/result` 供用量区块使用。
- **CLIENT 半**（`lib/client.js`）注册 `conversation.view`（id `trellis`，
  order 20 —— 纯新增，不替换任何已发布 UI），用 `useWorkspaces` 解析工作区，
  轮询宿主 API，并用 `React.createElement` + 自带 Markdown 渲染器渲染。
- **发布形态的通道是 HTTP**：`harness.handle`/`host.call` 仅存在于动态运行时
  插件，因此发布插件的 client→host 流量走 `webServer` 路由；由于没有
  host→client 推送通道，客户端采用轮询。
- `.trellis/` 保持**只读**，唯一的写入是 `set-current-task` 的会话指针
  （复刻 `trellis task.py set_active_task`）。

### 热重载矩阵

| 变更对象 | 生效方式 | 是否需要重建 web 产物 |
|---|---|---|
| 动态原型代码（`cordis_define`） | 追加新 Package → `cordis_run update` | 否（运行时加载） |
| 发布包 host（`lib/index.js`） | 重装 / 组合重启 | 否（随组合加载） |
| 发布包 client（`lib/client.js`） | clientModules 按文件 hash 提供 | **是** |
| checkout 内客户端源码（web 壳 / 普通包） | `pnpm run dev:web` watcher 重建 bundle | 是（dev 模式） |

关键区分：动态插件由运行时 runner 直接求值（无需 Vite/dev:web）；只有修改
checkout 内**源文件**（已发布客户端模块 / web 壳）才需要 `dev:web` 重建，
且 watcher 必须从**同一 checkout** 运行。

### 排错速查

| 现象 | 处理 |
|---|---|
| 装完没有 Trellis 标签 | client bundle 未重建 → 重跑 web build / `dev:web`；或组合未含本层 → 核对 `--dump-config` |
| host 路由 404 | `webServer` 路由未注册 → 确认 `inject: ['fs','webServer']` 且 profile 是 web |
| 动态插件激活失败 | `cordis_inspect_self(pluginId, packageId)` 读诊断 → 同插件追加修正版再 `update` |
| GitHub 安装报错 | 本包无 `prepare` 故不需要；若 fork 后自行引入构建，请按官方文档核对 `allowBuilds` 指引 |

## 开发

```bash
npm run check   # node --check lib/index.js && node --check lib/client.js
npm test        # node --test test/ — 契约 + 耦合 + 规范一致性测试
```

插件是零依赖纯 JavaScript。阅读源码无需构建步骤；client bundle 直接以 Web 应用
的 `window.__ModuleLoader__.load({ id, factory })` 格式编写。框架级开发规范见
`.trellis/spec/dsh-plugin/`（仅源码仓库）；操作/调试/热加载笔记见
[`docs/dsh-plugin-development.md`](https://github.com/QianziTech/dsh-trellis-dashboard/blob/master/docs/dsh-plugin-development.md)。

## 许可

MIT —— 见 [LICENSE](LICENSE)。
