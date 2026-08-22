# dsh-opencode

一个 30 行(NOPE，现在变成130行的屎山了)的本地反向代理,解决 OpenCode Zen 免费模型(`deepseek-v4-flash-free` 等)在第三方客户端报 `429 FreeUsageLimitError` 的问题。

## 背景

OpenCode Zen 的免费模型仅限 opencode 自家客户端使用:网关通过 User-Agent 指纹(请求头中必须包含 `opencode` 字样)识别客户端,第三方客户端(Claude Code、DeepSeek Harness、自定义脚本等)直接请求会收到:

```
429 FreeUsageLimitError: Rate limit exceeded. Please try again later.
```

`dsh-opencode` 在本地起一个 OpenAI 兼容的代理端口,把每个请求转发到 `https://opencode.ai/zen/v1`,并强制注入 opencode 客户端的 User-Agent 和 `x-opencode-*` 请求头,让任意 OpenAI 兼容客户端都能使用 Zen 网关。

## 原理

| 项 | 说明 |
|---|---|
| 客户端指纹 | User-Agent 必须包含 `opencode`(大小写不敏感);`x-opencode-*` 头单独不够,UA 单独就够 |
| 注入的 UA | `opencode/1.18.18 ai-sdk/provider-utils/4.0.38 runtime/bun/1.3.14` |
| 注入的头 | `x-opencode-client: cli`、`x-opencode-project: global`、`x-opencode-session`、`x-opencode-request` |
| 兼容性 | 接受 `max_tokens` / `max_completion_tokens`、`developer` 角色、`thinking` + `reasoning_effort`(free 模型也返回 `reasoning_content`) |

## 快速开始

要求:Node.js 18+。

```bash
# 1. 启动代理(默认端口 8787)
node zen-proxy.js

# 2. 验证
curl http://127.0.0.1:8787/v1/models
```

设置环境变量 `ZEN_PROXY_VERBOSE=1` 可打印每个请求的摘要日志(模型名、reasoning 参数、工具数等)。

## 自动写入 DeepSeek Harness 配置

Zen 网关统一接受 `reasoning_effort`(low/medium/high/max)并自行映射到各上游模型,但 DSH 只会为 `settings.yaml` 里声明了 `reasoningEfforts` 的模型显示 reasoning 选项。运行:

```bash
node zen-proxy.js dsh
```

会实时抓取 Zen 模型列表,并自动写入 `~/.dsh/settings.yaml`(替换 `llm-pi-ai.providers.zen` 下的 `models:` 和 `compat:`,保留 `apiKeyEnv`、`baseURL`、其他 provider 及全部无关配置;写入前自动备份为 `settings.yaml.zenproxy.bak`)。之后所有 Zen 模型在 DSH 中都有 reasoning efforts 选项。

- 配置目录通过环境变量 `DSH_HOME` 指定,默认 `~/.dsh`
- `node zen-proxy.js dsh --print` 只打印配置块,不写入
- 重复运行幂等(无变化时不写入、不备份);DSH 运行中写入后无需重启,下次请求自动生效

## 接入客户端

在任意 OpenAI 兼容客户端中:

- **Base URL**: `http://127.0.0.1:8787/v1`
- **API Key**: Opencode Zen  Key(`sk-...`)
- **模型**: `deepseek-v4-flash-free` 等 Zen 免费模型 (付费模型可用性尚未测试)

### 示例:DeepSeek Harness(DSH)

在 `~/.dsh/settings.yaml` 中:

```yaml
llm-pi-ai:
  providers:
    zen:
      apiKeyEnv: ZEN_API_KEY      # 从 credentials 或环境变量解析
      api: openai-completions
      baseURL: http://127.0.0.1:8787/v1
      models:
        - id: deepseek-v4-flash-free
```

### 示例:curl

```bash
curl -X POST http://127.0.0.1:8787/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ZEN_API_KEY" \
  -d '{"model":"deepseek-v4-flash-free","messages":[{"role":"user","content":"hi"}]}'
```

> Windows PowerShell 下用 `curl.exe` 且 JSON 请写入文件后以 `--data-binary @file` 传入,避免引号转义问题。

## 注意事项

- 该方案绕过的是"仅限 opencode 客户端"的客户端校验,**可能造成Opencode Zen Key被封禁**(实测下来概率几乎为0)，请仅用于个人学习研究,遵守 Opencode 服务条款
- 代理不存储任何请求/响应数据,key 由各客户端自行透传

## License

MIT
