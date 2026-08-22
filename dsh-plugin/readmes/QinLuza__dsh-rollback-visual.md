# dsh-rollback-visual

> ## ⚠️ 本仓库已报废，不要再用了
>
> 这里做的是**对话回退**（fork 子会话）+ 前端可视化，方向已被推翻：
> - **对话回退**：官方 DSH 自带 fork/分支功能，这里做的是重复造轮子；
> - **前端可视化**：DOM 注入方案有根本问题，已放弃。
>
> **替代项目**：[`QinLuza/dsh-file-undo`](https://github.com/QinLuza/dsh-file-undo) —— 真正的成品：**操作级回退**（撤销 agent 的文件 write/edit 操作，`/undo` 恢复到操作前），实测可用、已开源。
>
> 本仓库仅保留作**踩坑存档**（`docs/踩过的雷.md` 记录了 10 个雷，供后续插件开发避坑用），不再维护。

---

DeepSeek Harness 会话回滚（`/rollback`）仓库：**后端三件套**（fork 子会话回滚，已可用）。前端可视化已放弃（DOM 注入方案有根本问题），踩坑记录见 [docs/踩过的雷.md](docs/踩过的雷.md)。

## 功能

回滚 = 在会话事件日志里选一个边界 seq，fork 出一个子会话——**源会话历史不变**，子会话从边界处开始新时间线。

- **checkpoint 锚点**：每轮（turn）结束自动追加一条 `rollback/checkpoint` 事件（记录 turn 号 + 边界 seq，可用 `checkpoints: false` 配置关闭），供人按"第几轮"回退，不用记 seq。
- **fork 回滚**：通过边界派生子会话，源会话留下成对的 `rollback/start` → `rollback/end` 事务标记（成功、失败都闭合，无悬空括号），全部落盘可重放。
- **边界验证**：非法边界一律拒绝——越界、落在 open turn 内、落在 compaction 区间内、agent 忙碌（busy）、信号中止（cancelled）。

## 如何使用（CLI）

在 GUI 输入框输入（或 CLI 环境执行）：

| 命令 | 作用 |
|---|---|
| `/rollback` | 显示用法 + 当前会话所有 checkpoint 锚点列表 |
| `/rollback checkpoint` | 回退到**最近**一个锚点 |
| `/rollback checkpoint:<turn>` | 回退到指定 turn 的锚点 |
| `/rollback <seq>` | 精确回退到指定事件 seq（高级用法，易错） |

示例：

```
/rollback
→ turn 3 -> seq 47
→ turn 7 -> seq 120

/rollback checkpoint:3
→ Rolled back to seq 47 — new child session rollback-xxxx.
```

成功后：新子会话已生成，在会话列表切过去继续；源会话保留原样，可随时切回。

**注意**：
- 回滚只 fork 会话历史，**工作区 / 沙箱文件不会回退**；
- 回滚必须在轮次之间进行（agent 空闲、边界落在 turn 结束处）；
- 失败时会返回人类可读原因：`busy`（忙碌）、`boundary`（非法边界）、`cancelled`、`persistence`。

## 前端可视化（已放弃）

DOM 注入渲染方案已放弃，不再重构。数据层（`src/client/anchors.ts` 的 conversationEvents/conversationViews 定义）写对了、可复用；渲染层（MutationObserver 钉 DOM）判死刑。完整踩坑记录与根因见 [docs/踩过的雷.md](docs/踩过的雷.md)。

## 重做前端时的路线图（供参考）

- [ ] **饼 1：原生节点重构**。把渲染层从 DOM 注入换成轨迹原生节点：改 trajectory 源码，在渲染器的 kind 分发链里加 `rollback-anchor` / `rollback-bracket` 两个分支，锚点成为轨迹的一等公民（跟布局、折叠、tooltip 走），数据层照抄本仓库 `anchors.ts`。
- [ ] **饼 2：已派生标记**。被 fork 过的锚点显示「已派生」徽标（`rollback/start` 的 `boundarySeq` 就是证据，白给）。
- [ ] **饼 3：谱系面包屑**。子会话顶部「← 从源会话 turn N 派生」（`sessionQuery.traceSession` 现成，fork 时 `parentSession` 已记录）。
- [ ] **饼 4：谱系树 + 双侧对比**。多代派生可视化，源会话与子会话并排看。
- [ ] **饼 5：工作区快照提示**。等官方 `WorkspaceSnapshotter` seam——在此之前只能弹窗里写大字"文件不会回退"。
- [ ] **饼 6：agent tool 通道**。把 `ctx.rollback` 包成 model tool，用户说"回到 XX 之前"就能回滚，不用手点也不用敲命令。

## 安装

**后端三件套**（`timeline-rollback` / `rollback-basic` / `command-rollback`）：源码与构建配置见 [feat/timeline-rollback](https://github.com/QinLuza/deepseek-harness-research/tree/feat/timeline-rollback) 分支，加载方式为 profile 的 `cordis.patch.yml` 中 insert `rollback-basic` 与 `command-rollback` 两条（`timeline-rollback` 是 Service Definition，作为依赖自动引入，**不要**单独加载）。

**前端插件**（本仓库）：

```sh
pnpm build
dsh plugin --profile web add .
```

## 结构

```
src/index.ts          host 空壳（浏览器插件，host 无事可做）
src/client/anchors.ts 数据层：conversationEvents/conversationViews 定义（✅ 可复用）
src/client/overlay.ts 渲染层：MutationObserver DOM 注入（过渡实现，待重构为原生节点）
src/client/styles.ts  徽标/弹窗样式（设计令牌驱动）
cordis.patch.yml      loader 补丁（insert 到插件树）
```

## 参考

- 后端源码与修复：[feat/timeline-rollback](https://github.com/QinLuza/deepseek-harness-research/tree/feat/timeline-rollback)
- 完整测试结论与可视化设计文档：[docs/测试与参考.md](docs/测试与参考.md)
- **踩过的雷（经验总结）**：[docs/踩过的雷.md](docs/踩过的雷.md)
