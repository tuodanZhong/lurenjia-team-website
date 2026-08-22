# dsh-peak-hours

<p align="center">
  <img src="https://img.shields.io/badge/DeepSeek%20Harness-Plugin-4D6BFE?style=for-the-badge&logo=deepseek" alt="DeepSeek Harness Plugin">
</p>

<div align="center">

[![GitHub Stars](https://img.shields.io/github/stars/lco117/dsh-peak-hours?style=social)](https://github.com/lco117/dsh-peak-hours/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/lco117/dsh-peak-hours?style=social)](https://github.com/lco117/dsh-peak-hours/network/members)
[![GitHub Issues](https://img.shields.io/github/issues/lco117/dsh-peak-hours)](https://github.com/lco117/dsh-peak-hours/issues)
[![GitHub Pull Requests](https://img.shields.io/github/issues-pr/lco117/dsh-peak-hours)](https://github.com/lco117/dsh-peak-hours/pulls)
[![License](https://img.shields.io/badge/License-MIT-blue)](LICENSE)
[![简体中文](https://img.shields.io/badge/🇨🇳_简体中文-当前-blue)](README.zh-CN.md)
[![English](https://img.shields.io/badge/🇺🇸_English-Available-green)](README.md)

</div>

<div align="center">

[![dsh-plugin](https://img.shields.io/badge/dsh--plugin-46C6FF?style=flat-square&logo=github)](https://github.com/topics/dsh-plugin)
[![北京时间](https://img.shields.io/badge/北京时间-UTC%2B8-4D6BFE?style=flat-square)](client.js)
[![自动刷新](https://img.shields.io/badge/自动刷新-15%20秒-2ea44f?style=flat-square)](client.js)
[![纯 JS](https://img.shields.io/badge/纯%20JS-无构建-F7DF1E?style=flat-square)](client.js)

</div>

DeepSeek Harness 插件：在会话顶栏（对话区域顶部）显示「**高峰时段**」状态徽章。插件获取当前系统时间，转换为**北京时间（UTC+8）**，当时间落在 **09:00–12:00** 或 **14:00–18:00** 时显示 **🔴 高峰时段**，否则显示 **🟢 非高峰时段**，旁边附带当前北京时间。

<p align="center">
  <a href="#界面预览">界面预览</a> · <a href="#功能">功能</a> · <a href="#工作原理">工作原理</a> · <a href="#安装">安装</a> · <a href="#使用">使用</a> · <a href="#开发">开发</a> · <a href="#开源发布">开源发布</a> · <a href="#star-history">Star History</a>
</p>

---

## 界面预览

| 高峰时段（🔴） | 非高峰时段（🟢） |
|:---:|:---:|
| <img src="screenshots/01.webp"> | <img src="screenshots/02.webp"> |

---

## 功能

- **会话顶栏徽章**：位于对话区域顶部，与其它会话工具项排在一起，并排在「会话日志下载」的左边。
- **始终北京时间**：把绝对时间戳直接平移 UTC+8（无夏令时）再判断，无论机器在哪个时区，状态都正确。
- **两个高峰区间**：`09:00–12:00` 与 `14:00–18:00`（半开区间：12:00:00 与 18:00:00 属于非高峰）。
- **每 15 秒自动刷新**：到达整点边界后最多 15 秒内状态翻转，无需刷新页面。
- **语言可配置**：在 **设置 → 通用 → 徽章语言** 选择徽章显示语言（中文 / English），选择持久化，重启后保持。
- **跟随主题**：使用外壳的语义色 token（`--dsw-alias-*`），浅色/深色主题下都协调。
- **零延迟**：纯客户端时间计算——没有网络请求、没有额外模型调用。

---

## 工作原理

| 半 | 职责 |
|---|---|
| `client.js`（浏览器半） | 挂载时及每 15 秒读取 `new Date()`；转换为北京时间钟面分钟（`UTC+8`，无夏令时）；对照两个半开高峰区间判断；把徽章注册进 `conversation.session.header.utilities`（排在会话日志工具左边），并把「徽章语言」选择行注册进 `settings.general.item` |
| `index.js`（Host 半） | 注册 `peak-hours` 设置命名空间（`language` 字段，默认 `zh`）与私有 loopback RPC 通道 `/peak-hours`（`get`/`set`），供浏览器半读写该语言设置 |

> **为什么用私有 RPC 通道而不是 settings RPC？** `dsh-host-apiproxy` 只向显式白名单（`WEB_SETTINGS_NAMESPACES` / `PRODUCT_SETTINGS_NAMESPACES`）内的命名空间开放 settings 读写，第三方插件注册的命名空间会收到 `settings-not-exposed`，选择无法持久化。因此浏览器半走宿主进程内私有通道（`ctx.connection.rpc.handle`），宿主内对 `ctx.settings` 的读写不受该白名单限制——持久化保持不变。

> **为什么高峰判断仍在客户端？** 需求是"当前系统时间，转为北京时间"。浏览器时钟就是系统时间，UTC+8 平移是常量，因此徽章本地计算即可：没有 Host RPC 往返、没有额外失败点。

> `conversation.session.header.utilities` 座位由会话顶栏渲染，因此打开会话时徽章可见（首次运行的空白欢迎页会隐藏整个顶栏）。

---

## 安装

要求：已安装 `dsh` CLI 并初始化过 profile（`dsh plugin --profile <name> add` 会自动初始化）。

### 从 GitHub 直装（推荐）

```sh
dsh plugin --profile web add github:lco117/dsh-peak-hours
```

> 纯 JS 包没有 `prepare` 构建脚本，只有 `@deepseek-ai/schemastery` 一个运行时依赖，不需要 pnpm ≥10 的 `allowBuilds` 许可，GitHub 直装即装即用。建议像官方文档建议的那样固定提交：`github:lco117/dsh-peak-hours#<commit-sha>`。

### 从本地目录安装（开发时）

```sh
dsh plugin --profile web add ./dsh-peak-hours
```

### 验证

```sh
dsh --profile web --dump-config   # 应出现 "# == dsh-peak-hours" 层
```

---

## 使用

1. 启动 `dsh web`。
2. 打开（或保持打开）任意会话——徽章出现在会话顶栏工具行的最左侧（会话日志下载按钮的左边）。
3. 阅读状态：`09:00–12:00` / `14:00–18:00` 期间显示 **🔴 高峰时段** + 北京时间，其余时间显示 **🟢 非高峰时段**。鼠标悬停可查看完整区间说明。
4. 可选：打开 **设置 → 通用**，在「**徽章语言**」中选择 中文 或 English。选择会持久化，重启后保持。

---

## 开发

```
dsh-peak-hours/
├── package.json       # 声明 dsh.bundle 与 dsh.client
├── cordis.patch.yml   # 插件行：mount 本包的两个半
├── index.js           # Host 半：设置命名空间 + /peak-hours RPC 通道
├── client.js          # 浏览器半：高峰时段徽章 + 语言设置行（手写 factory bundle）
├── README.md          # English docs
├── README.zh-CN.md    # 中文说明
└── screenshots/       # README 截图（webp）
```

高峰区间与刷新间隔是 `client.js` 顶部的常量——在 `PEAK_WINDOWS` / `REFRESH_MS` 处调整即可。徽章文案在 `LANGUAGES`（client.js），设置 schema 在 `index.js`；新增语言时需要同步两处。

---

## 技术栈

| 类别 | 技术 |
|------|------|
| 插件平台 | [DeepSeek Harness (DSH)](https://github.com/deepseek-ai/dsh) |
| 插件框架 | Cordis |
| 语言 | JavaScript (ESM) |
| Schema | @deepseek-ai/schemastery |
| 构建 | 无（纯 JS，GitHub 直装） |

---

## License

[MIT](LICENSE) © 2026 lco117

---

## ⭐ Star History

如果这个项目对你有帮助，欢迎点一个 ⭐ Star，让更多人发现 dsh-peak-hours。

<a href="https://www.repostars.dev/?repos=lco117%2Fdsh-peak-hours&theme=ocean">
  <img alt="Star History Chart" src="https://www.repostars.dev/api/embed?repo=lco117%2Fdsh-peak-hours&theme=ocean" />
</a>
