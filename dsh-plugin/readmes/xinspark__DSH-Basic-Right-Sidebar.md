<p align="center">
  <img src="docs/screenshots/image.png" alt="Basic Right Sidebar 界面预览" width="100%">
</p>

<p align="center">
  <img src="https://img.shields.io/github/v/release/xinspark/DSH-Basic-Right-Sidebar?style=flat&amp;label=release&amp;color=08C" alt="GitHub release">
  <img src="https://img.shields.io/badge/plugin-UI%20%E5%A2%9E%E5%BC%BA-47848F?style=flat" alt="UI enhancement plugin">
  <img src="https://img.shields.io/badge/DSH%20Web%20GUI-Windows%20%7C%20macOS%20%7C%20Linux-4493F8?style=flat" alt="Windows | macOS | Linux">
  <img src="https://img.shields.io/badge/license-MIT-2EA44F?style=flat" alt="MIT License">
</p>

<p align="center"><sub>简体中文 · <a href="README.en.md">English</a></sub></p>

<h3 align="center">把 DSH 的原生能力搬进右侧边栏：双栏导航、会话概览与日志下载、原生轨迹视图、可配置顶栏整理</h3>

<p align="center"><a href="#安装"><ins><code>dsh plugin --profile web add github:xinspark/DSH-Basic-Right-Sidebar#v1.0.0</code></ins></a></p>

Basic Right Sidebar 是面向 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) 的**右侧边栏基础插件**——纯 UI 增强，不引入任何新能力，而是把 DSH 的原生能力搬进右侧边栏展示，定位为所有功能增强右侧边栏的**基础插件**。

