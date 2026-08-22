# dsh-web-search-duckduckgo

[English](README.md) | 中文

为 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) 提供的免费 [DuckDuckGo](https://duckduckgo.com) 搜索——无需 API key、无需凭据、每次搜索零成本。本仓库发布两个 npm 包：

- `packages/dsh-web-search-duckduckgo/` — **实现包**：注册进 `ctx.web` 的 `WebSearchProvider`（id `duckduckgo`），以及直接调用该 provider 的模型可见工具 `web_search_ddg`。它本身不声明 `dsh.bundle`，不作为组合层安装。
- `packages/dsh-web-search-duckduckgo-bundle/` — **可安装 bundle**：声明 `dsh.bundle.patch`，其 `cordis.patch.yml` 插入一行 `web-search-duckduckgo`。该行指向 bundle 自己的入口（bundle 入口 re-export 内嵌的实现包），因此打包产物**自包含**——`bundleDependencies` 会把实现包（连同 `schemastery`/`cosmokit`）一起打进 tarball。
- `dist/` — 构建好的 tarball。**分发时只需要 bundle 一个文件。**

## 安装

打包产物已内嵌实现包，单条命令即可安装并挂载进 profile：

```sh
dsh plugin --profile <name> add ./dist/dsh-web-search-duckduckgo-bundle.tgz
```

安装后重启该 profile（新增 bundle 层/新包需要重启；`cordis.patch.yml` 和 settings 的改动是热生效的），可以用 `dsh --profile <name> --dump-config` 确认组合树里出现 `web-search-duckduckgo` 行。

包发布到 registry 后同样按 bundle 名安装：

```sh
dsh plugin --profile <name> add @deepseek-ai/dsh-web-search-duckduckgo-bundle
```

只安装实现包（`./dist/dsh-web-search-duckduckgo.tgz`）会作为普通依赖落地，不产生组合层；它供希望在自己的 `cordis.patch.yml` 里手动挂载该行的部署使用。

## 热插拔与动态加载

- **加载**：`dsh plugin add` 是 profile 管理的 pnpm 安装 + `dsh.profile.bundles` 协调；bundle 补丁在空根上组成插件树，`web-search-duckduckgo` 行与其它 DSH 行同级。
- **卸载**：`dsh plugin --profile <name> remove @deepseek-ai/dsh-web-search-duckduckgo-bundle` 移除依赖和 bundle 层；在 profile 自己的 `cordis.patch.yml` 里 `{ id: web-search-duckduckgo, disabled: true }` 可以不改包临时停用，改回即恢复。
- **运行时清理**：插件是命名导出函数插件（`name`/`inject`/`Config`/`apply`，无 default export）；provider、`web_search_ddg` 工具、system-prompt 节、settings 节全部是 fiber 作用域 effect，HMR 替换/行移除时随 fiber 一起回卷。单测和安装产物验证都覆盖了 dispose 后工具与 provider 消失。
- **配置热生效**：`web-search-duckduckgo` settings 节每次搜索时重新解析；提交 settings 改动无需重挂插件或重启。

## 配置

所有选项均可选；部署时可以在 web seam 上固定另一个 provider（出厂配置为 `searchProvider: deepseek-official`），同时并提供这条免费路线，让模型每轮自行选择。

| 键 | 默认值 | 含义 |
|---|---|---|
| `proxy` | （未设置） | `host:port` 或 `http://host:port` 形式的 CONNECT 代理，用于直连无法到达的端点。未设置 = 直连；隧道失败自动回退直连。 |
| `region` | `us-en` | HTML 表单 `l` 字段的区域代码（如 `us-en`、`uk-en`、`de-de`）。 |
| `baseURL` | `https://html.duckduckgo.com/html/` | HTML 搜索端点，通过 POST `q`/`b`/`l` 表单搜索。 |
| `fallbackBaseURL` | `https://api.duckduckgo.com/` | HTML 无结果时使用的 Instant Answer JSON 端点。 |
| `userAgent` | 浏览器 UA | 每次请求发送的 `User-Agent` 头。 |
| `timeoutMs` | `30000` | 单次请求超时（毫秒）。 |
| `maxResults` | `8` | 请求未携带 `maxResults` 时的结果数上限。 |

通过 `web-search-duckduckgo` 设置命名空间或组合覆盖层配置：

```yaml
- id: web-search-duckduckgo
  name: '@deepseek-ai/dsh-web-search-duckduckgo-bundle'
  config:
    proxy: http://127.0.0.1:8080
```

## 工作原理

HTML 搜索通过 POST `q`/`b`/`l` 表单（查询词、bang 占位、区域）提交到 `html.duckduckgo.com/html/`，因此 `result__a` 的 href 以**直链**形式返回，而不是 GET 时的 `uddg` 广告包装。结果按当前的 `results_links` 布局解析、归一化（Unicode NFC、去除控制字符），并丢弃 `y.js` 广告追踪链接。当 HTML 无结果时回退到 Instant Answer JSON 端点。可选的零依赖 CONNECT 隧道（`node:net` + `node:tls`）用于直连无法到达的端点。

## 从源码构建

本仓库自带 pnpm workspace，可以独立于 DeepSeek Harness checkout 安装、构建、测试和打包：

```sh
pnpm install
pnpm build
pnpm test
pnpm pack
```

`pnpm-workspace.yaml` 使用 `nodeLinker: hoisted`，这是 `bundleDependencies` 打包所要求的。重新生成的 tarball 落在 `dist/`；分发时只需要 `dsh-web-search-duckduckgo-bundle.tgz` 一个文件。

## 许可证

MIT
