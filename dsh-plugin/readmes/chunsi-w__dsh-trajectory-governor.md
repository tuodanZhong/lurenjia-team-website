# dsh-trajectory-governor

面向 DeepSeek Harness 的**闭环 Agent 轨迹控制平面**。它不是继续增强一句 persona，也不是把会话永久分成 spec/react，而是围绕真实事件流维护：

- Task Episode 与连续性关系；
- 当前工作阶段；
- 结构化信息增益；
- 修改后的验证债务；
- workspace revision 与完整 benchmark 证据；
- 同规格、带容差的性能回归判断；
- 重复调用与无新信息轨迹；
- scoped 工具能力面；
- 显式 `finish` 与自然结束的完成门；
- 可选的自适应 reasoning effort；
- 本地、非模型可见的决策账本。

本项目是对 `dsh-mode-boost` 的 clean-sheet 重构，不依赖 preset fork，也不依赖 super-injector。

## 已实现的闭环

```text
真人消息被 inbox claim
  -> 在第一次 prompt assembly 前建立 Task Contract
  -> 判断 new / continuation / extension / correction / review / conversation
  -> 必要时通过 agent.ctx.tools.restrict() 暂时隐藏 write/edit
  -> agent/pre-step 在同一个请求内追加可重建的近场 policy message
  -> Native tool 或 Code Mode SDK 子调用产生 durable 事件
  -> 计算 observation novelty / mutation / verification
  -> 修改产生 Verification Debt
  -> readback + test/build/check 清偿当前 revision 的债务
  -> 可选 benchmark gate 只接受当前 revision 的完整、可解析结果
  -> 同 query count / concurrency / warmup 才比较 QPS，容差内不误判噪声
  -> finish guard 与 turn-stopping 阻止无证据结束
  -> 有限续步耗尽后要求模型明确报告 blocker
```
## 安装

要求：

- Node.js `^22.19.0 || >=24.0.0`；
- DeepSeek Harness `0.1.0-rc.7`（开发与集成测试基线）；peer range 兼容 `0.1.0-rc.5` 至 `<0.2.0`。

从当前目录安装：

```sh
npm run build
dsh plugin --profile web add .
dsh --profile web --dump-config
```

从 npm 安装（推荐）：

```sh
dsh plugin --profile web add @chunsi-m/dsh-trajectory-governor
dsh --profile web --dump-config
```

如需固定版本：

```sh
dsh plugin --profile web add @chunsi-m/dsh-trajectory-governor@0.2.0
```

安装 tarball：

```sh
npm run pack:release
dsh plugin --profile web add ./chunsi-m-dsh-trajectory-governor-0.2.0.tgz
```

包已经声明正式的：

```json
{
  "dsh": {
    "bundle": {
      "patch": "./cordis.patch.yml"
    }
  }
}
```

所以 `dsh plugin --profile web add ...` 会把它加入 `web` profile 的 bundle 层，而不是只安装成无效普通依赖。

## 配置

`cordis.patch.yml` 默认配置：

```yaml
- insert:
    - id: trajectory-governor
      name: '@chunsi-m/dsh-trajectory-governor'
      config:
        mode: active
        adaptiveReasoning: false
        restrictBeforeEvidence: true
        autoVerify: true
        maxAutomaticContinuations: 1
        exposeStatusTool: true
        ledger: true
        maxLedgerBytes: 10485760
        benchmarkRequired: false
        benchmarkToolNames: [run_benchmark]
        verificationToolNames: [build_project, run_correctness_test]
        finishToolNames: [finish]
        fullBenchmarkMinQueries: 10000
        fullBenchmarkMinRecall: 0.95
        benchmarkScoreTolerancePercent: 2
        maxActionsWithoutBenchmark: 8
        maxStagnantFullBenchmarks: 2
        stopRetryOnDeterministicErrors: true
```

