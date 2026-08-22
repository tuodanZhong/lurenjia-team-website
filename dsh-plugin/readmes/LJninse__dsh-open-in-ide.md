# dsh-open-in-ide

> 顶部栏「IDE」按钮 —— [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)（简称 **dsh**）Web UI 插件：自动检测本机已安装的 IDE，一键用其打开当前会话的工作区目录。

[![License](https://img.shields.io/badge/license-CC_BY--NC_4.0-blue.svg)](./LICENSE)
[![dsh](https://img.shields.io/badge/dsh-%3E%3D0.1.0--rc.6-blueviolet)](./package.json)
[![platform](https://img.shields.io/badge/platform-Windows-lightgrey)](./README.md)

---

## 简介

在 DeepSeek Harness 的 Web GUI 里工作时，经常需要「把当前项目用本地 IDE 打开」。这个插件在**会话头部右上角**加入一个「IDE」按钮：设置默认 IDE 后单击即直接打开当前工作区目录，点 ▾ 或右键可展开菜单选择其它 IDE —— 省去手动复制路径、再到 IDE 里 `File > Open Folder` 的麻烦。

插件是标准的 dsh 双面包：

- **宿主半（Node）** `index.mjs`：负责在本机检测 IDE、启动所选 IDE，并自建同源 HTTP 路由 `/open-in-ide`。
- **浏览器半（Client）** `client.js`：负责顶栏按钮与下拉菜单 UI，通过同源 `fetch` 调用宿主半的路由。

## 用途 / 使用场景

- 在 dsh Web GUI 中让 agent 干活时，一键把当前工作区目录在本地 IDE 中打开，边看边改。
- 多 IDE 共存时（VS Code / Cursor / JetBrains 全家桶等）快速切换，无需记住各自的安装路径。
- IDE 装在任意自定义目录（D 盘、便携版等）都能通过注册表 `App Paths` 精确定位；即便个别程序没写注册表，也有目录扫描兜底，实在扫不到还能手动指定任意 `.exe`。

## 功能特性

- **自动检测（注册表优先）**：优先读取 Windows 注册表 —— `App Paths`（安装程序注册的「exe 名 → 真实路径」映射，能精确定位任意自定义安装位置）与卸载项（`InstallLocation` / `DisplayIcon` / `UninstallString`）；再以常见安装目录、`PATH` 里的 `.cmd` shim、scoop、JetBrains Toolbox、`Program Files` 下的 JetBrains、开始菜单 `.lnk` 快捷方式，以及桌面/下载/文档等用户目录与其它盘符根目录的启发式扫描作为兜底。
- **自定义添加（持久化）**：菜单底部「选择 IDE 程序…」弹出 Windows 原生文件对话框，任选一个 `.exe` 立即加入列表；自定义项保存到 `.dsh-open-in-ide-prefs.json`，重启后仍存在，并可随时删除。
- **默认 IDE / 最近使用**：条目右侧 ☆ 可设为默认（再次点击取消），默认项自动置顶并显示「默认」徽标；未设默认时最近一次使用的 IDE 置顶并显示「上次」。
- **点击直达**：已设默认（★）时，单击「IDE」按钮直接用它打开当前工作区，无需展开菜单；仍想选其它 IDE 时，点按钮右侧的 ▾ 下拉箭头或右键按钮展开完整菜单。
- **缓存与预热**：检测结果缓存到工作区下的 `.dsh-open-in-ide-cache.json`（TTL 30 分钟），插件启动后会延迟预热扫描，首次点击通常无需等待；「重新检测」会绕过缓存强制执行全新扫描。
- **菜单选择打开**：展开菜单点击任一 IDE 即用其打开当前会话的工作区目录；菜单顶部显示目标目录。
- **随时重新检测**：菜单底部提供始终可用的「重新检测」按钮，安装/移动 IDE 后无需重启即可重新扫描。
- **双面包架构 + 可测试**：宿主半负责检测与启动，浏览器半负责 UI，互不耦合；纯检测逻辑抽到 `lib.mjs` 并带 `node:test` 单测。
- **中英文界面**：客户端文案接入 DSH locale（`open-in-ide` 命名空间），跟随界面语言显示中文或英文。

## 支持检测的 IDE

VS Code / VS Code Insiders、Cursor、Windsurf、Zed、Trae、VSCodium、IntelliJ IDEA（Ultimate / Community）、PyCharm（Professional / Community）、WebStorm、PhpStorm、GoLand、CLion、Rider、DataGrip、RubyMine、RustRover、Aqua、Writerside、Fleet、Android Studio、Sublime Text、Eclipse、Visual Studio 等。菜单里还内置「资源管理器」入口，可直接用系统文件管理器打开目录。

## 安装

### 前置要求

- [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) ≥ `0.1.0-rc.6`
- **Windows**（文件对话框与检测脚本面向 Windows 桌面环境）

### 方式一：从本仓库克隆安装（推荐）

```sh
git clone https://github.com/LJninse/dsh-open-in-ide.git
dsh plugin --profile web add ./dsh-open-in-ide
```

包内 `cordis.patch.yml` 会自动成为 bundle 层（插入 `open-in-ide` 插件行），**重启 Web 后生效**。

### 方式二：本地目录 / tarball 安装

```sh
dsh plugin --profile web add ./dsh-open-in-ide

# 或先打包再安装：
pnpm pack            # 生成 dsh-open-in-ide-0.5.2.tgz
dsh plugin --profile web add ./dsh-open-in-ide-0.5.2.tgz
```

### 方式三：手动挂载（零依赖，无需 pnpm）

1. 把本包放入目标 profile 的 `node_modules/dsh-open-in-ide/`（`index.mjs` + `lib.mjs` + `client.js` + `cordis.patch.yml` + `package.json`）；
2. 在 profile 的 `package.json` 的 `dependencies` 中添加 `"dsh-open-in-ide": "file:<本包路径>"`；
3. 在 profile 的 `cordis.patch.yml` 末尾追加：

```yaml
- insert:
    - id: open-in-ide
      name: dsh-open-in-ide
```

4. 重启 `dsh web`。

## 使用方法

重启 Web 后，打开任意会话，顶部栏右上角出现「IDE」按钮：

1. 点击按钮：已设置默认（★）时直接用默认 IDE 打开当前工作区目录；未设置默认时弹出菜单，列出检测到的 IDE（含可执行文件路径、默认/上次徽标）。
2. 点按钮右侧 ▾ 或右键按钮，总是展开完整菜单；点击某个条目即用该 IDE 打开当前会话的工作区目录。
3. 条目右侧 ☆ 可设为默认 IDE（再点 ★ 取消默认）；自定义条目右侧 × 可删除。
4. 菜单底部「选择 IDE 程序…」可手动添加未被检测到的 `.exe`；「重新检测」按钮可随时清空缓存并重新扫描（新增/移动 IDE 后无需重启）。

## 测试

```sh
pnpm test
# 或
node --test tests/detect.test.mjs tests/host.route.test.mjs
```

## 验证

```sh
dsh --profile web --dump-config
# 应看到 open-in-ide 行，且 bundle 层标注 # == dsh-open-in-ide
```

行为验证：重启后打开任意会话，顶部栏右上角出现「IDE」按钮；未设默认时单击弹出菜单并列出检测到的 IDE，设默认后单击直接打开默认 IDE（点 ▾ 或右键仍可打开菜单）。

## 项目结构

```
dsh-open-in-ide/
├── index.mjs          # 宿主半：IDE 检测、启动、偏好持久化、/open-in-ide 路由
├── client.js          # 浏览器半：顶栏按钮与菜单 UI、locale 文案
├── lib.mjs            # 纯函数：IDE 名称/exe 映射、路径规范化、排序
├── tests/             # node:test 单元测试（检测逻辑 + 路由行为）
├── cordis.patch.yml   # bundle patch：插入 open-in-ide 插件行
├── package.json       # 包元信息（含 dsh.bundle / dsh.client 声明）
├── LICENSE            # CC BY-NC 4.0
└── README.md
```

## 说明与限制

- **仅支持 Windows**：文件对话框与检测脚本面向 Windows 桌面环境。
- **真实启动程序**：每次点击都会真实启动所选程序，打开/传输消耗真实本机资源。
- **自定义项与偏好持久化**：自定义 `.exe`、默认 IDE、最近使用记录写入工作区根目录的 `.dsh-open-in-ide-prefs.json`；如需让该文件保持私密或不被提交，可将其加入 `.gitignore`。
- **检测结果缓存**：自动检测结果写入工作区根目录的 `.dsh-open-in-ide-cache.json`（TTL 30 分钟）；如需让该文件保持私密或不被提交，可将其加入 `.gitignore`。
- **检测只读**：检测脚本只读取注册表（`App Paths`、卸载项）、环境变量、开始菜单与本地目录（限深、限预算），不修改系统。
- **注册表为主、目录扫描兜底**：注册表 `App Paths` 能精确定位任意自定义安装位置的 IDE；仅当个别程序未写注册表（如绿色/便携版）时才退回目录启发式扫描（限深度、限目录数，极深的目录树可能被预算截断）——这种情况可改用「选择 IDE 程序…」手动添加。

## 许可

© 2026 dsh-open-in-ide contributors

本项目采用 [Creative Commons Attribution-NonCommercial 4.0 International（CC BY-NC 4.0）](./LICENSE) 许可证：允许自由使用、复制、修改与再分发，但**禁止商业用途**；使用或再分发时须保留署名。

> 说明：CC BY-NC 4.0 属于“源码可用（source-available）”协议，并非 OSI 所定义的“开源”许可证（OSI 开源许可证允许商业使用）。
