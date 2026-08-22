# DSH UI Plugins

两个 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) Web GUI 的界面美化插件，零依赖、纯 JavaScript、开箱即用。

| 插件 | 功能 |
|---|---|
| [`dsh-ui-nav`](./dsh-ui-nav) | 右侧对话导航栏：一键跳转到任意一条用户提问，当前对话位置蓝色高亮，悬停弹出缩略文字框 |
| [`dsh-ui-starfield`](./dsh-ui-starfield) | 交互式星空背景：发光星点 + 鼠标排斥 + 星座连线（tsParticles 风格） |

两个插件彼此独立，可单独安装、单独卸载。

---

## 目录结构

```
dsh-ui-plugins/
├── dsh-ui-nav/
│   ├── package.json      # dsh.client 声明（platform: web）+ ./client 导出
│   ├── lib/
│   │   ├── index.js      # node half（空 apply，仅供 Loader 挂载）
│   │   └── client.js     # browser half（window.__ModuleLoader__.load 包裹，纯 JS）
│   └── README.md         # 该插件的可调参数 / 移植 / 卸载说明
├── dsh-ui-starfield/
│   ├── package.json
│   ├── lib/
│   │   ├── index.js
│   │   └── client.js
│   └── README.md
├── README.md
└── LICENSE
```

## 环境要求

- **DeepSeek Harness**（`@deepseek-ai/dsh`），版本 `0.1.0-rc.6`（或与之兼容的版本）。
  > 说明：这两个插件是 Harness 的「客户端插件」，依赖 Web GUI 内置的 Client Slot（`shell.overlay`）和会话渲染 DOM 约定（`[data-conversation-scroll]`、`[data-chat-flow-kind="user"]`、`--dsw-chat-content-width` 等）。这些约定随版本演进，若目标机 DSH 版本不同，个别选择器/token 可能需要微调。
- 已启用 Web 界面（`dsh web`，默认 `http://127.0.0.1:3080`）。

---

## 安装

两个插件都是「客户端插件包」，通过 Web profile 的补丁层挂载。它们不需要 `npm install`、不需要编译——直接拷贝文件 + 登记即可。

### 第 1 步：拷贝插件目录

把插件目录复制到 DSH 的 web profile 的 `node_modules` 下：

```
~/.dsh/profiles/web/node_modules/dsh-ui-nav/
~/.dsh/profiles/web/node_modules/dsh-ui-starfield/
```

> 在 Windows 上 `~` 即 `C:\Users\<你的用户名>`；在 macOS/Linux 上即 `/home/<用户名>` 或 `/Users/<用户名>`。

### 第 2 步：在 `cordis.patch.yml` 中登记

打开 `~/.dsh/profiles/web/cordis.patch.yml`，在条目数组里追加（需要哪个就加哪一行）：

```yaml
- insert:
    - id: dsh-ui-starfield
      name: dsh-ui-starfield
    - id: dsh-ui-nav
      name: dsh-ui-nav
```

> 该文件通常是 `[]`（空数组）；如果是其它内容，把 `- insert:` 里的两行条目合并进去即可。

### 第 3 步：重启并刷新

重启 DSH 的 web 服务（重新运行 `dsh web` / 重跑你的启动脚本），然后在浏览器里**硬刷新**（`Ctrl + Shift + R`）。

> 为什么要重启：客户端插件的「发现 + 下发」由 node 侧在启动时扫描完成，新增插件需重启后才会进入启动清单。

---

## 使用说明

### 导航栏（dsh-ui-nav）

安装后，界面右侧会出现一列**竖排横线**，每条对应一条**用户提问**（不包含助手回答）。

- **当前对话位置高亮**：正在浏览的那条提问（视口顶部那条；滚动到底时为最后一条）的横线显示为**蓝色、略长**，并随滚动实时更新。
- **点击**：平滑滚动定位到对应提问。
- **悬停显示缩略文字**：鼠标悬停在横线上时，弹出圆角框，框内左侧显示该条提问的缩略文字。
- **深浅色自适应**：深色主题下悬停的横线 + 文字由灰变白；浅色主题下由灰变黑（不加粗）；当前行（蓝色）悬停时保持蓝色不变。
- **对话过长自动压缩**：间距随提问数量自动收窄；导航栏最高占 70% 屏幕高度，超出部分在栏内滚动。

