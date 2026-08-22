# dsh-redact · DSH / DeepSeek Harness 密钥与 PII 脱敏插件

[![License](https://img.shields.io/github/license/dingge001/dsh-redact)](LICENSE)
[![Node.js](https://img.shields.io/badge/Node.js-22.19%2B-brightgreen)](#安装)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.8-3178C6)](#开发)
[![DSH](https://img.shields.io/badge/DSH-plugin-8A2BE2)](https://github.com/deepseek-ai/deepseek-harness)

中文 | [English](#english)

dsh-redact 是 DeepSeek Harness（DSH）的**运行时、源头、可逆、可代填执行**的密钥 / PII 脱敏插件。它在数据进入「模型」与「canonical 会话日志」之前完成处理，保持 DSH 的「模型可见即已记录」不变量：模型看到什么，日志就记录什么——但都已经是脱敏后的内容。

- **Mask 模式**：不可逆，把命中值替换成 `[REDACTED:<type>]`；
- **Vault 模式**：可逆，把命中值入库后替换成 `[VAULT:redact:<id>]`，日志与模型只见 token，另提供离线恢复 API；
- **执行时代填**：`vault_write` / `vault_run` / `vault_request` 三个工具在内部解析 token 后执行副作用，让 Agent 在「看不到明文」的前提下安全使用密钥。

如果你正在找「DSH 插件」「DeepSeek Harness 密钥脱敏」「LLM 敏感信息 / PII 掩码」「可逆 secret vault」，这个仓库就是干这件事的。

## 效果

用户输入（含百炼 / 火山引擎等 API key）：

```
我在百炼申请的 key 是 sk-xxxxxxxxxxxx  怎么配到 codex 呀
```

- Mask 模式：

```
我在百炼申请的 key 是 [REDACTED:secret]  怎么配到 codex 呀
```

- Vault 模式（轨迹、模型、日志只出现 token，真值单独写入 vault）：

```
我在百炼申请的 key 是 [VAULT:redact:xxxx]  怎么配到 codex 呀
```

## 功能

### 源头拦截

脱敏发生在数据进入模型与日志之前：

| 挂载点 | 处理对象 |
| --- | --- |
| `agent/pre-step` | 进入会话的用户消息 |
| `tools/post-execute` | 工具执行结果（命令输出、文件内容、API 响应） |
| `session-telemetry/record` | 外发遥测副本（**永远不可逆 mask**，绝不外泄可逆 token） |

### Mask 脱敏

内置规则：

- **密钥**：`sk-*`、AWS Access Key、Google API Key、JWT、PEM 私钥、Bearer / Basic token、`KEY=value` 赋值；
- **PII**：中国手机号、身份证（含校验位）、邮箱、IPv4。

支持按类型开关、自定义替换符、白名单跳过、重叠命中去重（密钥优先于 PII）。

### Vault 可逆

- token 形式：`[VAULT:redact:<id>]`，同一明文去重返回同一 token；
- 存储后端：`memory`（会话内）与 `file`（默认）；
- 文件默认路径：`$DSH_HOME/vault/redact.json`（未设置 `DSH_HOME` 时为 `~/.dsh/vault/redact.json`），目录 `0700`、文件 `0600`（POSIX）；
- `failMode: closed`（默认）：Vault 写入失败直接报错，不放明文；`failMode: open`：失败项退化为不可逆 mask。

### 执行时代填

Vault 模式下自动注册三个工具：

| 工具 | 作用 |
| --- | --- |
| `vault_write` | 把 token 对应的真值写入文件（支持 `raw` / `json` / `env` 三种格式） |
| `vault_run` | 解析命令与环境变量中的 token 后执行 shell 命令 |
| `vault_request` | 解析 URL / headers / body 中的 token 后发起 HTTP 请求 |

三个工具返回前都会对输出二次脱敏：即使子进程或 HTTP 响应回显了真值，模型和日志也不会看到明文。工具未解析到 token 时 fail-closed 报错，不会发送占位符。

同时暴露**只读** Vault 服务给第三方工具：

```ts
const value = await ctx.redactVault.resolve('[VAULT:redact:<id>]')
const plain = await ctx.redactVault.restore(redactedText)
```

第三方工具可以在自身内部解析 token、执行副作用、只返回摘要，复用同一套 Vault。

### 能力对齐，不削弱 Agent

- `vault_write` 走 `ctx.fs`：继承部署的 filesystem provider / policy（与普通写文件工具一致）；
- `vault_run` 走 `ctx.shell`：与 bash 工具同一执行 seam，超时、沙箱策略、executor 选择完全一致；
- `vault_request` 使用进程 HTTP transport：默认不设主机白名单，与现有 egress 能力一致。

## 与其他方案对比

| 方案 | 定位 | 检测 | 拦截位置 | 可逆 / 代填 | DSH 原生 |
| --- | --- | --- | --- | --- | --- |
| **dsh-redact** | DSH 运行时插件 | 密钥规则 + 中文 PII | 数据进入模型与日志前（hook 层） | ✅ Vault 可逆 + 三个执行时代填工具 | ✅ |
| [gitleaks](https://github.com/gitleaks/gitleaks) | 仓库历史扫描 | 海量规则库 | 事后扫描，不拦截模型流量 | ❌ | ❌ |
| [Microsoft Presidio](https://github.com/microsoft/presidio) | PII 识别 / 匿名化库 | 可插拔 recognizer | 应用自行接入 | 可选 deanonymizer | ❌ |
| [secretgate](https://github.com/secretgate/secretgate) | 外部安全代理 | 密钥扫描 | 请求出口代理层 | 代理侧恢复 | ❌（进程外） |

## 配置

```yaml
- id: redact
  name: 'file:///E:/path/to/dsh-redact/src/index.ts'  # 或 npm 包名，见下文安装
  config:
    mode: vault               # mask | vault
    secrets: true
    pii: [phone, idcard, email]
    replacement: '[REDACTED]'
    allowlist: []
    failMode: closed          # closed | open
    vault:
      backend: file           # file | memory
      # path: /absolute/path/to/vault.json
      # 不写则默认 $DSH_HOME/vault/redact.json
```

| 字段 | 说明 | 默认 |
| --- | --- | --- |
| `mode` | `mask` 不可逆 / `vault` 可逆 | `mask` |
| `secrets` | 是否启用密钥检测 | `true` |
| `pii` | 启用的 PII 类型：`phone` / `idcard` / `email` / `ipv4` | `[phone, idcard, email]` |
| `replacement` | 自定义占位符；默认值会展开为 `[REDACTED:<type>]` | `[REDACTED]` |
| `allowlist` | 命中值包含这些子串就跳过（大小写不敏感） | `[]` |
| `failMode` | Vault 失败时 `closed` 报错 / `open` 回退 mask | `closed` |
| `vault.backend` | `file` / `memory` | `file` |
| `vault.path` | 文件后端路径，建议用绝对路径 | `$DSH_HOME/vault/redact.json` |

## 安装

### 方式一：GitHub 源码安装（当前推荐）

需要 Node.js ≥ 22.19 与 pnpm：

```sh
git clone https://github.com/dingge001/dsh-redact.git
cd dsh-redact
pnpm install
pnpm test          # 应全部通过
```

然后把插件按**绝对路径**挂进 web profile 的 `$DSH_HOME/profiles/web/cordis.patch.yml`：

```yaml
- insert:
    - id: redact
      # Windows
      name: 'file:///E:/path/to/dsh-redact/src/index.ts'
      # macOS / Linux
      # name: 'file:///home/you/dsh-redact/src/index.ts'
      config:
        mode: vault
        secrets: true
        pii: [phone, idcard, email]
        failMode: closed
        vault:
          backend: file
          # 默认 $DSH_HOME/vault/redact.json
```

重启：

```sh
dsh web
```

### 方式二：npm（发布后）

发布后直接按包名安装：

```sh
dsh plugin --profile web add <你的 npm 包名>
```

装完重启 `dsh web` 即可。

### 验证与卸载

- 重启后 Web UI「设置 > 插件」应能看到 `redact`；
- 发一条包含 `sk-` key 的消息，输入框 / 轨迹应变成 `[VAULT:redact:xxxx]`（mask 模式为 `[REDACTED:...]`）；
- 可用 `dsh web --dump-config` 确认配置层已挂载。

卸载：从 `cordis.patch.yml` 删除 `redact` 条目并重启；npm 方式则执行 `dsh plugin --profile web remove <包名>`。

## 使用示例

### 恢复明文（非模型 API）

```ts
import { openVault, restoreText } from 'dsh-redact'

const vault = await openVault({ backend: 'file', path: '/absolute/path/to/vault.json' })
const plain = vault.restore(redactedText)
await vault.close()

// 或一次性便捷函数
const plain2 = await restoreText(redactedText, { backend: 'file', path: '/absolute/path/to/vault.json' })
```

### 纯逻辑层直接调用

```ts
import { redact, redactVault, openVault } from 'dsh-redact'

const masked = redact('api_key=sk-...', {
  mode: 'mask',
  rules: { secrets: true, pii: ['email'] },
  replacement: '[REDACTED]',
  allowlist: [],
})

const vault = await openVault({ backend: 'memory' })
const tokenized = await redactVault('api_key=sk-...', {
  mode: 'vault',
  rules: { secrets: true, pii: ['email'] },
  replacement: '[REDACTED]',
  allowlist: [],
  failMode: 'closed',
}, vault)
```

## 安全边界

- 插件降低数据泄露面，但**不是**对抗恶意模型的完整边界；
- `vault_run` 给模型 shell 执行权、`vault_request` 可把真值发送到任意 URL：模型看不到真值，但能诱导外发；如需收紧可自行加 egress / sandbox 策略；
- Vault 文件权限只挡其他 OS 用户，不挡同 UID 的模型进程；更强隔离需 OS keychain。

## 开发

```sh
pnpm install
pnpm test         # node --test
pnpm typecheck    # tsc --noEmit
```

```text
src/
├─ index.ts            # API 导出
├─ policy.ts           # redact / redactMask / redactVault / detectMatches
├─ token.ts            # [VAULT:redact:<id>] 词汇
├─ vault.ts            # memory / file backend + restoreText
├─ tools.ts            # 三个代填工具的参数与 facade 类型
├─ vault-actions.ts    # vault_write / vault_run / vault_request handler
├─ detect/             # 密钥 / PII 检测
├─ redact/             # mask 替换
└─ hooks/              # pre-step / post-execute / telemetry / 注册入口
```

本项目为纯 TypeScript 逻辑层，零运行时依赖：可独立作为库使用和测试，挂进 DSH 后由 hooks 自动生效。

## 许可

[MIT](LICENSE)

## 参考

- DeepSeek Harness：https://github.com/deepseek-ai/deepseek-harness
- 官方插件开发指南：https://deepseek-harness.github.io/deepseek-harness/develop/basic/
- gitleaks：https://github.com/gitleaks/gitleaks
- Microsoft Presidio：https://github.com/microsoft/presidio
- secretgate：https://github.com/secretgate/secretgate

---

## English

dsh-redact is a runtime, source-level redaction plugin for DeepSeek Harness (DSH). It detects secrets and PII before data enters the model or the canonical session log, and supports:

- **Mask mode** — irreversible `[REDACTED:<type>]` placeholders;
- **Vault mode** — reversible `[VAULT:redact:<id>]` tokens with offline restore;
- **Execution-time substitution** — `vault_write` / `vault_run` / `vault_request` let the agent use a secret without ever seeing the plaintext.

In vault mode, tool and HTTP outputs are redacted a second time, so even if a subprocess echoes the real value, the model and session log never see it. A read-only `ctx.redactVault` service lets third-party tools resolve tokens and perform side effects on their own.

**Keywords:** DeepSeek Harness, DSH plugin, secret redaction, secret scanning, PII masking, data loss prevention, LLM security, secret vault, AI agent security.

See the Chinese sections above for configuration, installation, and API details.