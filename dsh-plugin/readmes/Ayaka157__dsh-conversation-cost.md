# dsh-conversation-cost

在 DSH Web 对话底部的统计行里，**实时**显示本次对话的 DeepSeek 用量费用（人民币 + 美元双币）。

![效果示意](https://img.shields.io/badge/dsh-dsh--plugin-blue)

## 功能

- **逐请求精确计费**：Host 侧注册 `costLedger` 会话投影，逐条折叠请求事件（提供方上报用量 + 请求发出时刻 + 实际模型）到「档位 × 模型」token 桶，O(1) 状态、O(1) 每事件开销，不做聚合估算、不重放日志。
- **双币显示**：`费用 ¥0.0123 / $0.0018` —— ¥ 取官方中文页人民币表价、$ 取官方英文页美元表价，各自独立、不换算汇率。
- **缓存命中**：区分缓存命中 / 未命中输入分别计价（缓存写入免费）；DSH 的 `inputTokens` 已是未命中输入（已扣 cache-hit），不重复计费。
- **峰谷定价**：按每条请求自身的发生时刻（UTC 小时，等价北京 9–12、14–18，含起不含止）自动归入 平价/高峰/空闲 档位；2026-08-17 00:00（北京时间）前一律平价。
- **模型识别**：每条请求用其消息自带模型源（失败请求回退请求头），混合模型会话各按各价；未知模型不计价并标注。
- **档位明细**：hover 统计行可查看「平价/高峰/空闲」三档小计与未知模型提示。
- **无感融入**：费用作为统计行的最后一个分组，与「轮/步、耗时、TTFT、缓存命中、输入/输出」用同一分隔符、同一对齐、同一字号，中英文自动适配。

## 安装

从 GitHub 安装（推荐）：

```sh
npx -p @deepseek-ai/dsh dsh plugin --profile web add github:Ayaka157/dsh-conversation-cost
dsh web
```

或先 clone 到本地，再从本地目录安装：

```sh
git clone git@github.com:Ayaka157/dsh-conversation-cost.git
cd dsh-conversation-cost
dsh plugin --profile web add .
```

## 定价表

| 模型 | 档位 | 命中 | 未命中 | 输出（每格 ¥ / $ / 百万 tokens） |
| --- | --- | --- | --- | --- |
| deepseek-v4-flash | 平价 | 0.02 / 0.0028 | 1.0 / 0.14 | 2.0 / 0.28 |
| deepseek-v4-flash | 高峰 | 0.10 / 0.014 | 3.0 / 0.44 | 9.0 / 1.32 |
| deepseek-v4-flash | 空闲 | 0.05 / 0.007 | 1.5 / 0.22 | 4.5 / 0.66 |
| deepseek-v4-pro | 平价 | 0.025 / 0.003625 | 3.0 / 0.435 | 6.0 / 0.87 |
| deepseek-v4-pro | 高峰 | 0.30 / 0.044 | 9.0 / 1.32 | 27.0 / 3.96 |
| deepseek-v4-pro | 空闲 | 0.15 / 0.022 | 4.5 / 0.66 | 13.5 / 1.98 |

> 价格随时可能变动，以上为 2026-08-14 抓取的官方表价；峰谷定价于 2026-08-17 00:00（北京时间）生效。计费公式：`费用 = 未命中输入 × 未命中价 + 命中输入 × 命中价 + 输出 × 输出价`（缓存写入 ¥0）。

## 说明与限制

- 精确数据源：自注册的 `costLedger` 会话投影，折叠 `assistant/message`（提供方上报用量 + 自带模型源）与 `assistant/chunk`（失败请求用量），时间取 `step/start`（请求发出时刻）。
- 存储开销：checkpoint 只存「档位 × 模型」token 桶聚合（O(1)），不存逐请求明细；价格在读取时按当前表价计算，调价无需重放。
- 降级：`costLedger` 未就绪（刚安装、历史回填未完成）时，回退到聚合用量 × 当前档位的近似金额，并加「≈」标注。
- 时间归属约定：峰谷按请求发出时刻（`step/start`）判定；官方未明示按发出还是完成，属本插件约定，官方若明确口径可单点调整。
- 升级：重新执行 `dsh plugin --profile web add github:Ayaka157/dsh-conversation-cost` 覆盖安装后**重启 DSH Web** 生效。

## 许可

[MIT License](LICENSE)
