# dsh-build-diff

DeepSeek Harness Web GUI（DSH）的 Agent 循环变更审查插件。**每次 agent 结束一轮 loop**（一次 `running → idle` 驱动周期，与 dsh-agent-loop 的 kick() 语义一致）后，自动快照会话工作区、检测文件/代码变更，并支持：

- **审查**：右侧边栏按轮次列出所有变更文件，内联展示行级 diff（双栏行号、+/− 着色、长上下文折叠为「N 行未改动」）。
- **撤销**：一键撤销整轮变更，或逐文件撤销——恢复为 loop 开始前的精确内容；删除 agent 新建的文件、还原 agent 删除的文件。
- **审查气泡**：每轮结束后，气泡（「已编辑 N 个文件 · +X -Y · 撤销 / 审核」）渲染在助手消息「复制 / 好的回答 / 有问题的回答」按钮行正上方。宽度与消息列一致；文件预览默认 3 个，「再显示 N 个文件」在气泡内展开其余项。点击文件可在右侧栏打开该文件的 diff。
- **轮次切换**：通过「轮次」下拉回顾该工作区之前的各轮变更。
- **复制 Diff / 标记已处理**：复制统一 diff 文本、标记已审阅。

[English](README.en.md)

官方双面 dsh 插件（host 半端 + browser 半端），零运行时依赖，不改 dsh 源码。

## 前置插件

**必须安装 `dsh-better-sidebar`（^0.12.1）**——审阅界面以标签页形式存在于它的 VS Code 式右侧栏工作台中。客户端半端通过 cordis `inject` 声明该服务，未安装时 UI 不加载（host 半端照常检测与记录变更）。先安装：

```bash
dsh plugin --profile web add dsh-better-sidebar
```

## 安装

```bash
# 从 npm（发布后），或本地目录：
dsh plugin --profile web add @kelearns/dsh-build-diff
# 本地开发：
dsh plugin --profile web add link:/path/to/dsh-build-diff
```

手动安装（与桌面版内置插件同机制）：

1. 把本目录复制到 `~/.dsh/profiles/node_modules/@kelearns/dsh-build-diff/`（保留 `index.js`、`lib/`、`package.json`、`cordis.patch.yml`）。
2. 在 `~/.dsh/profiles/web/cordis.patch.yml` 追加：

   ```yaml
   - insert:
       - id: dsh-build-diff
         name: '@kelearns/dsh-build-diff'
   ```

3. 重启 DSH（重启桌面应用或 `dsh web`）。设置页（设置 → 变更审阅）可开关检测与内容捕获上限。

## 工作原理

```
agent/status running  →  快照工作区（全量指纹 + 小文本文件内容）
   … agent 修改文件 …
agent/status idle      →  重扫、对比、持久化 loop 记录（Myers 行级 diff）
   GET  /dsh-build-diff/loops?cwd=…         loop 元数据
   GET  /dsh-build-diff/loop/<id>           完整记录（diff；旧内容仅存服务端）
   POST /dsh-build-diff/loop/<id>/revert    撤销全部或指定文件
   POST /dsh-build-diff/loop/<id>/dismiss   标记已处理
```

- 存储：`$DSH_HOME/build-diff/{config.json,index.json,loops/<id>.json}`；超过 `retentionDays`（默认 7 天，保留最近 200 条）自动清理。
- 快照成本：全文件指纹 + 文本文件（≤ `contentCapBytes`，默认 1 MB，单轮总预算 256 MB）内容捕获；内存缓存按（路径, size, mtime）命中，未变工作区后续轮次近似零 IO。
- 默认排除：`.git`、`node_modules`、`dist`、`build`、`target`、`out`、`coverage`、`.next`、`.venv`、`__pycache__`、`.idea`、`.vscode` 等（见 `lib/engine.js`）。

## 限制

- 只跟踪插件激活**之后**开始的 loop；激活时已在运行的 loop 会漏掉开头。
- 超过 `contentCapBytes` 的文件（或二进制）：仍检测并计数，但无 diff、不可撤销；可在设置中调高上限。
- 撤销 = 原样回写 loop 开始前的内容；若之后有更新的 loop 改过同一文件，撤销旧 loop 会覆盖新变更。
- 撤销按记录幂等执行，无重做。
- 同一工作区内的子 agent / 后台任务 agent 也会产生记录（共享工作区根），便于一并审查。
- 快照扫描有文件数上限（默认 50,000）。

## 集成面

客户端半端依赖 **`dsh-better-sidebar`**（cordis `inject: ['betterSidebar', …]`——前置声明，服务出现前 UI 挂起），注册：

| 表面 | 条目 | 用途 |
|---|---|---|
| `conversation.chat.turnTail` | chain 条目 | 助手消息按钮行正上方的审查气泡（按 `loop-by-turn` 查询；该轮无变更则不渲染） |
| `betterSidebar.registerTab` | 标签页 `build-diff` | 右侧栏「变更审阅」标签页（单实例、待处理角标、轮次选择、逐文件内联 diff、撤销） |
| `conversation.session.header.actions` | `build-diff` | 会话头按钮，点击在侧边栏打开审阅标签页 |
| `settings.section` | `dsh-build-diff` | 设置页（检测开关 / 上限 / 历史） |

从气泡的「审核」、会话头按钮或「+」菜单均可打开侧边栏标签页（带内容的打开会自动展开右侧面板）。

## 测试

```bash
node test/diff.test.mjs             # Myers diff + hunks + 统一 diff 文本
node test/snapshot.test.mjs         # 扫描 / 捕获 / 对比 / 撤销（临时目录）
node test/host-integration.test.mjs # mock ctx 应用插件 + 完整 loop → 路由 → 撤销
node test/client-smoke.test.mjs     # 浏览器半端模块契约 + 槽位注册
```

## License

MIT
