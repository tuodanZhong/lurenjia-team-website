[English](./README.md) · **简体中文**

# dsh-history — DSH Web 命令历史插件

在 DSH Web GUI 中记住**当前会话**的历史命令，输入框获得焦点时按 **↑ / ↓** 键即可切换之前的命令，修改后按 Enter 重新执行。

## ✨ 功能

- **记录**：自动记录当前会话中你发送过的所有消息（普通消息与 `/xxx` 斜杠命令），按会话隔离；历史来自会话日志（`user`/`command` 节点），因此刷新页面后会自动重建，无需额外存储。
- **↑**：从输入框回退到上一条命令；再按继续往前翻。首次按下时会保存你正在编辑的草稿，之后按 ↓ 可回到它。
- **↓**：向前翻到更新的一条；翻到最新后再按 ↓ 回到之前保存的草稿。
- **修改再执行**：召回的命令写入输入框草稿，直接编辑后按 Enter 即重新发送。
- **安全兜底**：`/` 或 `@` 触发菜单打开时、中文等 IME 输入中、composer 忙碌/锁定时、焦点不在输入框时，↑/↓ 保持原有行为，不会干扰。

## 📦 加载方式

插件是标准的 DSH 静态插件（参见 [develop/basic 教程](https://deepseek-harness.github.io/deepseek-harness/develop/basic/)）。入口名必须是**裸包名** `dsh-history`，并且要从两个解析树都能解析到本包目录（host loader 从 DSH 安装目录的 node_modules 解析裸名，客户端模块扫描器从 profile 目录向上解析 `dsh-history/package.json`），因此需要建立两个符号链接：

```sh
# 1) profile 侧（客户端模块扫描器）：$DSH_HOME 默认 ~/.dsh
ln -s /absolute/path/to/dsh-history ~/.dsh/profiles/node_modules/dsh-history

# 2) 安装侧（host loader 裸名解析）：指向 dsh 安装的 node_modules
ln -s /absolute/path/to/dsh-history /home/ender/.npm/_npx/1e7f6d9597241db0/node_modules/dsh-history
```

然后通过 patch 启动：

```sh
dsh web --patch /absolute/path/to/dsh-history/cordis.yml
```

或把 `cordis.yml` 的内容（`insert` 一段）合并进 `$DSH_HOME/profiles/web/cordis.patch.yml` 常驻加载。

## 🗂️ 目录结构

```
dsh-history/
├── package.json        # dsh.client 声明（platform: web）→ 被 client-modules 扫描进 __DSH_BOOT__
├── cordis.yml          # patch：把插件 entry 插入 loader
├── lib/
│   ├── index.js        # host 半区：仅占位（loader 需要可解析的模块）
│   └── client.js       # 浏览器 bundle：历史记录 + ↑/↓ 导航 + dock 指示器
├── scripts/
│   └── smoke-test.mjs  # Node 冒烟测试（npm test）
├── README.md           # 英文版
└── README.zh-CN.md     # 本文件（简体中文）
```

## ⚙️ 工作原理

- **客户端模块机制**：包声明 `dsh.client: { platform: "web" }` 且 `exports["./client"]` 指向 `lib/client.js` 后，`dsh-client-modules` 会自动把该 entry 编入 `window.__DSH_BOOT__`，并以 `/plugins/<entry名>/client.js` 提供；浏览器端按 `window.__ModuleLoader__.load({ id, factory })` 契约注册插件。
- **记录**：注册在 `conversation.input.dock` 插槽的组件订阅会话快照 `useSession((s) => s.nodes)`，按 `seq` 增量扫描 `user`/`command` 节点（列表按 seq 升序且不截断），去重（相邻相同合并）、上限 100 条，存于模块级 `Map<sessionId, …>`。
- **导航**：`document` 上挂 capture 阶段 `keydown`，仅当焦点在 `[data-composer-card]` 内、无触发菜单（`claim` 为空）、非 IME、无修饰键、非忙碌时接管 ↑/↓，通过 `inputActions.setDraft(text)` 写入草稿；编辑检测会在你输入后自动回到实时位置。
- **指示器**：浏览历史时在 composer 上方显示「历史 n/m」小徽标。

## ⚠️ 限制

- 历史按会话隔离、内存驻留（页面刷新后从会话日志重建，因此会话内不丢；浏览器关闭则丢弃）。
- 斜杠命令以 `/name args` 形式召回（来自 `command` 节点）。
- 图片消息（无文本）不进入历史。

## 🤝 社区

- [贡献指南](./CONTRIBUTING.md) — 如何报告 Bug、提功能需求、提交 Pull Request（含面向新手的 `good first issue` 入门任务）。
- [行为准则](./CODE_OF_CONDUCT.md) — 我们对社区每一位成员的期望。
- [安全政策](./SECURITY.md) — 如何私下上报安全漏洞。
- [支持渠道](./SUPPORT.md) — 在哪里提问（Issues 与 讨论区 的分工）。

## 📄 许可证

[MIT](./LICENSE) © [xuender](https://github.com/xuender)
