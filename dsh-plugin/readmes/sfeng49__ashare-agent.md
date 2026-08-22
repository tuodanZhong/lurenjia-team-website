<div align="center">

# ashare-agent

**基于 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)（dsh）+ [AKShare](https://akshare.akfamily.xyz/) 的本地 A 股 AI Agent 工作台**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Python](https://img.shields.io/badge/Python-3.11-3776AB.svg?logo=python&logoColor=white)]()
[![Awesome](https://awesome.re/badge.svg)](https://github.com/Dominic789654/awesome-deepseek-harness)

</div>

A 股研究与复盘工作台：**数据获取 / 每日晨报 / 交易复盘**三大技能，外加回测、选股、监控的脚本骨架。Agent 只做分析、不做交易；所有数字来自数据接口实际输出，拿不到就明说，绝不估算编造。

> ⚠️ **免责声明**：本项目不含任何实盘下单能力，不构成投资建议。数据来自公开接口，可能存在延迟、缺失或错误，请自行核对。

## 目录

- [特性](#特性)
- [快速开始](#快速开始)
- [六个任务](#六个任务)
- [技能](#技能)
- [目录结构](#目录结构)
- [数据源与已知限制](#数据源与已知限制)
- [定时任务](#定时任务)
- [安全与隐私](#安全与隐私)
- [常见问题](#常见问题)
- [许可证](#许可证)

## 特性

- 🧭 **3 个 dsh 技能**：`ashare-data`（数据获取）、`ashare-report`（每日晨报）、`ashare-review`（交易复盘），SKILL.md 格式，dsh 原生识别
- 📜 **`AGENTS.md` 投资准则**：铁律约束——不做买卖决策、禁用「目标价/必涨」措辞、数字必须来自脚本、数据拿不到就明说
- 🐍 **Python 3.11 数据环境**：akshare + pandas + backtrader + matplotlib + tabulate，版本锁定在 `requirements.txt`
- 📈 **可复用脚本** `scripts/morning_report.py`：一条命令生成晨报，已处理数据源切换与代理绕过
- 🔒 **默认脱敏**：自选股 / 持仓 / 交割单等个人金融数据被 `.gitignore`，只提交 `*.example` 模板

## 快速开始

### 前置要求

- Python 3.11+（推荐 3.11，兼容老牌 backtrader）
- [dsh](https://github.com/deepseek-ai/deepseek-harness)（DeepSeek Harness CLI）
- git

### 安装

```bash
git clone https://github.com/sfeng49/ashare-agent.git
cd ashare-agent

# 一键初始化：建 venv、装依赖、生成数据文件、接好技能发现链接
./setup.sh
```

等价手动步骤：

```bash
python3.11 -m venv .venv
.venv/bin/pip install -r requirements.txt
cp data/watchlist.example.txt data/watchlist.txt   # 换成你的自选股
cp data/positions.example.csv data/positions.csv
mkdir -p .dsh && ln -sfn ../skills .dsh/skills
```

### 让 dsh 识别技能

dsh 只扫描固定技能根目录（`.dsh/skills`、`.agents/skills`、`~/.dsh/skills`、`~/.agents/skills`），**并不默认识别工作区顶层的 `skills/`**。`setup.sh` 已创建项目级链接 `.dsh/skills -> ../skills`。

如需让技能在**任意工作区**可用，再执行：

```bash
ln -sfn "$(pwd)/skills" ~/.dsh/skills
```

### 跑第一个晨报

```bash
# 直接用脚本（不依赖 dsh）
.venv/bin/python scripts/morning_report.py --save

# 或在 dsh 中把工作区指向本目录后
执行 ashare-report
```

## 六个任务

这是工作台的完整玩法，每个任务都可用一句话在 dsh 里发起。

| # | 任务 | 一句话触发 | 产出 |
|---|---|---|---|
| 1 | 每日晨报 | `执行 ashare-report` | `output/daily/YYYY-MM-DD-morning.md` |
| 2 | 年报速读 + 财务排雷 | 把 PDF 放进 `data/reports/` 后让 Agent 分析 | 提取 + 横向对比 + 矛盾清单 + 风险清单 |
| 3 | 自然语言选股 | 描述条件让 Agent 生成脚本 | 参数化的 `scripts/screener.py` |
| 4 | 回测「盘感」 | 用 backtrader 回测你的交易习惯 | 年化/回撤/夏普 + 参数敏感性测试 |
| 5 | 盯盘监控 | 写 `scripts/monitor.py` | webhook 推送异动（去重） |
| 6 | 交易复盘 | 交割单放 `data/trades/` 后 `执行 ashare-review` | 胜率/盈亏比/行为模式/相对沪深300 的 alpha |

### 任务示例 prompt

<details>
<summary>任务一 · 每日晨报</summary>

```
读取 data/watchlist.txt 里的自选股，生成今日晨报：
1. 大盘：昨日三大指数涨跌幅、成交额、北向资金净流入
2. 自选股：昨日涨跌幅、换手率、是否放量（对比 20 日均量）
3. 消息面：每只自选股近 24 小时的新闻标题，按重要性排序
4. 异动标记：涨跌幅绝对值 > 5% 或成交量 > 20日均量 2 倍的，单独列出并说明可能原因
输出为 markdown，存到 output/daily/YYYY-MM-DD-morning.md，存前先给我看内容。
```
</details>

<details>
<summary>任务二 · 年报速读 + 财务排雷</summary>

```
读取 data/reports/600xxx_2025年报.pdf：
【提取】营收/净利润近三年趋势、分业务营收占比、毛利率、经营性现金流 vs 净利润、
应收账款与存货周转率、商誉占净资产比例、有息负债率
【交叉验证】用 akshare 拉同行业市值相近 3 家做横向对比，指出明显偏离项
【找矛盾】对比管理层表述与实际财务数据，列出口径不一致处
【风险清单】按严重程度列出疑点，每条指明原文页码与对应数字
不要给投资建议，只呈现事实和疑点。
```
</details>

<details>
<summary>任务三 · 自然语言选股</summary>

```
筛选全市场股票：近三年 ROE 连续 >15%、当前 PE(TTM) 低于行业中位数、
近一月北向持股比例上升；剔除 ST、次新、近 3 个月解禁高峰、近一年财务造假处罚/非标审计意见。
写成 scripts/screener.py，阈值做成常量放开头。跑一遍输出结果，并告诉我：
1) 每层各过滤掉多少只 2) 这套条件的明显缺陷在哪。
```
</details>

<details>
<summary>任务四 · 回测「盘感」</summary>

```
我的习惯：放量（成交量 > 5日均量1.5倍）突破 20 日均线买入，跌破 10 日均线卖出。
用 backtrader 回测：沪深300成分股，2020-01-01 至今，初始资金 10 万、单只最大仓位 20%、
手续费万三、印花税千一（卖出）、滑点 0.1%。
输出：年化、最大回撤、夏普、胜率、平均持仓天数、交易次数，并与同期沪深300定投对比。
再做敏感性测试：均线参数在 5/10/20/30/60 遍历，看参数是否落在“运气好”的点上。
```
</details>

<details>
<summary>任务五 · 盯盘监控</summary>

```
写 scripts/monitor.py：交易时段每 5 分钟检查自选股，触发条件为涨跌幅 ±5%、
成交量突破今日均量3倍、上榜龙虎榜、发布公告；触发后推到 Server酱/钉钉（webhook 从环境变量读）；
同一只股同一类型事件 30 分钟内只推一次。先跑一次模拟（只打印不推送）给我看。
```
</details>

<details>
<summary>任务六 · 交易复盘</summary>

```
分析 data/trades/ 下过去一年的交割单：
1. 总体：胜率、盈亏比、平均持仓天数、总收益 vs 同期沪深300
2. 亏损归因：亏损最大的 10 笔共同点（买点/卖点/选股）
3. 行为模式：盈利单 vs 亏损单持仓天数、是否“拿不住盈利死扛亏损”、交易频率与收益相关性
4. 时间分布：什么时段/环境下胜率最低
5. 若一年前买入沪深300ETF 持有至今收益多少？主动交易创造了正 alpha 还是负 alpha？
直接、不留情面地陈述结论。
```
</details>

### 晨报示例输出

```markdown
# A 股晨报 · 2026-08-17（周一）
> 生成时间：2026-08-17 11:54（盘中，数据为快照，会变动）
> 数据来源：akshare —— 日线/实时走 sina；个股新闻/北向资金走 eastmoney

## 一句话摘要
三大指数盘中多数上涨；600519 贵州茅台 盘中 -4.2% 领跌。

## 一、大盘
| 指数 | 收盘 | 涨跌幅 |
|---|---|---|
| 上证指数 | 3927.18 | +0.01% |
| 深证成指 | 14354.31 | +0.45% |
| 创业板指 | 3626.30 | +1.12% |
……
```

## 技能

| 技能 | 能力 | 触发 |
|---|---|---|
| `ashare-data` | 实时行情、历史 K 线（前复权）、财务摘要、龙虎榜、北向资金、个股新闻 | 任何 A 股数据请求 |
| `ashare-report` | 每日晨报：大盘 + 自选股 + 消息面 + 异动标记 | 晨报/早报/盘前简报 |
| `ashare-review` | 交易复盘：胜率/盈亏比/归因/行为模式/alpha | 复盘交割单、评估绩效 |

## 目录结构

```
.
├── AGENTS.md                 # 全局投资准则（Agent 每次任务都读）
├── skills/                   # dsh 技能（SKILL.md）
│   ├── ashare-data/          # 数据获取
│   ├── ashare-report/        # 每日晨报
│   └── ashare-review/        # 交易复盘
├── data/
│   ├── watchlist.example.txt # 自选股模板（复制为 watchlist.txt）
│   ├── positions.example.csv # 持仓模板（复制为 positions.csv）
│   └── trades/               # 交割单（复盘用，见 README）
├── output/daily/             # 每日报告输出
├── scripts/morning_report.py # 可复用晨报脚本
├── setup.sh                  # 一键初始化
├── requirements.txt          # 依赖锁定
└── LICENSE                   # MIT
```

## 数据源与已知限制

| 数据 | 来源 | 备注 |
|---|---|---|
| 日线 / 实时行情 / 指数 | sina | eastmoney K 线主机在部分网络下不可用，脚本固定走 sina |
| 个股新闻 / 沪深港通资金（南向） | eastmoney | |
| 北向净买额 | — | 交易所自 2024 年 8 月起停止实时披露，接口返回 0 |

**约定**：A 股代码 6 位不带前缀；日期 `YYYYMMDD`；历史行情默认前复权（`adjust="qfq"`）；akshare 接口名随版本变动，报错先查 `inspect.signature` 再调，不凭记忆硬猜。

## 定时任务

交易日早 8:30 自动生成晨报：

```bash
crontab -e
# 加入下面一行（替换成你的实际路径）
30 8 * * 1-5 cd ~/ashare-agent && .venv/bin/python scripts/morning_report.py --save >> logs/morning.log 2>&1
```

## 安全与隐私

- **Agent 只做分析、不做买卖决策**，最终判断由你本人做；`AGENTS.md` 已钉死这条铁律。
- **任何写/删文件、下单类操作必须先问你**（`AGENTS.md` 铁律第 5 条）。
- **实盘下单接口物理隔离**：easytrader 等不要放进本工作区，Agent 只输出「操作清单」，你手动去券商 App 下单。
- **脱敏**：个人自选股/持仓/交割单/生成的报告均被 `.gitignore`，不会提交到公开仓库。
- **权限预设**：dsh 建议用 `workspace-write`（审批 `ask`）而非 `danger-full-access`（审批 `never`），让危险操作真正走审批门禁。
- **幻觉抽检**：定期随机挑报告里 5 个数字去交易软件核对，确认配置的可靠度量级。

## 常见问题

<details>
<summary>dsh 里看不到我新建的技能？</summary>

dsh 只扫 `.dsh/skills`、`.agents/skills`、`~/.dsh/skills`、`~/.agents/skills`，不扫工作区顶层 `skills/`。用 `ln -sfn ../skills .dsh/skills`（项目级）或 `ln -sfn "$(pwd)/skills" ~/.dsh/skills`（全局）接入。
</details>

<details>
<summary>akshare 报 ProxyError / 连接被关闭？</summary>

部分机器配了本地代理（如 Clash）但未运行，Python 的 requests 会读到 macOS 系统代理导致连接失败。脚本已默认 `no_proxy='*'` 绕过；手动跑时也可先 `export no_proxy='*'`。
</details>

<details>
<summary>北向资金净流入为什么是 0？</summary>

交易所自 2024 年 8 月起停止披露北向实时净买额，这是数据本身没有了，不是接口坏了。
</details>

<details>
<summary>为什么用 Python 3.11 而不是更新的版本？</summary>

backtrader 较老，3.13/3.14 存在兼容风险；3.11 是量化栈的稳妥选择。`setup.sh` 会自动挑选 `python3.11/3.12/3`。
</details>

## 许可证

[MIT](LICENSE)
