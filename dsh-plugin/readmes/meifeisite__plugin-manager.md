# plugin-manager（DeepSeek Harness 插件管理器）

在 DeepSeek Harness（Web 版）的 **设置 → 插件** 中提供集中管控界面：

- **启用 / 停用**：实时生效、无需重启，写入用户补丁层后跨重启持久
- **卸载删除**：自动依赖检查（npm 依赖图 + web 启动图 inject 边）→ 二次确认 → 停用组合行并清除关联配置
- **查看详情**：版本、作者、许可、来源、包目录、声明依赖、被依赖关系、依赖注入、组合配置
- **操作日志**：JSONL 日志文件 + 界面内日志面板
- 内置保护：核心组件（含插件管理器自身）禁止启停/卸载；Agent Preset 挂载的条目只读

永久安装：刷新页面、重启 DSH 都不会丢失。

---

## 仓库结构

```
plugin-manager/
├── package.json        # 包清单（dsh.client 声明：浏览器端 bundle）
├── lib/
│   ├── index.js        # Host 半部（Node 端：loader/补丁/日志/RPC 路由）
│   └── client.js       # Client 半部（浏览器 bundle，__ModuleLoader__.load 格式）
├── install.ps1         # Windows / PowerShell 安装脚本
├── install.sh          # macOS / Linux 安装脚本
└── README.md
```

安装机制：包被复制到**两个解析锚点**（浏览器侧 `~/.dsh/profiles/web/node_modules/` 与
Host 侧 dsh 安装目录的 `node_modules/`），并在 `~/.dsh/profiles/web/cordis.patch.yml`
追加一条 **`insert:` 组合行**。补丁层被运行时热监听，改动即时生效。

---

## 安装（一条命令）

> 前提：DSH Web 版已通过 npm/pnpm 全局安装（`@deepseek-ai/dsh`）。
> dsh 正在运行：安装后**立即热重载生效**，刷新浏览器页面即可；
> dsh 未运行：配置已写好，下次启动自动挂载。

**Windows（PowerShell）**：

```powershell
irm https://raw.githubusercontent.com/meifeisite/plugin-manager/main/install.ps1 | iex
```

**macOS / Linux**：

```bash
curl -fsSL https://raw.githubusercontent.com/meifeisite/plugin-manager/main/install.sh | bash
```

> 把 `meifeisite` 换成你自己的 GitHub 用户名。远程管道执行前请先审阅脚本内容；
> 也可以 clone 后本地执行（`git clone ... && ./install.ps1` / `./install.sh`），效果相同且更安全。

安装后：刷新页面 → 左下角设置（齿轮）→ **插件** → **「插件管理」** 标签页。

## 更新

重跑同一条安装命令即可（覆盖包文件，组合行幂等跳过）。

## 卸载

```powershell
# 方式一：clone 后本地执行
git clone https://github.com/meifeisite/plugin-manager
cd plugin-manager
./install.ps1 -Uninstall          # Windows
./install.sh --uninstall          # macOS / Linux
```

```powershell
# 方式二：远程执行（通过环境变量传递卸载开关）
$env:PM_UNINSTALL = '1'
irm https://raw.githubusercontent.com/meifeisite/plugin-manager/main/install.ps1 | iex
```

```bash
# macOS / Linux 远程卸载
PM_UNINSTALL=1 curl -fsSL https://raw.githubusercontent.com/meifeisite/plugin-manager/main/install.sh | bash
```

## 可选参数与环境变量

| 变量 / 参数 | 作用 | 默认值 |
| --- | --- | --- |
| `PM_REPO`（或 `-Repo`） | 管道模式下载文件的 raw base URL | 默认 `https://raw.githubusercontent.com/meifeisite/plugin-manager/main` |
| `PM_SOURCE`（或 `-Source`） | 本地包目录，或 `npm:<包名>` 从 npm registry 拉取 | 无（自动用本地/远程仓库） |
| `PM_UNINSTALL`（或 `-Uninstall` / `--uninstall`） | 卸载 | 无 |
| `DSH_HOME` | dsh 配置目录 | `$HOME/.dsh` |
| `DSH_INSTALL_DIR` | dsh 包目录（探测不到时手动指定） | 自动探测（npm/pnpm 全局 root） |

示例：从 npm registry 安装

```powershell
./install.ps1 -Source npm:plugin-manager
```

```bash
PM_SOURCE=npm:plugin-manager ./install.sh
```

---

## 发布到 GitHub 的步骤

1. 初始化仓库并推送：

   ```bash
   git init
   git add .
   git commit -m "plugin-manager: settings plugin manager for DeepSeek Harness"
   git branch -M main
   git remote add origin git@github.com:meifeisite/plugin-manager.git
   git push -u origin main
   ```

2. 脚本默认 raw URL 已指向 `meifeisite/plugin-manager`；若你 fork 到了自己的仓库，把 `install.ps1` / `install.sh` 里的默认 URL 改为你自己的地址（或用 `-Repo` / `PM_REPO` 覆盖）。
3. README 里的安装命令同步为你的仓库地址。

## 常见问题

- **提示找不到 dsh 安装目录**：DSH 不是通过 npm/pnpm 全局安装的（如 Homebrew、源码运行）。
  把 dsh 包的目录（含 `node_modules` 的包根）设为 `DSH_INSTALL_DIR` 后重跑。
- **安装后标签页不出现**：先刷新页面；若仍无，检查 dsh 进程日志中补丁热重载是否报错，
  或重启 dsh 一次。
- **想修改功能**：改 `lib/` 后重跑安装命令即可（注意：改代码后若 dsh 在运行，需要重启 dsh
  才会重新加载模块——组合行/配置的修改是热生效的）。
- **日志位置**：首次操作后生成，路径见「插件管理」标签页底部脚注
  （默认 `$HOME/.dsh-plugin-manager.log.jsonl`，由工作区根配置决定）。

## License

MIT
