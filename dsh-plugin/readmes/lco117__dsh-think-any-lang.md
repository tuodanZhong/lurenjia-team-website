# dsh-think-any-lang

<p align="center">
  <img src="https://img.shields.io/badge/DeepSeek%20Harness-Plugin-4D6BFE?style=for-the-badge&logo=deepseek" alt="DeepSeek Harness Plugin">
</p>

<div align="center">

[![GitHub Stars](https://img.shields.io/github/stars/lco117/dsh-think-any-lang?style=social)](https://github.com/lco117/dsh-think-any-lang/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/lco117/dsh-think-any-lang?style=social)](https://github.com/lco117/dsh-think-any-lang/network/members)
[![GitHub Issues](https://img.shields.io/github/issues/lco117/dsh-think-any-lang)](https://github.com/lco117/dsh-think-any-lang/issues)
[![GitHub Pull Requests](https://img.shields.io/github/issues-pr/lco117/dsh-think-any-lang)](https://github.com/lco117/dsh-think-any-lang/pulls)
[![License](https://img.shields.io/badge/License-MIT-blue)](LICENSE)
[![简体中文](https://img.shields.io/badge/🇨🇳_简体中文-当前-blue)](README.md)
[![English](https://img.shields.io/badge/🇺🇸_English-Available-green)](README.en-US.md)

</div>

<div align="center">

[![dsh-plugin](https://img.shields.io/badge/dsh--plugin-46C6FF?style=flat-square&logo=github)](https://github.com/topics/dsh-plugin)
[![思考语言](https://img.shields.io/badge/思考语言-13%20种-4D6BFE?style=flat-square)](index.js)
[![零延迟](https://img.shields.io/badge/零延迟-零额外调用-2ea44f?style=flat-square)](index.js)
[![纯 JS](https://img.shields.io/badge/纯%20JS-无构建-F7DF1E?style=flat-square)](client.js)

</div>

DeepSeek Harness 插件：在 **设置 → 通用** 中添加「**思考语言**」下拉选择器，选择模型进行推理思考（chain of thought）时使用的语言（中文、English、日本語、한국어、Deutsch……）。**最终回复语言保持不变。**

<p align="center">
  <a href="#界面预览">界面预览</a> · <a href="#功能">功能</a> · <a href="#工作原理">工作原理</a> · <a href="#安装">安装</a> · <a href="#使用">使用</a> · <a href="#开发">开发</a> · <a href="#开源发布">开源发布</a> · <a href="#star-history">Star History</a>
</p>

---


## 界面预览

<table>
  <tr>
    <td align="center" width="50%"><img src="screenshots/01.webp" alt="设置 → 通用 中的思考语言选择器"><br><b>设置页里的选择器</b><br><sub>在通用设置中直接选择</sub></td>
    <td align="center" width="50%"><img src="screenshots/04.webp" alt="思考语言选择框"><br><b>选择框</b><br><sub>点击即可展开语言选项</sub></td>
  </tr>
  <tr>
    <td align="center" width="50%"><img src="screenshots/02.webp" alt="展开的语言下拉菜单"><br><b>语言选项一次展开</b><br><sub>默认 与 12 种语言一屏选完</sub></td>
    <td align="center" width="50%"><img src="screenshots/03.webp" alt="插件列表中的 dsh-think-any-lang"><br><b>插件列表里的样子</b><br><sub>安装后出现在插件管理列表</sub></td>
  </tr>
</table>

---


## 功能

- **设置 → 通用 → 思考语言**：一个下拉选择器，选择模型思考时使用的语言。
- **零延迟、零额外调用**：实现方式是系统提示词指令（`systemPrompt.section`），不会像"翻译推理过程"那样引入额外的模型调用或响应延迟。
- **指令用目标语言书写**：每条指令都以其目标语言撰写（如英语指令用 English 书写），模型遵循度更高。
- **持久化**：选择结果存入用户设置文档（settings 服务），重启后保持。
- **纯 JS、无构建**：Host 半与浏览器半都是手写 JavaScript，GitHub 直装零门槛。

支持的语言：`off`（跟随默认，不注入指令）、简体中文、English、日本語、한국어、Deutsch、Français、Español、Português、Русский、Italiano、العربية、हिन्दी。

---


## 工作原理

| 半 | 职责 |
|---|---|
| `index.js`（Host 半） | 注册 `think-any-lang` 设置命名空间（`language` 字段，枚举，默认 `zh`）；监听选择变化，非 `off` 时注册 `systemPrompt.section`（名称 `think-any-lang`），`off` 时注销；另注册私有 loopback RPC 通道 `/think-any-lang`（`get`/`set`）供浏览器半读写该命名空间 |
| `client.js`（浏览器半） | 以 `window.__ModuleLoader__.load` 契约注册 `settings.general.item` 行，渲染下拉选择器；通过 Host 半的 `/think-any-lang` RPC 通道读写设置 |

> **为什么用私有 RPC 通道而不是 settings RPC？** `dsh-host-apiproxy` 只向显式白名单（`WEB_SETTINGS_NAMESPACES` / `PRODUCT_SETTINGS_NAMESPACES`）内的命名空间开放 settings 读写，第三方插件注册的命名空间会收到 `settings-not-exposed`，选择无法持久化。因此浏览器半走宿主进程内私有通道（`ctx.connection.rpc.handle`），宿主内对 `ctx.settings` 的读写不受该白名单限制——持久化与 `systemPrompt` 联动保持不变。

> 语言表在 `index.js`（指令文本）与 `client.js`（显示标签）中各维护一份：浏览器 factory 的 `require` 只能解析平台模块，不能读取本地模块，因此两半各自持有自己的语言视图。新增语言时两个文件需要同步。

---


## 安装

要求：已安装 `dsh` CLI 并初始化过 profile（`dsh plugin --profile <name> add` 会自动初始化）。

### 从 GitHub 直装（推荐）

```sh
dsh plugin --profile web add github:lco117/dsh-think-any-lang
```

> 纯 JS 包没有 `prepare` 构建脚本，不需要 pnpm ≥10 的 `allowBuilds` 许可，GitHub 直装即装即用。建议像官方文档建议的那样固定提交：`github:lco117/dsh-think-any-lang#<commit-sha>`。

### 从本地目录安装（开发时）

```sh
dsh plugin --profile web add ./dsh-think-any-lang
```

### 验证

```sh
dsh --profile web --dump-config   # 应出现 "# == dsh-think-any-lang" 层
```

---


## 使用

1. 启动 `dsh web`。
2. 打开 **设置 → 通用**。
3. 在「**思考语言**」下拉中选择语言（默认中文）。
4. 之后的模型调用会在系统提示中收到对应语言的思考指令；DeepSeek 推理模型通常据此用所选语言输出 `reasoning_content`。

---


## 开发

```
dsh-think-any-lang/
├── package.json       # 声明 dsh.bundle 与 dsh.client
├── cordis.patch.yml   # 插件行：mount 本包的两个半
├── index.js           # Host 半：设置命名空间 + systemPrompt.section 联动
├── client.js          # 浏览器半：设置行 UI（手写 factory bundle）
├── README.md          # 中文说明
├── README.en-US.md    # English docs
└── screenshots/       # README 截图（webp）
```

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

如果这个项目对你有帮助，欢迎点一个 ⭐ Star，让更多人发现 dsh-think-any-lang。

<a href="https://www.repostars.dev/?repos=lco117%2Fdsh-think-any-lang&theme=ocean">
  <img alt="Star History Chart" src="https://www.repostars.dev/api/embed?repo=lco117%2Fdsh-think-any-lang&theme=ocean" />
</a>