| 字段 | 默认 | 说明 |
|---|---:|---|
| `mode` | `active` | `off` / `shadow` / `active`；shadow 只决策和记账，不改请求 |
| `adaptiveReasoning` | `false` | inspect/design/recover 阶段选择模型声明的最深 effort；阶段结束后恢复 provider default |
| `restrictBeforeEvidence` | `true` | fix/continuation 等任务在观察前临时隐藏已知专用写工具 |
| `autoVerify` | `true` | 有完成 blocker 时允许 `agent/turn-stopping` 追加有限验证步骤 |
| `maxAutomaticContinuations` | `1` | 每个 turn 的自动验证续步上限；耗尽后只追加一次 blocker-report 步 |
| `noInformationLimit` | `3` | 重复且无新信息达到阈值后成为完成 blocker，取得新结果后解除 |
| `exposeStatusTool` | `true` | 注册只读 `trajectory_policy_status` 工具 |
| `ledger` | `true` | 写入本地 policy ledger，不进入模型历史 |
| `ledgerPath` | `$DSH_HOME/trajectory-governor/decisions.jsonl` | 自定义账本路径 |
| `maxLedgerBytes` | `10485760` | 活动 JSONL 达到大小前轮转；旧文件保留 |
| `maxHintChars` | `1200` | 单条 model-visible policy hint 上限 |
| `benchmarkRequired` | `false` | 为性能任务强制当前 revision 的完整 benchmark；普通任务保持关闭 |
| `benchmarkToolNames` | `[run_benchmark]` | 视为 benchmark 的工具名，可按 harness 改写 |
| `verificationToolNames` | `[build_project, run_correctness_test]` | 视为常规验证的工具名 |
| `finishToolNames` | `[finish]` | 需要经过完成门的显式结束工具名 |
| `fullBenchmarkMinQueries` | `10000` | 完整 benchmark 的最小 `total_queries` |
| `fullBenchmarkMinRecall` | `0.95` | 完整 benchmark 的最小 `recall` |
| `benchmarkScoreTolerancePercent` | `2` | 同规格 QPS 下降不超过此比例时视作噪声范围 |
| `maxActionsWithoutBenchmark` | `8` | 缺当前完整 benchmark 时，多少成功动作后主动提醒补证据 |
| `maxStagnantFullBenchmarks` | `2` | 同规格完整 benchmark 无实质提升后提示平台期 |
| `stopRetryOnDeterministicErrors` | `true` | 对 HTTP 400 / `invalid_request_error` 不调用 DSH retry chain |
| `maxTrackedResults` | `256` | 每 Agent 保留的 result fingerprint 与 benchmark best record 上限 |

### 推荐上线顺序

先使用 shadow mode：

```yaml
mode: shadow
ledger: true
```

确认 relation/phase 判断符合真实会话后，再切换：

```yaml
mode: active
```

`adaptiveReasoning` 默认关闭，因为改变 reasoning effort 会改变 request header 与缓存形状。应在具体 provider/model 上完成校准后再启用。

## Task Episode

当前确定性 relation：

```text
new-objective
continuation
extension
correction
clarification
review
conversation
```

它综合：

- 指代与连续性词；
- 文件名和 artifact 重合；
- 与上一 objective 的词面相似度；
- fix/build/review 语义；
- 寒暄与短确认。

第一条消息是“你好”不会永久关闭插件；下一条真实任务会建立新的 objective。

## 能力面控制

当前版本只把明确的 `write`、`edit` 视为专用 mutation 工具。`str_replace_editor` 是读写混合工具，只有在仍有独立 `read` 时才会被暂时隐藏。

这使它不会把 Minimal preset 变成零观察能力，同时在 Code Mode 下 restriction 会自动改变生成的 TypeScript SDK，而不会删除保留 transport `run_code`。

`bash`/`pwsh` 仍是混合读写工具。对 `apply_patch`、重定向、`sed -i`、`git apply`、包管理安装等常见写入签名，Governor 会保守地标记为 mutation risk：成功后递增 workspace revision 并创建需要命令验证的债务；无法确定 artifact 时不会伪造文件级 readback。Governor 仍是轨迹策略，不是安全边界；真正权限仍由官方 sandbox/approval 执行。

## Verification Debt

成功的 `write/edit/str_replace_editor mutation` 或高风险 shell 写入会创建验证债务。债务绑定创建它的 workspace revision，之后发生的修改会使旧 readback/test 证据失效：

- 源代码：需要 readback + test/build/check；
- 文档：需要 readback；
- 未知 artifact：需要可执行验证。

以下 shell 命令会被识别为 verification：

```text
npm/pnpm/yarn/bun test|build|lint|typecheck|check
pytest / vitest / jest / mocha / tsc
cargo test / go test / dotnet test / mvn test / gradle test / make test
```

`bash` 文本里出现非零 `[exit code: N]` 时也会被视为失败，即使工具层没有把它标为 `isError`。

债务未清时，Governor 最多按配置追加有限验证步；到达上限后会追加一次仅用于报告 blocker 的步骤，不会无限循环，也不会静默放行。

## Benchmark-aware Stop Controller

实验型性能任务应显式打开 gate，而不是影响普通开发任务：

```yaml
benchmarkRequired: true
benchmarkToolNames: [run_benchmark]
verificationToolNames: [build_project, run_correctness_test]
finishToolNames: [finish]
fullBenchmarkMinQueries: 10000
fullBenchmarkMinRecall: 0.95
benchmarkScoreTolerancePercent: 2
```

配置的 benchmark 工具必须在 `meta` 或模型可见文本中返回完整命名指标；JSON 是最可靠的格式：

