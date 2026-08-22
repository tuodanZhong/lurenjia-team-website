# dsh-model-router

[中英配套主页](./README.md)

[![持续集成](https://github.com/superboy911/dsh-model-router/actions/workflows/ci.yml/badge.svg)](https://github.com/superboy911/dsh-model-router/actions/workflows/ci.yml)
[![版本](https://img.shields.io/badge/version-0.2.2-blue)](./package.json)
[![许可证：MIT](https://img.shields.io/badge/License-MIT-green.svg)](./LICENSE)
[![Node](https://img.shields.io/badge/node-%5E22.19.0%20%7C%7C%20%3E%3D24.0.0-brightgreen)](#运行要求)

`dsh-model-router` 是 DeepSeek Harness（DSH）的薄路由策略插件。模型提供方、凭据、模型目录、模态能力和重试仍由 DSH 管理；本插件只增加确定性的关键词路由、默认关闭的白名单 `model_route` 工具，以及隔离的 `image_gen` 生图通道。

DSH 官方**模型**页面仍是唯一的模型提供方配置入口。

> 当前版本：v0.2.2，已在 DSH 0.1.0-rc.6 验证。`image_gen` 仍为 Beta；视频、音频和 3D 尚未实现。

## 维护者的话

这是我第一次维护开源仓库。我还在学习插件设计、测试、安全、文档和项目维护。当前版本已经可以使用并有自动化测试，但我不会把它包装成成熟或完美的方案；代码里仍可能存在错误、粗糙之处，或者更好的架构选择。

非常欢迎熟悉 DSH、TypeScript、安全、模型路由和技术文档的朋友参与。一个 Issue、一条审查意见、一份复现记录、一次文档修正或一个 Pull Request 都很有价值。提出修改时也欢迎说明原因，让我能跟着一起学习。

- [如何参与](./CONTRIBUTING.zh.md)
- [公开路线图](./ROADMAP.md)
- [社区行为准则](./CODE_OF_CONDUCT.md)

## 能做什么

| 能力 | 实际行为 |
|---|---|
| 原生模型目录 | 读取 DSH 中启用及休眠的提供方，不重复注册文字模型适配器 |
| 关键词规则 | 按顺序匹配、首次命中即停；未命中不改动会话 |
| 子代理路由 | 仅在子代理规则命中并通过校验后安装 DSH 模型选择，插件卸载时清理监听器 |
| 精确校验 | 写入会话模型头之前校验提供方、模型和可选推理强度 |
| `model_route` | 默认关闭，只能切换到明确加入白名单的模型 |
| `image_gen` Beta | 隔离的 OpenAI 兼容生图端点；除本机回环 HTTP 外必须使用 HTTPS，并严格限制结果下载 |
| 无认证媒体 | 凭据引用留空时不会解析凭据，也不会发送 Authorization 请求头 |
| Kimi K3 输出约束 | 仅给 K3 增加提示约束，不猜测、不隐藏、不重标响应块 |
| V1 配置迁移 | 只在内存中迁移，用户明确保存后才持久化 V2 |

插件不会再调用一个模型去“猜”应该选谁，而是执行你在**设置 → 模型中枢**中配置的确定性规则。

## 模型购买策略

示例中的五个模型只是一套兼顾成本的起点，不代表通用排行榜，也不要求贡献者必须购买：

| 模型 | 建议职责 | 成本思路 |
|---|---|---|
| DeepSeek V4 Flash | 默认模型、日常问答、轻量分析 | 优先承接大多数请求 |
| DeepSeek V4 Pro | 架构、复杂推理、重要审查 | 只把高难任务升级过去 |
| Kimi K3 | 产品设计、前端方向、视觉与内容策划 | 设计类关键词命中时调用 |
| Qwen3.7 Plus | 代码实现、结构化工具工作、工程任务 | 编码和执行型任务按需调用 |
| 豆包 Seedream 5.0 Lite | 只负责生图 | 明确调用工具才产生生图成本 |

原则是“低成本模型做默认、复杂任务定向升级、媒体模型明确调用”。价格和模型可用性会变化，购买前请以各提供方当期官网为准。详细说明见[模型策略与路由边界](./docs/model-strategy.md)。

## 运行要求

- DeepSeek Harness 0.1.0-rc.6
- Node.js `^22.19.0` 或 `>=24.0.0`
- 仅开发或重新构建时需要 pnpm 11

## 从 GitHub 安装

```bash
git clone https://github.com/superboy911/dsh-model-router.git
cd dsh-model-router

# 可选：复现仓库中的构建产物。
corepack enable
pnpm install --frozen-lockfile
pnpm build

# 安装到 DSH web profile。
npm exec @deepseek-ai/dsh -- plugin --profile web add --force "$PWD"
```

安装后重启 DSH Web，再打开**设置 → 模型中枢**。手动启动命令：

```bash
npm exec @deepseek-ai/dsh -- web
```

## Seedream 生图通道

把真实密钥保存在 DSH Credentials 中，引用名使用 `VOLCENGINE_ARK_API_KEY`；不要把密钥值写进仓库。

```yaml
model-router:
  mediaProviders:
    - id: volcengine-seedream
      name: 豆包 Seedream 5.0 Lite
      capabilities: [image_gen]
      adapter: openai-images
      baseUrl: https://ark.cn-beijing.volces.com/api/v3
      credential: VOLCENGINE_ARK_API_KEY
      models:
        - doubao-seedream-5-0-lite-260128
      allowedResultHosts:
        - ark-acg-cn-beijing.tos-cn-beijing.volces.com
      defaultSize: 1920x1920
```

会话头显示的是负责调度工具的文字模型，`image_gen` 工具结果才记录真正的生图提供方和模型。

## 路由示例

```yaml
model-router:
  schemaVersion: 2
  enabled: true
  matchCase: false
  rules:
    - id: architecture-review
      enabled: true
      keywords: [架构, 重构, architecture, refactor]
      target:
        provider: deepseek-official
        model: deepseek-v4-pro
        reasoningEffort: high
  agentSwitch:
    enabled: false
    allow: []
```

未命中不改动会话：继续使用当前手动选择，或由 DSH 默认模型接管。

## 开发与验证

```bash
corepack enable
pnpm install --frozen-lockfile
pnpm test
pnpm check:secrets
pnpm build
pnpm pack:dry
```

`accept:models` 会真实调用外部模型并可能产生费用，因此不会在持续集成中运行。

## 文档

- [配置参考](./docs/configuration.zh.md) · [English](./docs/configuration.md)
- [架构说明](./docs/architecture.zh.md) · [English](./docs/architecture.md)
- [模型策略](./docs/model-strategy.md)
- [脱敏示例](./examples/providers.example.json)
- [安全策略](./SECURITY.zh.md) · [English](./SECURITY.md)
- [参与贡献](./CONTRIBUTING.zh.md) · [English](./CONTRIBUTING.md)
- [更新记录](./CHANGELOG.zh.md) · [English](./CHANGELOG.md)
- [MIT 许可证](./LICENSE) · [非正式中文译文](./LICENSE.zh-CN.md)

## 安全边界

- 不得提交密钥、DSH 设置、签名媒体地址、本机绝对路径或生成产物。
- 媒体 API 端点必须使用 HTTPS；只有本机回环开发端点可以使用 HTTP。
- 生图结果必须使用 HTTPS，并经过域名、重定向、DNS、大小和文件魔数校验。
- 设置页可以看到凭据引用名，但看不到凭据值。
- 仓库公开后 CodeQL 工作流会运行；私有仓库需要另行启用 GitHub Advanced Security，本项目不会自动开启该功能。

疑似漏洞请通过 [GitHub Security Advisories](https://github.com/superboy911/dsh-model-router/security/advisories/new) 私下报告。
