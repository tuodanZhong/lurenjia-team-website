# 🧸 toybox —— DSH 插件玩具箱

> **正经插件与玩具插件都由 [DSH Hub Workshop](https://github.com/omdsh-dev/dsh-hub-workshop) 按同一门禁收录；toybox 专门放有趣的小工具。**
> 一个专门收藏"有意思"的 [DeepSeek Harness (DSH)](https://github.com/deepseek-ai/dsh) 插件的仓库：
> 有趣的技能、古怪的 MCP 服务器、能讲段子的工具。每个插件都有源码、离线打包与协议验收标准——只是比正经插件多了一点灵魂。

> **版权**：本仓库为独立插件项目，版权归作者（mattheliu）所有；仅包含原创插件代码，不包含 DeepSeek Harness 的实现源码。

## 当前可用性

五个 MCP 叶子包直接采用官方 MCP 2.0 SDK、`2026-07-28` 协议和
`server.json` 2025-12-11 schema；三个 Skill 是只做静态检查的直接 Skill。
`pnpm verify` 会逐个验证构建、精确打包面、MCP discovery/工具调用/进程失败与
重启，以及 Skill frontmatter、路径和危险命令模式。

这些是**源仓门禁结果**，不是 Workshop 的最终准入。每个叶子仍须绑定一个公开
完整 commit，由 Workshop 在隔离环境重跑对应 adapter，经独立人工审核后才能
显示为已验证；未经 admission 不进入安装 Registry。

## 🏠 住户（插件目录）

| 住户 | 类型 | 简介 | 状态 |
|---|---|---|---|
| [code-archaeologist](plugins/code-archaeologist/) | `skill` | **代码考古学家**：以田野考古方法论解剖遗留代码——地层判定、出土文物登记、发掘报告、保护性迁移建议。让"这代码为什么长这样"变成一场有证据的考古发掘 🏛️ | ✅ 本地静态验证 |
| [almanac-mcp](plugins/almanac-mcp/) | `mcp` | **老黄历·今日宜忌**：宜忌/冲煞/幸运方向（按天干五行推算，含星期彩蛋）、抽签（seed 可复现）、每日一诗。开工前先问一句"今日宜 merge 吗" 📜 | ✅ 本地协议验证 |
| [naming-master-mcp](plugins/naming-master-mcp/) | `mcp` | **取名大师**：古风/赛博/极简/程序员梗四种风格给变量、函数、项目、宠物起名，带出处梗，起名困难症终极解药 📛 | ✅ 本地协议验证 |
| [decision-dice-mcp](plugins/decision-dice-mcp/) | `mcp` | **决策骰子**：抛硬币/掷骰/命运抉择，选择困难时的"天意裁决"，附经典决策技巧提示 🎲 | ✅ 本地协议验证 |
| [chinese-colors-mcp](plugins/chinese-colors-mcp/) | `mcp` | **中国传统色**：61 色库（名称/HEX/典故）搜索、按日期"今日色"、按色系出和谐色板，前端配色秒变文化人 🎨 | ✅ 本地协议验证 |
| [time-capsule-mcp](plugins/time-capsule-mcp/) | `mcp` | **时间胶囊**：把想法封存，N 天后才能"挖出来"回看；未到期服务器拒绝泄露内容，写给未来的自己 ⏳ | ✅ 本地协议验证 |
| [bug-tamer](plugins/bug-tamer/) | `skill` | **Bug 驯兽师**：诱捕（最小复现）→ 驯化（根因）→ 放归（回归测试）→ 饲养手册（防复发），bug 修复方法论 🦁 | ✅ 本地静态验证 |
| [code-talent-scout](plugins/code-talent-scout/) | `skill` | **代码星探**：函数选秀 S/A/B/C 评级，四维评分卡 + 证据点评 + 回炉重造方案 🕵️ | ✅ 本地静态验证 |

> 表中“本地验证”表示源仓 RC.6 门禁通过，不等于 Workshop 已准入。

> 想入住？看 [入住指南](#-入住指南) —— 写 TS 源码 → `pnpm build` → README 加一行，完事。

## 📦 固定源码身份

提交 Workshop 时必须把仓库、完整 40 位 commit 与叶子路径一起固定；下面是
身份记录，不是可直接执行的安装配置：

<!-- INSTALL -->
```yaml
- id: almanac-mcp
  repository: https://github.com/omdsh-dev/toybox
  commit: <FULL_COMMIT_SHA>
  path: plugins/almanac-mcp/.dsh-plugin
```
<!-- /INSTALL -->

各插件发布 ref（本仓库每个 commit 都是不可变身份，更新插件 = 换 ref）：

<!-- REFS -->
| 插件 | 类型 | 发布 ref |
|---|---|---|
| almanac-mcp | `mcp` | `<COMMIT_SHA>` |
<!-- /REFS -->

装好后对模型说一句："**帮我考古一下 `legacy/payment.js` 这段代码**"，收获一份地层剖面 + 文物清单 + 保护性发掘建议；再问一句"**今天宜忌如何？抽个签**"，它就会翻老黄历、给你抽一支 🎋；卡在起名或选择困难时，喊它"**给这个模块起个古风名字**"或"**抛个硬币决定今晚吃啥**" 📛🎲。

## 🔨 构建链

MCP 插件源码是 **TypeScript**（`plugins/<id>/src/<id>.mts`），由 toybox 构建链编译为仓库候选静态包使用的单文件产物（`.dsh-plugin/server/<id>.mjs`）：

```sh
pnpm install        # 安装 TypeScript、官方 MCP 2.0 client/server 与 esbuild
pnpm build          # 类型检查并将官方 SDK 固定打包进五个单文件服务器
pnpm build:one <id> # 只编译一个
pnpm typecheck      # 只做类型检查（--noEmit）
pnpm verify         # 逐叶子全验：构建/包面/MCP 隔离与重启/Skill 静态检查
TOYBOX_GITHUB_REPOSITORY=omdsh-dev/toybox pnpm release:prepare
```

- 编译器选项启用 `strict`、`noUncheckedIndexedAccess` 和 `exactOptionalPropertyTypes`。
- 产物是**自包含单文件**：esbuild 把固定版本的官方 MCP Server SDK 打入 `.mjs`，运行时不读取仓库 `node_modules`。
- 产物随源码一起提交（`.dsh-plugin/` 是交付物）；改源码后必须 `pnpm build` 再提交。
- `pnpm verify` 是源仓门禁；Workshop 仍需基于不可变公开 commit 独立重跑并人工审核。
- 语言统计：`.gitattributes` 把构建产物标为 generated，`.mts` 显式归 TypeScript。
> 语言统计重算时机：push 触发、异步刷新（.gitattributes 的 linguist 规则随最新 commit 生效）。

## 🏗️ 入住指南

新插件四步入住：

1. **写源码**：MCP 用 `plugins/<id>/src/<id>.mts`；Skill 用 `plugins/<id>/.dsh-plugin/skills/<id>/SKILL.md`。
2. **声明契约**：MCP 同时提供 `package.json#dshWorkshop`、`mcpName` 与 `server.json`；Skill 直接指向唯一 `SKILL.md`，不得带安装脚本。
3. **构建 + 自证**：`pnpm build:one <id>` 后运行 `pnpm verify -- --only <id>` 和该叶子测试。
4. **登记**：README 住户表加一行。

### 玩具箱纪律

- **好玩是第一生产力**，但验收标准不能少：每个插件必须能过仓库自有 packager，README 里写清“什么时候用”。
- **不重复造轮子**：toybox 只收有趣且边界清楚的插件；统一经 Workshop 收录。
- **诚实标注**：判断类技能要带证据（参考 code-archaeologist 的"证据链"纪律），段子归段子，结论归结论。

## 🗺️ 规划中住户（候选，未开工）

| 住户 | 类型 | 梗点 | 状态 |
|---|---|---|---|
| 🧘 代码瑜伽 `code-yoga` | skill | 重构动作瑜伽体式化，小步可验收 | 候选 |
| 🌐 代码翻译官 `code-translator` | skill | 老代码现代化"翻译"，原文/译文对照 | 候选 |
| 🧭 代码导游 `code-tour-guide` | skill | 带新人逛代码库的旅游路线 | 候选 |
| 🃏 代码塔罗 `code-tarot-mcp` | mcp | 编程概念牌组 22 张大阿卡纳 | 候选 |
| 🚑 乱码急救员 `mojibake-medic` | skill | 中文编码救援：GBK/UTF-8/转义诊断修复 | 候选（已下架待重启） |

> 想新增别的？看 [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md)。

## 📜 许可

本仓库的源码、插件与文档统一采用 **MIT** 许可，版权归作者 mattheliu 所有（见 [LICENSE](LICENSE)）。
