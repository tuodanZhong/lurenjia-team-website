# dsh-auto-compact

为 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) 提供**自动上下文压缩**：
每个 agent 步骤用 token 计量对路由请求计价，压力超过配置阈值时，把较早的对话段用对话自身模型
压缩成持久化的 `<compacted-summary>` checkpoint（复用预热前缀缓存），长会话不丢关键上下文。

本插件包装 harness 自带的 token 计量引擎（`@deepseek-ai/dsh-compaction-basic`），额外提供：
**默认更晚触发**、设置卡片、安装文档。

## 为什么「更晚压缩」？

harness 的 pi-ai 提供商对未声明窗口的模型回退到 `DEFAULT_CONTEXT_WINDOW = 262144`（256K）。
默认 `thresholdRatio` 0.8 意味着约 205K tokens 就会压缩——对真实 1M 窗口只有 ~20%。本插件默认
`thresholdRatio: 0.92` 并附窗口修复文档，让大窗口真正被用满。

## 安装

```bash
# profile 目录（C:\Users\<你>\.dsh\profiles\<名字>）
pnpm add -w dsh-auto-compact
# 或从 GitHub：
pnpm add -w dsh-auto-compact@github:lileikeji/dsh-auto-compact
```

把 `dsh-auto-compact` 加进 profile `package.json` 的 `dsh.profile.bundles`，然后**禁用 harness 自带引擎**，
只保留一个压缩引擎：

```yaml
# profile cordis.patch.yml
- id: compaction-basic
  name: '@deepseek-ai/dsh-compaction-basic'
  disabled: true
```

## 窗口配置（重要）

引擎从 LLM 适配器读取模型上下文窗口。若模型未声明窗口（pi-ai 默认 256K），在 `~/.dsh/settings.yaml`
按提供商设置：

```yaml
llm-pi-ai:
  providers:
    my-provider:
      apiKeyEnv: MY_API_KEY
      defaultContextWindow: 1000000   # 模型的真实窗口
```

## 配置（设置卡片）

设置 → 插件 → 自动压缩上下文（auto-compact）：

- `thresholdRatio` — 触发阈值（占上下文窗口比例，默认 `0.92`）。
- `retainRatio` — 原样保留的最近对话比例（默认 `0.12`）。
- `maxTokens` — 摘要输出上限（默认 `8192`）。
- `auto` — 自动压缩开关。

改动在 profile 重启后生效。

## 原理

1. `agent/pre-step`：用 token 计量对最近一次持久化路由请求计价。
2. 若 `总 tokens ≥ thresholdRatio × 上下文窗口`（已知输出预算时按输出感知收缩），选择不拆分工具
   调用/结果对的首部区间，保留最近尾部。
3. 用对话自身模型摘要该区间（逐字回放 system prompt + 工具 + 前序消息以复用 KV 缓存），追加压缩指令。
4. 以 `compaction/start` → 摘要 → `compaction/end` 事务落到会话 surface，后续步骤从 checkpoint 继续。

## License

MIT
