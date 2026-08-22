# dsh-console

[DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)（DSH）的桌面客户端——基于 Tauri v2，在 DSH Web 运行时之上以**插件组合**的方式构建的桌面界面层。

> 状态：**V1 完成**——提供 Windows 安装包（NSIS）。

## 兼容性

基于 **`@deepseek-ai/dsh` 0.1.0-rc.6**（cordis 4.0.1）验证。deepseek-harness 仍在快速演进——本桌面端依赖 DSH 的插件/bundle 契约，上游未来若出现破坏性版本变动，本仓库需要相应适配。

## V1 功能

- **原生壳**：系统托盘（宿主状态 + 菜单）、关闭到托盘、单实例锁、开机自启、全局快捷键（Alt+Space）、窗口状态记忆、崩溃自动重启（进程树清理）、日志查看窗口
- **完整 DSH 界面**：对话、工具、后台任务、目标、子代理、工作区、Plan 模式、设置等全部 Web GUI 能力在应用窗口内本地运行；**首次启动自动创建桌面 profile**，无需手动配置
- **GUI 优先管理**：MCP 服务器（即时挂载/卸载）、技能、桌面偏好（自启/托盘/通知）全部在设置界面操作，配置持久化、即时生效，无需手写 YAML
- **Codex 式"已安排"面板**：对话中创建的持久化定时任务（"10 分钟后提醒我…"）跨会话聚合展示（状态/下次触发/所属会话），到点触发系统通知
- **自包含安装包**：内置 Node + dsh + 桌面包——用户机器无需预装 dsh/Node

## 架构

桌面端把 DSH 当作"万物皆插件"来对待：`dsh-console-app` 是一个 **delta bundle**，其 patch 叠加在 `@deepseek-ai/dsh-base` + `@deepseek-ai/dsh-web-app` 之上——桌面 profile 继承全部既有 host/client 行，只追加自己的行：`desktop-native`（`desktop` 服务 + 能力名册，通过 loopback JSON-RPC 管道与 Tauri 壳通信）、`schedule-center`（跨会话定时任务投影 + 触发通知）、`mcp-manager`（settings 命名空间 + MCP 服务器动态挂载）、以及 `ui-desktop-*` client 插件（桌面/MCP/技能/已安排设置分区）。Tauri 侧只做进程守护与原生能力后端（托盘、通知、自启、窗口）。

```
desktop profile = [dsh-base, dsh-web-app, dsh-console-app] + 用户 cordis.patch.yml
Tauri (Rust) ◄── loopback JSON-RPC 管道 ──► dsh 子进程 (node) ──► 主窗口加载 http://127.0.0.1:<port>
```

## 开发

前置：Node 20+、Windows 10/11（WebView2；Rust 工具链若在工作区内会自动挂载）。

```sh
.\dev.cmd        # 启动应用，使用你真实的 ~/.dsh（含模型配置）
```

- `dev.cmd` 不受 PowerShell 执行策略限制，自动挂载工作区工具链，每次启动自动修复桌面 profile
- `scripts/tauri-dev.mjs` 解析全局安装的 `@deepseek-ai/dsh` 并通过环境变量交给应用；打包构建自带运行时
- 首次运行会在 `~/.dsh/profiles/desktop` 创建桌面 profile，与你既有 `~/.dsh` 数据并存

## 打包

```sh
node scripts/bundle-dsh.mjs      # 把 Node + dsh + 桌面包打包进 src-tauri/resources
node scripts/tauri-dev.mjs build # 产出 NSIS 安装包（src-tauri/target/release/bundle）
```

安装包完全自包含：首次启动从内置资源自举桌面 profile，无需仓库、无需 npm。

## 目录结构

```
packages/bundle/desktop-app       delta patch + 运行时 glue 插件（surface 提示词）
packages/host/desktop-native      node 侧原生桥（desktop 服务、偏好、管道）
packages/host/schedule-center     跨会话定时任务投影 + 触发通知
packages/host/mcp-manager         GUI 管理的 MCP 服务器（命名空间 + 动态挂载）
packages/client/ui-desktop-*      设置分区：桌面 / MCP / 技能 / 已安排
src                               Tauri 启动前内核壳页（启动中/错误/日志）
src-tauri                         Rust：进程守护、托盘、窗口、通知、偏好
scripts                           resolve-dsh / tauri-dev / gen-icon / bundle-dsh / bootstrap-desktop-profile
.github/workflows                 CI（fmt/clippy/test）+ Release（tauri-action 出 NSIS）
```

## 许可

MIT
