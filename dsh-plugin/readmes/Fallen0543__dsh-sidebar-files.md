# dsh-sidebar-files

[English](README.md) | 中文

[![npm version](https://img.shields.io/npm/v/dsh-sidebar-files.svg)](https://www.npmjs.com/package/dsh-sidebar-files)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

为 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) 提供侧边栏文件树插件：在左侧边栏加入 **会话 / 文件** 标签栏，并在工作区内联渲染按需懒加载的文件树 —— 支持按扩展名区分的彩色图标、复制路径、发送给 Agent 阅读等操作。

![侧边栏中的文件标签](docs/screenshot-v2.png)

悬停文件行即可使用两个操作 —— **复制路径** 与 **发给 Agent 读**：

<table>
<tr>
<td align="center"><img src="docs/feature-copy-path.png" width="320" alt="复制路径"><br><sub>复制路径</sub></td>
<td align="center"><img src="docs/feature-send-to-agent.png" width="320" alt="发给 Agent 读"><br><sub>发给 Agent 读</sub></td>
</tr>
</table>

> **插件状态。** 已针对发布版 harness（`0.1.0-rc.6`，`web` profile）构建并验证。插件完全以树外 bundle 运行：Node 端通过自身的 HTTP 路由提供目录列表，浏览器端负责渲染文件树。无需修改核心代码。

## 功能特性

- **会话 / 文件标签栏**：注入到「新建会话」按钮下方（宽侧边栏）。文件树内嵌渲染在侧边栏区域中 —— 与 harness 自带浏览界面的呈现方式一致。
- **按需懒加载**：按需拉取单个目录层级（打开时拉取工作区根目录，首次展开时拉取子目录），通过插件自身的 `GET /dsh-sidebar-files/list?path=…` 路由实现，网络开销只跟随实际展开的内容。
- **按扩展名图标**：为常见扩展名（ts/js/json/yml/yaml/css/html/md/ico/png/zip/log/…）提供 47 个品牌风格图标，另有通用文档图标兜底。图标路径数据来自 [Material Icon Theme](https://github.com/PKief/vscode-material-icon-theme)（MIT，© Material Extensions 2025）—— 见 [LICENSE](LICENSE)。
- **默认隐藏项**：以点开头的名称、`node_modules`、`.git` 默认过滤；「显示隐藏项」开关可将其显示。`node_modules`/`.git` 在开关打开前始终保持隐藏。
- **行操作**（悬停显示）：复制路径（带 1 秒「已复制」反馈）、将文件发送给当前会话的 Agent（入队的「请读取该文件」提示）。
- **健壮的降级方案**：若未来 shell 的侧边栏结构无法识别，插件会自动降级为底部操作按钮 + 居中弹窗，而不是标签栏 —— 绝不会白屏。
- **双语支持**（中文 / English），跟随 harness 的本地化。

## 安装

需要 `dsh` CLI（`npm i -g @deepseek-ai/dsh`）和 pnpm。

**什么是 profile？** profile 是 harness 的一种可运行组合 —— 一个带独立插件集的具名实例。profile 存放在 `$DSH_HOME/profiles/<名称>` 下（例如 `~/.dsh/profiles/web`）。`--profile <名称>` 告诉 `dsh` CLI 要操作哪个实例；请把 `<名称>` 换成你自己的名字（最常见的例子是 `web`）。

```sh
# 在任意目录 —— 从 npm 安装已发布版本
dsh plugin --profile web add dsh-sidebar-files
```

如果这个名字的 profile 还不存在，命令会在首次使用时自动初始化。用同一个 profile 名重启 harness，侧边栏即出现 **会话 / 文件** 标签：

```sh
dsh --profile web
```

> 如果 profile 是全新创建的，请先添加 web 应用 bundle：`dsh plugin --profile web add @deepseek-ai/dsh-web-app@0.1.0-rc.6`（或直接使用 CLI 自带的 `web` profile 模板）。

### 备选安装方式

本地检出或预构建 tarball（无需 registry）：

```sh
dsh plugin --profile web add ./dsh-sidebar-files           # 本地检出（使用 prepare 构建）
dsh plugin --profile web add ./dsh-sidebar-files-0.1.0.tgz # 预构建 tarball
```

从 GitHub（`github:Fallen0543/dsh-sidebar-files`）安装会拉取**源码**；包的 `prepare` 脚本随后会从源码自包含地构建 `lib/`（无需 monorepo 检出）。pnpm ≥10 默认拒绝运行 git 依赖的 `prepare` 脚本，需要先将其加入白名单 —— 将 pnpm 打印的包键复制到 profile 的 `pnpm-workspace.yaml`：

```yaml
allowBuilds:
  dsh-sidebar-files: true
```

然后重新执行 `add`。请只信任来源可信的包，并建议固定提交（`github:Fallen0543/dsh-sidebar-files#<sha>`）。从 npm 或 tarball 安装则无需任何构建授权。

## 开发

```sh
pnpm install
pnpm test        # 单元测试：列表逻辑、侧边栏宿主探测/注入、面板行为
pnpm run typecheck
pnpm run build   # lib/index.js（Node）+ lib/client.js（浏览器 bundle）
```

浏览器 bundle 是 CommonJS 闭包工厂产物（`window.__ModuleLoader__.load({…})`），harness 的平台模块保持外部引用，因此可通过 Web shell 的模块表加载；CSS modules 使用 lightningcss 编译。

## 工作原理

- `cordis.patch.yml` 插入一行宿主配置（`id: sidebar-files`）以挂载 Node 端。
- Node 端（`src/index.ts`）注册 Web 服务器路由前缀 `/dsh-sidebar-files`；`GET /list?path=` 列出单层目录（目录优先、再文件；最多前 1000 项）并返回 `{ path, entries, truncated }` —— 错误返回 400 及机器可读错误码。
- 浏览器端（`dsh.client` 声明，`./client` 导出）先注册到 harness 的 `sidebar.footer.action` 槽位，然后在运行时从自身的触发按钮向上定位侧边栏列，注入「会话 / 文件」标签栏和内联文件树区域（见 `src/client/sidebar-host.ts`）。当 shell 结构无法识别时，由底部按钮 + 弹窗兜底。
- 活动工作区路径从会话/工作区存储推导（当前会话所属工作区，否则最近工作区，否则第一个），通过选择器钩子实现，与 harness 自带浏览界面完全一致。

## 许可证

MIT —— 见 [LICENSE](LICENSE)。文件类型图标字形衍生自 [Material Icon Theme](https://github.com/PKief/vscode-material-icon-theme)（MIT，© Material Extensions 2025）；署名与版权声明保留在 `src/client/file-type-icons.tsx` 中。
