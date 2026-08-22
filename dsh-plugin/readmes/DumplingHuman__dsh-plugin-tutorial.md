# DeepSeek Harness 插件开发教程

> **📖 在线文档站：https://DumplingHuman.github.io/dsh-plugin-tutorial/**

[![Docs](https://img.shields.io/badge/📖-在线文档站-blue)](https://DumplingHuman.github.io/dsh-plugin-tutorial/)
[![GitHub](https://img.shields.io/badge/GitHub-仓库-black)](https://github.com/DumplingHuman/dsh-plugin-tutorial)

从零开始学习为 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)（DSH）开发插件的中文教程：环境搭建、Cordis 基础、第一个 Tool、插件配置、事件系统、LLM 适配器、会话与持久化、后台任务与子代理，以及打包发布。

> DSH 是一个基于 [Cordis](https://github.com/cordiverse/cordis) 的插件化 Agent Harness：**一切皆插件**——模型适配器、工具注册表、会话日志、agent 循环本身都是插件，注册是可逆副作用（effect），换提供方不改模型契约。

## 📚 目录

| 章节 | 内容 | 状态 |
|---|---|---|
| [00-glossary.md](docs/00-glossary.md) | 术语表 | ✅ |
| [01-setup.md](docs/01-setup.md) | 环境搭建与启动 | ✅ |
| [02-cordis-basics.md](docs/02-cordis-basics.md) | Cordis 插件基础 | ✅ |
| [03-first-tool.md](docs/03-first-tool.md) | 开发你的第一个 Tool | ✅ |
| [04-plugin-config.md](docs/04-plugin-config.md) | 插件配置 | ✅ |
| [05-events.md](docs/05-events.md) | 事件系统：DSH 的扩展点 | ✅ |
| [06-llm-adapter.md](docs/06-llm-adapter.md) | 开发 LLM 适配器 | ✅ |
| [07-session.md](docs/07-session.md) | 会话与持久化 | ✅ |
| [08-jobs-subagent.md](docs/08-jobs-subagent.md) | 后台任务与子代理 | ✅ |
| [09-publish.md](docs/09-publish.md) | 打包与发布插件 | ✅ |
| [10-reference.md](docs/10-reference.md) | 参考资源与能力地图 | ✅ |

## 🚀 快速开始

```sh
# 1. 检出 DSH 仓库（前置：Node 22.19+ / 24+，pnpm 11.7.0，Git 2.26+）
git clone https://github.com/deepseek-ai/deepseek-harness.git
cd deepseek-harness
pnpm install
pnpm run typecheck   # 通过即搭建完成

# 2. 配置模型（设置 → 模型，或 DEEPSEEK_API_KEY 环境变量）

# 3. 启动 Web UI
pnpm dsh web

# 4. 打开 http://127.0.0.1:3080，选择工作区，开始对话
```

## 🧩 示例插件

[`examples/greet-tool/`](examples/greet-tool/) 是一个完整可运行的示例：带配置的 `greet` 工具，演示依赖声明（`inject`）、配置（`Config` + Schemastery schema）与工具注册（`defineTool`）三个核心能力。

```sh
# 在 deepseek-harness 仓库根目录
pnpm dsh web --patch /absolute/path/to/examples/greet-tool/cordis.yml
```

## 📖 内容基于

本教程基于 [DeepSeek Harness 官方文档](https://deepseek-harness.github.io/deepseek-harness/)（`/guide`、`/develop`、`/reference` 模块）与仓库源码整理编写，力求与官方实现保持一致；如与官方文档冲突，以官方为准。

## 🤝 贡献

欢迎通过 Issue / PR 完善教程。所有章节文件位于 [`docs/`](docs/)，示例位于 [`examples/`](examples/)。

## 📄 License

[MIT](LICENSE)
