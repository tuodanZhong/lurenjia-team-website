# TangDSH Desktop · DeepSeek Harness 桌面客户端

**开箱即用的 DeepSeek Harness 桌面客户端** —— 零命令行、双击即用，为开发者而生。

> **免责声明**：TangDSH Desktop 是第三方非官方项目，与 DeepSeek 公司无关。"DeepSeek" 相关名称与商标归 DeepSeek 公司所有。

---

## 📥 立即下载

> 适用系统：**Windows 10 / 11（64 位）**。两个版本功能完全一致，区别仅在首次启动是否联网。

| 版本 | 说明 | 大小 |
|------|------|------|
| ⚡ **离线版（推荐）** | 已内置运行环境，**下载解压即用、断网可用、秒开** | 173 MB |
| 🌐 在线版 | 单文件，首次启动自动联网部署环境（约 1–6 分钟） | 64.6 MB |

### ⬇️ 下载链接

**[⚡ 下载离线版（推荐）](https://github.com/tangbohu2017/TangDSH-Desktop/releases/download/v1.1.2/TangDSH-Desktop-v1.1.2-win-x64-offline.zip)**

**[🌐 下载在线版](https://github.com/tangbohu2017/TangDSH-Desktop/releases/download/v1.1.2/TangDSH-Desktop-v1.1.2-win-x64-online.zip)**

> 💡 网络正常、追求最小下载体积 → 选**在线版**；网络受限或想开箱即用 → 选**离线版**。

---

## 📸 界面预览

<p align="center">
  <img src="docs/screenshots/screenshot-1.png" width="49%" alt="主界面" />
  <img src="docs/screenshots/screenshot-2.png" width="49%" alt="工作区文件面板" />
</p>
<p align="center">
  <img src="docs/screenshots/screenshot-3.png" width="49%" alt="@ 文件引用" />
</p>
<p align="center">
  <img src="docs/screenshots/screenshot-4.png" width="49%" alt="识图功能：对话中识别图片" />
  <img src="docs/screenshots/screenshot-5.png" width="49%" alt="识图功能：通用设置" />
</p>

---

## 快速开始

1. **下载**上方安装包并解压到任意目录（建议非系统盘、路径不含中文）；
2. **双击** `TangDSHDesktop.exe` 启动，首次运行自动完成环境部署（在线版需联网，界面显示进度）；
3. **输入 DeepSeek API 密钥**（支持"显示明文"开关），点击"开始使用"；
4. 等待"服务就绪"，自动加载主界面，即可开始使用。

> 尚未申请密钥？请访问 [platform.deepseek.com](https://platform.deepseek.com) 创建 API Key。

---

## 启动流程

应用启动后按以下流水线自动运行（任一步失败都会在界面给出明确的中文错误提示，并可点击"重试"）：

```
启动应用
   │
   ▼
① 初始化日志系统 ──────────────► 写入 %LOCALAPPDATA%\...\logs\
   │
   ▼
② 检查 WebView2 浏览器内核 ──── 缺失？→ 自动下载安装（需一次 UAC 授权）
   │
   ▼
③ 部署运行环境 ──────────────── 查找顺序：
   │                            exe 旁 runtime\（随包）→ 本地缓存 → 系统 Node.js → 自动下载
   ▼
④ 读取 / 输入 API 密钥 ──────── 已有加密密钥则直接使用，否则弹出输入框
   │
   ▼
⑤ 选择端口并启动本地服务 ────── 首选端口被占用时自动换空闲端口（3080–3180）
   │                            注入 DEEPSEEK_API_KEY 环境变量（先清空系统残留密钥变量）
   ▼
⑥ 健康检查（最多 3 分钟） ────── 每 800ms 探测一次服务就绪状态
   │
   ▼
⑦ 加载界面 ──────────────────── WebView2 导航到 http://localhost:<端口>
```

---

## 功能特性

| 特性 | 说明 |
|------|------|
| **零环境依赖** | 自动检测并部署 Node.js 与 DeepSeek Harness，无需手动安装任何开发工具 |
| **离线分发支持** | 可将已就绪的运行环境随程序一起分发，用户无需联网即可使用 |
| **自动端口管理** | 默认端口被占用时自动选择空闲端口（3080–3180 范围） |
| **API Key 安全存储** | 使用 Windows DPAPI 加密保存，绑定当前用户，不落明文 |
| **图片识别（识图）** | 设置 → 通用设置 → 识图功能：开启后，聊天中发布的图片通过阿里云千问（Qwen）视觉模型自动理解，可直接提问图片内容（需自备百炼 DashScope API Key） |
| **工作区文件面板** | 浏览本地任意文件夹，自动识别项目类型（.NET / Java / Node / Python / Go / Rust / PHP 等），**启动即自动加载上次的工作目录** |
| **变更记录（每轮会话一个版本）** | 每次发消息后 Agent 的改动归并为**一个新版本**（不再按 15 分钟空闲合并），附"N 个文件"标签；回退可恢复到会话开始前的状态，支持撤销回退 |
| **代码审核（VSCode 风格）** | 三色差异标记：**红=删除、绿=新增、橙=修改**；点击文件在多标签页中打开差异视图，可同时打开多个文件；一键"全部通过"或逐个审核（通过并下一个/上一个待审） |
| **AI 变更摘要（自动）** | 每轮会话结束自动用 DeepSeek 生成语义摘要并保存到版本记录；支持 AI 代码自检（审查待审核改动） |
| **辅助文件智能过滤** | 自动识别并排除 AI 辅助文件（watch-*/probe*/repro*/create-*）、浏览器缓存（Cache/GPUCache 等）、DSH 技能库（.dsh）等，审核与自动跟随只针对正式代码 |
| **工作区自动跟随** | 点击哪个项目的会话，工作区面板自动跟随显示该项目目录（基于当前会话精确匹配），切换时显示加载状态 |
| **Markdown 渲染预览** | .md 文件一键在源码 / 渲染预览间切换，支持标题、列表、代码块、表格、图片（含 HTML 标签安全过滤） |
| **大文件差异** | 超大文件（数千行）也正常显示红绿灰三色差异，不再降级为"全部新增" |
| **桌面悬浮球** | 桌面置顶小圆球：单击最小化/恢复窗口（保留任务栏），右键菜单快速操作；仅显示图标无多余背景 |
| **代码预览** | 点击文件即可在右侧面板预览内容，大文件自动截断保护性能 |
| **@ 文件引用** | 在输入框输入 `@` 即可搜索并引用工作区文件/文件夹，内容随消息自动附加 |
| **国内 NuGet 优化** | 已配置国内镜像源并关闭漏洞审计，`dotnet` 构建不再因官方源超时而报警告 |
| **系统托盘** | 最小化到托盘、托盘菜单快速操作、更换 API 密钥 |
| **WebView2 自动安装** | 缺少浏览器内核时自动下载安装（需一次管理员授权） |
| **完善的日志系统** | Serilog 按天滚动记录，保留 7 天，便于排查问题 |

---

## 系统要求

| 项目 | 要求 |
|------|------|
| 操作系统 | Windows 10 / Windows 11（64 位） |
| 架构 | x64 |
| 磁盘空间 | 约 500 MB（含运行环境缓存） |
| 网络 | 首次运行需联网以下载运行环境（离线版/随包 runtime 则无需联网） |
| 浏览器内核 | WebView2 运行时（Windows 10/11 一般已自带；缺失时应用会自动安装） |
| .NET 运行时 | **无需安装**（已内置自包含运行时） |

> 不支持 32 位系统与 Windows 7 及更早版本。

---

## 为什么选择 TangDSH Desktop

**开发者友好，开箱即用——把"环境准备"这件事彻底交给应用。**

### 🚀 零命令行，双击即用
- **无需安装任何东西**：Node.js、npm、DeepSeek Harness、WebView2 全部自动检测与部署——第一次双击，应用自己完成一切；
- **不用记住任何命令**：没有 `npm install`、没有 `npx dsh web`、没有环境变量配置，打开就是完整界面；
- **国内网络优化**：下载与安装自动走国内镜像（npmmirror），失败自动切换，告别"卡在安装"；
- **离线可用**：附带运行环境的离线版，断网环境也秒开。

### 🛡️ 安全与隐私，天然为开发者设计
- **API 密钥不落明文**：DPAPI 加密存储，绑定当前 Windows 用户，换机器无法解密；
- **密钥环境隔离**：启动服务前自动清空系统中残留的所有 AI 密钥环境变量，只注入你自己的密钥，杜绝"串号"；
- **纯本地运行**：服务仅监听 `localhost`，你的代码与对话不出本机。

### 📁 为开发者打造的工作区体验
- **可视化文件浏览**：工作区内置文件树面板，无需 `cd` / `ls`，点开即看项目结构；
- **智能项目识别**：自动识别 .NET / Java / Node.js / Python / Go / Rust / PHP 项目类型、框架与语言；
- **@ 一键引用文件**：在对话中输入 `@` 即可模糊搜索并引用任意文件/文件夹，文件内容自动附加给 AI——像 VS Code 一样自然的上下文注入；
- **内嵌代码预览**：点文件即在右侧预览源码，无需离开窗口。

### 💻 原生桌面体验
- **WebView2 内嵌**：原生窗口 + 网页界面的最佳结合，可缩放、可托盘、可记忆窗口状态；
- **系统托盘**：一键显示/隐藏/更换密钥/退出，不打断工作流；
- **完善的日志系统**：按天滚动记录，遇到问题直接看日志定位。

---

## 界面与功能说明

### 主界面

主界面为内置浏览器（WebView2）呈现的 DeepSeek Harness Web 界面，地址为本地服务（`http://localhost:<端口>`），所有数据仅在本机处理。

### 工作区文件面板

点击页面左侧的 **☰ 按钮** 打开工作区面板：

- **打开工作区**：选择本地文件夹后，应用自动分析项目类型（.NET、Java、Node.js、Python、Go、Rust、PHP 等），显示框架、语言与关键文件；
- **文件树浏览**：展开目录、点击文件即可在右侧面板预览代码内容（超过 1 MB 的文件仅显示前 1 MB）；
- **自动忽略**：`node_modules`、`bin`、`obj`、`.git` 等目录与二进制文件自动过滤，保持树形整洁。

### @ 文件引用

在输入框输入 `@` 会弹出文件/文件夹选择器：

- 支持**模糊搜索**、**方向键导航**（`↑`/`↓` 选择、`←`/`→` 展开折叠目录、`Enter`/`Tab` 确认、`Esc` 关闭）；
- 选中后生成引用标签（chip），被引用文件的内容会**自动附加**到发送给 DeepSeek Harness 的消息中（单个文件超过 80 KB 时仅附加前 80 KB）；
- 应用会自动记忆上次打开的工作区，并在页面加载后自动恢复。

### 图片识别（识图功能）

1. 打开 **设置 → 通用设置 → 识图功能**，打开开关；
2. 填写**阿里云百炼（DashScope）API Key**（在 [bailian.console.aliyun.com](https://bailian.console.aliyun.com) 的「API-KEY 管理」创建），保存；
3. 之后在聊天中**直接发布图片**并提问（如"这张图里有什么？"），应用会调用千问视觉模型（默认 `qwen-vl-max`）描述图片内容后回答。

> API Key 只保存在本机（`dsh-home\settings.yaml`），界面永不显示明文；图片仅发送给阿里云百炼用于生成描述。可在设置中更换模型（`qwen-vl-plus`、`qwen2.5-vl-72b-instruct`）。

### 系统托盘

- 关闭窗口时默认**最小化到托盘**（而非退出），双击托盘图标可恢复窗口；
- 右键托盘图标菜单：
  - **显示窗口**：恢复主窗口；
  - **更换 API 密钥**：重新输入密钥并重启服务；
  - **退出**：完全退出应用（同时停止本地服务）。

### 窗口状态记忆

应用会记住窗口大小与最大化状态，下次启动自动恢复。

---

## 数据与隐私

应用产生的所有数据均保存在**本机当前用户**目录下：

| 数据 | 位置 | 说明 |
|------|------|------|
| API 密钥 | `%LOCALAPPDATA%\DeepseekHarnessDesktop\apikey.dat` | DPAPI 加密，仅当前 Windows 用户可解密 |
| 应用设置 | `%LOCALAPPDATA%\DeepseekHarnessDesktop\settings.json` | 窗口状态、端口偏好等 |
| 运行环境缓存 | `%LOCALAPPDATA%\DeepseekHarnessDesktop\runtime\` | Node.js 与 DeepSeek Harness |
| 隔离数据目录 | `%LOCALAPPDATA%\DeepseekHarnessDesktop\dsh-home\` | 会话与配置文件（与应用隔离，不影响系统） |
| 日志 | `%LOCALAPPDATA%\DeepseekHarnessDesktop\logs\` | 按天滚动，保留最近 7 天 |

其中 `%LOCALAPPDATA%` 通常为 `C:\Users\<用户名>\AppData\Local`。

**安全设计**：

- API 密钥使用 Windows DPAPI（`DataProtectionScope.CurrentUser`）加密，绑定当前机器与用户；
- 启动 DeepSeek Harness 服务前会**清空**环境中所有已知的 API 密钥变量（如 `DEEPSEEK_API_KEY`、`OPENAI_API_KEY` 等），再仅注入您配置的密钥，避免误用系统残留凭据；
- **日志中不包含密钥明文**（保存密钥时仅记录"已保存"操作，不记录密钥内容）；
- 本地服务仅监听 `localhost`，不对外网开放。

---

## 配置说明

配置文件位于 `%LOCALAPPDATA%\DeepseekHarnessDesktop\settings.json`，首次运行后自动生成。请先退出应用再修改，保存后重启生效。

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `PreferredPort` | 整数 | `0` | 首选服务端口；`0` 表示自动选择（3080–3180 范围内的空闲端口） |
| `MinimizeToTray` | 布尔 | `true` | 关闭窗口时最小化到托盘而非退出 |
| `StartWithWindows` | 布尔 | `false` | **预留字段**：开机自启动。当前版本尚未在界面中启用，修改暂不生效 |
| `WindowWidth` | 数字 | `1280` | 窗口宽度（像素） |
| `WindowHeight` | 数字 | `800` | 窗口高度（像素） |
| `WindowMaximized` | 布尔 | `false` | 上次退出时窗口是否为最大化 |
| `LastWorkspacePath` | 字符串 | `null` | 上次打开的工作区文件夹路径 |

> 提示：窗口大小与最大化状态由应用自动维护，无需手动修改；手动修改后需重启应用生效。

---

## 卸载与数据清理

本应用**无需安装、无注册表写入、无系统服务**，卸载方式为：

1. 通过托盘菜单 **退出**（或直接关闭所有窗口后确认进程已退出）；
2. 删除数据目录：`%LOCALAPPDATA%\DeepseekHarnessDesktop`；
3. 删除程序文件（`TangDSHDesktop.exe` 及其所在文件夹）。

删除数据目录后，应用回到**首次启动状态**：API 密钥、设置、运行环境缓存、日志全部清除。

> ⚠️ **重要**：API 密钥使用 DPAPI 加密，**绑定当前 Windows 用户与机器**。更换电脑、更换 Windows 用户、或重装系统后，`apikey.dat` 无法解密，需要重新输入密钥。

---

## 升级与更新

应用采用"绿色软件"方式升级，无需卸载：

1. 通过托盘菜单 **退出** 应用；
2. **备份数据（可选）**：复制 `%LOCALAPPDATA%\DeepseekHarnessDesktop` 目录（含密钥与设置）；
3. **替换程序**：用新版本 `TangDSHDesktop.exe` 覆盖旧文件；
4. **运行环境处理**：
   - 若新版本未变更底层运行时（Node.js / dsh），保留 `runtime` 目录即可，启动更快；
   - 若升级后遇到异常，可删除 `%LOCALAPPDATA%\DeepseekHarnessDesktop\runtime`，让应用重新部署；
5. 重新启动应用。设置与密钥保存在 `%LOCALAPPDATA%`，**不会因替换 exe 而丢失**。

---

## 已知限制

以下为本应用当前版本的已知边界，请在使用前知悉：

| 限制 | 说明 |
|------|------|
| 仅支持 Windows x64 | 不支持 32 位系统、macOS 与 Linux |
| 密钥绑定本机 | API 密钥加密后仅当前机器/当前用户可解密，不能拷贝 `apikey.dat` 到其他电脑使用 |
| 首次运行需联网 | 未随包附带 `runtime` 时，需联网下载 Node.js（约 40 MB）并安装 DeepSeek Harness |
| @ 引用大小上限 | 单个被引用文件仅附加前 80 KB 内容 |
| 预览大小上限 | 单个文件预览仅显示前 1 MB |
| Node.js 版本固定 | 当前内置 Node.js 版本固定为 24.19.0 |
| 注入式增强 | 工作区面板与 @ 引用通过向页面注入脚本实现，若 DeepSeek Harness 网页结构发生重大改版，相关功能可能失效，需随版本更新适配 |
| 网络依赖 | 无随包 runtime 时，环境部署依赖 Node.js 官方源与 npm 仓库（已配置国内镜像双源容错） |

---

## 常见问题（FAQ）

**Q1：启动时提示"需要安装 WebView2"？**
应用会自动尝试安装。若自动安装失败，请手动下载安装 [WebView2 运行时](https://developer.microsoft.com/microsoft-edge/webview2/) 后重启应用。

**Q2：首次启动需要等待很久？**
首次运行需要下载 Node.js（约 40 MB）并安装 DeepSeek Harness，视网络而定。若使用**离线版**或随包附带 `runtime` 文件夹，可跳过下载直接使用。

**Q3：提示"服务启动超时"？**
首次运行初始化较慢，请点击"重试"稍候。若反复失败，请检查日志（见[故障排查](#故障排查)）。

**Q4：更换了 API 密钥后需要重启吗？**
通过托盘菜单"更换 API 密钥"保存后，应用会自动重启服务并应用新密钥。

**Q5：关闭窗口后程序还在运行？**
这是"最小化到托盘"行为，属正常设计。请通过托盘菜单"退出"彻底关闭。

**Q6：杀毒软件提示风险？**
自包含单文件应用在首次运行时可能被安全软件误报。请将程序加入信任列表，并确保程序来自可信来源。

**Q7：如何修改服务端口？**
修改 `settings.json` 中的 `PreferredPort`（设为 `0` 表示自动选择），保存后重启应用。详见[配置说明](#配置说明)。

**Q8：换了一台电脑，密钥失效了？**
正常现象。API 密钥经 DPAPI 加密绑定原机器与用户，新机器需重新输入密钥。

**Q9：如何彻底卸载应用？**
见[卸载与数据清理](#卸载与数据清理)：退出后删除 `%LOCALAPPDATA%\DeepseekHarnessDesktop` 与程序文件即可。

**Q10：引用大文件时内容不完整？**
单个被引用文件仅附加前 80 KB，预览仅显示前 1 MB，属设计限制。

---

## 故障排查

应用日志记录了完整的运行过程，排查问题时请提供对应日志文件：

```
%LOCALAPPDATA%\DeepseekHarnessDesktop\logs\app-YYYYMMDD.log
```

常见排查步骤：

1. 确认系统满足[系统要求](#系统要求)；
2. 查看日志中是否包含 `Failed` / `Error` 关键字；
3. 确认网络可达（首次部署需要）；
4. 删除 `%LOCALAPPDATA%\DeepseekHarnessDesktop\runtime` 目录后重启，可触发全新部署；
5. 若界面异常，删除 `%LOCALAPPDATA%\DeepseekHarnessDesktop\dsh-home` 后重启（会重置会话配置）。

---

## 发布与分发指南

> 本章面向**将应用打包分发给终端用户**的分发者。

### 推荐发布包结构

```
TangDSH-Desktop-v1.1.1/
├── TangDSHDesktop.exe          # 主程序（单文件，含 .NET 运行时）
├── runtime/                    # [强烈建议] 已就绪的运行环境（离线可用、秒级启动）
│   ├── node/node.exe
│   └── node_modules/@deepseek-ai/dsh/...
└── 使用说明.pdf / README.md     # 用户文档
```

- **在线版**：仅 `TangDSHDesktop.exe`（用户首次需联网部署，约 1–6 分钟）；
- **离线版**：exe + `runtime\`（用户打开即用，无需等待下载）。

### 分发前必做清单

1. **删除** `TangDSHDesktop.exe.WebView2` 文件夹（WebView2 运行时产生的本机浏览器数据目录，含缓存与登录状态，**严禁随包分发**）；
2. 删除 `*.pdb` 调试符号与 `Microsoft.Web.WebView2.*.xml` 文档（非必需）；
3. 在干净环境完成一次完整启动验证（见下方测试清单）；
4. 可选：为 exe 配置应用图标与版本信息，降低安全软件误报概率；有条件的可进行代码签名，消除 SmartScreen"未知发布者"提示；
5. 提供简要使用说明（本 README 即可），重点说明：首次运行联网、UAC 授权、杀软放行。

### 分发前测试清单

在发布前，建议至少在以下场景各验证一次：

| 场景 | 预期行为 |
|------|----------|
| 全新 Windows 11（带 WebView2） | 自动部署环境，输入密钥后正常进入主界面 |
| 无 WebView2 的旧系统 | 自动下载安装（弹 UAC），完成后正常启动 |
| 无网络 / 弱网环境（带 runtime） | 直接使用随包 runtime，无需下载 |
| 无网络 / 弱网环境（不带 runtime） | 明确报错并提示检查网络，不崩溃 |
| 32 位系统 | 无法启动（预期，属支持范围外） |
| 系统已装 Node.js 与 dsh | 优先复用系统环境，不重复下载 |
| 杀软 / Defender 拦截 | 用户加入信任列表后可正常运行 |
| 端口被占用 | 自动切换空闲端口，功能不受影响 |

---

## 开发者指南：构建与打包

### 技术栈

| 项 | 说明 |
|----|------|
| 框架 | .NET 8（WPF，`net8.0-windows`） |
| 内嵌浏览器 | WebView2 |
| 日志 | Serilog（文件 + 控制台） |
| JSON | Newtonsoft.Json |
| 密钥 | System.Security.Cryptography.ProtectedData (DPAPI) |

### 开发环境

- Windows 10/11（x64）
- .NET 8 SDK（建议 Visual Studio 2022 或更高）

### 构建

```bash
dotnet publish DeepseekHarnessDesktop/DeepseekHarnessDesktop.csproj \
  -c Release \
  -r win-x64 \
  --self-contained true \
  -p:PublishSingleFile=true \
  -p:IncludeNativeLibrariesForSelfExtract=true \
  -o publish
```

产物为单文件 `publish\TangDSHDesktop.exe`。

### 生成随包 runtime（可选）

在开发机完成一次完整启动（使 `%LOCALAPPDATA%\DeepseekHarnessDesktop\runtime` 就绪）后：

```powershell
Copy-Item "$env:LOCALAPPDATA\DeepseekHarnessDesktop\runtime" "publish\runtime" -Recurse
```

### 项目结构

```
DeepseekHarnessDesktop/
├── App.xaml / App.xaml.cs        # 应用入口：日志初始化、生命周期
├── Config/
│   ├── AppLogger.cs              # Serilog 日志系统
│   ├── AppSettings.cs            # 用户设置持久化（JSON）
│   └── ApiKeyStore.cs            # API 密钥 DPAPI 加密存储
├── Core/
│   ├── RuntimeBootstrapper.cs    # Node.js 与 DSH 环境部署（查找/下载/安装）
│   ├── RuntimeEnvironment.cs     # 运行环境信息模型
│   ├── DshProcessManager.cs      # DSH 子进程生命周期与密钥环境变量管理
│   ├── HealthChecker.cs          # 本地服务健康轮询
│   ├── NodeDetector.cs           # Node.js / DSH 版本检测
│   ├── ExecutableLocator.cs      # 多策略可执行文件定位
│   ├── PortFinder.cs             # 空闲端口查找
│   └── WebView2Installer.cs      # WebView2 检测与自动安装
└── UI/
    ├── MainWindow.xaml(.cs)      # 主窗口与启动流程编排
    ├── TrayIconManager.cs        # 系统托盘
    └── WorkspacePanelInjector.cs # 工作区面板与 @ 引用注入
```

---

## 版本信息

| 项 | 值 |
|----|----|
| 产品名称 | TangDSH Desktop |
| 当前版本 | 1.1.2 |
| 平台 | Windows x64 |
| 运行时 | .NET 8（自包含） |

---

## 更新日志

### v1.1.2（当前）

- **修复：会话实时输出状态稳定** —— 综合 DSH 输入栏「停止生成」按钮、对话流流式输出与运行中节点信号判定，加 4 秒防抖；工具调用间隙不再出现「已结束」与「输出中」来回闪跳，会话未结束前始终显示「输出中」；
- **优化：行级差异更精确** —— 变更前快照缺失时自动用 git HEAD 基线补齐，文件修改可精确标出绿/红/橙，不再整篇标绿/红；
- **优化：待审核通知时机** —— 每轮会话结束（发送下一条消息）时才提示「有文件待审核」，不再 AI 一改文件就弹通知打扰；
- **优化：识图功能统一入口** —— 禁用主模型不支持的 `read_image` 工具，图片理解统一走千问视觉（qwen_vision），避免「图片识别失败」反复出现。

### v1.1.1

- **新增：图片识别（识图）功能** —— 设置 → 通用设置 → 识图功能，接入阿里云千问（Qwen）视觉模型（默认 `qwen-vl-max`），开启后聊天中发布的图片可直接被理解；API Key 存为 secret 字段、热更新、界面永不回显明文；
- **优化：工作目录面板启动即显示** —— 移除固定 2 秒 + 2.5 秒的延迟等待，启动后约 1 秒内出现"工作目录"页签，并自动从 DSH 工作区记录加载当前会话目录，不再出现"未选择工作区"空窗；
- **优化：变更记录按会话合并** —— 一次会话（连续改动，默认 15 分钟空闲阈值）内所有文件的增删改归并为**一个版本**，同一文件多次修改只保留一份"改动前"快照；版本列表显示"N 个文件"标签，回退恢复到会话开始前状态；回退/撤销后自动开启新版本；
- **优化：NuGet 国内镜像 + 关闭漏洞审计** —— 新增 `NuGet.config`（腾讯云 / Azure 中国镜像优先），并关闭 NU1900 漏洞审计，`dotnet` 构建不再因 `api.nuget.org` 超时而报警告；
- **优化：修复识图设置热更新不生效的问题** —— 工具改为每次执行实时读取最新设置（修复 JS 闭包按值捕获导致的旧配置问题）。

### v1.0.0

- 首个正式版本：环境自动部署、API 密钥安全存储、工作区文件面板、@ 文件引用、系统托盘、WebView2 自动安装。

---

## 许可证与反馈

- **许可证**：本项目当前未指定开源许可证，保留所有权利。分发与二次开发请联系作者获取授权。
- **反馈渠道**：如遇问题，请提供日志文件（`%LOCALAPPDATA%\DeepseekHarnessDesktop\logs\app-YYYYMMDD.log`）与问题描述。

---

---

## ⭐ 支持项目

如果 TangDSH Desktop 对你有帮助，欢迎 **点击右上角 ⭐ Star** 支持一下，或分享给需要的朋友。你的支持是持续更新的最大动力！

---

*本文档由 TangDSH Desktop 项目整理，具体行为以实际软件为准。*
