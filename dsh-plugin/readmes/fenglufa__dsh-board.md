# dsh-board

> **DSH（DeepSeek Harness）插件**：一个按工作区/项目隔离、支持多个看板、持久化存储的任务看板，
> 供多 agent / subagent 协作使用。AI 可通过工具操作看板，人可以在 Web 界面中可视化查看。

> A DSH plugin: a durable, multi-board, workspace-scoped task board for
> multi-agent / subagent collaboration. Agents operate the board through tools;
> humans visualize and manage it through a web panel.

---

## 这是什么 / What is this

`dsh-board` 是 [DeepSeek Harness (DSH)](https://github.com/deepseek-ai/deepseek-harness)
的一个 **Cordis 插件（bundle）**。它把一个持久化的任务看板挂进你的 DSH 环境，让所有
会话和 subagent 共享同一块看板，协同推进任务。

核心特性：

- **多看板**：一个工作区（项目）可以创建多个看板，例如「开发看板」「发布看板」。
- **工作区/项目隔离**：看板自动归属到创建它的会话所在的工作区（cwd）。
  在 `collect` 项目中创建的看板只出现在 `collect` 项目下，不同项目互不可见。
- **持久化**：看板数据写入 DSH 数据目录（`~/.dsh/sessions/<项目>/team-board.json`），
  重启后自动恢复，任务不丢失。
- **丰富的任务模型**：状态流转（可自定义状态集）、优先级、标签、截止日期、长描述、
  依赖关系、评论流、归档/恢复。
- **双入口**：
  - **AI 工具**：会话中通过 `board_*` / `task_*` 工具创建、认领、流转、评论任务。
  - **Web 面板**：DSH Web 界面侧边栏「新建会话」下方点「任务看板」，按工作区浏览看板。

---

## 安装 / Installation

### 本地目录安装

把本仓库克隆（或复制）到本地，然后在 DSH 的 profile 中通过本地路径安装：

```sh
# 进入你的 DSH 工作区
cd <你的项目目录>

# 克隆本插件（或者把插件目录放到任意位置）
git clone https://github.com/fenglufa/dsh-board.git

# 安装到 DSH web profile（本地路径安装，方便修改）
dsh plugin --profile web add ./dsh-board
```

### 安装后

重启 DSH（`dsh web`），插件即生效：

1. 侧边栏「新建会话」按钮下方会出现 **「任务看板」** 入口。
2. 会话中 AI 会自动获得 `board_*` / `task_*` 工具。
3. 首次使用无需配置，每个工作区会自动按需创建看板。

---

## 使用方法 / Usage

### 一、Web 面板（人机交互）

1. 打开 DSH Web 界面，在左侧侧边栏 **「新建会话」按钮下方** 找到 **「任务看板」** 入口。
2. 点击后，看板在**右侧主区域**展开（对话界面保持挂载，可随时「返回对话」）：
   - **左侧**：按工作区/项目分组的看板树（`工作区 → 看板列表`），不同项目的看板互不可见。
   - **右侧**：选中看板后的状态列视图（列数跟随看板自定义状态集，默认
     `todo / doing / in-review / blocked / done`）。
3. 面板内可以：
   - **新建看板**：点左侧看板树里的「+ 新建看板」，可自定义状态集。
   - **新建任务**：点看板右上角「+ 新建任务」，可填优先级/标签/截止日期/描述。
   - **查看任务详情**：点击任意任务卡片，查看描述、标签、负责人、评论，并可直接流转状态、删除任务。
   - **搜索过滤**：看板顶部搜索框按标题/描述过滤任务。

### 二、AI 工具（Agent 操作）

在任意会话中，直接对 AI 说需求，AI 会自动调用以下工具：

#### 看板管理

| 工具 | 说明 | 示例 |
|---|---|---|
| `board_create` | 创建看板（可自定义状态集） | 「创建一个发布看板，状态用 backlog/doing/done」 |
| `board_list` | 列出当前工作区的看板 | 「看看有哪些看板」 |
| `board_rename` | 重命名看板 | 「把发布看板改名为上线看板」 |
| `board_archive` | 归档/恢复看板（`restore: true` 恢复） | 「归档发布看板」 |

#### 任务管理

| 工具 | 说明 | 示例 |
|---|---|---|
| `task_create` | 创建任务（优先级/标签/截止日期/描述/负责人/依赖） | 「在看板上创建一个紧急任务：修复登录样式，标签加 bug，明天截止」 |
| `task_claim` | 认领任务（→ doing） | 「认领 task-xxx」 |
| `task_update` | 部分字段更新 | 「把 task-xxx 的优先级改成高」 |
| `task_transition` | 状态流转 | 「把 task-xxx 移到 done」 |
| `comment_add` | 追加评论 | 「给 task-xxx 评论：已定位到问题」 |
| `task_archive` | 归档/恢复任务（`restore: true` 恢复） | 「归档 task-xxx」 |
| `task_delete` | 永久删除任务 | 「删除 task-xxx」 |
| `task_list` | 多条件筛选查询 | 「列出所有 doing 状态的高优先级任务」 |

> 任务 ID 形如 `task-xxxxx-1`，创建后返回；认领/更新/流转/删除都需要它。

---

## 工作区隔离说明 / Workspace scoping

- 看板的 `workspace` 字段取自**创建时所在会话的 cwd**（工作区路径）。
- 同一个工作区内的所有会话/subagent 共享该工作区的所有看板。
- 没有 cwd 的会话（如无项目的 headless 场景）创建的看板归入 `_no-cwd` 全局区。
- 数据按工作区分文件持久化（`~/.dsh/sessions/<项目目录>/team-board.json`）。

---

## 数据模型 / Data model

```
Board = {
  id, name, workspace,          // workspace = 项目路径
  statuses: string[],           // 状态集，默认 todo/doing/in-review/blocked/done
  archived: boolean,
  createdAt, updatedAt
}

Task = {
  id, boardId, subject,
  status,                       // 必须是所属看板状态集之一
  priority,                     // urgent | high | medium | low
  tags: string[],
  dueDate,                      // ISO 日期，如 2026-08-20
  description, owner,
  deps: string[],               // 依赖的任务 id
  comments: [{ id, author, text, at }],
  archived: boolean,
  createdAt, updatedAt
}
```

---

## Web API（面板数据通道）

面板通过宿主提供的 JSON API 读写看板（与 AI 工具共享同一数据源）：

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/team-board/api/state?workspace=<path>` | 获取看板+任务快照 |
| POST | `/team-board/api/create-board` | 创建看板 |
| POST | `/team-board/api/create-task` | 创建任务 |
| POST | `/team-board/api/update-task` | 更新任务 |
| POST | `/team-board/api/add-comment` | 添加评论 |
| POST | `/team-board/api/archive-task` | 归档/恢复任务 |
| POST | `/team-board/api/archive-board` | 归档/恢复看板 |
| POST | `/team-board/api/delete-task` | 删除任务 |

---

## 项目结构 / Structure

```
dsh-board/
├── package.json           # 插件声明（dsh.client 双半区）
├── cordis.patch.yml       # bundle 挂载层
├── README.md
├── dist/
│   ├── board.js           # 数据层（纯领域逻辑，无 Cordis 依赖）
│   ├── index.js           # 服务端半区：工具注册 + 文件持久化 + Web API
│   └── client.js          # 浏览器半区：侧边栏入口 + 看板视图（中心列挂载）
└── scripts/
    └── board-smoke.mjs    # 数据层冒烟测试（node scripts/board-smoke.mjs）
```

## 测试 / Test

```sh
node scripts/board-smoke.mjs
```

覆盖：多工作区隔离、自定义状态集校验、部分字段更新、认领/流转、评论、归档/恢复、
快照序列化与回放、筛选查询。

---

## 已知局限 / Known Limitations

- **单进程内共享**：看板数据在同一个 DSH 进程内的所有会话间共享；跨进程/跨机器
  同步是后续路线。
- **快照式持久化**：每次变更写入整板快照（O(n)），几十条任务的量级足够；海量任务
  可改为增量事件流。
- **入口为 DOM 注入**：「任务看板」入口注入在侧边栏「新建会话」下方（该位置没有官方
  slot，采用 DOM 注入 + MutationObserver 自愈实现）；看板视图以 `data` 属性切换
  中心列显隐，对话界面保持挂载。

---

## License

MIT
