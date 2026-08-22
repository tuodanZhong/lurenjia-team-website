# DshDesktop — DeepSeek Harness 桌面壳

DshDesktop 是一个轻量的 Windows 原生桌面程序，用 **WinForms + WebView2** 承载
DeepSeek Harness 的 Web GUI（`http://127.0.0.1:3080`），双击即用，无需手动打开浏览器。

## 功能特性

- 双击启动，自动完成「探测服务 → 启动 harness → 加载界面」全流程
- 原生窗口承载 Web GUI，页面外链用系统默认浏览器打开
- **默认视图纯净**：顶部无导航栏、无标签条，只有 harness 页面
- **多标签页**：主页标签页固定不可关闭；设置页、网页标签页以独立标签页打开，可关闭
- **网页标签页**：注入 API 可打开 / 激活任意网页标签页（供 dsh-chat-web 插件使用）
- **右键功能项（插在 WebView2 原生右键菜单的第二组）**：首页 (Ctrl+Home) / 标签页 /
  设置 (Ctrl+F12)，组与默认项之间用分隔线隔开
- **右键菜单搜索（dsh-chat-web 插件配套）**：主页选中文本后右键时，在原生菜单
  「复制」项正下方追加「🔍 搜索选中文本」项，点击后用选中文本打开插件的悬浮搜索框
- **浏览器扩展挂载**：可配置目录 + harness 插件目录自动发现（启动及每 30 秒重扫）
- **扩展通道**：WebView2 扩展内容脚本（隔离世界）经桥接也能调用全部 `window.dshDesktop` API
- **浏览器设置同步**：dsh-chat-web 插件设置的浏览器选项，同步分发到网页标签页的扩展顶部栏
- **JS 注入开放 API**：`window.dshDesktop` 提供关闭/切换标签页、前进/返回、
  缓存管理、网页标签页、设置同步
- **缓存管理**：设置页提供缓存大小查看、清除缓存、清除全部浏览数据
- **版本信息与更新检查**：设置页展示当前版本，通过 GitHub Releases API 检查更新；
  发现新版本时提示，一键跳转系统默认浏览器打开 Release 页面下载
- 单实例运行；关闭窗口时自动停止由本程序启动的 harness 进程
- 自包含单文件发布，目标机器无需安装 .NET 运行时

## 用户指南

### 下载与安装