```json
{
  "total_queries": 10000,
  "recall": 0.98,
  "qps": 1250.5,
  "concurrency": 8,
  "warmup": 500
}
```

规则是确定性的：

- 只有 `total_queries >= fullBenchmarkMinQueries` 且 `recall >= fullBenchmarkMinRecall` 才能通过当前 revision；无法解析的结果明确成为 blocker，绝不当作 pass。
- QPS 只和相同 `total_queries`、`concurrency`、`warmup` 的 best record 比较；1K 与 10K 不会混比。
- 同规格下降未超过 `benchmarkScoreTolerancePercent` 时保留为可接受噪声；超过容差时，当前 revision 不能结束，模型必须恢复已知好版本或提出并验证新假设。
- 每次已识别 mutation 或高风险 shell 写入都会使先前 benchmark 失效；新的 current-revision full pass 才会重新打开 `finish`。
- `agent.ctx.tools.guard()` 拦截已配置的显式 `finish`；自然结束由 `agent/turn-stopping` 以同一门槛处理。

Governor 只保留 benchmark best record 与状态，不直接写用户工作区。因此它不会伪造“自动 rollback”：外部 evaluator/harness 若需要真正自动恢复，必须自己提供可验证的 checkpoint/restore API。

## Native 与 Code Mode

Governor 同时观察：

- Native：`tool/call` / `tool/result`；
- Code Mode：`tool/code-dispatch-start` / `tool/code-dispatch`。

因此 `run_code` 内部的 read/write/edit 也会更新信息增益、释放 restriction、创建并清偿验证债务。

## 状态工具

```text
trajectory_policy_status
```

返回当前调用 Agent 自己的：

- episode / human round；
- relation / kind / phase / risk；
- artifacts；
- observed / mutated artifacts；
- 当前 restriction；
- no-information、recovery blocker 与 repeated-call 计数；
- revision-aware open verification debt；
- benchmark 当前 revision pass、最新结果、同规格 best record、平台期和 blocker；
- ledger 轮转/失败状态；
- 最终 assembly hash。

实现严格使用 `exec.agent`，不会读取“最后组装请求的另一个会话”。

## 决策账本与隐私

默认路径：

```text
$DSH_HOME/trajectory-governor/decisions.jsonl
```

账本保存：

- session/message id；
- 原消息 SHA-256，不保存原文；
- relation、phase、risk、complexity；
- restriction；
- tool effect、artifact、错误、novelty；
- open verification debt；
- request assembly hash；
- turn stop reason。

账本失败不会改变官方 Agent 执行流，但不再静默吞掉：首次写入失败会输出一条 `console.error`，`trajectory_policy_status` 的 `ledger.failed/error` 也会暴露原因，随后停止重试该账本。活动文件在 `maxLedgerBytes` 前轮转为带时间戳的 JSONL，历史记录不会被删除。

## 构建与测试

```sh
npm install
npm run check
```

当前测试覆盖：

- Task Episode 关系；
- 寒暄后真实任务；
- correction / extension continuity；
- artifact 提取；
- tool semantics；
- revision-aware verification debt 与 shell mutation risk；
- benchmark 结构化解析、1K/10K 隔离、容差比较；
- 显式 finish guard、自然结束 blocker-report、修改后 benchmark 失效；
- no-information completion blocker；
- JSONL rotation 与账本失败状态；
- Minimal 防失能；
- Code Mode restriction；
- 首次请求前捕获输入；
- 同请求近场 policy；
- runtime context 保留；
- 观察后释放写工具；
- 自动验证续步上限；
- adaptive reasoning 选择与恢复；
- 多会话状态隔离；
- shadow mode 请求不干预。

## 当前限制

- relation engine 是可解释规则基线，不是 learned classifier；
- artifact graph 目前以路径和工具参数为主；
- shell 命令语义只能保守识别；
- benchmark 只能接受工具输出中明确命名的指标；不能从自由文本性能宣称推断 pass；
- 没有官方 workspace checkpoint API，所以不执行自动 rollback；外部 evaluator 必须提供 restore 机制；
- 没有自动 subagent evaluator；
- 没有 contextual bandit；
- 没有 workspace counterfactual fork runner；
- 外部插件尚无官方 custom durable SessionEvent 注册面，所以研究决策存在 sidecar，而不是伪造未知 session event；
- Governor 不替代测试、sandbox、approval 或人工评审。

## 代码结构

```text
src/core.ts       Task Episode、PolicyPlan、工具语义、Verification Debt 纯逻辑
src/index.ts      Harness runtime hooks 与闭环控制
src/ledger.ts     本地 append-only sidecar
cordis.patch.yml  官方 DSH bundle 层
tests/            纯逻辑与真实 AgentLoop 集成测试
```
