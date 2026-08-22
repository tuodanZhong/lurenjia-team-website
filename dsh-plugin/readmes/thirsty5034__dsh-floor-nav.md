# dsh-floor-nav

[English](./README.md) | [简体中文](./README.zh-CN.md)

DeepSeek Harness **社区插件**：Web GUI 上的 **LiveAgent 风格楼层导航**。

- **收起**：对话区右侧一列短横线 tick（用户消息采样），几乎不占宽度  
- **展开**：鼠标悬停打开毛玻璃列表面板；点击跳到对应提问  
- **收藏 ★**：按会话写入 `localStorage`  
- 通过 `--dsh-sidebar-width` / `--dsh-composer-height` 避让 better-sidebar 与输入区  

## 致谢 / 参考来源

**交互与信息架构参考开源项目 [LiveAgent](https://github.com/thirsty5034/LiveAgent)**：

| LiveAgent 源码 | 作用 |
|----------------|------|
| `crates/agent-ui/src/pages/chat/transcript/FloorNavRail.tsx` | 轨道 UI：短横线、悬停面板、触屏显隐、收藏行 |
| `crates/agent-ui/src/lib/chat-floor-nav/floorModel.ts` | 楼层列表、预览截断、标记采样、最近高亮 |
| `crates/agent-ui/src/lib/chat-floor-nav/floorBookmarks.ts` | 按会话的 pin 持久化 |

本仓库是 **DSH 原生重写**（Cordis Client 插件 + DSH 会话快照 / `data-chat-anchor-key` 跳转），**不是** LiveAgent 的 git fork，也**不**把 LiveAgent 源码打进依赖。LiveAgent 仍遵循其自身许可证；查阅上游代码时请遵守其条款。

## 环境要求

- DSH **web** profile  
- 可选：[dsh-better-sidebar](https://github.com/omdsh-dev/DSH-better-sidebar)（未安装时 offset 变量为 0，行为仍正确）

## 安装

**macOS / Linux：**

```sh
curl -fsSL https://raw.githubusercontent.com/thirsty5034/dsh-floor-nav/main/scripts/install.sh | bash
```

**Windows（PowerShell）：**

```powershell
irm https://raw.githubusercontent.com/thirsty5034/dsh-floor-nav/main/scripts/install.ps1 | iex
```

或 CLI（上 npm 前默认 GitHub）：

```bash
export DSH_HOME=${DSH_HOME:-$HOME/.dsh}
dsh plugin --profile web add "dsh-floor-nav@github:thirsty5034/dsh-floor-nav"
dsh --profile web --dump-config | grep floor-nav
```

安装后 **重启 dsh web** 并 **硬刷新** 浏览器。当前会话至少有 **2 条**用户提问后才会出现右侧 tick。


## 可发现性

- GitHub topics：`dsh-plugin`、`deepseek-harness`、`dsh`（[dsh.so](https://www.dsh.so/) 自动收录所需）
- 当前请从 GitHub 安装：见上文 **安装**
- 商店目录可能滞后于爬虫；以本仓库为准


## 行为摘要

| 状态 | 交互 |
|------|------|
| 收起 | 高度自适应采样 tick；收藏楼层必留 |
| 展开 | 悬停展开 / 移出延迟收起；触屏点按与外点关闭 |
| 跳转 | `[data-conversation-scroll]` + `[data-chat-anchor-key]` |
| 当前层 | 视口上四分位线附近的用户行 → 最近采样 tick 高亮 |
| 收藏 | `localStorage["dsh-floor-nav.bookmarks.v1"]` |

## 开发

```bash
npm run check
```

Host 半为空壳；UI 全在 `lib/client.js`。

## 许可证

MIT — 见 [LICENSE](./LICENSE)。

LiveAgent 为独立项目；本插件仅**参考**其楼层导航设计。
