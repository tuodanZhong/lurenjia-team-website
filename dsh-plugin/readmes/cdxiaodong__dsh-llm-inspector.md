# dsh-llm-inspector

> 统一 LLM 请求/响应检查器 —— [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) 插件

一个插件收编四类能力，全部通过配置开关：reasoning 控制、外部思考（think）导出、流量/包分析、会话落盘审计。

## 功能

| 功能 | 实现机制 | 配置项 |
|------|----------|--------|
| **reasoning 控制** | 挂 `agent/request` waterfall，改写 `LlmCallConfig.reasoningEffort`（关推理 / 调 budget） | `reasoningEffort` |
| **外部思考导出** | 注册 `think` 工具（schema 自动流入请求体）+ `systemPrompt` 注入"先调 think"指令，再从 `llm/stream` 抓回 `thoughts` 参数 | `externalThinking` |
| **流量/包分析** | 挂 `llm/stream` waterfall 拦截每个 chunk，按类型统计 token/字符、捕获 reasoning 与 tool-call 块 | `trafficAnalysis` |
| **会话落盘审计** | 订阅 `session/event` + 命中的流式块，写入 `audit.jsonl` | `persistSession` |

### 外部思考（external thinking）说明

对**明文返回 reasoning 的模型**（DeepSeek 等开源模型），本插件直接从 `llm/stream` 抓 `reasoning` 块，零侵入。

对**加密推理的模型**（OpenAI / Anthropic / Gemini），原生推理被厂商加密藏起。本插件复刻 [oh-my-pi](https://github.com/can1357/oh-my-pi) 的 externalThinking 思路：

1. `reasoningEffort: 'none'` 关掉原生隐藏推理；
2. 注册一个 `think` 工具（description 为 "private scratchpad; not shown to user"），其 schema 经 `ctx.tools.register()` 自动进入发往 LLM 的请求体；
3. 通过 `systemPrompt.section()` 注入"回答任何问题前必须先调用 think"的指令；
4. 模型把推理写进 `think` 的 `thoughts` 参数，本插件在 `llm/stream` 拦截该 tool-call 块并抓回、落盘。

> ⚠️ **与 omp 的差异**：DSH 核心 `LlmCallConfig` 刻意裁剪了 `tool_choice`，因此本插件用 **system prompt 强制** 替代 omp 的 API 层 `tool_choice` 强制。这意味着 think 触发是"软强制"，触发率取决于模型遵循度，不保证 100%。这是上架前需实测验证的已知边界。

## 安装

```bash
dsh plugin --profile <你的profile> add github:cdxiaodong/dsh-llm-inspector
```

## 配置

```yaml
plugins:
  dsh-llm-inspector:
    reasoningEffort: 'none'      # 可选:'none' 关推理,或 adapter 支持的 'low'/'medium'/'high'
    externalThinking: true       # 是否启用 think 导出
    trafficAnalysis: true        # 是否做流量/包分析
    persistSession: true         # 是否落盘审计
    logDir: '.dsh-inspector'     # 落盘目录
    # thinkPrompt: '...'         # 可选,覆盖默认强制提示
```

## 服务

插件对外提供两个 Service（可被其他插件 `inject`）：

- `inspectorTraffic` —— 流量统计：`snapshot()` 返回 `{ calls, chunks, reasoningChars, thinkCalls, thinkChars, byKind }`
- `inspectorAudit` —— 审计：`log(tag, payload)` / `flush()`

## 开发

```bash
npm install
npm run build    # tsc 产出 lib/(已提交进 git,DSH 可直接从 Git 安装)
npm test         # node --test,7 个零依赖测试
```

## 安全与信任声明

按 DSH 社区约定：**GitHub topics 不是安全审核，也不是官方背书**。本插件会拦截并（在开启 `persistSession` 时）落盘你的模型请求/响应内容，其中**可能包含推理过程、代码、甚至凭证**。请：

- 仅在可信环境开启 `persistSession`；
- 注意 `audit.jsonl` 的存储位置与访问权限；
- 安装前自审源码（`src/index.ts`，约 200 行）。

## License

MIT