从 [Releases](https://github.com/sweven-tears/DshDesktop/releases/latest) 页面下载最新版
`DshDesktop.exe`。**无需安装**，双击即可运行。

> 可选校验：每个版本 Release 说明中都会公布 SHA256，下载后可用以下命令核对文件完整性：

```powershell
Get-FileHash DshDesktop.exe -Algorithm SHA256
```

### 系统要求

- Windows 10 / 11
- WebView2 运行时（Windows 11 自带；Windows 10 通常随 Edge 一并安装，如缺失程序会提示）

### 快速上手

双击 `DshDesktop.exe` 后程序会自动：

1. 探测 `http://127.0.0.1:3080`；
2. 若服务未运行，自动在后台启动 harness（优先直接运行本地 npm 缓存的
   `@deepseek-ai/dsh`，必要时退回 `npx @deepseek-ai/dsh web`，工作目录
   `D:\Program\harness`）并等待就绪；
3. 若 3080 已被其他进程占用（例如残留的外部服务），会询问是否**接管**：
   选择“是”则结束占用进程、由本程序重新自启并独占服务；选择“否”则直接连接现有服务；
4. 在原生窗口内加载 Web GUI。

### 右键菜单与快捷键

在页面内**右键**，弹出的是浏览器原生右键菜单（复制/粘贴/打印等默认项原样保留），
在默认第一组之后插入一组应用功能项（组与默认项之间用分隔线隔开）：

- **首页 (Ctrl+Home)**：回到主页（DeepSeek Harness 首页，不关闭已打开的标签页；
  处于主页时菜单中自动隐藏此项）
- **标签页**：二级子菜单，列出已打开的标签页（主页除外），点击即切换；
  没有其他标签页时整个「标签页」项隐藏
- **设置 (Ctrl+F12)**：打开 / 切换设置页（不重复打开，已有设置页则直接激活）
- **🔍 搜索选中文本**（仅主页，dsh-chat-web 插件）：选中文本后右键时出现，位于
  「复制」正下方；点击后用选中文本打开插件的悬浮搜索框（可换搜索引擎后在新标签页打开）

快捷键 **Ctrl+Home** / **Ctrl+F12** 全局生效（页面内也响应）。

### 设置页

> ⚠️ **开发中**：设置页目前功能简陋，正处于开发迭代中——界面与交互较为基础，
> 后续版本会持续完善（主题、浏览器设置等）。当前提供：

- **扩展管理**
  - 用户配置目录默认 `%LOCALAPPDATA%\DshDesktop\Extensions`，可点「浏览…」更换；
  - 把 unpacked 扩展文件夹（内含 `manifest.json`）放入目录后点「扫描并加载扩展」，
    列表中的扩展可逐个「移除」；
  - **harness 插件自动发现**：程序启动时及每 30 秒自动扫描 harness 的 `plugins`
    目录——插件目录本身含 `manifest.json`，或含 `extension/`、`web-extension/`、
    `ext/` 子目录的，会被识别为扩展并自动加载（列表中标记「harness 插件」，不可手动移除）。
  - > 注意：仅支持 unpacked 目录，Chrome 商店的 `.crx` 需先解压；WebView2 只支持
    > 部分 `chrome.*` API，个别扩展可能无法加载。扩展按 profile 生效，对所有标签页立即生效。
- **缓存管理**：显示缓存大小（估算自 WebView2 用户数据目录），可「清除缓存」
  （HTTP/磁盘缓存 + 缓存存储，保留登录态）或「清除全部浏览数据」（含 Cookie 等，会退出登录）。
- **版本信息**：显示当前程序版本（来自程序集信息）与 GitHub 仓库入口；点「检查更新」
  经 GitHub Releases API（`sweven-tears/DshDesktop`）查询最新 Release 并比较版本号——
  有更新时展示新版本号与更新说明，点「前往下载」用系统默认浏览器打开 GitHub Release 页面；
  打开设置页时自动检查一次（成功结果缓存 30 分钟；带 ETag 条件请求，GitHub 限流时用最近一次成功结果兜底，不直接报错）。

### JS 注入开放 API

宿主在每个页面文档创建时注入桥接脚本，页面脚本（含注入的用户脚本）可直接调用
`window.dshDesktop`：

| API | 说明 |
| --- | --- |
| `dshDesktop.openWebTab(url)` | 打开/激活网页标签页（有则切换，无则新建） |
| `dshDesktop.newWebTab(url)` | 新建网页标签页 |
| `dshDesktop.setWebSettings(settings)` | 同步浏览器设置给宿主（分发给网页标签页的扩展顶部栏） |
| `dshDesktop.closeTab()` | 关闭当前标签页（主页不可关闭） |
| `dshDesktop.switchTab(index)` | 切换到指定标签页（0 为主页；隐藏页面即切回主页保活） |
| `dshDesktop.back()` / `forward()` | 页面返回 / 前进 |
| `dshDesktop.clearCache()` | 清除缓存（Promise） |
| `dshDesktop.cacheSize()` | 查询缓存大小，字节数（Promise） |

> **扩展通道**：WebView2 扩展的内容脚本运行在隔离世界，无法直接访问
> `window.chrome.webview`。桥接脚本会监听 `window.postMessage` 的 `__dshExt`
> 消息代为转发，并把宿主回执以 `__dshExtReply` 转回隔离世界——因此扩展内容脚本
> 同样可以调用以上全部 API。

### 行为说明

- **单实例**：桌面壳是服务的唯一入口，重复启动只会提示“已在运行”。
- **独占服务**：由本程序启动的 harness 进程在关闭窗口时会被一并停止
  （`taskkill /T /F` 整棵进程树）；服务异常退出时窗口会给出提示。
- **启动更稳**：优先直接运行本地 npm 缓存的 `@deepseek-ai/dsh`（免 npx 联网解析），
  失败自动重试 3 次；服务自身输出写入 `%TEMP%\DshDesktop-server.log`，
  启动失败的弹窗会附上该日志末尾以便排查。
- 如果选择了“不接管”而连接现有服务，关掉桌面壳不会停止那个外部服务。

### 环境变量与配置目录

- 环境变量（可选）：
  - `DSH_HARNESS_DIR`：harness 根目录（默认 `D:\Program\harness`）
  - `DSH_DESKTOP_USERDATA`：WebView2 用户数据目录（默认
    `%LOCALAPPDATA%\DshDesktop\webview`）
  - `DSH_DESKTOP_LOG`：日志文件路径（默认 `%TEMP%\DshDesktop.log`）
- 用户配置目录：`%LOCALAPPDATA%\DshDesktop\`（`settings.json` 记录扩展配置目录；
  `web\` 为设置页静态资源；`Extensions\` 为默认扩展目录；`webview\` 为浏览器用户数据）。

## 开发者指南

### 源码结构

- `Form1.cs` — 主窗体：启动/等待 harness、多标签页（含网页标签页）、追加在 WebView2
  原生右键菜单上的功能项与全局快捷键（Ctrl+Home / Ctrl+F12）、注入脚本桥消息路由
  （`window.dshDesktop`）与设置页协议、浏览器设置同步分发、外链处理、关窗清理
- `BridgeScript.cs` — 注入页面的开放 API 桥接脚本（v2：网页标签页、设置同步、扩展通道）
- `ExtensionManager.cs` — 扩展扫描/加载/移除（WebView2 profile 级；含 harness 插件目录自动发现）
- `CacheOps.cs` — 缓存大小估算与清除
- `SettingsStore.cs` — 用户配置持久化（`settings.json`）
- `SettingsPage.cs` — 设置页 HTML/CSS/JS（写入 `%LOCALAPPDATA%\DshDesktop\web\`，
  经虚拟主机 `https://dsh-settings.local/` 加载）
- `Program.cs` — 程序入口
- `DshDesktop.csproj` — 项目文件（net7.0-windows + WebView2 1.0.4129.50，Version 0.1.4）
- `NuGet.Config` — 项目级 NuGet 源配置（包缓存重定向到 `D:\Program\harness\.nuget-packages`）
- `app.ico` — 应用图标

### 环境要求

- Windows 10/11
- .NET 7 SDK（`dotnet --version` 确认）
- WebView2 运行时（开发机通常已随 Edge 安装）

### 构建

```powershell
dotnet build DshDesktop.csproj -c Release
```

### 发布（生成自包含单文件到 `publish-new\`）

```powershell
dotnet publish DshDesktop.csproj -c Release -r win-x64 --self-contained true `
  -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true `
  -o publish-new
```

### 发布新版本到 GitHub Releases

```powershell
gh release create v0.1.4 publish-new/DshDesktop.exe `
  --title "DshDesktop v0.1.4" --notes "更新说明…（附 SHA256）"
```

## 许可协议

本项目采用 [MIT License](LICENSE)。Copyright (c) 2026 sweven-tears。

## 更新日志

### v0.1.4（2026-08-16）— 修复更新检查

- **修复「检查更新失败：GitHub 接口返回 HTTP 403」**：GitHub 匿名 API 限流
  60 次/小时/IP，共享 IP 上极易触发 403。本次调整：
  - **优先走本机 gh CLI**（已认证，5000 次/小时，不受匿名限流影响）；gh 不可用时
    退回匿名 API；
  - 匿名路径带 **ETag 条件请求**（`If-None-Match`）：版本未变化时 GitHub 返回 304，
    **不消耗限流配额**，并复用上次成功结果；
  - 成功结果缓存从 10 分钟延长到 **30 分钟**；
  - 遇到限流 / 网络失败时，**24 小时内展示最近一次成功结果兜底**，并提示稍后重试，
    不再直接报错。
- 项目文件写入 `Version 0.1.4`

### v0.1.3（2026-08-16）— 初版发布

首个完整功能发布：

- **WinForms + WebView2 桌面壳**：自包含单文件，双击即用，自动「探测服务 → 启动
  harness → 加载界面」；关闭窗口自动停止由本程序启动的 harness 进程
- **多标签页**：主页固定不可关闭；设置页、网页标签页以独立标签页打开，可关闭
- **右键菜单功能项**：首页（Ctrl+Home）/ 标签页 / 设置（Ctrl+F12），以及
  dsh-chat-web 插件配套的「🔍 搜索选中文本」
- **浏览器扩展挂载**：可配置目录 + harness 插件目录自动发现（启动及每 30 秒重扫），
  扩展经隔离世界桥接通道（`__dshExt`）调用全部桌面 API
- **JS 注入开放 API**：`window.dshDesktop`（打开/关闭/切换标签页、前进/返回、
  浏览器设置同步、缓存管理）
- **缓存管理**：设置页提供缓存大小查看、清除缓存、清除全部浏览数据
- **版本信息与更新检查**：设置页展示当前版本，经 GitHub Releases API 检查更新，
  发现新版本一键跳转系统默认浏览器打开 Release 页面下载
- 单实例运行；浏览器设置同步分发到网页标签页扩展顶部栏
