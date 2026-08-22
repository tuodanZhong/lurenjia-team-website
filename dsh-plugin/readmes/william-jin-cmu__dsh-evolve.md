# dsh-evolve

![dsh-evolve](assets/hero.png)

自进化 harness 插件：**agent 在 session 内随对话给自己长出/剪掉能力**。用户的表述暴露出一个缺口（反复要查的表、天天要算的换算、老要看的端点），agent 现场写一个 cordis 插件挂载给自己——新工具在**下一个 step**就可调用；不再需要时可逆卸载；重启自动恢复。

进化不限于工具。evolution 是完整的 cordis 插件：常驻 system prompt 规则、`agent/step` / `agent/settled` 事件钩子、定时器主动唤醒 agent——**改行为、而不只是加能力**的进化，同样一次 `evolve_add` 完成（[三条非工具实录](#不止工具改行为的进化)）。

依据的机制：dsh 的工具列表每个 step 都从当前挂载的插件实时重算（无 session 级快照），cordis 4 的 fiber 具有可回滚 effect——挂载即生效，dispose 即净。

## 工具

- **`evolve_add(name, source, description?, config?)`** — 把一段纯 ESM cordis 插件源码持久化到 evolve store（`~/.dsh/evolve/<name>.mjs` + manifest），并热挂载。同名再次调用即替换（旧 fiber 先完整卸载）。
- **`evolve_remove(name, keepSource?)`** — 卸载 fiber（它注册的工具/监听/服务全部自动清理）、移出 manifest、删除源码。
- **`evolve_list()`** — 每个 evolution 的名称、fiber 状态、版本、用途。

另注册一段 system prompt（order 118）教模型进化姿态：会复用才长、过时就剪、长了剪了要告知用户；并附四条非工具进化的配方（常驻规则 → prompt section、每步自纠 → `agent/step` 钩子、事后自动化 → `agent/settled` 监听、主动性 → 定时器 + `agent.send` 唤醒）。

## 什么值得进化

不是所有事都配长一个工具——温度换算这种模型口算就对的，进化只是噪音。工具要**挣到它的位置**，得至少占一条模型裸答做不到的：

1. **跨会话状态** — 随口记的账、喂药时间，下个会话还要接着用；
2. **实时/外部数据** — 天气、汇率、你们的 git 仓库；
3. **精确计算** — 日期边界、分类汇总、利息摊销，模型心算容易出错；
4. **你的私有信息** — 家人的城市、家里的日子、项目的表，长进工具后零参数随口问。

还有第五条，它筛选的不是"值不值得进化"，而是"该进化成什么形态"：**工具是 pull——模型得记得去调**。凡是"不经过模型决策也必须发生"的需求（每次都要、自动发生、没人问也要来），做成工具就是错的姿态——该长的是 prompt section、事件钩子或定时器，见下面的[非工具实录](#不止工具改行为的进化)。

### 生活

| 你的日常表述 | agent 长出的工具 | 凭什么需要工具 |
|---|---|---|
| 「今天买菜花了 86，以后我随口说你就记着，月底我要问分类统计」 | `expense_add` / `expense_stats`：持久账本 | **跨会话状态**：下个会话接着记、接着算 |
| 「我妈周六去杭州，要带伞吗？我经常帮家里人看天气」 | `weather_city`：降水概率+带伞建议，**「妹妹」自动对应深圳** | 实时数据 + 私有别名 |
| 「帮我记下宝宝生日、结婚纪念日、我妈生日」 | `family_*` 三件套：**日子固化在工具里** | 私有信息 + 精确日期计算 |
| 「供应商报价 12800 美元折人民币？天天要算」 | `convert_currency`：实时汇率、双数据源容错 | 实时数据 |
| 「房贷 120 万 30 年，提前还 10 万能省多少利息」 | 等额本息摊销表工具 | 精确计算（模型心算容易出错） |

### 工作

| 你的日常表述 | agent 长出的工具 | 凭什么需要工具 |
|---|---|---|
| 「每周五我都要汇总三个仓库大家这周的提交写周报」 | `team_weekly_report`：仓库清单长在工具里，按人/按仓库分组 | 私有数据源 + 多步聚合 |
| 「E4103 是什么错误来着？」（项目错误码表天天翻） | `lookup_error_code`：实时解析表文件 | 私有信息 |
| 「这批实验数据 A/B 组差异显著吗」（每周都问） | 显著性检验工具（t-test/卡方，出精确 p 值） | 精确计算 |
| 「staging 现在什么版本？」（每天问） | 包住团队 health 端点的状态工具 | 实时私有端点 |

以上带工具名的都不是设想——全部有下面的实录。

## 实证（未剪辑 E2E）

六条真实会话（`dsh web` + DeepSeek-V4-Flash，RPC 驱动，事件流原样提取）。重点看前两条：

**① 家庭记账 — 跨会话状态，模型裸答做不到的事**（[session 1](assets/trajectory-expense-1.md) · [session 2](assets/trajectory-expense-2.md)）：session 1 里用户说「帮我记账，买菜 86、加油 400，月底要分类统计」，agent 长出带持久存储的记账工具并入账；**session 2 是完全独立的新会话**，用户只说「昨天外卖 62 记一下，这个月花了多少」，agent 直接调用上个会话长出的工具——账本延续（¥486 → ¥548，3 笔，分类正确）。

![跨会话记账](assets/session-expense-cross.png)

**② 团队周报 — 多仓库聚合 + 模型修自己写的 bug**（[完整 trajectory](assets/trajectory-weekly-report.md)）：用户说「每周五要汇总三个仓库的提交写周报，想个办法以后一句话就出」。agent 先手动拉数据核对，再把逻辑固化成 `team_weekly_report`（仓库清单、周界计算长在工具里）；验证 `weekOffset: -1` 时**自己发现了自己写的日期边界 bug**（`--since` 开区间把本周提交漏进上周报表），同名 `evolve_add` 替换为 rev 2 修复，三条参数路径回归全过。以后说「出这周周报 / 上周的 / 7月20号那周的」一句话即可。

![团队周报](assets/session-weekly-report.png)

**③ 帮家里人看天气 — 个人化别名 + 真实气象 API**（[trajectory](assets/trajectory-weather.md)）：接 open-meteo 的天气插件（地理编码→逐日降水概率→带伞建议），**家人城市做成别名**；挂载后「杭州 / 成都 / 妹妹」三查全过，还结合联网搜索发现台风「白海豚」周末过境，给出「周六带结实的伞、能调就避开周日」的活人建议。

![天气会话](assets/session-weather.png)

**④ 家庭纪念日 — 日子长进工具里**（[trajectory](assets/trajectory-family-dates.md)）：三个日子固化进插件，长出三个工具并逐个验算（宝宝 0 岁 4 个月 19 天、离纪念日 287 天、下一个生日是妈妈还有 88 天）。以后任何会话秒答。

![纪念日会话](assets/session-family-dates.png)

**⑤ 汇率换算 — 真实网络请求 + 挂载失败自修复**（[trajectory](assets/trajectory-currency.md)）：双数据源容错；前两次挂载因引号转义、`additionalProperties` 失败，agent 读错误**同名重试修复**，成功后当场算出 12800 USD ≈ ¥86,372。

**⑥ 项目错误码查询 — agent 主动提出进化**（[trajectory](assets/trajectory-error-codes.md)）：用户只抱怨「每天都得来查错误码」，agent 答完当次问题后**主动**长出查表工具并验证。

挂载后的 store（跨会话、跨重启持久）：

```json
{
  "plugins": {
    "expense-tracker":    { "rev": 1, "description": "个人记账：随口说花钱就记录，自动分类，按月统计。数据持久化在账单文件里" },
    "team-weekly-report": { "rev": 2, "description": "每周五周报：汇总三仓库本周/指定周的 git 提交，按仓库和按人分组" },
    "weather-check":      { "rev": 1, "description": "查任意城市天气…支持家庭成员别名（爸妈→成都、妹妹→深圳）…" },
    "family-reminders":   { "rev": 1, "description": "家庭重要日期常驻工具：宝宝年龄、结婚纪念日倒计时、下次是谁的生日…" },
    "currency-converter": { "rev": 1, "description": "实时汇率换算工具，支持 150+ 币种…" },
    "error-code-lookup":  { "rev": 1, "description": "实时查询 demo-shop 错误码表…", "config": { "path": "…/docs/error-codes.md" } }
  }
}
```

另验证过：重启 `dsh web` 后新 session 直接调用已恢复的工具；用户说「不需要了」时 agent 调 `evolve_remove`，manifest 清空、源码删除、工具消失。

## 不止工具：改行为的进化

上面六条长的都是工具。但 evolution 是完整的 cordis 插件，而工具是 **pull**——模型得记得去调。下面三条实录里用户的需求都带着"每次、自动、主动"，工具形态在这些需求面前必败，agent 长出的插件**一个工具都没注册**：

| 你的日常表述 | agent 长出的注册面 | 为什么工具做不到 |
|---|---|---|
| 「说了多少遍简短点都没用，想个办法**真正管住自己**」 | prompt section（常驻规则）+ `agent/settled` 钩子（量长度）+ 插件唤醒（超限逼重写） | 违规的是模型自己，不能指望违规者记得调工具自纠 |
| 「每次帮我干完活，**自动**往 worklog.md 记一行」 | `agent/settled` 监听器，普通代码里 `appendFileSync` | "每次"押在模型自觉上必然漏；监听器跟着 turn 提交的事实走 |
| 「每天早上 9 点**你主动来找我**过安排」 | 定时器 + `agent.send(…, { wakeup: true })` 造出新 turn | 清晨没有会话、没有 step——工具连被调用的宿主都不存在 |

**⑦ 回复长度自我监督 — 守卫的第一个猎物是它自己的出生通告**（[完整 trajectory](assets/trajectory-brevity-guard.md)）：用户说「超过 300 字符就该被自动提醒，不靠你记得」。agent 长出 **brevity-guard**（常驻规则 + 事后测量 + 超限唤醒收敛），挂载成功后的"搞定"通告本身 407 字符——**立刻被自己刚长出的插件拦下重写成 78 字符**。随后的三次误报成了整条 trajectory 的主菜：agent 自己读 dsh 源码和 session 日志，逐层定位出字数语义（reasoning 思考块被计入）、触发时机（`agent/step` 在步骤开始前触发、量到旧消息）、投递积压（旧版排队的"幽灵提醒"逐轮延迟送达）三个根因，rev 5 收敛稳定——终验 132 字符一次过，45 秒零幽灵。

![回复长度自我监督](assets/session-brevity-final.png)

**⑧ 干完活自动记工作日志 — 零工具调用的自动化**（[完整 trajectory](assets/trajectory-worklog.md)）：**worklog** 插件只有一个 `agent/settled` 监听器。关键验证在 turn 2：用户问了个 base64 解码，模型纯回答、**事件流里没有任何 tool/call**，settle 后 worklog.md 里照样多了一行——"记录"这件事从模型的决策空间里被拿走了，一个 token 都不花。第三轮让 agent 念日志，"念日志"这轮自己也被记了进去。

![工作日志会话](assets/session-worklog.png)

**⑨ 每天早上主动来找我 — 工具在定义上做不到的事**（[完整 trajectory](assets/trajectory-morning-reminder.md)）：用户要求"你主动发起对话，不是等我来问"，并要求先看 45 秒演示版。agent 长出 **morning-reminder-demo**（`inject: ['agents']`，定时器到点对空闲 agent `send` 唤醒）；45 秒后 turn 2 的 trigger source 是 `plugin: morning-reminder-demo`——**用户全程没发消息，对话是插件造出来的**。用户确认后一个 turn 内完成 `evolve_add` 正式版（自算距下一个 9:00 的毫秒数、fire 后自动重排）+ `evolve_remove` 演示版（定时器随 fiber dispose 自动清理）。正式版提醒文案还主动引用了此前长出的天气/账本/家庭日期工具——organism 在互相咬合。

![主动提醒会话](assets/session-morning-reminder.png)

一个未剪辑的涟漪：demo 定时器用 `ctx.agents.list()` 广播，而挂载是进程级的——同进程另一个会话也收到了演示提醒。那个 agent 先怀疑「我没装过定时器插件」，调 `evolve_list` 查明真相后照做打招呼。广播还是定向是进化代码该考虑的事；但每个 agent 都对突如其来的插件消息做出了正确反应，这本身是鲁棒性的证据。

## 安装

本插件是标准 Profile Bundle：`package.json` 的 `dsh.bundle` 指向 `cordis.patch.yml`，patch 按包名（而非绝对路径）挂载，dsh 版本升级后挂载不再失效。构建后从 checkout 安装进 profile：

```sh
scripts/build.sh                 # 见下
dsh plugin --profile web add .   # 追加为该 profile 的 bundle 层
```

卸载：`dsh plugin --profile web remove @dsh-external/dsh-evolve`。另一条互斥通道是 plugin-registry（`dsh registry`，读 `dsh.plugin.json` 增量清单）——同一部署二选一，不要双挂载。

构建：`scripts/build.sh`（需要 `dsh` 在 PATH，或设 `DSH_CHECKOUT` 指向 checkout 根；用 checkout 的 tsc 对 symlink 的 checkout 包编译）。测试：`$CHECKOUT/node_modules/.bin/vitest run`。

evolve store 的 `node_modules` 会自动 symlink 到本插件的 node_modules（后者已链入 dsh checkout），因此进化源码里可以直接 `import { defineTool } from '@deepseek-ai/dsh-tools'`，Node 内置模块也完全可用。

## 配置

| 键 | 默认 | 说明 |
|---|---|---|
| `dir` | `~/.dsh/evolve` | store 目录 |
| `autoRestore` | `true` | 启动时重挂 manifest 里的全部 evolution |

## 设计要点

- **同名重试必须能加载新源码**：挂载失败不写 manifest、rev 不前进，若用 rev 做 `import()` 的 cache-bust，重试会命中 Node 模块缓存加载旧的坏源码（这个 bug 正是在 E2E 里被 agent 自己诊断出来的）。现用进程内单调 seq 作为 cache-buster，与持久 rev 解耦。
- **中途改工具集会使该 session 的 prompt cache 前缀失效**，一次性成本，正确性不受影响。
- **信任立场**：evolution 是真实模块加载、无沙箱（与主 harness 同权限），面向可信的自用环境；需要人工把关的部署可在此基础上加确认模式（roadmap）。
