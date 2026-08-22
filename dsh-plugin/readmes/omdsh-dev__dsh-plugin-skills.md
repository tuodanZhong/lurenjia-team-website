# dsh-plugin-skills

[English](README.md) | **中文**

为 **DeepSeek Harness** 插件开发而生的 Agent skills——从零搭建插件包，到选择正确的测试分层，全程在 agent 会话内完成。

## 包含内容

| Skill | 功能 |
|---|---|
| `dsh-write-plugin` | 端到端搭建插件：先选对形态（工具 / LLM 适配器 / hook / 服务 / 配置），再走完包清单（package.json 不变量、tsconfig 注册、README + Model Experience、验证门禁），每种形态配一份自包含的参考文件。 |
| `dsh-test-plugin` | 为插件改动选择正确的测试分层：单元测试、逐文件覆盖率门禁、真实 API e2e、无密钥快照、Web 浏览器快照——以及何时"必须"加快照，含真实入口路径与 built-bin smoke 覆盖。 |

两个 skill **完全自包含**：运行时不需要任何外部文档或其他 skill——所需内容全部写在 skill 内部。

## 安装

将 skill 文件夹复制到项目的 agent skills 目录：

```sh
cp -r dsh-write-plugin dsh-test-plugin <你的项目>/.agents/skills/
```

Claude Code 项目通常把 `.claude/skills` 软链到 `.agents/skills`；如果没有：

```sh
ln -s ../.agents/skills <你的项目>/.claude/skills
```

完成。agent 会自动发现这两个 skill（技能目录会随磁盘变更热刷新）——直接说"帮我写一个插件"或"测试这个插件改动"，或按名字调用即可。

## 适用环境

**可在任意主流 Agent 产品中运行**——skill 就是纯 `SKILL.md` Markdown 目录，不含任何产品特定的胶水代码，只要 agent 能读取技能说明即可使用：Codex、Claude Code、DeepSeek Harness、Cursor、Windsurf、Gemini CLI、GitHub Copilot、Cline、Roo Code、OpenHands、Aider、Devin 等，不限于此。
