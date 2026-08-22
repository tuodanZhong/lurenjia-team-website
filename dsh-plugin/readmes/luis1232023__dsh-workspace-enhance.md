# dsh-workspace-enhance（dsh工作区加强）

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/luis1232023/dsh-workspace-enhance/blob/main/LICENSE)
[![Node](https://img.shields.io/badge/node-%3E%3D18-green.svg)](https://nodejs.org)
[![CI](https://github.com/luis1232023/dsh-workspace-enhance/actions/workflows/ci.yml/badge.svg)](https://github.com/luis1232023/dsh-workspace-enhance/actions/workflows/ci.yml)

DSH（DeepSeek Harness）Web 界面的侧栏工作区增强插件：以默认工作区浏览器为基础，把左侧栏改造成**工作区文件夹列表**——每个文件夹展开后有 **任务 / 文件 / Git** 三个子 Tab，另加右侧文件预览面板。

## 源码位置与结构

插件根目录：`D:\luisdesk\other\dsh-workspace-enhance`

```
dsh-workspace-enhance/
├── package.json            # 插件清单：dsh.client 清单 + dsh.bundle.patch（安装入口）
├── cordis.patch.yml        # bundle patch：向 profile 注入一行插件配置
├── build.mjs               # 构建脚本（esbuild 原生二进制，产出 web2 ModuleLoader 格式 bundle）
├── tsconfig.json           # 类型检查配置（paths 指向 profile 内的 @deepseek-ai 类型）
├── CONTRIBUTING.md         # 贡献规范（贡献前检查清单 / 提交流程，请先阅读）
├── LICENSE / CODE_OF_CONDUCT.md / SECURITY.md / CHANGELOG.md
├── .github/                # PR / Issue 模板与 CI（.github/workflows/ci.yml）
├── lib/
│   ├── index.js            # node 半边（宿主进程运行）：RPC 通道 + fs/git/会话删除
│   └── client.js           # client 半边（浏览器运行）：由 src/ 构建，勿手改
├── src/                    # client 半边源码（TypeScript/TSX）
│   ├── client.tsx          # 入口：注册 sidebar.workspaces(priority -1) + shell.overlay
│   ├── store.ts            # 共享 store（预览、删除墓碑、每文件夹子 Tab、视图模式）
│   ├── rpc.ts / contract.ts# RPC 调用封装与类型契约
│   ├── rows.tsx            # 对齐内置样式的文件夹行/会话行
│   ├── highlight.ts        # Prism.js 语法高亮（显式语言 + line-numbers 行号，内联打包）
│   ├── styles.ts           # 全部样式（对齐默认工作区的 --dsw-* 变量）
│   ├── tabs/               # WorkspaceRegion / WorkspaceFolderTabs / Sessions / File / Git
│   └── preview/            # 右侧文件预览面板（shell.overlay 槽位）
└── scripts/                # 测试与校验（node 半边集成测试、渲染测试、真实 store 测试）
```

架构：**node 半边**在宿主进程注册通用 RPC 通道 `/dsh-workspace-enhance`
（`ctx.connection.rpc.handle`，loopback 信任），endpoints：`fs/root`、`fs/list`、
`fs/read`、`git/log`（含 `--graph`、支持按分支过滤）、`git/show`、`git/status`、
`git/branches`、`session/delete`、`debug/report`。**client 半边**注册两个槽位：
`sidebar.workspaces`（`priority: -1`
遮蔽内置浏览器）渲染文件夹/子 Tab 区域；`shell.overlay`（additive 列表槽）渲染
右侧文件预览面板。

## 功能

插件将默认工作区浏览器替换为增强侧栏：左侧为**工作区文件夹列表**，每个文件夹展开后含
**任务 / 文件 / Git** 三个子 Tab；点击文件在右侧打开**预览面板**。

### 任务（会话）

- 每个文件夹下列出该工作区的任务（会话），始终按最近更新排序；无归属的会话自动归入「未分组」。
- 会话行操作：打开 / 重命名 / 归档 / 彻底删除（host 直接删除会话日志目录，二次确认、不可恢复；
  删除当前任务后自动打开下一个）。
- 文件夹行操作：新建任务 / 重命名 / 删除工作区（仅移除注册记录，目录与任务日志保留，任务转为未分组）。
- 顶部 ＋ 按钮为**添加工作区**（原生目录选择器，失败时回退为手动路径输入）。
- 会话状态点：运行中为宿主动画点；待交互黄色；空闲会话当前项蓝色、非当前灰色。

### 文件

- 以文件夹为根的文件树：懒加载、逐目录缓存、展开/折叠；列表上限 2000 条（超出提示截断）。
- 彩色图标：Windows 资源管理器风格黄色文件夹（开/合两态）；文件按扩展名分 9 类图标
  （JS/TS/JSON/Markdown/图片/文本/配置/代码/通用）。
- 工具栏「⋯」菜单：刷新文件夹、显示/隐藏 dot 文件（隐藏文件默认过滤）。
- 点击文件在右侧预览：代码为 Prism 语法高亮（显式语言映射 + 行号，配色跟随 DSH 浅/深主题）；
  Markdown 默认渲染 HTML（GFM：标题/表格/删除线/任务列表/自动链接/脚注/代码块高亮），
  「预览 / 源码」Tab 可切换、每次打开文件重置为预览；源码中的原始 HTML 会被转义（防 XSS）；
  图片以 data URL 居中预览；二进制占位提示；大文件仅取前 512 KB 并提示截断。
- 预览面板 Esc 或 ✕ 关闭；快速连续切换文件时有乱序响应保护。

### Git

- 仅当目录是 git 仓库（`git/status` 探测）才显示 Git 子 Tab。
- **Changes**：工作区改动列表（`分支 → 上游 · ahead/behind · N 处改动`，干净时提示）；状态标签
  A/M/D/R/C/T/U/? 带颜色与工具提示；点击文件在右侧预览。
- **Graph**：ASCII 分支图提交记录，顶部下拉切换分支（默认当前分支）；点击提交查看元信息 / 作者 /
  提交者（仅当与作者不同时显示）/ 变更文件（含重命名）/ 语法高亮 diff（超 256 KB 提示截断）。
- 只读：log / show / status / branches，无任何写操作。

### 侧栏与视图

- 折叠侧栏（rail）模式：💬/📁/⎇ 一键定位工作区并展开对应子 Tab。
- 区头：搜索（展开式输入、250ms 防抖的内容搜索 + 元数据匹配结果合并，Esc 关闭）、添加工作区、
  视图选项（按工作区 / 平铺列表；排序 最近更新 / 手动，手动仅作用于平铺列表）。
- 视图模式与每个文件夹的子 Tab 选择持久化（重载后保留）。
- 崩溃隔离：每个文件夹子 Tab 由错误边界包裹，出错时内联显示错误与重试，不会静默回退到内置浏览器。

## 安装（DSH 插件安装说明）

前置：本机已安装 DSH（`dsh` 命令可用），且已存在 web profile（`C:\Users\yicheng\.dsh\profiles\web`）。

### 1. 添加插件到 profile

在插件目录的**上级目录**（即 `D:\luisdesk\other`）执行：

```powershell
dsh plugin --profile web add file:./dsh-workspace-enhance
```

该命令会：
- 把 `dsh-workspace-enhance` 追加到 profile 的 `dsh.profile.bundles`；
- 因插件声明了 `dsh.bundle.patch`，自动把一行插件配置注入配置树；
- 在 profile 的 node_modules 里安装插件（pnpm `file:` 依赖是**打包拷贝**，只含
  `files` 字段列出的 `lib/` 与 `cordis.patch.yml`，见下方「开发」注意事项）。

### 2. 重启使生效

```powershell
# 先停止当前 web 实例，再：
dsh web
```

重启后左侧栏即为插件界面。验证：

```powershell
# bundle 可访问（含最新 rev）：
Invoke-WebRequest http://127.0.0.1:3080/plugins/dsh-workspace-enhance/client.js
# 合成配置树确认：
dsh --profile web --dump-config
```

### 2.1 效果对比（安装前后）

| 安装前（默认 DSH 侧栏） | 安装后（dsh-workspace-enhance） |
|---|---|
| <img src="plugin.png" width="420" alt="安装前：默认工作区浏览器"> | <img src="install_plugin.png" width="420" alt="安装后：工作区文件夹列表 + 任务/文件/Git 子 Tab + 右侧预览"> |

安装后左侧栏由默认工作区浏览器变为工作区文件夹列表：每个文件夹展开后含
**任务 / 文件 / Git** 三个子 Tab，点击文件在右侧打开预览面板。

### 3. 禁用 / 重新启用

编辑 `C:\Users\yicheng\.dsh\profiles\web\cordis.patch.yml`（顶层必须是 YAML 数组）：

```yaml
# 禁用（恢复默认工作区浏览器）：
- id: dsh-workspace-enhance
  disabled: true
```

删掉这两行（或把 `disabled` 改为 `false`）即重新启用。**每次改动后重启 `dsh web`**。

### 4. 卸载

从 profile 的 `package.json`（`dependencies` 与 `dsh.profile.bundles`）移除
`dsh-workspace-enhance`，删除 `cordis.patch.yml` 中对应行，重跑 `pnpm install` 与
`dsh --profile web --dump-config` 确认，再重启。插件目录本身可整个删除。

## 开发

```powershell
cd D:\luisdesk\other\dsh-workspace-enhance

# 首次：安装构建期依赖（esbuild + prismjs；会被打进 client bundle，无需进 profile）
npm install --ignore-scripts --legacy-peer-deps

# 构建 / 监听（client 半边改动）
npm run build          # 或 npm run watch（HMR 免刷新热加载浏览器半边）

# 类型检查（tsc strict；依赖本机 profile 内的 @deepseek-ai 类型）
npm run typecheck

# 测试
npm test               # 聚合：node 半边集成测试 + client 干跑 + 真实 store 测试（需 profile）
node scripts/test-node.mjs        # node 半边集成测试（需本机 git）
node scripts/dry-run-client.mjs   # client bundle 干跑（ModuleLoader 格式校验）
node scripts/test-real-store.mjs  # 真实 store 引擎 + persist 测试（需本机 profile）
# 渲染测试：esbuild 打包 scripts/render-tabs-test.tsx 后运行（见该文件头部注释）
```

**注意（重要）**：web profile 用 pnpm 安装的 `file:` 依赖是**打包拷贝**，不是
符号链接——`npm run build` 会把 `lib/*` 同步进
`C:\Users\yicheng\.dsh\profiles\web\node_modules\dsh-workspace-enhance\lib`（在受限
沙箱/权限环境下无法写入时需手动复制，或在普通终端执行构建）。**client 半边**改动靠
HMR 热加载（无需重启）；**node 半边（lib/index.js）改动必须重启 `dsh web`**。

> `npm run typecheck` 与 `npm test`（其中的真实 store 测试）依赖本机 DSH profile
> 的绝对路径（`tsconfig.json` 的 paths、`scripts/test-real-store.mjs` 的
> `createRequire`），CI 中只跑不依赖 profile 的部分（见 `.github/workflows/ci.yml`）。

## 贡献

欢迎贡献！请先阅读 **[CONTRIBUTING.md](./CONTRIBUTING.md)**（贡献前检查清单、
什么算好的贡献、质量与数据完整性、提交流程），并遵守
**[CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md)**。

- Bug / 功能 / 文档问题：按 [Issue 模板](https://github.com/luis1232023/dsh-workspace-enhance/issues/new/choose) 提交
- 代码改动：按 [PR 模板](https://github.com/luis1232023/dsh-workspace-enhance/pulls) 发起，勾选检查清单
- 安全漏洞：见 [SECURITY.md](./SECURITY.md)（请勿公开披露）

## 保持关注

- Watch 本仓库，关注 Releases 与 [CHANGELOG.md](./CHANGELOG.md)。
- 功能讨论与使用问题：GitHub Issues / Discussions。
- 已知边界以本文档「已知限制」为准。

## 常见问题（FAQ）

**Q：为什么 Git Tab 不显示？**
A：仅当当前工作区文件夹是 git 仓库（`git/status` 探测）时才显示。

**Q：改动 client 半边后界面没变化？**
A：client 半边走 HMR 免刷新热加载；若没生效，确认 `npm run watch` 在运行，或手动
`npm run build` 后刷新页面。node 半边改动则必须重启 `dsh web`。

**Q：「彻底删除」能恢复吗？**
A：不能。它由 host 直接删除任务（会话）目录，不可恢复，界面有二次确认。

**Q：远程/容器部署时「添加工作区」不可用？**
A：原生目录选择器在远程/进程内部署可能不可用，此时会回退到手动输入路径。

**Q：CI 为什么没跑 typecheck？**
A：`tsc` 的 paths 与真实 store 测试都指向本机 profile 的绝对路径，CI 沙箱没有
profile；它们是本地质量门禁（见 CONTRIBUTING.md 检查清单）。

## 已知限制

- 任务「彻底删除」由 host 直接删除 `$DSH_HOME/sessions/<scope>/<sessionId>/`
  目录，不可恢复；工作区记账可能残留该 id，由本插件渲染层过滤。
- Git 为只读（log/show/status），无写操作；Changes 视图点击文件是在右侧预览，
  不是编辑。
- 原生目录选择器在远程/进程内部署可能不可用，此时添加工作区会回退到手动输入路径。

## 许可

[MIT](./LICENSE) © 2025 luis
