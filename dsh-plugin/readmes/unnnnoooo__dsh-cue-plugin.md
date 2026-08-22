# dsh-cue-plugin

跨会话结点引用（cue）插件 / Cross-session node reference plugin for DeepSeek Harness.

---

# 中文

在对话 A 中，从对话 B 里挑选「结点」（用户消息），把它们的上下文快照注入到 A 给模型阅读——模型不需要自己去翻找任何内容。

## 安装

```sh
dsh plugin add github:unnnnoooo/dsh-cue-plugin
```

（本地路径同样支持：`dsh plugin add ./path/to/dsh-cue-plugin`。）

## 用法

1. 在输入框工具条点击 **cue** 按钮。
2. 按标题选择目标会话，再勾选它的用户结点——单击切换、拖拽框选，或用
   **全选 / 清空** 批量操作。agent 回复折叠展示且不可选，只有用户消息会成为结点。
3. 点 **cue 这些结点** 确认：所选结点立即变成输入框里的 chip，上下文快照在
   **确认这一刻** 由固定程序捕获并写进 chip 载荷；相邻的结点自动合并成一个 chip。
4. 发送消息。宿主端 `agent/pre-step` 监听器解析 `dsh-cue:` 引用，把它改写为
   可读标记 `[cue 引用：@标题 #序号…]`（让模型知道这是一次引用），并在前面注入
   包装好的 `session-reference` 召回消息：

   ```text
   ## Cued nodes from <title>

   用户 cue 引用了以下结点，请把它们作为跨会话参考上下文阅读：
   ...
   ```

   这条消息使用 harness 原生的跨会话形式（`source.kind: 'session-reference'` +
   `form: 'recall'`），转录中会呈现为持久的「Session recall」行，带来源标题和
   保留/省略条数——模型和用户都能一眼把它和本会话内容区分开。

## 设计要点

- **捕获在 cue 时，不在发送时。** 用户确认的瞬间由浏览器端读取源会话；宿主端
  从不重读源会话，模型也从不自己做提取。
- **去重。** 每个选中结点附带一个小上下文窗口（自身 + 前 3 条用户/agent 记录）；
  相邻选区的窗口自动合并，连续结点的上下文绝不重复。
- **一个包，两半。** `lib/index.js` 是宿主半（pre-step 钩子）；`lib/client.js`
  是浏览器半（工具条按钮、选择器、chips），通过 `dsh.client` 清单和
  `window.__ModuleLoader__.load` 注册。

## 已知限制

- 除 harness 原生的「Session recall」上下文行外，没有自定义卡片。独立插件包
  无法追加自定义会话事件（日志白名单属于 harness 核心，且公开的 append API
  无法给仅日志事件标记 `ignorable`），所以召回行就是持久化呈现。
- 读取其它 harness 版本写入的会话可能失败（日志格式不跨版本）；选择器会给出
  友好的错误提示。
- `@cue` 触发器只注册了 codec；选择器本身由按钮驱动，不走 @ 菜单。

## 构建

```sh
pnpm install
pnpm build   # tsc --noEmit 类型检查 + tsdown → lib/index.js, lib/client.js
```

`lib/` 已提交，git 安装直接使用预构建产物（安装方无需任何构建步骤）。

---

# English

In conversation A, pick user nodes from conversation B and inject their captured
context into A for the model — without the model having to search for anything
itself.

## Install

```sh
dsh plugin add github:unnnnoooo/dsh-cue-plugin
```

(Local checkout works too: `dsh plugin add ./path/to/dsh-cue-plugin`.)

## Usage

1. In the composer's tool row, click the **cue** button.
2. Pick a target session by title, then select its user nodes — click to
   toggle, drag to box-select, or **全选 / 清空** for batch. Agent replies are
   shown collapsed and are never selectable; only user messages become nodes.
3. Confirm (**cue 这些结点**): the selection becomes chips in the composer,
   captured **at cue time** — the context snapshot is built by fixed client
   code the moment you confirm and shipped inside each chip. Consecutive nodes
   merge into one chip automatically.
4. Send the message. On the host, an `agent/pre-step` listener parses the
   `dsh-cue:` mentions, rewrites them to a readable marker
   (`[cue 引用：@标题 #seq…]`) so the model knows a reference happened, and
   prepends a wrapped `session-reference` recall message:

   ```text
   ## Cued nodes from <title>

   用户 cue 引用了以下结点，请把它们作为跨会话参考上下文阅读：
   ...
   ```

   The recall message rides the harness's first-class cross-session form
   (`source.kind: 'session-reference'` + `form: 'recall'`), so the transcript
   renders a persistent "Session recall" node with the source label and
   retained/omitted counts — the model and the user can both tell referenced
   context apart from the native conversation.

## Design notes

- **Capture at cue, not at send.** The browser reads the source session the
  moment the user confirms; the host never re-reads a source session and the
  model never performs the extraction.
- **Dedup.** Each selected node ships with a small context window (itself plus
  the preceding user/agent turns, width 3); windows of adjacent selections are
  merged so consecutive nodes' context is never repeated.
- **One bundle, two halves.** `lib/index.js` is the host half (pre-step hook);
  `lib/client.js` is the browser half (composer trigger, picker, chips),
  registered through the `dsh.client` manifest and
  `window.__ModuleLoader__.load`.

## Known limitations

- No custom cue card beyond the harness-native "Session recall" context row.
  Standalone bundles cannot append custom session events (the log whitelist
  is harness-core, and log-only events cannot be marked `ignorable` through
  the public append API), so the recall row is the durable presentation.
- Reading sessions written by a different harness version may fail (log
  format is not cross-version); the picker shows a friendly error instead.
- The `@cue` trigger registers a codec only; the picker itself is
  button-driven, not menu-driven.

## Building

```sh
pnpm install
pnpm build   # tsc --noEmit typecheck + tsdown → lib/index.js, lib/client.js
```

`lib/` is committed, so git installs use the prebuilt bundle directly (no
`prepare`/build step runs on the installing machine).