### 星空背景（dsh-ui-starfield）

安装后，界面背景会出现一层**发光星点**（带光晕 + 闪烁 + 缓慢漂移）。

- **鼠标排斥**：鼠标周围的星点会被平滑地推开（带速度 + 阻尼的力模型）。
- **星座连线**：相距较近的星点之间会自动连成细线，距离越近线越亮。
- 深色模式下星点为白色，浅色模式下为靛蓝色，两种模式都可见。

> 星空画在内容层之下（`z-index: -1`），并通过把主表面背景调成半透明来透出，因此不影响点击、不影响阅读。

---

## 自定义参数

每个插件的可调项都集中在各自 `lib/client.js` 顶部，改完**硬刷新浏览器即可**（客户端 bundle 每次重新下发）；若改了 `package.json` 或 `cordis.patch.yml` 才需要重启 web。

### dsh-ui-nav

| 参数 | 默认值 | 说明 |
|---|---|---|
| `BASE_GAP` | `16` | 基础间距（px） |
| `MIN_GAP` | `9` | 最小间距（px，对话很多时） |
| 横线宽度 | `18px`（`.dshui-nav-btn`） | 横线长度 |
| 当前行缩放 | `scaleX(1.2)` | 蓝色当前行相对灰色行的变长比例 |
| 文字宽度 | `360px`（`.dshui-nav-text`） | 缩略文字框宽度 |
| 文字字号 | `16px` | 缩略文字大小 |
| 文字截断 | `60` 字 | 缩略文字最长字符数 |
| 内边距 | `22px 26px` | 框内上下 / 左右留白 |
| 圆角 | `22px` | 框的圆角 |
| 位置 | `20px` | 距屏幕右边缘 |

### dsh-ui-starfield

| 参数 | 默认值 | 说明 |
|---|---|---|
| `STAR_COUNT` | `150` | 星星数量 |
| `LINK_DISTANCE` | `130` | 星座连线最大距离（px） |
| `REPULSE_RADIUS` | `110` | 鼠标排斥半径（px） |
| 背景透明度 | `0.6`（深色）/ `0.82`（浅色） | `rgba(...,0.6)` 里的 0.6；数值越大背景越不透明、星空越淡 |

---

## 移植到其它电脑

目标机需装好**同版本（或兼容）**的 DSH。把下面的东西复制过去即可，无需 npm、无需编译：

1. 要装的插件目录（`dsh-ui-nav/` 和/或 `dsh-ui-starfield/`）→ 目标机 `~/.dsh/profiles/web/node_modules/`；
2. `cordis.patch.yml` 里的对应 `insert` 条目 → 目标机同名文件；
3. 重启目标机 web，硬刷新。

---

## 卸载

1. 从 `cordis.patch.yml` 删掉对应插件的 `insert` 行；
2. 删除 `~/.dsh/profiles/web/node_modules/<插件名>/` 目录；
3. 重启 web。

---

## 工作原理（简述）

- 每个插件是一个**双面 Cordis 客户端包**：`lib/index.js` 是空 `apply` 的 node half（让插件能出现在 Loader 里），`lib/client.js` 是浏览器 half，通过 `window.__ModuleLoader__.load({ id, factory })` 注册。
- `package.json` 里的 `dsh.client.platform: "web"` + `exports["./client"]` 让 DSH 的 `dsh-client-modules` 能自动发现并下发 bundle 到浏览器。
- 浏览器 half 通过 `ctx.slots.inject("shell.overlay", ...)` 把 UI 注册进全局浮层 Slot；`shell.overlay` 是加性（list）slot，注册不会替换任何内置 UI。
- 导航栏通过查询会话渲染 DOM 里的 `[data-chat-flow-kind="user"]` 定位每一条用户提问；星空则在 `<body>` 上挂一个 `z-index: -1` 的 `<canvas>` 做粒子系统。

## License

[MIT](./LICENSE)
