# dsh-memory

[English](README.md) | [中文](README.zh.md)

一个用于 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) 的**持久、可由模型读写的记忆 / 笔记库**插件。它让 Agent 拥有一等公民的"跨会话仍能记住"的能力：持久写入、取回、检索自己想存的事实。这正是一般的历史对话检索、`todo_write`、运维配置和静态技能文档都不覆盖的空白。

这是社区版 `dsh-plugin`：一个可安装的 Cordis bundle，以纯 ESM JavaScript（`index.js` + `index.d.ts`）发布，因此从 git 或 npm 安装都**无需构建步骤**。

记录存储在一个 **storage domain**（`dsh_memory`）里，走内置的 `ctx.storageDomain` 能力缝——**不是**手写的文件——从而能持久化到部署方配置的后端（json/sqlite），并发出 `domain/changed` 事件供实时 UI 使用。

## 为什么它不冗余

| 已有能力 | 与 dsh-memory 的区别 |
|---|---|
| `session_search` / `session_event_*` | 只能**读**历史对话，不能存储持久事实 |
| `todo_write` | 任务状态跟踪，不是知识 |
| `settings` / `credentials` | 运维配置，不是模型可写的知识 |
| `skills` | 静态文档，模型不能写入 |
| `goal` / `schedule` | 目标 / 提醒，不是知识库 |
| MCP memory server | 需要外部服务/账号；这是内置轻量方案 |

## 工具

| 工具 | 用途 |
|---|---|
| `memory_set` | 在稳定 key 下持久地（覆盖式）存一条事实/笔记，可带标签。 |
| `memory_get` | 按 key 读取一条；省略 key 时列出全部。 |
| `memory_delete` | 按 key 删除一条（幂等）。 |
| `memory_search` | 对 key/value/tags 做不区分大小写的子串检索，也可按必需标签过滤。 |

## 示例

```
用户: 以后这个项目不要动 public/ 目录。
模型: memory_set key="project/convention" value="不要修改 public/" tags=["project","rule"]
      → [memory] saved "project/convention" (2 tags)

（下一个会话）
用户: 继续那个项目。
模型: memory_get key="project/convention"  → "不要修改 public/" → 据此工作
```

## 安装

安装进某个 Harness profile。以源码签出为例：

```sh
dsh plugin --profile web add ./dsh-memory
```

或从本仓库安装（无需构建步骤——包自带 JS）：

```sh
dsh plugin --profile web add github:Amengclass/dsh-memory
```

> 存储后端由你的部署方提供（web profile 默认挂载 `@deepseek-ai/dsh-storage-json`，`backend: json`）。本插件只声明一个 storage **domain**，因此无需改动后端。

## 配置

以 Schemastery 校验的 `config`，可在你的 profile patch 中覆盖：

| 键 | 默认值 | 含义 |
|---|---|---|
| `domainName` | `dsh_memory` | storage domain 名称（须匹配 `/^[a-z][a-z0-9_]*$/`）。 |
| `maxItems` | `1000` | 存储条数硬上限。 |
| `maxKeyLength` | `120` | key 最大长度；超长拒绝写入。 |
| `maxValueLength` | `10000` | 存储值最大长度；超长拒绝写入。 |

```yaml
- insert:
    - id: dsh-memory
      config:
        maxItems: 500
```

## 依赖与许可

- 运行时 peer 依赖（由 harness 自身的 node_modules 提供）：`@deepseek-ai/dsh-storage-domain`、`@deepseek-ai/dsh-tools`、`@deepseek-ai/schemastery`、`zod`。
- 无运行时构建工具链；无 Node 原生扩展。
- 使用 MIT 许可——见 [LICENSE](LICENSE)。

## 贡献 / 话题

发布在 `dsh-plugin` [GitHub 话题](https://github.com/topics/dsh-plugin) 下。欢迎 PR 与 issue。
