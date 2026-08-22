# 转债情报局 Convertible Bond Intel

> **DeepSeek Harness（DSH）可转债插件与技能**：行情梳理、强赎监控、配债测算、条款科普，一个技能全搞定。
> **Convertible Bond plugin & skill for DeepSeek Harness / Codex / Claude Code / Coze** — daily bond brief, redemption (强赎) tracking, convertible-bond check & 配债 (allotment) calculator.

> ⚖️ 定位：知识科普与公开信息整理，不提供操作指导。数据来源为公开免费接口。

---

## ✨ 能做什么（可转债投资者日常三件事）

| 能力 | 说明 | 一句话例子 |
|---|---|---|
| **📰 市场信息梳理** | 每日市场概况、涨跌表现、强赎/到期提醒（含最后交易日/最后转股日）、下修公告、打新与上市日历、付息日历 | "今天转债市场怎么样" |
| **🩺 转债条款与信息解读** | 输入 6 位转债代码，解读评级、条款含义、风险维度（强赎/下修/回售/到期）、需关注信息点 | "查一下 123277" |
| **🧮 配债概念与数据梳理** | 配债相关公开数据：每股配售额、所需持股、转股价值、价格参考区间、覆盖度参考 | "配债 123282" |
| **📚 条款科普** | 强赎/下修/回售/双低/转股溢价率…用大白话讲清楚 | "强赎是什么意思" |

**为什么选它**：
- ✅ 全市场 300+ 可转债真实数据（评级/价格/溢价率/剩余年限/公告），离线可用
- ✅ 强赎/到期**最后交易日、最后转股日**自动提醒（散户最常踩的坑）
- ✅ 纯 Python 标准库实现，无第三方依赖，安装即用
- ✅ 一个技能，多平台通用（DSH / Codex / Claude Code / Coze）

---

## 🚀 安装（DeepSeek Harness）

### 方式一：npm 插件（推荐，正式工具）

```bash
# 在 DSH 环境内安装
pnpm add @wxmark/dsh-tool-cb-intel
```

在 DSH 组合配置（cordis.yml）中加入：

```yaml
plugins:
  - "@wxmark/dsh-tool-cb-intel"
```

重启 DSH 后，模型自动获得 4 个工具：`cb_market_brief` / `cb_bond_check` / `cb_peizhai` / `cb_update_data`。

### 方式二：技能（Skill）形式，一键复制

```powershell
# Windows
powershell -ExecutionPolicy Bypass -File install.ps1
```

```bash
# macOS / Linux
chmod +x install.sh && ./install.sh
```

或手动：把 `convertible-bond-intel` 目录复制到 DSH 用户技能目录 `<DSH_HOME>/skills/`（Windows 默认 `C:\Users\<你>\.dsh\skills\`），重新加载会话即生效。

> 运行前提：系统装有 **Python 3.7+**（数据脚本为标准库，无 Python 第三方依赖）。

---

## 💬 使用示例

| 你说 | 得到 |
|---|---|
| "转债早报" / "今天转债市场" | 市场概况（价格/溢价率中位数）、涨跌榜、强赎到期提醒、下修公告、打新上市、付息日历 |
| "查一下 123277" | 该转债的评级、条款、强赎/下修/回售风险维度、需关注信息点 |
| "配债 123282" | 配债相关数据：每股配售、所需持股、转股价值、覆盖度参考 |
| "强赎是什么意思" | 大白话条款科普 + 风险提示 |

**数据更新**（联网可选）：`cd` 到技能目录运行 `python scripts/run_live.py`，拉取最新公开数据并存档；`data/` 内置快照，离线可用。

---

## 🔧 项目结构

```
convertible-bond-intel/      # Skill 形态（多平台通用）
plugin-tool-cb-intel/        # Cordis 插件源码（npm 发布）
npm-package/                 # 已发布 npm 包
├── SKILL.md                 # 技能主文件
├── scripts/                 # Python 脚本（标准库，无依赖）
├── data/                    # 公开数据快照（离线可用）
└── references/knowledge.md  # 可转债知识库
```

## 🌍 多平台支持

- **DeepSeek Harness**：npm 插件（推荐）或 Skill 复制
- **Codex**：复制到 `~/.codex/skills/`
- **Claude Code**：复制到 `~/.claude/skills/`
- **Coze（扣子）**：作为技能包上传

## 🔍 相关关键词

可转债 / convertible bond / 强赎 / redemption / 配债 / allotment / 双低 / double-low / 转债打新 / DSH plugin / DSH skill / deepseek-harness 插件 / AI 理财工具

## ⚖️ 合规

- 仅做知识科普与公开信息整理，不评价具体品种、不提供操作指导
- 全输出附风险提示；历史数据标注"不代表未来表现"
- 数据来源：东方财富数据中心 + 腾讯行情 + 东财公告（公开免费接口）

## 📄 License

MIT（见 LICENSE）。本项目仅作科普用途，不构成任何投资建议。

---

⭐ 如果这个插件对你有帮助，欢迎 Star / Issue / PR！
