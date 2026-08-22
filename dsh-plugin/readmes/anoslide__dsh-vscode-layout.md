# DSH IDE —— DeepSeek Harness 魔改方案

把 DeepSeek Harness（dsh）Web 界面改造成 **VS Code 式 IDE** 的完整方案：
三栏布局、文件树、多标签查看器/编辑器、桌面启动器，全部改动可重放、可移植。

## 功能特性

- **三栏 IDE 布局**：左「文件/会话」双 Tab + 中多标签文件查看器 + 右「对话/详情」Tab，可拖宽，窄屏自动收成 rail
- **文件树**：懒加载、隐藏目录折叠、Git 状态角标（M/U/A/D/R）、行内重命名、**回收站删除**、新建文件/文件夹、递归搜索、系统原生选目录
- **多标签**：服务端 shiki 语法高亮（**跟随浅色/深色主题自动切换色板**）、行号、只读查看 + 编辑模式（Ctrl+S 保存、脏标记）、拖拽排序、右键菜单、状态持久化
- **双模式**：全屏对话 / 分栏视图一键切换
- **对话增强**：工具详情与思考内容限高内滚、斜杠命令汉化、**非多模态模型的图片发送桥接**（自动转本地路径 → 视觉 MCP 识图）
- **设置面板管理**：全局人设（所有会话生效）、Skill 开关/删除、MCP 开关/删除/添加（动态挂载，即时生效）
- **全局人设**：类似 Claude Code 的全局 CLAUDE.md，~/.dsh/global-persona.md 注入所有会话系统提示，改后即时生效（右栏「⚙ 人设」编辑）
- **桌面启动器**（Windows）：Edge app 模式独立窗口、自动拉起/隐藏服务、一键停止、自定义应用图标

## 目录结构

```
├── install.ps1              # Windows 一键安装脚本（自动装插件/打补丁/写配置）
├── cordis.patch.yml         # dsh profile 补丁配置模板（密钥已脱敏，见「配置」）
├── patches/node_modules/    # 官方包补丁副本（按相对路径镜像，升级后重放）
├── plugins/                 # 自研插件源码
│   ├── dsh-host-files/          # 宿主接口 /vscode-files/*（文件系统 + shiki 高亮）
│   └── dsh-client-vscode-layout/  # 客户端三栏 IDE 布局
├── launcher/                # Windows 桌面启动器（vbs + ps1 + 应用图标）
└── tools/                   # github-mcp-server 官方二进制（MCP 用）
```

## 快速开始（部署到自己的 dsh）

前置：`npm i -g @deepseek-ai/dsh`。本方案在 **Windows** 上开发验证；其他平台需微调路径。

### 一键安装（Windows，推荐）

下载 ZIP 解压后，右键 `install.ps1` → **使用 PowerShell 运行**
（或 `powershell -ExecutionPolicy Bypass -File install.ps1`）。
脚本自动完成：装插件 → 打补丁 → 写配置。

### 手动安装

1. **安装插件**：把 `plugins/` 下两个包复制到 `~/.dsh/profiles/node_modules/@anoslide/`
2. **打补丁**：把 `patches/node_modules/@deepseek-ai/` 覆盖到全局 dsh 安装的对应路径
   （Windows 全局安装：`%APPDATA%\npm\node_modules\@deepseek-ai\dsh\node_modules\@deepseek-ai\`）
3. **配置**：复制 `cordis.patch.yml` 到 `~/.dsh/profiles/web/`，按下方「配置」填入自己的密钥与路径
4. **启动**：`dsh web` 后用浏览器打开；或直接用 `launcher/` 桌面启动器

> Windows 提示：`~/.dsh/profiles/node_modules/@deepseek-ai/*` 是指向全局安装的 junction——
> 改官方包文件直接改全局路径即可，两处同时生效。
> 若已有 `cordis.patch.yml`，手动合并 `vscode-host-files` 段即可；MCP 通过设置面板「MCP 管理」添加。

## 配置与数据位置

| 内容 | 位置 | 说明 |
|---|---|---|
| profile 补丁配置 | ~/.dsh/profiles/web/cordis.patch.yml | 复制仓库模板，只挂载自研插件，无密钥 |
| MCP server | ~/.dsh/mcp-servers.json | 设置面板「MCP 管理」添加/开关/删除（含密钥，勿提交仓库） |
| 全局人设 | ~/.dsh/global-persona.md | 设置面板「全局人设」编辑 |
| 全局 Skill | ~/.dsh/skills | 设置面板「Skill 管理」开关/删除 |

> 仓库内所有配置文件均为脱敏模板/示例，真实密钥只存在于本机 ~/.dsh。
## 魔改清单

### 1. 斜杠命令汉化（6 个官方包）
`/compact` `/goal` `/feedback` `/plan` `/permission` `/export` 描述中文化，
外加计划模式退出弹窗选项与权限预设说明。

### 2. 图片发送桥接（非多模态模型）
**取消非多模态模型的图片发送限制**：放行入站拦截 → 附件落盘（`~/.dsh/attachments/`）→
序列化为含本地路径的文本 → agent 调用视觉 MCP 识图。
涉及：`dsh-host-apiproxy`、`dsh-llm-deepseek`、`dsh-llm-pi-ai`、`dsh-tool-fs`。

### 3. VS Code 式布局（自研插件）
左「文件/会话」双 Tab + 中多标签查看器（高亮/行号/编辑/持久化）+ 右「对话/详情」Tab，
替换官方 layout 插件（`dsh-web-app/cordis.patch.yml` 指向自研包，位置不变保注册顺序）。

### 4. 对话体验补丁
- 工具详情 / 思考内容限高 480px 内部滚动（`dsh-client-ui-tool`、`dsh-client-ui-conversation`）
- 原生文件夹对话框强制置顶（`dsh-host-directory-picker-native`）

### 5. 桌面启动器 + 应用图标
Edge `--app` 独立窗口（自动探测端口、未运行则隐藏拉起 `dsh web`、首次自动建桌面快捷方式），
应用图标部署进 web 前端 dist（`dsh-web-frontend` 的 favicon + manifest）。

### 6. 浅色主题高亮
服务端 shiki 固定深色色板会导致浅色主题下代码/文档文字过淡。
`/vscode-files/highlight` 支持 `?theme=dark|light` 出对应色板，客户端监听主题切换自动重取。

## 维护：升级重放

`npm update -g @deepseek-ai/dsh` 会覆盖全部官方包补丁，重放方法：

1. 把 `patches/node_modules/@deepseek-ai/` 覆盖回全局安装对应路径
2. **不要动** 本地 `~/.dsh/profiles/web/cordis.patch.yml`（含你的真实密钥；仓库模板已脱敏）
3. 重启 dsh

补丁内容详见上文「魔改清单」，升级重放方法见下。

## 说明

- **密钥约定**：仓库内配置为脱敏模板，真实密钥只存在于本机 `~/.dsh`；请勿把密钥提交到任何仓库
- 本方案在 Windows 上开发验证；macOS/Linux 需调整路径与 junction 相关说明
- 基于 DeepSeek Harness 二次开发，仅供学习交流