DSH 原生左侧边栏功能完备，但一旦收起——或者你更习惯右侧工作流——会话、工作区与面板切换就需要额外的点击才能触达。本插件把这些原生操作带到屏幕右缘。安装本插件即自动安装子插件 [dsh-better-session-title](https://github.com/xinspark/dsh-better-session-title)（会话顶栏工作区/会话面包屑）。

支持 **Windows · macOS · Linux**（DSH Web GUI）——纯 JavaScript，无原生依赖，分发无需构建步骤。

## 主要功能

<table>
  <tr>
    <td width="50%" valign="top">
      <h3>两级导航</h3>
      <p>功能区 / 会话管理菜单切换面板（概览 · 轨迹 / 概览）。所有界面在侧栏头部一键可达。</p>
    </td>
    <td width="50%" valign="top">
      <h3>工作区/会话面包屑</h3>
      <p>直接在会话顶栏切换工作区与会话，无需展开左侧边栏。由子插件 <a href="https://github.com/xinspark/dsh-better-session-title">dsh-better-session-title</a> 提供（原生菜单/对话框交互）；本插件的「启用会话顶栏工作区/会话面包屑」设置会实时控制它。</p>
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <h3>会话概览</h3>
      <p>会话信息、日志统计（时间跨度 / 事件计数 / 大小）与一键日志下载（zip）。</p>
    </td>
    <td width="50%" valign="top">
      <h3>原生轨迹视图</h3>
      <p>与 DSH 原生轨迹界面逐像素一致（官方组件内嵌、懒加载），无需改动任何系统源码。</p>
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <h3>可配置顶栏整理</h3>
      <p>逐项隐藏顶栏重复元素：会话日志 · 会话模式 · 子代理 · 后台任务 · 对话/轨迹 Tab 栏。</p>
    </td>
    <td width="50%" valign="top">
      <h3>内置基础库</h3>
      <p>图标库（原生优先）与可复用组件库随插件自带：扩展侧栏只需要写组件，不需要对抗 DOM。侧栏支持展开/收起与全屏，启动后默认展开（手动收起永不被打断）。</p>
    </td>
  </tr>
</table>

## 截图

会话界面右侧边栏 UI 展示：

**功能区/概览（非全屏）**

![功能区/概览](docs/screenshots/image.png)

**功能区/轨迹（非全屏）**

![功能区/轨迹](docs/screenshots/image-1.png)

**会话管理/概览（非全屏）**

![会话管理/概览](docs/screenshots/image-2.png)

**功能区/轨迹（全屏）**

![功能区/轨迹（全屏）](docs/screenshots/image-3.png)

**右侧边栏收起**

![右侧边栏收起](docs/screenshots/image-4.png)

**插件配置 UI**

![插件配置 UI](docs/screenshots/image-5.png)

![插件配置 UI（续）](docs/screenshots/image-6.png)

## 安装

`dsh-basic-right-sidebar` 是一个**组合包（bundle）**——以包形式分发的配置补丁层（见 [DSH 官方插件发布文档](https://deepseek-harness.github.io/deepseek-harness/develop/basic/publish)）。用 `dsh plugin` 命令安装进 profile：它会自动链接包并追加到 `dsh.profile.bundles`：

```sh
# 从 GitHub 安装（主分发渠道，v1.0.0 为当前发布 tag）
dsh plugin --profile web add github:xinspark/DSH-Basic-Right-Sidebar#v1.0.0
```

- **建议锁定 commit**：GitHub 安装拉取的是仓库源码，tag 之后的新推送不会自动影响已安装版本；如需把运行内容严格固定到某个提交，用 `github:xinspark/DSH-Basic-Right-Sidebar#<commit-sha>`（官方文档推荐做法）。
- **本地目录 / tarball**（开发或离线环境）：

  ```sh
  dsh plugin --profile web add ./dsh-basic-right-sidebar
  dsh plugin --profile web add ./dsh-basic-right-sidebar-1.0.0.tgz
  ```

然后启动 Web UI：`dsh web`（或 `dsh --profile web`）。首次 `add` 会自动用 `@deepseek-ai/dsh-base` 初始化 profile。

**子插件自动装齐**：本 bundle 的 `cordis.patch.yml` 同时插入 `dsh-basic-right-sidebar` 与 `dsh-better-session-title` 两行插件。子插件作为 **GitHub git 依赖**声明在 `package.json` 的 `dependencies` 中（锁定 commit SHA，防止上游推送悄悄改变行为）；安装本 bundle 时 pnpm 自动拉取，一条命令装齐。请勿再用 `dsh plugin add dsh-better-session-title` 单独安装（`insert` 是追加语义，会产生重复插件行）。

> **首次安装需要一条 pnpm 安全设置**：pnpm ≥10.6 默认启用 `blockExoticSubdeps`，会拒绝安装带 git 规格**子依赖**的包（本插件的子插件正是 git 依赖），报错形如 `ERR_PNPM_EXOTIC_SUBDEP`。若遇到，在 profile 的 `pnpm-workspace.yaml`（如 `$DSH_HOME/profiles/web/pnpm-workspace.yaml`）末尾加一行，再重跑安装命令即可：
>
> ```yaml
> blockExoticSubdeps: false
> ```
>
> 这是 profile 级的一次性设置（DSH 官方模板本身不含此配置）；本插件是纯 JS、无生命周期脚本，**不需要** `allowBuilds` 放行流程。

- **本地开发（同时改两个插件）**：pnpm 不解析 git 依赖指向的本地改动，因此需把子包作为 **profile 直接依赖**手动链接。**必须用 `--save-dev` 装进 devDependencies**：`dsh plugin` 的 bundle 清单 reconcile 只扫描 `dependencies`，若把子包装进 `dependencies`，下一次任何 `dsh plugin` 命令都会把它自动提升为独立 bundle 层，与父 bundle 插入的同一行重复：

  ```sh
  dsh plugin --profile web add ./dsh-basic-right-sidebar
  pnpm --dir "$DSH_HOME/profiles/web" add -w --save-dev link:"$DSH_HOME/plugins/dsh-better-session-title"
  ```

  若子包已误入 `dependencies` 或 `dsh.profile.bundles`：从 `package.json` 的 `dependencies` 移入 `devDependencies`，并从 `dsh.profile.bundles` 移除该包名。
- **升级子插件**：把 `package.json` 依赖里的 commit SHA（或 tag）更新为 dsh-better-session-title 仓库的新提交即可。
- **卸载**：`dsh plugin --profile web remove dsh-basic-right-sidebar` 并 `pnpm --dir "$DSH_HOME/profiles/web" remove dsh-better-session-title`。

插件的 bundle 补丁（`cordis.patch.yml`）会自动注册 host 与 client 两半。客户端按请求加载：客户端改动刷新页面即可，host 改动需要重启。

## 配置

打开 **设置 → 插件 → Basic Right Sidebar**：

| 选项 | 说明 |
| --- | --- |
| 默认展开右侧边栏 | 启动后自动展开侧栏；手动收起不会被重新打断。 |
| 隐藏会话顶栏重复部分 | 总开关；开启后可按下方列表逐项勾选隐藏：**会话日志 · 会话模式 · 子代理 · 后台任务 · 对话/轨迹 Tab 栏**。 |
| 启用会话顶栏工作区/会话面包屑 | 在会话顶栏左侧显示面包屑（由子插件 dsh-better-session-title 提供）；关闭后恢复原生顶栏。 |

设置持久化到 `$DSH_HOME/plugins/dsh-basic-right-sidebar/settings.json`。插件自带持久化端点（`/bsrs-settings`）：DSH 官方设置线只暴露白名单内的命名空间，第三方命名空间无法使用。

## 与 dsh-better-session-title 的关系

本插件把 [dsh-better-session-title](https://github.com/xinspark/dsh-better-session-title) 作为**子插件**：`package.json` 的 `dependencies` 声明它（git 依赖锁定 commit），`cordis.patch.yml` 随本 bundle 一并插入它的插件行。顶栏面包屑由子插件**独占提供**（注册进 `conversation.session.header.actions`）；父插件的「启用会话顶栏工作区/会话面包屑」设置经全局快照 `window.__BASRS_SETTINGS__` 与 `'basrs:settings'` 事件桥接给它，关闭时子插件隐藏面包屑、恢复原生标题。

- **装了本插件就不要单独安装子插件** —— 两个 bundle 各自插入同名插件行会产生重复行。
- 子插件也可以**独立安装、独立使用**（无父插件时设置桥接缺省为启用）。
- 两个 bundle 都装了时，请在任意一侧设置中关闭其一的面包屑。

## 与官方项目的关系

本项目基于官方 [deepseek-ai/deepseek-harness](https://github.com/deepseek-ai/deepseek-harness) 构建，是一个**社区插件**，并非 DeepSeek 官方产品。

它展示的一切都是 DSH 自己的数据与界面，只是重新组织：

- 侧栏渲染进官方 `details` 插槽；侧栏开关注册进 `conversation.session.header.utilities`；配置卡片注册进 `settings.plugin.item`；顶栏面包屑由子插件 `dsh-better-session-title` 注册进 `conversation.session.header.actions`。
- 轨迹视图是 DSH 官方轨迹组件，内嵌并懒加载——逐像素一致，零系统源码改动。
- 图标库原生图标优先，侧栏与官方 UI 放在一起毫无违和感。

如果你更习惯命令行，或想参与核心功能开发，请优先使用官方仓库。

## 二次开发

- **`index.js`** —— host 半：会话日志统计、任务快照、设置持久化（`GET/POST /bsrs-settings`）。
- **`lib/client.js`** —— 浏览器半（UMD，注册进 DSH `clientModules`）。结构自上而下：
  1. 内嵌的 DSH 官方轨迹视图（懒加载，一般不用碰）。
  2. **图标库**（`createIconLibrary`）—— 原生图标优先；新增图标按库头部规则注册。
  3. **组件库**（`createComponentLibrary`）—— `SectionCard`、下拉菜单（`MenuItem`/`MenuPop`/`MoreMenu`/`DropdownList`）、`Tag`、`StateDot`、`TodoList`/`TodoGlyph`/`ProgressGlyph`、任务状态归一化、时间格式化、共享样式。`DropdownList` 吸收自子插件 dsh-better-session-title（自绘数据驱动下拉：fixed 定位 + 视口避让 / click 外部关闭 / 行内 meta + 悬浮更多按钮）；图标库已覆盖子插件面包屑的全部原生图标（含 `chevronDownOutline14`/`chevronUpOutline14`/`ellipsis16` 命名对齐别名）。
  4. `apply(ctx)` —— 注册插槽：`details`（侧栏）、`conversation.session.header.utilities`（侧栏开关）、`settings.plugin.item`（配置卡片）；内置 zh/en 双语字典，跟随 DSH 语言切换。顶栏面包屑（`header.actions`）由子插件提供。
- **子插件 `dsh-better-session-title`** —— 独立包（git 依赖声明于 `package.json`，插件行插入于 `cordis.patch.yml`）。其 client 半注册 `conversation.session.header.actions` 面包屑；父插件的 `showBreadcrumb` 设置经 `window.__BASRS_SETTINGS__` 快照与 `'basrs:settings'` 事件桥接给它。改它的代码在 [dsh-better-session-title](https://github.com/xinspark/dsh-better-session-title) 仓库。

扩展速查：

- **新增面板** —— 在 `apply` 的 `panels` 列表加一项，并写对应渲染组件。
- **新增文案** —— 在 `BSR_ZH` / `BSR_EN` 字典加 key。
- **新增图标** —— 在图标库注册（原生优先，无原生对应时用自定义）。

## 社区交流

- [GitHub Issues](https://github.com/xinspark/DSH-Basic-Right-Sidebar/issues) —— 提交 Bug、功能请求与问题咨询。
- [GitHub Discussions](https://github.com/xinspark/DSH-Basic-Right-Sidebar/discussions) —— 讨论侧栏扩展思路与使用心得。
- 主题 [`dsh-plugin`](https://github.com/topics/dsh-plugin) —— 本插件所属的社区插件主题。

### 生态链接

我们觉得有用的 DeepSeek Harness 生态项目与资源：

| 项目 | 简介 | 链接 |
| --- | --- | --- |
| DeepSeek Harness | 官方项目：Everything is a Plugin。 | [GitHub](https://github.com/deepseek-ai/deepseek-harness) |
| dsh-TUI | DSH 全屏交互式终端界面。 | [GitHub](https://github.com/ccch1mneyyy/dsh-TUI) |
| Awesome DSH Plugin | DSH 社区插件精选列表。 | [GitHub](https://github.com/AdamPlatin123/awesome-dsh-plugins) |
| dsh-market | 收录 1500+ DSH 插件的市场。 | [GitHub](https://github.com/2BingLing/dsh-market) |
| DSH-Plugins-Marketplace | 基于 `dsh-plugin` 主题的 GUI 内插件市场。 | [GitHub](https://github.com/bradeGithub/DSH-Plugins-Marketplace) |

想让你的项目也出现在这里？欢迎提 PR 或在 Discussions 里告诉我们。

## 特别感谢

感谢 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) 与 DeepSeek AI 团队——核心的智能体、模型、工具、会话、Web UI 与插件生态都来自这个项目；也感谢 [Cordis](https://github.com/cordiverse/cordis) 提供的插件化基础，以及 [Koishi.js](https://koishi.chat/) 社区长期积累的插件化实践、工具与经验。

## 许可证

[MIT](LICENSE) —— 完全开源免费。

Basic Right Sidebar 是 DeepSeek Harness 的社区插件，**并非 DeepSeek 官方产品**。如果有人向你以任何形式出售此插件，请拒绝交易。
