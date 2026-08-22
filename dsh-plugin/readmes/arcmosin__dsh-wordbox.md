# 常用词盒子（Common Word Box）— DeepSeek Harness 客户端插件

[English](README.en.md) | 中文

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

DeepSeek Harness（`dsh web`）的 **Web 客户端插件**：在对话输入框右侧放一个「词」按钮，点击弹出一个**常驻**的上拉面板，管理自己的常用词/句，一键插入对话输入框。
![dsh-wordbox](docs/cover.png)

词条分两个桶：**全局**（所有工作区共享）与**当前项目**（按工作区目录隔离）。

## 功能

- 🖱️ 点击「词」按钮 → 上拉面板（带滑入动画），**常驻不消失**（再点一次 / 点击外部 / Esc 关闭）
- 🔀 三档显示范围：**全部 / 全局 / 当前**（切换控件在「＋ 添加」同行最右侧）
- ⏎ 点击词条 → **追加进输入框**（保留焦点、一个撤销步、面板不关闭，可连续插入）
- 🌐 中/英双语（跟随 DSH 界面语言）

## 安装

前置：DeepSeek Harness `dsh web` + `pnpm`（`dsh plugin` 命令会转发给 pnpm，需要它在 PATH 上）。

本插件是标准的 **DSH bundle 插件**（`dsh.bundle.patch` 声明，包内自带插件行 patch），因此安装/卸载都是**一条命令**：

### 安装

```sh
# 前提，安装官方 CLI（已装可跳过）
npm install -g @deepseek-ai/dsh

# 安装本插件
# 方式一：从 npm 安装（推荐，已发布到 npm）
dsh plugin --profile web add dsh-wordbox

# 方式二：从 GitHub 安装（仓库根即插件包，无构建步骤，直接可用）
dsh plugin --profile web add github:arcmosin/dsh-wordbox

# 方式三：本地开发（link 到本仓库）
dsh plugin --profile web add link:D:/path/to/dsh-wordbox
```

装完**重启 `dsh web`** 即生效（输入框右侧出现「词」按钮）。

> `dsh plugin add` 会把包安装进 profile，并因 `dsh.bundle` 声明**自动挂载**到 `dsh.profile.bundles`；无需手动编辑任何 patch 文件。

### 卸载

```sh
dsh plugin --profile web remove dsh-wordbox
```

然后**重启 `dsh web`**，按钮即消失。浏览器里保存的词库数据（localStorage）不会随卸载删除，如需清空可自行删除以下键：`dsh.common-word-box.words.v1`、`dsh.common-word-box.words.project.v1`、`dsh.common-word-box.mode.v1`。

> 个别情况下 `remove` 后 `profiles\web\node_modules\dsh-wordbox` 会残留空目录/链接，手动删除即可，不影响任何功能。

## 使用

1. 点击输入框右侧的「词」按钮（英文界面显示 **W**），面板上拉并保持打开；
2. 底部右侧切换 全部 / 全局 / 当前；
3. 点击词条 → 追加进输入框（可连续点多条）；悬停行尾出现 × 删除；
4. 「当前」模式下悬停行尾出现"添加到全局"转化按钮，一键复制进全局；
5. 长词悬停会慢速流动显示完整内容。

## 存储

| 数据 | localStorage 键 |
|---|---|
| 全局词 | `dsh.common-word-box.words.v1`（string[]） |
| 项目词 | `dsh.common-word-box.words.project.v1`（`{规范化目录: string[]}`，空桶自动清理） |
| 显示模式 | `dsh.common-word-box.mode.v1`（`all` / `global` / `current`） |

词库存浏览器本地（按浏览器 profile 隔离），跨工作区、跨标签页通过 `storage` 事件同步。

## 开发

- 本地调试安装：`dsh plugin --profile web add link:<本仓库绝对路径>`，改代码无需重装；
- 修改 `lib/client.js` 后**无需重启**：宿主 `client-hmr` 每 500ms 轮询 bundle 哈希，变化自动热重载（React 状态会重置）；首次安装/卸载或改 `cordis.patch.yml` 后需重启 `dsh web`。
- bundle 是 `window.__ModuleLoader__.load({ id, factory })` 格式的纯 JS，**无构建步骤**，改完直接生效。
- 长词流动速度常量：`lib/client.js` 中的 `FLOW_SPEED`（默认 60 px/s）。

## 架构

| 部分 | 文件 | 说明 |
|---|---|---|
| bundle patch | `cordis.patch.yml` | `dsh.bundle.patch` 声明的插件行，`dsh plugin add` 时自动挂载进 profile |
| node 半体 | `lib/index.js` | 空 `apply`，让 loader 条目在宿主侧激活 |
| browser 半体 | `lib/client.js` | 客户端 bundle：`conversation.input.right` 槽注册 + 全部交互逻辑 |
| 清单 | `package.json` | `dsh.bundle` + `dsh.client`（`platform: "web"` + inject）+ `exports["./client"]` |

- 挂载槽位：`conversation.input.right`（由 `@deepseek-ai/dsh-client-ui-conversation` 声明，list 槽，session 作用域），渲染在输入框卡片 trailing 区。
- 写入输入框：标准工具包 `inputActions.setDraft(text)`；读取草稿用 `useInput((s) => s.draft)`。
- 等待槽位声明：`ctx.slots.inject("conversation.input.right", () => ctx.slots.register({...}, Component))`。
- 形态范例：`@deepseek-ai/dsh-client-ui-model-selection`（官方纯 UI 客户端插件）。

## License

[MIT](LICENSE)
