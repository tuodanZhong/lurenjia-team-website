# dsh-subprocess-win32

[English](README.md) | 中文

> **DeepSeek Harness (DSH) 原生 Windows 子进程运行时插件与优化 Agent 预设套件**

`dsh-subprocess-win32` 是专为 Windows 平台下的 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) 打造的 Cordis 运行时插件与预设管理套件。它彻底解决了 Windows 下终端进程残留与信号控制问题，并为 DSH 提供轻量、省 Token 的 Windows Agent 预设。

---

## 核心特性

- ⚙️ **原生 Windows 子进程引擎 (`subprocess-win32`)**  
  针对 Windows 平台重构子进程生命周期管理，提供精准的进程树探测与优雅关闭机制，彻底解决 Git Bash / 终端工具进程残留问题，同时不影响 Linux/macOS 原生行为。
- 🚀 **内置开箱即用的两套 Windows 预设**  
  - **`Minimal (Windows)`**：极简配置，仅包含持久化 Git Bash 与 `str_replace_editor`，首轮上下文极度清爽。
  - **`Anchored Standard (Windows)`**：两阶段渐进式加载预设。启动时零额外开销，按需动态检索并解锁重量级工具（PowerShell、网络工具、子智能体等）。
- 🛡️ **安全可靠的 PowerShell 生命周期管理器**  
  内置全流程脚本，支持环境体检 (`doctor`)、一键安装 (`setup`)、无损热更新 (`update`)、快速回滚 (`rollback`) 及彻底卸载 (`uninstall`)，绝不在后台暗改 PATH 或权限。

---

## 解决的核心痛点

DeepSeek Harness 原生的终端执行机制主要面向 Unix 环境设计，在 Windows 下容易出现进程清理不彻底、终端挂起或平台判断兼容问题。

`dsh-subprocess-win32` 作为 DSH 的 Cordis 运行时插件接入体系，从底层接管 Windows 进程调用，并配套提供经过完整测试的 Agent 预设，让 Windows 用户无需折腾即可享受稳定高效的 AI 编程体验。

---

## 仓库关系与选型指南

