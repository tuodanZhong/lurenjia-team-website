# dsh-minimal-msys2

> [English](README.en.md) | 中文

Windows 极简模式 dsh 插件：在 Windows 上提供与官方极简模式工具定义完全一致的持久 `bash` 工具（`command` 参数、持久 shell 语义），外加 `str_replace_editor`。同时为 `str_replace_editor` 提供了专属的工具调用行（命令摘要、运行/失败状态、展开可见 old→new 变更预览），极简模式下不再只有通用占位卡片。

内置两个 preset：

- **Windows Minimal Mode**（`minimal-msys2`）：纯极简，`bash` + `str_replace_editor`，工具定义与官方极简模式逐字节一致。
- **Minimal Extended Mode**（`minimal-extended`，极简扩展模式）：第一轮为极简模式（持久 bash + str_replace_editor + 极简 persona）；第 2 条真实用户消息到达时自动注入标准模式的工具与 skill（pwsh、read/write/edit、glob/grep、skill、goal、jobs、web_search、ask_user_question、todo、subagent/subagent_fork/send_message/interrupt_agent/list_agents、workflow、ralph），注入完成后（第 3 轮起）模型即可见；persona 保持极简不变（不注入标准 persona / agent-instructions / plan-mode）。

## 背景

官方 `minimal`（极简模式）preset 的持久 bash 在 Windows 上无法工作，有两层独立的平台限制：

1. `dsh-subprocess-local` 的终端分配依赖 POSIX 进程检查（Linux /proc、macOS ps），win32 直接抛 `terminal inspection is unsupported on platform win32`；
2. 即使绕过第一层，默认 `workspace-write` 沙箱会把 bash 包进 Windows ACL 受限令牌 runner，而 MSYS2/Cygwin 运行时在受限令牌下无法创建信号管道（`bash: *** fatal error - couldn't create signal pipe, Win32 error 5`），bash 启动即崩溃。

本插件提供 win32 原生 PTY spawn（node-pty/ConPTY，无 POSIX 进程检查），并复用官方 `BashTerminalBackend` 的会话逻辑，因此模型看到的 `bash` 工具定义与官方极简模式完全一致。

## 安装

```powershell
dsh plugin --profile web add github:AythyaCrispus/dsh-minimal-msys2
```

然后**重启 dsh**。插件启动时会自动把 agent preset 复制到 `$DSH_HOME/.agent-presets/minimal-msys2`（已存在则不覆盖，保留你的修改）。

## 使用

1. 以 **danger-full-access** 模式启动/切换会话（MSYS2 bash 与 Windows 受限令牌不兼容，这是硬限制）：
   ```powershell
   $env:DSH_PERMISSION_MODE = 'danger-full-access'
   dsh web
   ```
   或在 Web UI 的会话设置中把沙箱模式切到 danger-full-access。
2. 新建会话，Agent 选择 **Windows Minimal Mode**（选择器里显示英文名）。
3. 工具列表应为 `bash` + `str_replace_editor`。

## 配置 bash 路径（GUI）

MSYS2 与 Git Bash 的安装路径不同，无需改配置文件：

1. 打开 Web GUI **设置 → 插件配置 →「Windows 极简模式」**（卡片标题跟随界面语言，中文界面显示「Windows 极简模式」，英文界面显示 "Windows Minimal Mode"）；
2. 在 **bash 路径** 输入框填写你的 `bash.exe` 绝对路径（如 `C:/msys64/usr/bin/bash.exe` 或 `C:/Program Files/Git/bin/bash.exe`），点击 **保存**；
3. 该值写入 `$DSH_HOME/.credentials.yaml` 的 `DSH_MSYS2_BASH` 条目（经凭据域持久化，绕开 rc.6 的 settings 白名单）；后端启动 bash 时优先读取；点「清除」并保存可恢复默认值。

也可以直接设置环境变量 `DSH_MSYS2_BASH`（优先级高于凭据文件），或编辑 `$DSH_HOME/.agent-presets/minimal-msys2/agent.cordis.yml` 里 `terminal-bash` 行的 `shellPath`（优先级最低，作兜底默认）。

## 卸载

```powershell
dsh plugin --profile web remove dsh-minimal-msys2
Remove-Item "$HOME\.dsh\.agent-presets\minimal-msys2" -Recurse -Force   # 手动删除已复制的 preset
```

## 第二轮注入的触发与验证（0.6.0+）

`minimal-extended` 的第二轮注入（`lib/extended.js`）采用三路冗余触发 + 消息 id 去重，任何一路可达即注入：

1. `agent/inbox/inserted`（standing 挂载）—— 真实用户消息进入 inbox 才触发；runtime-context 快照等插件注入的 `user/message` 不经 inbox，是最忠实的"轮次"信号；
2. `session/event` `user/message`（standing 挂载，过滤 `source.kind === "user"`，排除 `@deepseek-ai/dsh-system-prompt` 的快照注入）；
3. `agent/created` 处理器内在 `agent.ctx` 与 `agent.ctx.extend(extra)` 双挂 `session/event`（实测这两个位置能收到事件）。

第 2 条真实用户消息触发注入（异步，需数秒完成 import 与注册）。注入完成后注册哨兵工具 **`minimal_extended_ready`**（随 agent 清理），模型工具列表 / `request/header` 可见——用它确认注入确实执行：

- 第 3 轮起模型能看到 `pwsh` / `read` / `write` 等标准工具 + `minimal_extended_ready` → 注入成功（第 2 轮请求可能已在注入完成前组装，看不到新工具属正常时序）；
- 仍只有 `bash` / `str_replace_editor` 等极简工具 → 触发链路仍断（查 dsh 服务端日志中的 `minimal-extended:` 行）。

## 已知限制

- 必须在 `danger-full-access` 模式下使用（MSYS2/Cygwin 与 Windows 受限令牌的根本不兼容，无法绕过）。
- 非持久：与官方极简模式一致，为持久 PTY shell。
- 依赖 host 已有的 `node-pty`、`@deepseek-ai/dsh-terminal-bash`、`@deepseek-ai/dsh-subprocess`（peerDependencies，安装时复用，不重复构建原生模块）。
