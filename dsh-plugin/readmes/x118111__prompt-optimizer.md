# ✨ Prompt Optimizer

一个用于 **DeepSeek Harness (DSH)** 的插件：在聊天输入框（发送按钮左侧）添加一个 ✨ 按钮，用大模型把当前草稿提示词改写得更清晰、更具体、更有效，并把优化结果写回输入框供确认后发送。支持**静态配置**（重启自动加载）与**动态加载**（快速试用）两种方式。

![optimize button](https://img.shields.io/badge/DSH-Plugin-4D6BFE)

## 功能特性

- **一键优化**：在输入框工具行放置一个 28×28 圆形按钮（单色 ✨ 闪光星图标，与 Harness 浅色外观统一），点击即可用大模型改写当前提示词。
- **上下文感知**：优化时自动携带最近 8 条对话（用户 + 助手），让模型先理解你的真实意图再改写，避免优化结果偏离需求；新会话没有上下文时，则直接基于提示词本身优化。
- **模型回退链**：优先使用配置的默认模型（`agentDefaultModel.currentSelection()`）；若未配置或不可用，自动回退到第一个已注册 provider 的第一个可用模型（`llm.listProviders()` + `llm.listModels()`）。
- **可见的错误提示**：失败原因不再只藏在 `title` 里——同时输出到浏览器控制台、显示在悬停提示与 `aria-label` 中（如 `优化失败：no-model`）。
- **写回确认**：优化结果通过 `inputActions.setDraft()` 写回输入框，你可以检查、编辑后再发送，不会直接发出。
- **忙碌状态**：优化过程中按钮切换为沙漏图标并禁用，防止重复点击。
- **零调试残留**：`console.error` 仅用于真实错误上报，正常路径无任何日志噪音。

## 工作原理

插件分为两半：

| 文件 | 运行环境 | 职责 |
| --- | --- | --- |
| `host.js` / [`static/lib/index.js`](static/lib/index.js) | DSH Node.js 进程（Host） | 解析模型路由（含回退）、构造优化提示、流式调用 `llm.stream()` 并返回结果 |
| `client.js` / [`static/lib/client.js`](static/lib/client.js) | 浏览器页面（Client） | 在 `conversation.input.right` 插槽注册按钮，读取草稿与对话上下文，调用 Host，写回优化结果 |

- **动态版**（根目录 `host.js` / `client.js`）：Host 注册 `prompt.optimize` RPC，Client 用 `host.call` 调用；
- **静态版**（[`static/`](static/)）：Host 注册 `promptOptimizer` Typert Remote 服务，Client 用 `ctx.remote.promptOptimizer.optimize` 调用。

## 安装方式

本插件支持两种加载方式，**推荐静态配置**（重启后自动加载）：

| 方式 | 持久性 | 适用场景 |
| --- | --- | --- |
| [静态配置](docs/loading-methods.md)（推荐） | ✅ 重启自动加载 | 长期使用、团队部署 |
| 动态加载（手动） | ❌ 重启丢失 | 快速试用、迭代调试 |

完整对比、优缺点、推荐建议、静态配置的完整示例与操作步骤见
**[docs/loading-methods.md](docs/loading-methods.md)**。

### 方式一：静态配置（推荐，重启自动加载）

1. 将仓库 [`static/`](static/) 目录复制为 `$DSH_HOME/profiles/<profile>/plugins/prompt-optimizer/`；
2. 在 profile `package.json` 的 `dependencies` 增加 `"prompt-optimizer": "file:plugins/prompt-optimizer"`；
3. 在 `cordis.patch.yml` 的 `insert` 列表增加 `- id: prompt-optimizer` / `name: 'prompt-optimizer'`；
4. `pnpm install` 后重启 DSH，✨ 按钮自动出现。

### 方式二：动态加载（手动，重启丢失）

在 DSH 会话中通过动态插件机制加载：

1. 将 [`host.js`](host.js) 的完整内容作为 `code.host`，[`client.js`](client.js) 的完整内容作为 `code.client`，调用 `cordis_define` 定义插件；
2. 调用 `cordis_run` 激活（首次运行需在界面中批准）；
3. 批准后按钮即出现在输入框工具行。

> 动态插件临时扩展当前 DSH 进程，定义不修改仓库源文件，进程重启后需重新加载。若希望常驻，请使用方式一。

## 使用方法

1. 在输入框输入你想优化的提示词，例如：`帮我写个介绍`；
2. 点击输入框工具行左侧（发送按钮旁）的 ✨ 按钮；
3. 等待模型改写（按钮变为沙漏，几秒完成）；
4. 优化结果自动填入输入框，检查、编辑后发送。

### 交互细节

| 状态 | 按钮表现 |
| --- | --- |
| 空闲 | ✨ 闪光星（浅灰单色） |
| 悬停 | 显示气泡提示"优化提示词" |
| 优化中 | ⏳ 沙漏，按钮禁用 |
| 失败 | 悬停/`aria-label` 显示"优化失败：\<原因\>"，控制台同步输出 |

## 配置说明

本插件本身无需配置，但依赖 Host 侧的 LLM 服务：

- **默认模型**（推荐）：在 Harness 设置中配置默认 provider/model，插件会通过 `agentDefaultModel.currentSelection()` 读取；
- **无默认模型时**：插件自动使用 `llm.listProviders()` 返回的第一个 provider 及其第一个模型；
- **优化策略**：系统提示词内置（保留原意、参考上下文、具体化、分步、明确格式、输出语言跟随原文）。如需调整优化风格，可修改 `host.js` 中的 `system` 数组后重新加载插件。

## 错误处理说明

插件通过 `{ ok: boolean, error?: string }` 结构化返回结果，可能的错误码：

| error | 含义 | 建议 |
| --- | --- | --- |
| `empty` | 草稿为空 | 输入内容后再点击 |
| `no-model` | 无法解析任何可用模型 | 检查 Harness 是否配置了默认模型或注册了 LLM provider |
| `llm-error` / adapter 消息 | 模型调用失败（网络、鉴权等） | 查看控制台完整错误，检查模型凭据/网络 |
| `max-tokens` | 输出达到 token 上限 | 精简输入或调整 `maxTokens` |
| `tool-calls` | 模型意外请求调用工具 | 重试一次，一般偶发 |
| `empty-result` | 模型未产出文本 | 重试或调整输入 |
| 其他 | Host 内部异常 | 控制台有 `[prompt-optimizer]` 前缀的完整堆栈 |

所有失败都会：写入浏览器控制台（`[prompt-optimizer]` 前缀）、显示在按钮悬停提示和 `aria-label` 中——**不会静默失败**。

## 常见问题（FAQ）

**Q：新建对话（无上下文）时点优化没反应？**
A：新会话没有上下文时插件仍会正常工作——系统提示词明确"若没有上下文，直接基于提示词本身优化"。若按钮未出现，是因为 Harness 在 hero/无会话状态下本就不渲染工具行按钮（产品行为）；进入会话后按钮即出现。若点击后无效果，请打开浏览器控制台查看 `[prompt-optimizer]` 错误信息。

**Q：优化结果为什么和我想要的不一致？**
A：插件会携带最近 8 条对话作为上下文帮助模型理解意图。若在全新会话中优化，模型只能基于提示词本身推断；建议在优化前补充必要的背景信息，或先进行一两轮对话建立上下文。

**Q：图标为什么是单色的？**
A：为了与 Harness 浅色外观统一，图标使用内联 SVG + `fill: currentColor`（无彩色、无描边），颜色跟随按钮的浅灰文字色。形状为四角闪光星（sparkles），与原 ✨ 一致。

**Q：点一次会消耗多少模型调用？**
A：每次点击恰好一次 `llm.stream()` 调用。优化结果写回输入框后由你决定是否发送，不会自动重复请求。

**Q：会生成两遍提示词吗？**
A：不会。Host 端只累加 `text-delta` 增量（`block-end` 携带的是完整块，若同时累加会造成重复），与 DSH 官方 `BlockAssembler` 语义一致。

## License

[MIT](LICENSE)
