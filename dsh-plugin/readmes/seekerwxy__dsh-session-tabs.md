# dsh-session-tabs（DSH 会话标签页）

浏览器式会话标签页导航栏 for [DeepSeek Harness (DSH)](https://github.com/deepseek-ai/deepseek-harness)（DeepSeek 官方开源编码代理框架）。

在 DSH Web 界面**最上方**新增一条导航栏：每打开一个会话就多一个标签页 —— 像浏览器 / opencode 那样点击切换、关闭、新建。当前会话高亮，运行状态一目了然。

A browser-style session tab bar for DeepSeek Harness (DSH): every session you open becomes one tab at the very top of the app — click to switch, close per-tab, and start new sessions, just like a browser or opencode.

## Features / 功能

- 顶部全宽固定导航栏（34px，通过 `#root` padding 预留空间，**不遮挡**原有侧边栏/会话头部）
- 每个打开的会话一个标签页（按打开顺序，MRU）
- 当前会话高亮（品牌色下划线，`data-active`）
- 状态点：运行中（品牌色脉冲）/ 等待交互（琥珀）/ 已完成（绿）
- × 关闭标签：关闭当前标签自动切到相邻标签；全部关闭回到空状态
- ＋ 新建会话（`workspaces.startSession()`）
- 标签过多时横向滚动（隐藏滚动条）
- 主题感知：使用 DSH 主题 token（`--dsw-alias-*`），亮/暗色自动适配，`prefers-reduced-motion` 降级
- 纯客户端实现，无 Host 依赖，无持久化写入

## Install / 安装

### 方式一：动态插件（推荐，已实测 ✅）

在任意 DSH 会话中让 Agent 使用 `cordis_define` / `cordis_run` 工具：

1. `cordis_define`：`plugin.kind: "new"`，`idPrefix: "tabs"`，把 [`plugin/client.js`](./plugin/client.js) 中 `apply(ctx) { ... }` 的函数体粘贴为 **Client half**（外层写成 `return { apply(ctx) { ... } }`）。
2. `cordis_run` 激活，在页面批准即可。插件停止后样式与界面自动完全移除。

### 方式二：部署级安装（`dsh.client` 包，重启后仍生效 ✅）

`lib/client.js` 是预构建的客户端 bundle（`__ModuleLoader__.load` 格式，与已安装的社区插件一致），`package.json` 声明了 `dsh.client` 与 `exports["./client"]`。以本机 web profile 为例：

1. 将本仓库加入 profile 依赖（`<DSH_HOME>/profiles/web/package.json`）：
   `"dsh-session-tabs": "link:E:/.../dsh-session-tabs"`
2. 在 profile 的 `cordis.patch.yml` 插入插件行：
   ```yaml
   - insert:
       - id: dsh-session-tabs
         name: dsh-session-tabs
   ```
3. 在 profile 目录执行 `pnpm install`，然后**重启 DSH** —— 之后每次启动标签栏自动加载，无需批准、无需重新定义。

## How it works / 原理

- **席位**：注册到 `shell.overlay` —— 唯一"全幅、可叠加、默认点击穿透"的槽位，不替换任何出厂 UI；渲染 `position: fixed` 的顶部导航栏。
- **数据**：槽位标准钩子 `useSessions`（`SessionListState`：`current` + `byId[].displayTitle/running/pendingInteraction/completed`）；标签顺序 = 本页面会话内"打开过"的会话（MRU）。
- **动作**：切换 `sessions.open(id)`；关闭最后一个 `sessions.clear()`；新建 `workspaces.startSession()`。
- **空间预留**：包内样式 `#root { padding-top: 34px; box-sizing: border-box }`（动态版随插件停止自动移除；部署版以 `data-plugin-css` 守卫按包注入一次）。

## License / 许可

[MIT](./LICENSE) © 2025 seekerwxy
