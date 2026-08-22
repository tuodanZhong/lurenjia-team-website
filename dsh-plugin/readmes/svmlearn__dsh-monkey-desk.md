# 马喽办公室（Monkey Desk）

[English](README.en.md) · 中文

一个面向 **DeepSeek Harness（DSH）Web** 的多 Agent 可视化插件。它把当前工作区各个会话里的子 Agent 聚合成一间实时办公室：每个 Agent 有自己的工位、屏幕、状态和操作入口。

![马喽办公室总览](docs/images/monkey-desk-overview.png)

## 为什么做这个插件

多 Agent 协作通常藏在会话 ID、工具调用和日志里。任务一多，你很难立刻判断：谁在干活、谁已完成、谁还能继续、应该把返工发给谁。

马喽办公室把这些信息翻译成一个可以直接理解的工作空间：

- 屏幕亮着并敲键盘：Agent 正在工作。
- 趴下睡觉：长期子 Agent 已完成当前任务，仍可唤醒继续。
- 半透明空工位：一次性任务已经结束，可以查看结果或归档。
- 悬浮工位：直接派活、返工或归档。

## 功能

- 在 DSH 会话中增加独立的「马喽办公室」视图。
- 聚合当前工作区内所有会话的子 Agent，不局限于当前对话。
- 每 4 秒刷新工作区团队列表与最新活动摘要。
- 可视化 `running`、`ready`、`gone` 等生命周期状态。
- 向可继续的子 Agent 直接派发新任务。
- 把修改要求发送回原 Agent，保留它已有的工作历史。
- 二次确认后归档不再需要的会话。
- “招马喽”表单支持长期角色、一次性临时工和上下文 Fork。
- 自动探测本机 Codex 与 Claude Code CLI 是否可用。
- 自适应三列、两列和单列布局，并提供克制的状态动效。

## 实际接入效果

![马喽办公室在 DSH 中运行](docs/images/monkey-desk-in-dsh.png)

## 安装

要求：

- 已安装可运行的 DeepSeek Harness。
- 使用 DSH Web profile。
- Codex 和 Claude Code 仅在选择对应执行引擎时需要安装。

从 GitHub 安装到 `web` profile：

```bash
dsh plugin --profile web add https://github.com/svmlearn/dsh-monkey-desk.git
```

重启 DSH Web：

```bash
dsh --profile web
```

打开一个会话后，进入「马喽办公室」视图即可使用。

### 本地目录安装

```bash
git clone https://github.com/svmlearn/dsh-monkey-desk.git
dsh plugin --profile web add ./dsh-monkey-desk
dsh --profile web
```

## 如何使用

### 查看团队状态

顶部筛选器可查看全部、干活中、睡着和已离开的工位。每个子 Agent 的屏幕下方会展示最近一条活动摘要；派活时会自动路由到它真正所属的父会话。

### 派活与返工

将鼠标悬浮在工位上：

- `派活`：向该子 Agent 发送新任务。
- `叫醒`：唤醒已经完成上一项任务的长期 Agent。
- `返工`：把修改要求发回同一 Agent；它仍保留自己的历史上下文。
- `归档`：二次确认后归档会话。

### 招一个新角色

点击「招马喽」，填写角色名称、执行引擎和首个任务：

| 类型 | 上下文方式 | 生命周期 | 适用场景 |
| --- | --- | --- | --- |
| 长期角色（Spawn） | 新的独立上下文 | 可持续唤醒、派活和返工 | 产品、研发、运营等固定分工 |
| 一次性临时工 | 只接收本次任务所需信息 | 完成即离开 | 边界明确的一次性执行 |
| Fork 子 Agent | 复制创建时的父会话上下文快照 | 从当前节点分叉执行 | 需要理解当前讨论背景的支线任务 |

> Fork 继承的是创建瞬间的上下文快照，并不是父子 Agent 后续消息实时同步。

当前版本中，Codex 与 Claude Code provider 仅支持一次性临时工。长期角色与 Fork 使用 DeepSeek 子 Agent。

“招马喽”不会绕过主 Agent 直接创建角色。它会把一条结构化创建指令填入当前会话输入框，由你确认发送，再由主 Agent 完成人设、技能与子 Agent 创建。这让创建过程仍然可见、可检查。

## 工作原理

```text
DSH Web conversation.view
        │
        ├── lib/client.js
        │     ├── /monkey-desk-team（工作区团队聚合）
        │     ├── subagents.history
        │     ├── subagents.prompt
        │     └── workspace.archiveSession
        │
        └── lib/index.js
              ├── /monkey-desk-team（跨会话子 Agent 列表）
              └── /monkey-desk-engines（本机 CLI 可用性探测）
```

| 文件 | 作用 |
| --- | --- |
| `lib/client.js` | 注册团队视图、绘制工位、刷新状态并处理交互 |
| `lib/index.js` | Host 侧插件，聚合工作区团队并探测 Codex/Claude CLI 可用性 |
| `cordis.patch.yml` | 将插件挂入 DSH Web profile |
| `package.json` | DSH bundle 与客户端依赖声明 |

## 隐私与安全

- 插件不包含 API Key，也不要求单独配置密钥。
- 不包含统计、遥测或第三方数据上传。
- 会话列表、历史摘要、派活与归档都通过当前 DSH Host 提供的 API 完成。
- `/monkey-desk-team` 只读取当前 DSH 工作区的会话与子 Agent 投影。
- `/monkey-desk-engines` 只返回本机是否能找到 `codex` / `claude` 可执行文件，不返回路径或凭据。

## 当前限制

- 界面目前以中文为主。
- 状态由 DSH 当前公开的子 Agent 投影推断，不是逐 token 的实时画面。
- 创建角色仍需用户发送生成的指令；这是有意保留的确认步骤。
- 本项目只发布 GitHub 源码，`private: true` 用于防止误发到 npm registry。

## 开发

项目没有构建步骤。`lib/client.js` 是 DSH Web 可直接加载的原生模块封装，UI 使用 Host 提供的 React，并通过 `React.createElement` 渲染。

发布前快速检查：

```bash
node --check lib/index.js
node --check lib/client.js
npm pack --dry-run
```

## License

[MIT](LICENSE) © 2026 [svmlearn](https://github.com/svmlearn)