| 仓库 | DSH 角色 | 包含内容 | 适用场景 |
| :--- | :--- | :--- | :--- |
| **`dsh-subprocess-win32`** *(当前仓库)* | **Cordis 运行时插件** | `subprocess-win32` 底层引擎、生命周期管理脚本、两套预设源文件 | **Windows 用户必选**。安装后即可完整获得运行时支持及两套 Agent 预设。 |
| [**`dsh-anchored-standard-windows`**](https://github.com/delightedMaster/dsh-anchored-standard-windows) | **Agent 预设包** | 独立的 `agent.cordis.yml`、阶段门禁模块与预设单元测试 | **高级开发/定制可选**。仅在需要独立开发、调试或分发 Anchored 预设时使用。 |

> 💡 **极简结论：** 普通用户直接安装 `dsh-subprocess-win32` 即可，其自带的安装脚本会自动为您配置并生成两套 Windows 预设。

---

## 在其他 DSH profile 中安装

前置条件：Windows x64、Node.js 22.19+（推荐 Node.js 24 LTS）、Git for Windows
以及可用的 DSH。克隆本仓库后，将本地包加入目标 profile。支持插件命令的 DSH
版本可以使用：

```powershell
dsh plugin --profile web add C:\src\dsh-subprocess-win32
```

如果当前 CLI 没有 `add` 子命令，就在 profile 的 `package.json` 中添加本地
依赖，并将 `dsh-subprocess-win32` 加入 `dsh.profile.bundles`，然后使用该 profile
自己的包管理器安装。不要把这个包直接放进 DSH 核心版本目录。

本包的 Cordis patch 只在 Windows 停用官方 `subprocess` 并插入
`subprocess-win32`；Linux 和 macOS 继续使用官方运行时。

当前管理式安装的显式入口：

```powershell
$setup = "$env:LOCALAPPDATA\DeepSeekHarness\setup\dsh-subprocess-win32.ps1"
& $setup -Action doctor
& $setup -Action setup -PackageSource C:\src\dsh-subprocess-win32
```

安装后请新建一个空会话，再选择 `Minimal (Windows)` 或
`Anchored Standard (Windows)`；已有会话保留创建时的 Agent 组合。

## 更新和回退

DSH 核心更新与本包更新分开进行。让新源码目录与当前目录并存，不要原地覆盖。
先执行只读检查：

```powershell
& $setup -Action doctor
& $setup -Action update -DryRun -PackageSource C:\src\dsh-subprocess-win32
```

确认清单和测试结果后再应用：

```powershell
& $setup -Action update -PackageSource C:\src\dsh-subprocess-win32
& $setup -Action rollback
```

管理器会备份 profile、保留上一包，并在失败时恢复活动版本指针和 profile 文件。
它不会自动升级第三方 DSH bundle 或 Codex 插件。

## 完整卸载

先预览，再执行删除：

```powershell
& $setup -Action uninstall -DryRun
& $setup -Action uninstall
```

卸载器根据安装清单，只停止登记的 DSH 进程/任务，删除两个 DSH 预设和专用的
`%LOCALAPPDATA%\DeepSeekHarness` 根目录，并做残留审计。它不会删除项目源码、
`.agents\skills`、`.codex\skills`、Codex 插件、Codex MCP 原始配置或其他 Edge
应用。需要备份时使用管理器的导出选项；不要在 Host 运行时手工删除根目录。

## Windows 限制和安全注意事项

- DSH 的 `workspace-write` 受限令牌下，Git/MSYS Bash 可能返回
  `0xC0000142`。完整权限验证已通过；本包不会放宽权限、绕过审批或静默选择
  `danger-full-access`。
- Windows 回退路径没有 Linux `landlock` 隔离，请把命令输出当作不可信数据，
  保留 DSH 的审批策略。
- “极简”指模型可见的工具 schema 和提示词表面尽量接近 Minimal，不声称 Windows
  变成 Linux 内核，也不保证所有任务的延迟、缓存命中或完成率相同。
- 不要把 Codex 的 `.codex-plugin` 清单复制到本包。Codex 插件、DSH Cordis
  bundle、Agent 预设、Skills 和 MCP 使用不同加载器；只有明确兼容的
  `SKILL.md` 和 MCP Tools 配置可以共享。

## 开发和测试

使用 DSH 自带 Node.js（或 Node.js 22.19+）：

```powershell
npm test
```

测试覆盖预设阶段切换、首轮上下文抑制、工具发现、压缩恢复和 Windows
subprocess 适配器；不代替模型提供商、API 密钥或沙箱策略的配置检查。

## 参考项目和致谢

本项目是集成和 Windows 适配，不代表 DeepSeek、OpenAI 或上游维护者背书。

- [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)：官方
  预设、Skills、Cordis bundle 和 MCP 设计。
- [`sjh9714/dsh-win32`](https://github.com/sjh9714/dsh-win32)：固定源码提交
  `f8a68a9836b84fdfec5c1f36ab60cea9923c689f`，提供 Windows subprocess 方向。
- [`xiaobright/dsh-anchored-standard`](https://github.com/xiaobright/dsh-anchored-standard)：
  固定源码提交 `f57a1bde2dbaba3039bdae8631f78a0cb3ae3ebe`，提供两阶段 Agent
  预设思路。
- [Anchored Standard issue #24](https://github.com/xiaobright/dsh-anchored-standard/issues/24)：
  说明应在当前 Agent scope 中解析工具 schema。

感谢 DeepSeek Harness 和社区贡献者公开运行时接口、预设实验、测试和问题报告，
使这个 Windows 包成为可能。许可证和来源信息见 [`NOTICE`](NOTICE)。
