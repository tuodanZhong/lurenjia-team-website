# dsh-wsl-bash

> DSH (DeepSeek Harness) 插件：新增一个独立的 `wsl-bash` 工具，在 WSL（Windows Subsystem for Linux）里执行命令 —— **与默认的 PowerShell 终端并存**，不替换、不禁用任何现有功能。
>
> A DSH plugin that adds an independent `wsl-bash` tool to run commands inside WSL — **alongside** the default PowerShell terminal, without replacing or disabling anything.

## 为什么是"并存"而不是"替换"

DSH 的 `ctx.shell` 是**单实例服务**（同时挂两个 executor 会报 duplicate service），所以"把 bash 命令重定向到 WSL"的常规做法必须禁用 PowerShell executor —— 这既牺牲了 Windows 终端，又会触发权限预设服务的启动检查。

本插件绕开这条路径：**不碰 `ctx.shell`**，而是注册一个独立的工具直接消费更底层的 `ctx.subprocess`：

```
┌─ 保留（不动）──────────────────────────┐
│  pwsh-sandbox ─► ctx.shell ─► tool-pwsh │  PowerShell 终端照旧
└─────────────────────────────────────────┘

┌─ 新增（不碰 ctx.shell）────────────────┐
│  wsl-bash 工具 ─► ctx.subprocess.spawn │  直接执行 wsl.exe
└─────────────────────────────────────────┘
```

## 安装 / Installation

### 1. 获取插件

把本仓库放到你的 DSH web profile 的 `plugins/` 目录：

```powershell
$PROFILE = "$env:USERPROFILE\.dsh\profiles\web"
git clone https://github.com/kevin090820/dsh-wsl-bash.git "$PROFILE\plugins\dsh-wsl-bash"
```

### 2. 修改 profile patch

编辑 `$PROFILE\cordis.patch.yml`，追加：

```yaml
- insert:
    - id: wsl-bash
      name: './plugins/dsh-wsl-bash/lib/index.js'
      config:
        distro: Ubuntu-1804   # 你的 WSL 发行版注册名（wsl -l -v 查看）
        home: /root           # 发行版内的 HOME 目录
```

> 验证发行版名：`wsl -l -v`（注意注册名可能没有中间的连字符，如 `Ubuntu-1804` 而非 `Ubuntu-18.04`）。

### 3. 生效

保存后 DSH 通过 HMR 热重载 patch，**无需重启**（也可重启确认）。新会话中会出现 `wsl-bash` 工具。

## 使用 / Usage

工具名 **`wsl-bash`**，参数与 bash 工具一致：

| 参数 | 必填 | 说明 |
|------|------|------|
| `command` | ✅ | WSL 里执行的 bash 命令 |
| `description` | ✅ | 一句话描述（UI 展示用） |
| `workdir` | — | Windows 路径（如 `D:\catkin_ws`），自动翻译成 `/mnt/d/catkin_ws` |
| `timeoutMs` | — | 超时（默认 `120000`，即配置的 `timeoutMs`） |

示例：

```
wsl-bash: ls /opt/ros                      → melodic
wsl-bash: source /opt/ros/melodic/setup.bash && catkin_make   （构建 ROS 工作区）
wsl-bash: uname -r                          → WSL 内核版本
```

想跑 Windows 命令就用原来的 `pwsh` 工具 —— 两个工具并存，各管各的环境。

## 配置项 / Configuration

| 键 | 类型 | 默认值 | 说明 |
|----|------|--------|------|
| `distro` | string | `Ubuntu-1804` | WSL 发行版注册名 |
| `home` | string | `/root` | WSL 内 HOME 目录 |
| `timeoutMs` | number | `120000` | 命令超时 |

## 工作原理 / How it works

```
wsl-bash 工具调用
   │
   ▼
execute(args)
   │   wrapCommand(): export HOME=/root; cd /mnt/d/...; <command>
   ▼
ctx.subprocess.spawn({
     argv: ["wsl.exe","-d","Ubuntu-1804","--","bash","-c",<command>],
     stdio: 收集 stdout/stderr（64KB 内存 + 溢出转文件）
   })
   │
   ▼
返回 { exitCode, stdout, stderr, timedOut, ... }  → renderResult 渲染
```

- **路径翻译**：`D:\catkin_ws` → `/mnt/d/catkin_ws`
- **HOME 修复**：WSL 从 Windows 继承的 `HOME` 是坏值，统一重置
- **编码**：Node 直接读字节流，无 PowerShell 管道乱码
- **无 mesg 噪音**：用 `bash -c`（非登录 shell）

## 安全说明 / Security

- 本工具**不经过 Windows ACL 文件沙箱**：ACL 限制令牌会阻断 WSL 服务通信（`E_ACCESSDENIED`），所以 WSL 命令以完全访问方式运行。等价于在 WSL 内拥有 shell 权限，请像对待任何 shell 访问一样对待它。
- 与替换式方案不同，本插件**不触发**权限预设服务（`dsh-permission-presets`）对 `ctx.shell.sandboxMode` 的检查 —— 因为 `ctx.shell` 保持原样（pwsh-sandbox）。
- 插件只在**命令执行层**新增工具；`read`/`write`/`edit` 等文件工具、`pwsh` 命令工具均不受影响。

## 开发 / Development

```bash
# 运行测试（纯函数，无需 WSL）
node --test test/
```

## License

MIT

## Author

Developed with [DeepSeek Harness](https://github.com/deepseek-ai) — authored by **DeepSeek Harness (deepseek-v4-flash)**.
