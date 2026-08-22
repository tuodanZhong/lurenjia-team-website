# dsh-changes-panel · diff 面板

DeepSeek Harness Web GUI 的会话内 diff 面板：实时展示当前会话里所有被 `edit`/`write` 工具改动的文件，以及每个文件相对其最近状态分界点（本会话首次改动前的内容；条目被采纳/回退后以当时内容重新为界）的**累计差异**（git 风格 `+`绿 / `−`红），避免对话中看不清改动、误操作。

术语与设计决策见 [`CONTEXT.md`](./CONTEXT.md) 与 [`docs/adr/`](./docs/adr/)。

## 特性

- 入口是会话标签栏（`[role="tablist"]`，与「对话/轨迹」同排对齐）的 **diff** 标签，带改动数量角标，点击开合面板
- 面板位于**会话界面内部**：header 正下方、右侧贴边，不遮 header、不独立成框架级列
- 打开时聊天区与输入框整体左移（对 `[data-conversation-scroll]` 加 `margin-right`，带过渡动画），header 与标签栏不动；聊天内容在常见屏宽下只重新居中、不缩窄
- 面板**左缘拖拽调宽**（220–640px，始终给聊天区留 ≥320px），宽度在会话切换间保留
- 面板默认收起，仅在**出现真正改动**（会话工作集由空转非空）时自动展开；新建会话、切换会话、刷新页面、用户提问都不会触发展开，手动关闭后改动清零前保持关闭；工作区内/工作区外两个分区**按改动自动展开**（出现改动→展开，改动清零→收起，无转变时尊重手动开合）
- 文件行默认列出（`A/M` 状态 + 相对路径/绝对路径 + `+N −M` 统计）；`A` = 本会话新增（`fs/write-intent` 写入前探测到文件不存在，整文件渲染为 `+` 行），`M` = 已存在文件被修改；每个文件的 diff 详情默认收起，点击展开
- diff 带上下文行，滑动展开；`+` 绿、`−` 红；官方代码字体；单文件可「全屏」查看
- 底部操作条：勾选文件后 **采纳**（仅从面板移除）/ **回退**（把基线内容写回磁盘）；两个分区标签行带**全选勾选框**（已全选时点击即取消，分区为空时禁用），一键选中整个分区再操作；条目被采纳/回退后，该文件的下一次改动会以**采纳/回退后的状态**为新基线重新展示 diff
- 工作集按顶层会话一一对应（子代理的改动归属其父会话）；会话删除时清理（`session/disposed`）
- 深色主题使用官方 `--dsw-alias-*` token，自动跟随亮/暗主题

## 不包含（有意暂缓）

- **删除(D)**：本 harness 无删除工具（只能 shell 写盘），首版不追踪。见 `docs/adr/0001-defer-deletion-tracking.md`。
- **持久化**：工作集目前在 host 内存中——刷新页面不丢，重启 `dsh web` 清空。`storageDomain` 持久化因 zod 依赖问题暂缓。

## 结构

```
dsh-changes-panel/
├── CONTEXT.md                 # 术语表
├── docs/adr/                  # 架构决策记录
├── cordis.patch.yml           # 插入 host 半到插件花名册
├── package.json               # dsh.bundle.patch + dsh.client 声明
├── tsdown.config.ts           # node + browser 双产物构建
├── src/index.ts               # host 半：fs/observed 内容快照 + 会话隔离 + webServer 路由
└── src/client/index.ts        # client 半：标签注入 + 会话内面板 + diff 渲染
```

## 工作原理

- **host**：监听全局 `fs/observed` 事件，首次观察某路径时记录基线，内容变化即视为改动，用 LCS 行 diff 计算累计差异；`fs/write-intent` 前置探测目标不存在则标记为新增（`A`，基线为空内容）；条目被采纳/回退移除后，文件下次写/改前的 `fs/write-intent` / `fs/edit-intent` 会重新捕获当前内容作为新基线，让后续改动与采纳/回退后的状态对比；通过 `webServer` 注册 `GET /plugins/ui-changes-panel/working-set?sessionId=...` 输出 JSON，`POST /plugins/ui-changes-panel/action` 执行批量采纳/回退。工作集在 host 内存中按会话隔离（子代理改动归属顶层会话），`session/disposed` 时删除。
- **client**：把 `diff` 标签注入会话标签栏；面板本体挂在 `shell.overlay` 层，几何从 `[data-conversation-scroll]` 实测（ResizeObserver + 1s 心跳同步）；打开时给同一元素加 `margin-right` 让聊天区左移；`useSessions(s => s.current)` 取当前会话 id，轮询 working-set 渲染。

## 构建与安装

```sh
cd dsh-changes-panel
pnpm install
pnpm build                     # 产出 lib/index.js + lib/client.js
pnpm test                      # 运行 diff 算法单元测试
```

把包接入某个 Web 配置（profile）：在该 profile 的 `package.json` 中加入依赖

```json
"@dsh-external/dsh-client-changes-panel": "link:<本目录的绝对路径>"
```

重新安装依赖并重启 `dsh web` 即生效。host 半（`cordis.patch.yml`）与 client 半（`package.json` 的 `dsh.client` 声明）由包自身携带，无需额外配置。

> 生产构建建议改用 dsh-web-ui 脚手架自带的 `clientBundle` 预设（maid-atelier 同款）；本仓库的 `tsdown.config.ts` 是最小自包含替代。

## 遗留 TODO

- **删除(D) 状态**：见 `docs/adr/0001`——首版只追踪新增/修改，删除需 shell 写盘追踪，暂缓。
- **「新增(A)」的回退**：`A` 已实现（`fs/write-intent` 写入前探测）；但回退新增文件目前只把基线（空内容）写回，留下空文件而非删除文件——fs 服务无删除能力，真正的删除仍有意暂缓，见 `docs/adr/0001`。
- **持久化**：工作集落盘（`storageDomain`）以跨 host 重启保留。
- **面板宽度持久化**：拖拽宽度目前仅保留在页面生命周期内。

## 许可

MIT。
