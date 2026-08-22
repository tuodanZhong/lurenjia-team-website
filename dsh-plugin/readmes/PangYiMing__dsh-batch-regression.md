# dsh-batch-regression

> DeepSeek Harness 插件 · 批量回归 / DSH plugin for batch regression stats

"数据忽高忽低，到底信哪个"——对同一命令跑 **N 轮取中位数和分布**，用统计而不是单次结果下结论。

"Numbers keep jumping — which one do I trust?" Run the same command **N rounds and judge by median/distribution** instead of a single result.

## 真实方法论 Methodology（实测沉淀）

| 结论 | 说明 |
|---|---|
| **取中位数，不是平均** | 平均会被极值拉偏；中位数更稳 |
| **至少 5 轮** | 少于 5 轮的统计没意义 |
| **差距 > 20% 结论才稳** | 改前/改后对比，差距 >20% 才下结论 |
| **控制变量** | 同一台机器、同一时段、关掉浏览器/IDE 等大头进程 |
| **承认抖动来源** | Apple Silicon P/E 核动态调度会让单次耗时翻倍；笔记本连续跑十几分钟会热降频 |

> 重要教训：cpulimit/nice/taskpolicy 在 Apple Silicon 上实测全失效——消抖靠"多轮取中位数 + 控制变量"，不靠限制 CPU。

## 使用 Usage

```bash
ROUNDS=5 METRIC=time ./scripts/runner.sh "node bench.js"
# samples=5  median=1234ms  (min=1102ms max=1987ms)

ROUNDS=10 METRIC=success ./scripts/runner.sh "npm run build"
# PASS=9/10
```

## 什么时候用 / 不用

| 场景 | 用 |
|---|---|
| 性能数据抖动，取可信中位数 | ✅ 本工具 |
| 改前/改后对比耗时分布 | ✅ 本工具 |
| 偶现问题看复现率 | ✅ 本工具（`METRIC=success`） |
| 单次就能判定的事 | ❌ 直接跑 |
| 定位"哪次提交引入退化" | ❌ 用 git bisect（见 [dsh-bisect-debug](https://github.com/PangYiMing/dsh-bisect-debug)） |
| UI 视觉回归 | ❌ 用 [dsh-screenshot-diff](https://github.com/PangYiMing/dsh-screenshot-diff) |

## 执行纪律

1. 取中位数不是平均。
2. 至少 5 轮。
3. 控制变量：同一台机器、同一时段、关掉大头进程。
4. 承认局限：本地耗时受 P/E 核调度和热降频影响，结论用"差距>20%才稳"标注置信度。
5. 中间失败不中断：某轮 fail 记 FAIL 继续，不因单轮失败停。

## 安装 Install

```sh
# 发布到 npm 后
dsh plugin --profile demo add dsh-batch-regression

# 或从 GitHub 安装
dsh plugin --profile demo add github:PangYiMing/dsh-batch-regression
```

## 许可证 License

[MIT](./LICENSE)
