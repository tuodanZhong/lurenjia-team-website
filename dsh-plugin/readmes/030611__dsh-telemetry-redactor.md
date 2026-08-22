# DSH Telemetry Redactor

[![CI](https://github.com/030611/dsh-telemetry-redactor/actions/workflows/ci.yml/badge.svg)](https://github.com/030611/dsh-telemetry-redactor/actions/workflows/ci.yml)
[![npm](https://img.shields.io/npm/v/dsh-telemetry-redactor)](https://www.npmjs.com/package/dsh-telemetry-redactor)
[![License](https://img.shields.io/github/license/030611/dsh-telemetry-redactor)](LICENSE)
[![awesome · DSH plugin](https://awesome-dsh-plugin.com/badge.svg)](https://awesome-dsh-plugin.com)
[![featured on dsh-suite](https://img.shields.io/badge/featured%20on-dsh--suite-4d6bfe)](https://whyihaveyou.github.io/dsh-suite/)

[English](README.md) | 中文

![DSH Telemetry Redactor 社交预览图](docs/social-preview.jpg)

**在已配置的遥测后端收到导出副本前，对受支持的凭证模式脱敏，同时不改写规范会话日志。**

```sh
dsh plugin --profile web add dsh-telemetry-redactor
```

> 由社区维护，并非 DeepSeek 官方项目。相关 trust-layer 插件：[Verification Receipt](https://github.com/030611/dsh-verification-receipt)、[Evidence Audit](https://github.com/030611/qiushi-dsh-evidence-audit) 与 [Context Provenance](https://github.com/030611/dsh-context-provenance)。

`dsh-telemetry-redactor` 是一个最小 DeepSeek Harness Profile Bundle，在遥测后端收到记录之前脱敏敏感值。它挂载官方 `session-telemetry/record` waterfall，调用 `next()` 以保持其他部署规则可组合，并返回一份新的递归脱敏记录。

官方 telemetry coordinator 会在进入该 waterfall 之前深拷贝 canonical session event，并逐条隔离规则异常。因此本插件只改变外发副本，绝不改写权威 session log。本文中的 **fail-closed 仅表示该 coordinator 丢弃一条失败的导出副本**，同时 agent loop 继续运行；它不表示所有 telemetry 路径或 listener 顺序都不可绕过。

## 脱敏范围

- 高风险键名下的完整值，例如 `authorization`、`cookie`、`credential`、`password`、`secret`、`token`、`apiKey`、`access_token`、`clientSecret` 与 `privateKey`；键名本身包含已识别凭据模式时也会改写键名。
- 字符串中的 Bearer 与 Basic Authorization 值。
- 常见凭据形式，包括 `sk-...`、GitHub token、Slack token、JWT 三段式字符串，以及 `token=...` / `api_key: ...` 赋值。

插件先对键名分词再匹配，因此 `inputTokens`、`output_tokens`、`tokenUsage`、`tokenCount`、`contextTokenCount` 等遥测计数和 `tokenizer` 等普通字段会保留。脱敏是安全过滤器，不是对所有未知秘密格式均不泄漏的证明。精确支持与不支持边界见 [SECRET-MATRIX.zh.md](SECRET-MATRIX.zh.md)，信任边界见 [SECURITY.md](SECURITY.md)。

监听器以 prepend 方式注册，因此通常会包裹其前后挂载的部署规则，并脱敏这些规则的最终输出。若另一个插件刻意注册更外层的 prepended listener，仍可能在本插件之后加入内容；安全敏感部署必须审查完整 waterfall listener 集合。

## 安装

把公开包安装到选定的 DSH profile，然后检查最终配置：

```sh
dsh plugin --profile web add dsh-telemetry-redactor
dsh --profile web --dump-config
```

配置 dump 必须出现新增的 `telemetry-redactor` 行。本 bundle 不会添加、替换或启用 telemetry backend；它只保护部署已经选择的后端会处理的记录。

## 配置

唯一选项为 `replacement`，默认值是 `[REDACTED]`。长度必须为 1 至 128 个字符，且自身不能命中已支持的凭据模式；非法值在 Cordis plugin fiber 被 await 时响亮失败。

```yaml
- id: telemetry-redactor
  config:
    replacement: '[TELEMETRY-REDACTED]'
```

键名与模式规则属于固定安全行为，不能通过配置关闭。

## 验证

```sh
pnpm run typecheck
pnpm test
pnpm run build
pnpm run test:smoke
pnpm run test:performance
pnpm run test:official-head
pnpm run test:official-patch
pnpm run test:packed:clean-env
```

测试包含真实 Cordis Loader 与 `SessionTelemetryCoordinator` 组合：后端只能收到替换值，权威 session event 仍保留 fixture secret，超深记录会被阻断且异常不会逃出捕获 handler。release smoke 使用随包携带、对应官方 commit `47f943859bef60e4160492346772ded9b24f765a` 的冻结 fixture：它固定已审阅的源码哈希、精确的已发布 runtime 版本与 runtime 文件哈希，随后校验 Cordis/session/LLM/coordinator 所需 API surface，再与构建产物或 tarball 安装产物组合。`test:official-patch` 同样固定已审阅的 Include 源码哈希后应用 `cordis.patch.yml`。不需要环境变量或已安装的官方 checkout。测试不调用模型、不需要 API key、不连接网络 exporter，也不修改 canonical log。

## 模型体验

无。本插件只观察 session log 之后的外发 telemetry 副本，不贡献 prompt、工具 schema、消息或模型请求。

#### KV Cache 影响

无；不会改变任何模型请求。

## 已知限制

- 若未知秘密格式既不位于敏感键下，也不符合已识别字符串模式，可能继续透传。扩展固定规则前应先加入确定性覆盖。
- getter/setter 与非普通对象会被拒绝，而不是被读取或静默改变语义。支持数组、普通对象和 null-prototype 对象中的可枚举 JSON 数据；不可枚举字段不属于 telemetry contract。
- 键名命中后会替换完整值。这一选择优先保障安全，不保留凭据字段下的结构。
- 脱敏在 telemetry 捕获路径同步执行。实现递归且最多处理 64 层容器；很大但较浅的记录仍产生线性 CPU 开销。
- Proxy 的反射 trap 可能在插件检查内容前执行或抛错。官方 coordinator 的 `structuredClone` 通常会先拒绝 Proxy；恶意第三方直接分发不属于支持的隔离边界。
- `dsh.plugin.json` 是补充社区元数据。DSH 安装以 `package.json` 的 `dsh.bundle` 字段和 `cordis.patch.yml` 为准。

## 许可证

MIT
