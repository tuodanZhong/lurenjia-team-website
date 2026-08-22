# dsh-checkpoint-diff

> English version: [README.en.md](README.en.md)

把 [dsh-checkpoint-rewind](https://github.com/PerryLink/dsh-checkpoint-rewind) 的检查点（快照）当作**时间节点**，提供任意两个节点之间的**文件差异可视化**：会话头部 "Diff" 按钮打开浮层面板（时间线 → 文件清单 A/M/D → 逐行 diff），另有 `/diff` 命令与 JSON HTTP API 供 headless 使用。

只读设计，唯一显式例外是**回滚**：可从任意时间节点把工作区文件恢复回来（整节点或单文件），经面板、`/rollback` 命令或 API 触发。回滚**只覆盖写、绝不删除**（节点之后新建的文件保留并报告）、绝不碰 `.git`/`.dsh`、绝不写快照存储/git/会话。"绝不删除"的唯一例外是回滚的**单次撤销**（`/rollback --undo`、面板按钮）：只删除恢复操作自己刚创建的文件，其余一律不动（进程内记忆，重启即失效）。

[![npm version](https://img.shields.io/npm/v/dsh-checkpoint-diff)](https://www.npmjs.com/package/dsh-checkpoint-diff)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue)](LICENSE)
[![CI](https://github.com/tmpdot/dsh-checkpoint-diff/actions/workflows/ci.yml/badge.svg)](https://github.com/tmpdot/dsh-checkpoint-diff/actions/workflows/ci.yml)

## 理念：它解决什么问题，为什么是它

**场景。** AI 代理在替你写代码、改文件。它的"思考"是黑盒，但它的**行动**会落到你的工作区：它改了什么？什么时候改的？改坏了怎么办？——这些问题不能没有答案。

**立场。** 这类工具通常有两条路：一是**替你省事**——自动总结、自动判断、替你过滤信息；二是**让你安心**——把真相原样交给你，保证你随时能查清、能追究、能退回去。本插件明确选择第二条路：不做"替你看"的总结与过滤，而是把**看清楚**和**退回去**的能力完整交到你手里。

- **你不必看，但你必须能看。** 日常开发可以完全无视它；但任何时候想查，每次变更动作都对应一个高粒度的快照时间节点，任意两个节点之间改了什么、怎么改的，逐文件、逐行可见；
- **出问题能追究到底。** 哪一步、哪个工具、动了哪些文件，都能精确还原；确认误伤后，还能从任意时间节点把工作区恢复回来（只覆盖写、绝不删除、可撤销）；
- **安全感不来自"不出错"，而来自"查得到、退得回"。**

一句话：**你可以不看，但它不能不可查。** 人可以不看不追究，但绝不能没有看和追究的手段——这就是本插件存在的理由。

## 演示

### GUI 面板

全部为真实截图（运行在真实 harness 会话上）。面板全貌——scope 切换、from/to 时间节点下拉（意图标签 + `(HEAD)` 前缀）、目录树文件清单（A/M/D）、逐行 diff（红删绿增 + ↑/↓ 变更块跳转）、Restore workspace 恢复卡片：

![面板全貌](screenshots/01-overview.png)

**Trace (session log)** 范围——会话日志重放 + 三泳道拖选时间线（Input / Model / Tools span、turn 边界；拖选区间自动映射为 from/to 边界节点）：

![Trace 范围](screenshots/02-trace.png)

**本会话** 范围——当前会话的检查点时间线,选择要回滚的版本，点击“Preview Restore”预览效果：

![本会话范围](screenshots/03-this%20session.png)

**本项目** 范围——跨会话合并 + fork 血缘分支下拉：

![本项目范围](screenshots/04-this%20project.png)

> UI 每次大改后必须重新截图并更新本文（采集规则见 [docs/screenshots/README.md](docs/screenshots/README.md)）。

### 命令行形态（真实输出格式）

`/diff` 列出本会话时间线——rewind 在每次变更工具执行前自动留下快照时间节点（格式与真实输出一致，数据为示意）：

```text
diff: 3 checkpoint(s) for this session
  #a1b2c3d4  20m ago  turn 2 step 1  copy  3 file(s)  18 KiB  edit lib/engine.mjs
  #b2c3d4e5  10m ago  turn 3 step 1  copy  2 file(s)  12 KiB  edit README.md
  #c3d4e5f6   5m ago  turn 3 step 2  copy  4 file(s)  25 KiB  bash pnpm test
usage: /diff <from> <to>  (id prefix or "latest" for either side)
```

`/diff <from> <to>` 任意两节点：变更文件摘要 + 逐行 diff（GUI 面板中同屏显示红删绿增）：

```text
diff: #b2c3d4e5 (14:02 · edit README.md) → #c3d4e5f6 (14:07 · bash pnpm test)
  4 file(s) changed: +1 added, 2 modified, 1 deleted
  M  lib/engine.mjs
    - function lcs(a, b) {
    + function lcs(a, b, opts) {
  M  README.md
    - 只读设计，唯一例外是回滚
    + 只读设计，唯一显式例外是回滚
  A  test/engine.test.mjs
  D  lib/legacy.mjs
```

## 速览（At a glance）

- **是什么**：DeepSeek Harness 插件——把 dsh-checkpoint-rewind 的快照变成可浏览时间线，任意两个时间节点之间逐文件、逐行 diff（GUI 面板 / `/diff` / HTTP API），并提供预览式回滚（只覆盖写、绝不删除、可撤销）。
- **解决什么**：AI 代理自主修改工作区之后——它改了什么、何时改的、出问题时如何追究与恢复。
- **面向谁**：使用 DeepSeek Harness 并安装了 dsh-checkpoint-rewind 的开发者。
- **兼容**：DSH 0.1.0-rc.5 / rc.6 · rewind 0.4.0（域 v1）/ 0.5.0（域 v2）双兼容 · Node ^22.19 || >=24 · Apache-2.0。
- **入口**：会话头部 Diff 按钮 · `/diff` · `/rollback` · `/checkpoint-diff/api`。

## 特性

- **时间线** — 每个检查点都是一个可选时间节点（`#短id`、时间、turn/step、provider、触发工具；`/rewind` 守护检查点带标记）。
- **跨会话 / 同项目时间线** — 切到 *本项目* 合并共享同一工作区键的全部会话检查点，按 `/rewind` fork 血缘组织：分支下拉（根 + 旁支，会话标题）、会话标签、fork / 根缺失标记；可选 `dsh-session-query` 服务缺席时退化为扁平合并。
- **意图标签（紧凑）** — 节点按会话日志命名：`(turn, step)` 的 `tool/call` 事件解析出 `edit README.md`、`bash pnpm test` 之类的标签（GUI、`/diff` 输出、JSON API 一致）；**文件目标相对化到工作区**（超长退化为文件名）、**命令简写为"命令名 + 首参"**、`str_replace_editor` 显示为 `edit`、只读工具带 `Ⓡ` 标注；日志缺失回退原始触发工具。trace 时间线的 tooltip 还会附上该工具前一条 assistant 消息的说明文本（引号标注，批量工具共享）。
- **文件摘要** — 两节点间的变更文件清单，带 `A`（新增）/ `M`（修改）/ `D`（删除）徽标。
- **目录树视图** — 变更清单以可折叠目录树呈现，目录行带 A/M/D 计数；点文件看逐行 diff。
- **逐行 diff** — 自包含 LCS 引擎（copy 快照无需 git），`ctx`/`del`/`add` 行带对齐行号。
- **双快照 provider** — `git`（未引用 stash/commit-tree 对象，经 `git diff-tree`/`git show` 只读访问）与 `copy`（快照目录 + manifest），按记录分发；混合 provider 配对拒绝（响亮报错）。
- **回滚** — 从任意时间节点恢复工作区（整节点或单文件）：先预览再应用；只覆盖写——节点之后新建的文件保留并报告，绝不删除；路径校验（禁穿越、禁绝对路径、不碰 `.git`/`.dsh`）；git provider 只用只读原语，并要求会话 cwd 即仓库根。
- **恢复预览 diff** — 预览恢复时点计划中的任意文件，diff 区显示**当前工作区 → 目标快照**逐行差异（"current → #target"），应用前看清将要改什么。
- **单次撤销** — 应用恢复后一次 `↩ Undo this restore`（面板按钮、`/rollback --undo`、`POST /api/rollback-undo`）即可回退：被覆盖文件回到恢复前内容、恢复新建的文件被移除（"绝不删除"的唯一例外）；仅进程内、无 redo；恢复后被改动的文件跳过不动。
- **diff 视图细节** — ↑/↓ 按**变更块**跳转（连续新增行合成一块，相邻红区+绿区合成一块，纯删除也是一块；跳转对齐**块中心行**；最后一个块 ↓ 先提示、再点才回绕，↑ 对称）；打开文件自动定位到**第一个**变更块；diff 区下方 "Last view" 跳回上次查看的节点对（localStorage 持久）。
- **位置标签** — 最新节点带大写 `(HEAD)` 前缀（如 `(HEAD) #bbbbbbbb 20:26 · edit b.txt`）。HEAD 恒指**当前快照（全局最新节点）**：选择版本、切换分支过滤都不会移动它，刷新时间线后自动移到新快照。
- **独立恢复卡片** — 回滚区是工具栏下方独立的可折叠 "Restore workspace" 卡片，与节点对比区视觉分离；恢复预览（"Restore preview: current workspace → …"）与 from/to 对比**互相独立**：选择其它版本不清空预览，改恢复目标则按新目标重载。
- **优雅降级** — 被 `git gc` 回收（或重克隆丢失）的 git 检查点标 `⚠ degraded`，默认选择自动跳过；时间线显示 "N checkpoint(s) degraded" 提示条；diff/回滚报错精确点名死节点。绝不删除任何记录；剪枝记录、缺失记录/文件保持现有明确报错。
- **轨迹重放（可脱离 rewind 独立工作）** — 面板 scope 切到 **Trace (session log)** 或 `/diff --trace`：把会话日志（`session.jsonl.zstd`）里的每个工具调用当作时间节点（`trace:<seq>`），选中任意两节点即"选中区间"——由 `write`/`edit`/`str_replace_editor` 参数重放内容，逐文件逐行 diff（复用同一 LCS 引擎与面板）。**无需任何快照生产者**：rewind 缺席、快照被配额逐出或被 gc 回收、甚至装插件之前的历史会话，都能回答"这次对话改了哪些文件"。bash/pwsh 等任意命令的修改不可见（重放偏差以 note 诚实标注，绝不静默）；数据源优先 `sessionQuery.readSession`，zstd 帧直读为最后兜底（Node ≥ 23.5）。

## 同类对比（为什么是它）

以"AI 代理改了我的工作区"为场景，与常见方案对比（事实以各项目官方文档为准）：

| 工具 | 快照粒度 | 任意两节点 diff | 恢复/回滚 | 与 AI 会话的关联 |
|---|---|---|---|---|
| **dsh-checkpoint-diff（本插件）** | 每次变更型工具调用前 | **✅ 任意两节点逐文件逐行**（GUI 面板 / `/diff` / API；意图标签、目录树、变更块跳转） | **预览优先 → 应用；绝不删除；单次撤销**；整节点或单文件 | **会话内 + 跨会话项目级**（fork 血缘、分支） |
| dsh-checkpoint-rewind（上游生产者） | 每次变更型工具调用前（0.5.0 起 + 每回合/定时/手动） | ✅ 设置页两两对比（0.5.0 起：文件变更集 + 配置行级 diff；无工作区文件逐行 diff） | `/rewind` 预览 → 恢复 → fork（守护检查点；0.5.0 起 seed-replay 会话回退） | 单会话 |
| dsh-turn-rewind | 每条用户消息（更粗） | ❌ 无（changeLedger 服务，未提供可视化 diff） | 对话 + 工作区回退；Web 恢复对话框 | 单会话 |
| dsh-snapshot | 每次 write/edit/删除前（目标文件内容） | ❌ 无行级 diff | 按"对话"整体撤回（可再撤回） | 单会话（项目级配额） |
| Claude Code 原生 checkpointing + `/rewind` | 每对话回合（自动） | 文档未见节点间 diff 视图（以官方文档为准） | `/rewind` 恢复文件（git tracked） | Claude Code 会话内 |
| git 基线（`git diff`/`restore`，GitLens 等） | 每次人工 commit | ✅ 任意两 commit 逐行（生态成熟） | `git restore`/`checkout`；无预览规划、无撤销保护 | 无（纯仓库） |
| IDE 本地历史（JetBrains Local History / VS Code Timeline） | 每次编辑/保存（逐文件） | 单文件修订级 | 恢复单文件任意修订 | 无 |
| 系统级快照（Time Machine / Windows 文件历史） | 每小时/每天 | ❌ 无逐行 diff | 整文件/目录恢复 | 无 |

注：DSH 生态另有 `dsh-message-timeline`、`dsh-session-timeline`、`dsh-chat-timeline`、`dsh-undo-savepoint`（DSH 配置域）等时间线/快照类插件；本表聚焦"diff 可视化 + 回滚"维度。

**生态位立场（2026-08-17 核实）**：上游 rewind 0.5.0 已自带设置页时间线与两两对比（文件变更集 + 配置 diff；经读源码核实**无工作区文件逐行 diff**）。本插件不与生产者比拼"有没有 diff"，而是坚持**只读消费 + 分析层**定位——意图标签、跨会话 fork 血缘、非 git 工作区（copy）、预览回滚 + 单次撤销、`/diff` 命令与 HTTP API——并自 **0.5.0 起提供轨迹重放（Trace）**：无需任何快照生产者即可从会话日志重放逐行 diff，rewind 在场时继续消费其快照、缺席时独立工作，历史会话开箱即用。生态位评估、兼容性事实（rewind 0.5.0 域升 v2）与差异化路线见 [docs/competitive-analysis.md](docs/competitive-analysis.md) 与 [docs/decoupling-design.md](docs/decoupling-design.md)。

## 安装

```bash
dsh plugin --profile web add dsh-checkpoint-rewind   # 快照生产者（先装）
dsh plugin --profile web add dsh-checkpoint-diff     # 本插件
```

两个都是 bundle 插件：`dsh plugin add` 把它们写进 profile 的 `dsh.profile.bundles`，各自的 `cordis.patch.yml` 插入插件行。**host 侧变更需重启 harness**；浏览器 bundle 以 `no-cache` 直出，客户端修复刷新页面即可。

> bundle 层顺序必须是 **rewind 在 diff 之前**（diff 插件复用 rewind 打开的 checkpoints 域）。`remove`/`add` 会按依赖对象序重排，操作后请核对 `dsh.profile.bundles`。

## 用法

### GUI 面板

会话头部（标题右侧动作区）出现 **Diff** 按钮，点击打开浮层面板：

- 工具栏带 **scope 切换**：**Trace (session log)**（默认，排第一）或**本会话**或**本项目**（合并共享同一工作区键的全部会话检查点）；项目范围且有 fork 血缘时显示**分支下拉**（血缘根分支 + 旁支，标题来自 `readTitle`）；
- 标题行副标题显示**对话标题**（`sessionQuery.readTitle`，可选服务；不可用时回退为截断的会话短 id 如 `session-1641…`，完整文本悬停可见）；
- **Trace (session log) 范围带拖选时间线**：工具栏下方渲染一条**仿官方 TrajectoryTimeline** 的三泳道时间线（Input/Model/Tools span + turn 刻度；**视觉与交互对齐官方**：50px 图面、44px 标签列、8px span 按 14px 泳道间距 + 留缝、全高 turn 边界线、跟随指针的悬停竖线、span 悬停光环、选区带 = 品牌色底 + 选区外压暗 + 3px 边缘条、选区外 span 压暗；颜色语义：输入=蓝、模型=品牌色、只读工具=琥珀、内容型工具绿、变更型工具亮琥珀、失败调用红）——**鼠标拖选区间**（左/右键均可，双向）即映射到区间两端最近的工具调用边界并回写 from/to（区间语义 `(from.seq, to.seq]`，与 `/diff --trace` 一致）；**左键单击工具 span = 回溯锁定**：区间收敛为 "(前一工具调用边界, 该边界]"——直接回答"这一个操作改了什么"；再次单击同一 span 强制刷新摘要；非工具 span（消息/命令）回退为选中其最近边界节点。单击空白或 Esc 清除选区、右键菜单提供"查看区间文件差异 / 清除选区"；区间内没有工具调用时内联提示且不请求后端。from/to 下拉在时间线下方，作为键盘/精确寻址入口与时间线双向同步；
- **from / to** 两个下拉选择时间节点；有**意图 label** 时优先显示（如 `#a1b2c3d4 14:02 · edit README.md`）；项目范围下选项前缀归属会话短 id（如 `[sess-par]`）；
- 左侧为变更文件清单，以**可折叠目录树**呈现（目录行显示 A/M/D 计数、点击折叠/展开子树；文件行保留 `A` 新增 / `M` 修改 / `D` 删除 徽标，颜色随主题 token）；
- 点击文件，右侧显示逐行 diff（红删绿增，行号两侧对齐）；**打开文件自动定位到第一个修改块**；diff 头部带 **↑/↓ 修改点跳转**按钮（以**变更块**为单位上下跳转——连续新增行合成一块，修改的相邻红区+绿区合成一块，纯删除也是一块；**跳转目标 = 块中心行**，与视口中心对齐；**到最后一个块再点 ↓ 先弹出提示** "Last change block (click again to wrap)"，**再点一次才回绕**到第一个块，↑ 在第一个块同理）；
- 下拉选项、摘要范围行与预览标签中**最新节点带 `(HEAD)` 大写前缀**（如 `(HEAD) #bbbbbbbb 20:26 · edit b.txt`）。HEAD 永远指**当前快照（全局最新节点）**：选择版本、切换分支过滤都不会移动它——刷新时间线后它自动移到新快照；
- git 节点快照对象丢失（被 `git gc` 回收或重克隆丢失）时下拉选项标注 **`⚠ degraded`**：默认选择自动跳过降级节点、时间线显示"N checkpoint(s) degraded"提示条，diff/回滚报错会**精确指出哪个节点缺失**（如 `checkpoint #9312717a (to side) is missing from this repository (bad object …)`）；插件绝不删除任何记录或数据——换用较新节点，或执行 rewind 的 `/rewind clear` 重置时间线；
- 工具栏下方是**独立的可折叠卡片 "Restore workspace"**（回滚区与节点对比区视觉分离）：选择要恢复到的节点（默认最新节点；每个文件行也有 `↩` 按钮可只恢复该文件）→ **预览恢复**（dry-run 计划：将恢复/不变/跳过的文件 + 节点之后新建将保留的文件）→ **应用恢复**；计划/结果/撤销状态都渲染在卡片内，不再占用左侧文件清单顶部；
- 预览计划中的**将恢复**文件行是明显的链接样式（**`🔍 文件`** 品牌色 + 下划线）：点击后右侧 diff 区覆盖显示 **Restore preview: current workspace → 快照** 差异；预览激活时工具栏 from/to 下拉切换为只读的"当前工作区 → 目标节点"（from 显示 `(current workspace)`）。**预览与节点对比互相独立**：在 from/to 选择其它版本不会清空预览，改恢复目标则自动按新目标重载预览；点击左侧文件行退出预览回到普通 from/to diff；
- 应用成功后状态区只展示恢复记录（文件行不再可点击打开预览——工作区已恢复，再预览没有意义），回退入口是 **↩ Undo this restore** 按钮：一次撤销最近一次恢复（被覆盖文件回到恢复前内容、恢复新建的文件被删除、之后被改动的文件跳过不动）；
- diff 区下方有 **Last view** 小字行：记住上次查看的节点对（localStorage 持久），点击跳回（跨 session/project scope 也可）；
- 所选范围跨过 fork 衔接点时显示 `⤷ fork` 标记；血缘不完整时显示"更早历史不可见"提示；
- 点击面板外任意处关闭。

### 命令

```
/diff                       列出本会话本工作区的时间线（最近 listLimit 条）
/diff <from> <to>           打印两节点间的变更文件清单 + 逐行 diff
/diff --project             列出项目时间线（全部会话 + 分支头部）
/diff --project <from> <to> 跨会话两节点间的 diff
/diff --trace               列出本会话的轨迹时间线（会话日志重放；无需快照生产者）
/diff --trace <from> <to>   区间内变更文件清单 + 逐行 diff（trace:<seq> / 裸 seq / latest）
/rollback [--project] [--dry-run] <node> [<path>...]
                            从时间节点恢复工作区文件（单文件或整节点）
/rollback --undo            撤销最近一次恢复（单次）
```

`<from>`/`<to>` 支持检查点 id 前缀或 `latest`。示例：`/diff a1b2c3d4 latest`。项目范围下前缀歧义时优先本会话记录。

`/rollback` 恢复节点的全部文件，或只恢复给出的路径；`latest` 也是合法节点。`--dry-run` 只打印计划不写盘（`would restore N file(s), M unchanged, K skipped` + 将保留的遗留文件）；`--project` 可寻址共享同一工作区的其它会话节点。回滚绝不删除文件——只在原位覆盖写。`/rollback --undo` 撤销最近一次恢复（本进程内）：被覆盖文件回到恢复前内容、恢复新建的文件被删除、之后被改动的文件跳过不动（全部跳过 → 报错）。

### HTTP API（供其他 UI/脚本）

`webServer` 前缀路由 `/checkpoint-diff/api/*`（同源 JSON）。读端点只接受 GET 并可带 `scope=project` 参数跨会话寻址；`rollback` 与 `rollback-undo` 是 POST 端点（唯二写端点，且只写会话工作区）：

| 端点 | 方法 | 参数/请求体 | 返回 |
|---|---|---|---|
| `/api/timeline` | GET | `session`, `scope?` | `{ok, records[]}` 时间线（旧→新）；`scope=project` 附加 `branches[]` 与 `markers[]` |
| `/api/session-title` | GET | `session` | `{ok, id, title?}` — 会话标题（`sessionQuery.readTitle`；无标题/服务缺席时只回 `id`） |
| `/api/summary` | GET | `session, from, to, scope?` | `{ok, from, to, files[{path,status}], totalFiles, truncated}` |
| `/api/file-diff` | GET | `session, from, to, path, scope?` | `{ok, ops[{type:'ctx'\|'del'\|'add', text, a?, b?}], truncated, binary}` |
| `/api/preview-diff` | GET | `session, target, path, scope?` | `{ok, path, ops[], truncated, binary, present}` — 当前工作区 → 目标快照的预览 diff（只读） |
| `/api/rollback` | POST | JSON `{session, target, scope?, paths?, dryRun?}` | `{ok, dryRun, scope, target, files[{rel,action,reason?,mode?}], restored, unchanged, skipped, leftovers, notes}` |
| `/api/rollback-undo` | POST | JSON `{session}` | `{ok, target, time, restored, removed, skipped[]}` — 撤销最近一次恢复 |
| `/api/trace-timeline` | GET | `session` | `{ok, records[], spans[], turnBoundaries[]}` — 轨迹时间线（会话日志重放，节点 id = `trace:<seq>`；`spans`/`turnBoundaries` 为面板三泳道时间线的绘制数据；含 `source` 与读取失败时的 `error` 文案） |
| `/api/trace-summary` | GET | `session, from, to` | `{ok, from, to, files[{path,status}], totalFiles, truncated, notes[]}` — 区间变更清单（重放；`notes` 报告重放偏差） |
| `/api/trace-file-diff` | GET | `session, from, to, path` | `{ok, path, ops[], truncated, binary, notes[]}` — 区间内单文件逐行 diff（重放内容） |

`/api/rollback`：`target` 为 id 前缀或 `latest`；`paths` 限定只恢复这些文件（省略 = 整节点）；`dryRun: true` 只规划不写盘（此时 `restored` = 将恢复数）。`files[].action` 为 `restore` \| `unchanged` \| `skip`；`leftovers` 列出节点之后新建、被保留（绝不删除）的文件。

`/api/preview-diff`：diff 方向为**当前 → 快照**（`del` = 恢复会删除的当前行，`add` = 会加回来的快照行）；`present` 为 `both` 或 `workspace-missing`（工作区尚无该文件）。

`/api/rollback-undo`：`restored` = 写回恢复前内容的文件数，`removed` = 被删除的恢复新建文件数（"绝不删除"的唯一例外），`skipped` = 恢复后被改动而保留的文件（全部跳过 → `409`）。撤销状态只存进程内存——重启 harness 即清空（此后 `404 nothing to undo`）。

失败返回 `{ok:false, error}`（400 参数/跨 provider/非法 scope/不安全路径、404 未知会话/文件不在节点/未知端点、405 方法不允许、413 请求体过大、500 存储或 git 错误）。

## 数据契约

我们承诺的公开契约（消费契约 + 回滚安全契约）：**[docs/contract.md](docs/contract.md)**。

- 读 `storageDomain` 域 `checkpoints`（与 rewind 同 spec 重声明，见 `lib/domain.mjs`；域 spec 未从 rewind 包导出）。**双版本**：rewind 0.5.0 用域 v2（`kind`/`config` 必填、无 `forkSeq`）、0.4.0 用域 v1——本插件按 v2 打开、介质为 v1 时自动回退 v1，schema 为容错超集（新旧记录都能读）。优先复用已打开的域（`get`），否则自开（`open` 的 reserved 互斥 + 回退轮询）。
- 记录按 `(sessionId, cwd)` 归属。`scope=session`（默认）只取当前会话；`scope=project` 按 workspaceKey 合并全部会话，并沿 `/rewind` fork 血缘（`sessionQuery.traceSession`，可选服务，缺席时退化为扁平合并、无分支标记）组织分支；fork 锚点 v1 用 `forkSeq`、v2（rewind 0.5.0）用子会话创建时间回推的父侧最后记录。
- **意图 label**：按 (turn, step) 从会话日志的 `tool/call` 事件反查（只读）：`name` 与 `triggerTool` 精确匹配优先；`fs/*-intent` 触发取本步第一个变更型工具；否则取本步首个调用；日志缺失回退 `triggerTool` 原文（`lib/labels.mjs`）。live 会话直接读 `session.events`；冷会话经 `sessionQuery.readSession` 按需读取（都失败软降级）。
- **git** 快照：`git diff-tree -r -z --name-status`（清单）+ `git show <ref>:<path>`（内容），ref 按 40/64-hex 校验后入参；只读原语，绝不写 git。
- **copy** 快照：读 Harness home（`$DSH_HOME`，缺失时 `~/.dsh`）下 `dsh-checkpoint-rewind/<workspaceKeyHash16>/<uuid>/`（manifest.json + 文件），内容比较（manifest 哈希或字节）判 M。
- **跨 provider** 两端点拒绝（响亮报错）；缺失记录/缺失对象/配额清理后的旧节点全部优雅降级。
- 快照是**变更前**状态：`/diff <from> <to>` 呈现 from 快照 → to 快照的差异，to 快照不含 to 之后的变更。
- **回滚恢复节点的快照文件集**：git 节点 = 快照对象中的已跟踪文件树；copy 节点 = manifest 文件清单。工作区里不在节点文件集内的文件一律保留并报告（`leftovers`）。git provider 要求会话 cwd 即仓库根（快照树路径是仓库根相对），否则响亮拒绝。最近一次应用可用 `/rollback --undo` 撤销一次（进程内）。

## 开发

```bash
pnpm install                      # 依赖（zod/esbuild/jsdom/react，测试自足）
pnpm test                         # 单测（diff 引擎 / 时间线 / jsdom 面板冒烟）
pnpm test:integration             # 组装式 headless 集成（真 rewind + 真存储域）
pnpm build:client                 # 打包浏览器半 → lib/client.js（+ .map）
```

约定与设计见 [CONTRIBUTING.md](CONTRIBUTING.md) 与 [ARCHITECTURE.md](ARCHITECTURE.md)。集成测试消费本机 harness 部署（rc.5 包未发布到 npm；见 `scripts/link-profile-deps.mjs`）。

## Roadmap

- **投影单元化**：`scope=project` 目前每次请求全表扫描；宿主事件词汇覆盖 `checkpoint/*` 后可经 `sessionProjections` 按 workspaceKey 建索引。
- **分支线可视化**：时间节点间的分支连线（面板目前只在摘要区显示 fork 标记）。

## 致谢

本插件构建于 [dsh-checkpoint-rewind](https://github.com/PerryLink/dsh-checkpoint-rewind)（作者 [PerryLink](https://github.com/PerryLink)）之上——它是检查点**生产者**，本插件只读消费其 `checkpoints` 存储域与快照目录布局。**并非 fork，也不共享代码**：两者仅通过存储契约集成。第三方声明见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

## 许可

Apache-2.0（与 dsh-checkpoint-rewind 兼容）。第三方声明见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
