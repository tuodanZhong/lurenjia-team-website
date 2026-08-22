# obsidian-knowledge-mode

面向 Obsidian 的「知识系统模式」——DeepSeek Harness (DSH) 的 agent preset 包。它把一套经过真实使用验证的**底层上下文系统**封装成可安装的模式：日常思考、情感关系、工作判断、学习结论统一存储，按语义连接、越用越密。

> 核心主张：**知识系统的价值不来自你存了多少，而来自你能记住、能复用、能更新的那一小部分。** 你的知识库不属于任何 AI——带着它，任何模型都能很快了解你。详见 [docs/PHILOSOPHY.md](docs/PHILOSOPHY.md)。

## 快速开始

- **从 0 开始**：[docs/QUICKSTART.md](docs/QUICKSTART.md)——30 分钟上手，不需要先有知识库。
- **理解为什么**：[docs/PHILOSOPHY.md](docs/PHILOSOPHY.md)——反收藏夹、二八提炼、环、AI-native 的语义组织。
- **看真实用法**：[examples/](examples/)——不同人用这套系统管理了什么。

## 不同人有不同用法

这套系统不挑领域。作者用它管理情感关系（见 [examples/01-emotional-patterns](examples/01-emotional-patterns/)）；你也可以用它管理职业判断、学习认知、创作灵感、健康习惯——**任何你在乎、想持续理解的东西**。你的领域案例就是最好的文档，欢迎[贡献](CONTRIBUTING.md)。

## 包含什么

| 组件 | 作用 |
|---|---|
| **wrap** | 对话收口：显式触发后压缩为高密度摘要，不存全文；展示候选 Context/Claim 供确认 |
| **insight-refinery** | 连点成环：把突如其来的灵感与已有 Context/Memory 连成环，消化才算掌握 |
| **judgment-duel** | 判断力对打：收敛即高置信，分歧即下钻；隔离 red-team 与 defense |
| **vault-audit** | 结构周检 + 月度语义巡视（只读） |
| **red-team / defense / researcher / verifier** | 四个只读角色代理：攻击、钢人化、外部研究、换路复查 |
| **Source Gate Hook** | 外部来源写入的机械护栏：不确定是否保存原文就不写入 |
| **AGENTS.md 规则** | 知识分层、写入纪律、检索护栏的完整协议 |

## 安装

前置要求：DeepSeek Harness (DSH)。

分三层安装，按需选择。**第一层是所有人必装的**（骨架 + 4 个 Skill）；第二层启用判断力对打；第三层启用写入保护。

### 第一层：核心安装（必装，约 5 分钟）

1. **复制骨架**——本仓库的目录结构、schema 和模板（骨架是这套系统的地基，几乎所有人都需要它）：

```bash
cp -R starter-template /path/to/your-new-vault
```

骨架已包含完整目录结构、schema 和模板，见 [starter-template/README.md](starter-template/README.md)。

2. **安装 preset**——把模式放进 DSH 用户 preset 根目录：

```bash
mkdir -p ~/.dsh/.agent-presets
cp -R config/.agent-presets/obsidian-knowledge-mode ~/.dsh/.agent-presets/
```

3. **安装 4 个 Skill**——放入你的 Vault：

```bash
cp -R skills/* /path/to/your-new-vault/.agents/skills/
```

4. 新建会话，选择预设 `obsidian-knowledge-mode`。

> 完成这一步，`wrap`（收口）、`insight-refinery`（连点）、`vault-audit`（审计）立即可用。

### 第二层：判断力安装（启用 judgment-duel）

`judgment-duel` 强依赖 `red-team` 和 `defense` 两个只读子代理——**没有它们，对打无法运行**。要玩判断力对打，必须装角色代理：

```bash
cp -R agents/* /path/to/your-new-vault/.codex/agents/
```

> 这同时启用了 `researcher`（外部调研）和 `verifier`（换路复查）。

### 第三层：进阶安装（可选）

**Source Gate**（外部来源写入保护）：把 `hooks/source_gate_hook.py` 放入 Vault 的 `.codex/hooks/`，并按 `hooks/hooks.json` 注册。**注册前把 `hooks.json` 里的 `<VAULT_ROOT>` 替换成你的 Vault 绝对路径**，并设置环境变量：

```bash
export VAULT_ROOT="/path/to/your-new-vault"
```

> 注意：`hooks.json` 的 `command` 字段不走 shell 展开，`<VAULT_ROOT>` 必须手动替换为实际路径（脚本内部会从 `VAULT_ROOT` 环境变量读取 Vault 根目录）。

### 已有 Vault（迁移）

如果你已有 Obsidian Vault，补齐骨架中的 `_system/` 和 `templates/`（schema 与模板），再按上面第一、二层安装配置即可。

## 开始使用

- **从 0 开始**：读 [docs/QUICKSTART.md](docs/QUICKSTART.md)——30 分钟上手，不需要先有知识库。
- **组件关系**：读 [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)——Skill 与 Sub-agent 的区分、依赖关系、四层材料与 Project 定位。
- **完整哲学**：读 [docs/PHILOSOPHY.md](docs/PHILOSOPHY.md)——理解「为什么」比理解「怎么做」更重要。
- **真实用法**：看 [examples/](examples/)——不同人用这套系统管理了什么。

## 目录结构

```
obsidian-knowledge-mode/
├── config/
│   └── .agent-presets/
│       └── obsidian-knowledge-mode/   # preset.yml + agent.cordis.yml
├── skills/                       # wrap / insight-refinery / judgment-duel / vault-audit
├── agents/                       # red-team / defense / researcher / verifier
├── hooks/                        # Source Gate 脚本与注册
├── starter-template/             # 空库骨架：目录 + schema + 模板，从零开始
├── docs/
│   ├── PHILOSOPHY.md             # 设计哲学（为什么这样设计）
│   ├── ARCHITECTURE.md           # 组件关系、依赖、四层材料与 Project
│   └── QUICKSTART.md             # 从 0 开始（怎么做）
├── examples/                     # 领域案例（作者示范 + 社区贡献）
├── CONTRIBUTING.md               # 玩法指南 + 分享入口（三个问题起步）
└── LICENSE                       # MIT
```

## 许可证

MIT
