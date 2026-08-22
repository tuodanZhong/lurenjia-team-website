# dsh-tiered-approval

**自动放行安全的，拦下不可逆的，拿不准的问人。** 为 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)（DSH）写的分级自动审查插件。

🛡️ 静态规则安全网 · 🤖 LLM 审查员 · 🙋 人工兜底

[![npm](https://img.shields.io/npm/v/dsh-tiered-approval)](https://www.npmjs.com/package/dsh-tiered-approval)
[![license](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![ci](https://github.com/Elaina-real/dsh-tiered-approval/actions/workflows/test.yml/badge.svg)](https://github.com/Elaina-real/dsh-tiered-approval/actions/workflows/test.yml)

> [!WARNING]
> 纯 vibe coding 产物：**未经安全审计、与 DeepSeek 官方无关、不提供担保**。把关的是安全决策，请当**起点而非信任边界**——用前读一遍 [`lib/index.js`](lib/index.js)，按自己的威胁模型调规则，在真正在意的事情上保留人工兜底。

## Overview

DSH 原生只有「每次越界都弹窗」和「全放权」两个极端。本插件在中间加一道三层裁决，让每个工具调用在真正执行前经过：

1. **静态规则**（零成本、确定性）：内置危险命令安全网 + 配置的 `deny`/`allow` 正则。不可逆操作（递归删除、格式化、强推 git、写系统目录、杀进程）→ **直接拒绝，不弹窗也不调模型**。
2. **LLM 审查员**（默认开）：规则未裁决的调用交给模型判 `allow`/`deny`/`ask`。审查帧包含最近一条用户消息，供意图对齐。
3. **人工兜底**：`ask` 或审查不可用时弹原生确认框。

**省事档 `autoApproveAligned`**（默认开）：审查判 allow **且**用户明确指令高度对齐该调用 → 免弹窗自动放行（含 `danger-full-access` 常规操作）。**`alignDeny`**（默认关）：静态 deny 命中的不可逆操作若用户明确点名要做，降级为弹人工一眼确认而非硬拒。两者共用**意图对齐**检查（轻量 LLM 判断，用户消息缺失/无关/存疑一律判不对齐，保守优先）。

审查强度自动跟随 Access 选择器（read-only / workspace-write / danger-full-access）。门禁结论打在 callId 印记上，由审批应答者兑现一次性授权（`allowed-once`）。

**适合**：read-only 会话频繁升权做常规操作、不想每下都点批准的人。**不省力**：长期开 workspace-write / Full access 时升权请求几乎不产生，插件基本静默。

## Compatibility

| 项 | 说明 |
| --- | --- |
| DSH 版本 | `@deepseek-ai/dsh` `0.1.0-rc.6`；2026-08 验证（`npm test` 96 项 ALL PASS + 真实 DSH web 端到端实测） |
| 平台 | Windows（pwsh 规则集，实测）；POSIX（bash 规则集，理论兼容，未实测） |
| 依赖 | `@deepseek-ai/cordis` ^4.0.1、`@deepseek-ai/schemastery` ^3.18.1、`@deepseek-ai/dsh-llm` ^0.1.0-rc.6、`@deepseek-ai/dsh-timeout` ^0.1.0-rc.6 |

## Install / Uninstall

```sh
dsh plugin --profile web add dsh-tiered-approval          # 安装（npm 发布后）；本地开发用 add ./dsh-tiered-approval
dsh plugin --profile web add dsh-tiered-approval@latest   # 升级
dsh plugin --profile web remove dsh-tiered-approval       # 彻底移除（监听器随 fiber dispose）
```

- **手动兜底**（无 pnpm）：整个目录拷到 `~/.dsh/profiles/<profile>/node_modules/dsh-tiered-approval`，并在 profile 的 `cordis.patch.yml` 里 `- insert:` 挂载行。
- **临时禁用**：bundle 行加 `disabled: true`，重启。
- **注意**：插件代码在 node_modules，**HMR 不追踪**——改代码必须重启；验证安装用 `dsh --profile web --dump-config`（应出现 `# == dsh-tiered-approval` 层）。

## Quick start

最小配置就是默认配置——装完重启即生效：

```yaml
# ~/.dsh/profiles/<profile>/cordis.patch.yml
- insert:
    - id: tiered-approval
      name: 'dsh-tiered-approval'
```

验证三步：① 插件清单出现 `tiered-approval`；② 进程日志出现 `[auto-approval]` 决策行；③ 试一次「升权 + `Remove-Item ... -Recurse -Force`」→ 被直接拒绝且不弹窗（静态安全网生效）。

## Configuration

全部可选，省略即用默认值：

```yaml
config:
  builtinDeny: true              # 内置危险命令安全网总开关（建议永远别关）
  deny: []                       # 追加硬拒绝规则 { tool, where:{参数:[正则]}, escalating?, reason? }
  allow: []                      # 追加自动放行规则（门禁打 allow 印记，配合应答者生效）
  log: true                      # 每次自动决策写进程日志 [auto-approval] 行
  answerer:                      # 审批应答者（文本规则层）
    allowModes: ['workspace-write']   # 可自动批准的升权模式
    allowJustifications: []      # 升权理由命中这些正则 → 自动批准
    denyJustifications: []       # 理由命中 → 自动拒绝（优先于 allow）
  review:                        # LLM 审查层（默认开）
    mode: 'on'                   # 'off' = 纯规则版
    provider: ''                 # 显式审查路由（与 model 成对，可选）
    model: ''                    # 缺省自动跟随会话当前模型（request/header），开箱可用；
                                 # 会话模型不可得时才兜底第一个 provider 的第一个模型
    skipTools: [read, read_image, glob, grep, web_search, job_output, job_list,
                job_kill, ask_user_question, todo_write, list_agents, interrupt_agent]
    skipNested: true             # 跳过 run_code 子分发（只审查外层）
    allowModes: ['workspace-write']   # 审查员可自动批准的升权模式
    onUncertain: 'ask'           # 'ask'（默认，留人工）| 'deny'（不确定一律拒绝，fail-closed）
    alignDeny: false             # 静态 deny 命中时做意图对齐：用户明确点名该操作 → 降级 ask
    autoApproveAligned: true     # 省事档：审查 allow + 用户指令对齐 → 免弹窗放行（含 danger-full-access）
    timeoutMs: 20000             # 单次审查超时
    maxTokens: 2048              # 审查输出 token 上限（太小易截断 JSON → 审查失败）
    maxInputChars: 12000         # 输入帧截断
    perMode: {}                  # 按沙箱模式覆盖 mode/allowModes/skipTools
```

- **规则字段**（`deny`/`allow` 共用）：`tool`（工具名或 `*`）、`where`（参数点路径 → 正则列表，都命中才匹配）、`escalating`（只匹配带 `sandbox_permissions` 的调用）、`reason`。正则大小写不敏感，YAML 反斜杠写双份（`\\s`），**加载期校验，写错拒绝加载**。
- **perMode 跟随 Access**：Full access 下默认全量审查（沙箱不隔离，审查是最后防线）；Full access 预设同时把审批策略设为 `never`，此时审查员 `ask` 变成确定性拒绝——要人工兜底就别切 Full access。
- **安全锁**：静态 deny 永远先截住不可逆操作，不进入省事档路径；allow 与对齐缺一不可自动放。对齐只在「升权目标不在 allowModes」时检查，其余直接 review-allow（不白烧 LLM 调用）。
- **环境变量**：无。**敏感项**：开启审查时，工具完整参数 + 最近一条用户消息会发给审查模型（缺省跟随会话当前模型）。

## Permissions & data

| 内容 | 说明 |
| --- | --- |
| 读取 | 每个工具调用的完整参数（命令、路径、升权理由等）——门禁内读，仅用于裁决，不落盘 |
| 发送给模型 | 审查帧（工具名、参数、沙箱模式/工作区根、最近一条用户消息）——**可能含敏感文本，请知情** |
| 网络 / 凭据 / 写入 | 无独立网络（走 DSH `ctx.llm`）；不读不存凭据；不写文件；不写 session 事件（仅插件日志 `[auto-approval]`） |

## Troubleshooting

日志统一走 dsh 进程日志，`grep "[auto-approval]"` 定位哪一层做的决定；运行时 `/auto-review status` 看决策计数与最近决策——**审查失败直接显示根因**（如 `finish=max-tokens`、`stream failed: 400: ...`、`unparseable`）。

| 症状 | 排查 |
| --- | --- |
| 清单没有插件 | 重启；确认包在 node_modules、bundle 行正确；看启动日志 "plugin failed to load" |
| 弹窗变多 / 不自动批 | 查 Access 预设（Full access 下 `ask` 变确定性拒绝）；看 status 的 `allow` 是否带 `auto-approve (aligned):` 前缀 |
| fallback 涨（审查常失败） | 按根因修：`finish=max-tokens` → 调大 `maxTokens`；`stream failed: 400` → 网关拒参数（贴完整错误）；`unparseable` → 换守规矩的模型 |
| 没觉得省力 | 多半常开 workspace-write / Full access（升权请求不产生）；`ask` 高 = 模型太弱，`fallback` 高 = 审查没在干活 |
| 彻底回滚 | `dsh plugin --profile web remove dsh-tiered-approval` + 重启 |

快捷开关（内存态，重启重置）：`/auto-review on|off|rules|tiered|auto|status|reset`。

## Development

无构建步骤（`lib/` 即编译产物，无需 `allowBuilds`）。`npm install && npm test`（期望 "ALL PASS"，96 项断言；`prepublishOnly` 自动跑）。CI 在 push/PR 自动跑（Node 20/22）。Issues / PRs / **安全审计**都欢迎——改代码后务必重跑 `npm test`。

## License & security

[MIT](LICENSE)。未经安全审计，风险自负。报告安全问题：在 [Issues](https://github.com/Elaina-real/dsh-tiered-approval/issues/new) 标注 `security` 或私下联系作者——不要公开披露可利用细节。
