<p align="center">
  <img src="assets/icon.png" alt="DSH Notify" width="96">
</p>

<h1 align="center">DSH Notify</h1>

<p align="center">
  <strong>DeepSeek Harness 的 Windows 通知插件：任务完成或需要决策时弹出系统 Toast，并在托盘显示待处理角标。</strong>
</p>

<p align="center">
  <a href="https://github.com/MichengAI/dsh-notify/issues">反馈问题</a>
  · <a href="https://www.npmjs.com/package/@michengai/dsh-notify">查看 npm</a>
  · <a href="README.md">English</a>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache--2.0-blue.svg" alt="Apache License 2.0"></a>
  <a href="https://www.npmjs.com/package/@michengai/dsh-notify"><img src="https://img.shields.io/npm/v/%40michengai/dsh-notify?label=npm" alt="npm package"></a>
  <img src="https://img.shields.io/badge/DSH-Web%20Plugin-10b981" alt="DSH Web Plugin">
  <img src="https://img.shields.io/badge/Node.js-22%2B-339933?logo=nodedotjs&logoColor=white" alt="Node.js 22 or later">
</p>

> DSH Notify 是社区维护的插件，不是 DeepSeek AI 官方产品。

## 功能特性

- 根 Agent 从 `running` 回到 `idle` 时弹出 Windows Toast。
- 包装 `userQuestions.ask`，计划审批和决策提问也会提醒。
- 托盘角标统计待回复决策和尚未打开的完成会话。
- 使用 Windows 系统默认通知音。支持免打扰时段，并可跟随 Windows 专注助手静音。
- 以原生 DSH profile 插件安装，不修改任何内置包。

## 前置条件

- 本机已安装 DeepSeek Harness Web，并且 PowerShell 能直接运行 `dsh`。
- Toast 和托盘需要 Windows 10/11；其他平台会自动跳过这些能力。
- 示例使用 `web` profile，请按实际 profile 替换。
- 源码安装和开发需要 Node.js 22+；仅从 npm 安装无需在任意目录执行 `npm install`。

## 安装

### 从 npm 安装

在任意 PowerShell 目录执行。请通过 `dsh plugin` 安装到 DSH profile：

```powershell
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
dsh plugin --profile web add @michengai/dsh-notify
dsh --profile web --dump-config
```

安装或升级后重启 DSH Web，或重新加载当前 Web profile。若镜像未同步最新版本，可在安装命令末尾追加 `--registry=https://registry.npmjs.org/`。

### 从源码安装

适用于调试或使用未发布改动。克隆后的目录会直接作为插件安装路径：

```powershell
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
Set-Location D:\Repository\deepseek-harness-plugin
git clone https://github.com/MichengAI/dsh-notify.git
Set-Location .\dsh-notify
npm install
npm test
npm run build
dsh plugin --profile web add .
dsh --profile web --dump-config
```

完成后重启 DSH Web 或重新加载当前 Web profile。`dsh plugin ... add .` 会自动读取并应用 `cordis.patch.yml`；不要手工复制 `lib` 文件。

## 使用

打开「设置 → 通知」，再按下表操作：

| 目标 | 操作 | 范围 |
| --- | --- | --- |
| 轮次完成 | 选择「始终提醒」「仅在未聚焦时」或「关闭」。 | 根 Agent 完成 |
| 权限通知 | 开关「启用权限通知」。 | 工具批准和计划审批 |
| 提问通知 | 开关「启用提问通知」。 | 需要选择或输入才能继续 |
| 跟随系统勿扰 | 打开「跟随系统勿扰」。 | Windows 专注助手 |
| 合并连续完成 | 几秒内的多次完成收成一条。 | 完成 Toast |

环境变量覆盖：

| 变量 | 作用 |
| --- | --- |
| `DSH_NOTIFY=0` | 整体禁用 |
| `DSH_NOTIFY_MIN_INTERVAL_MS` | Toast 节流间隔，默认 `2500` |

## 权限与安全边界

| 位置 | 读取 | 写入 | 联网 |
| --- | --- | --- | --- |
| `$DSH_HOME\settings.yaml` 的 `dsh-notify` 节 | 支持 | 支持 | 不支持 |
| `$DSH_HOME\dsh-notify` 托盘状态和调试日志 | 支持 | 支持 | 不支持 |
| `/api/dsh-notify/config` | 仅同源设置页 | 仅同源设置页 | 仅本机 |

- 不发送遥测，不读取凭据。
- 子代理完成和武装态 goal 自动续跑不会弹出完成提醒。
- 未打包的 Windows 应用无法激活 Toast 按钮，因此通知只做提醒。

## 二次开发

本仓库在 `src` 开发，构建到 `lib`：

- [src\index.ts](src/index.ts)：宿主插件、设置注册和 HTTP 路由。
- [src\client\index.ts](src/client/index.ts)：设置页「通知」区段。
- [scripts\toast.ps1](scripts/toast.ps1) 与 [scripts\tray.ps1](scripts/tray.ps1)：Windows Toast 和托盘脚本。
- `tests\*.test.ts`：配置、免打扰、会话辅助函数和发布契约测试。

修改后请测试、重新构建，再以本地目录安装验证：

```powershell
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
npm test
npm run check
dsh plugin --profile web add .
```

含中文的 PowerShell 脚本必须保持 UTF-8 BOM。

## 验证

```powershell
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
npm test
npm run check
```

`npm run check` 会依次执行类型检查、测试和宿主/设置页构建。

## 项目文档与许可证

项目状态、使用边界、技术架构和迭代记录从[文档交接入口](docs/00-交接入口/00-阅读导航.md)开始。

本项目采用 [Apache License 2.0](LICENSE)。


