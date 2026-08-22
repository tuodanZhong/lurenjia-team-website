# DSH 会话置顶

[English](README.md)

`@dsh-external/dsh-session-pins` 为 DeepSeek Harness Web 侧边栏提供可持久化的
会话置顶菜单。

本插件回应了
[DeepSeek Harness Discussion #63](https://github.com/deepseek-ai/deepseek-harness/discussions/63)
中“让高价值会话保持易于访问”的请求。Harness 目前没有公开的会话行操作插槽；替换
内置会话浏览器又会依赖私有 UI 源码。因此，Session Pins 只通过公开、根作用域的
`sidebar.footer.action` 插槽贡献一个操作，不补丁或替换宿主。

## 兼容性状态

源码、自动化契约和包产物以 `@deepseek-ai/dsh@0.1.0-rc.6` 为目标。DeepSeek
Harness 仍处于开发者预览（developer preview）阶段，新的候选版本可能破坏兼容性，
需要重新审核后才能支持。

自动化测试包含隔离、无凭据的 rc.6 profile 冒烟测试：它通过已发布的 CLI 安装本仓库、
组合插件行、在临时回环端口启动、读取根页面启动清单，并获取以包名标识的浏览器模块
路由。Task 7 的展开/收起布局人工视觉验收仍待完成，本 README 不声称它已经通过。

## 使用体验

- **展开（wide）侧边栏：**底部操作显示图钉图标、**固定会话**文字和当前数量。
- **收起（rail）侧边栏：**只显示同一个图标，同时保留无障碍名称和延迟提示。
- 激活后，菜单在底部操作上方打开。选择根列表中的会话后，会在同一菜单内进入详情，
  按情况提供**打开**、**取消固定**和**返回**。没有置顶项时会显示明确的空状态。
- 当前普通会话只有在“非空白且来源不是子代理”时才能置顶。最新置顶位于最前；
  再次置顶已有 id 会把它移到最前而不会重复。当前会话已置顶时会显示
  **取消固定当前会话**。
- 当前空白（blank）会话不能新建置顶。如果存储中已经有空白会话 id，它仍可被移除；
  只有其非子代理摘要仍能解析且工作区可用性可操作时才可打开。
- 当前子代理（subagent）会话不能被新置顶，也不能由本插件打开。已经存储的子代理 id
  仍可移除；被拒绝的打开操作会被安全处理，并保留恢复操作。
- 只有在 `baselinesReady === true`、`phase === 'ready'` 且
  `state === 'idle'` 时，工作区归档状态才可操作。在此之前，所有可解析置顶项的详情都
  不显示**打开**，说明会话可用性尚未就绪，并保留**取消固定**和**返回**。
- DeepSeek Harness `0.1.0-rc.6` 会立即清除通过 `sessions.open()` 选择的归档 id，
  且没有公开的取消归档操作。因此，可操作的已归档置顶项会保留实时标题、不显示
  **打开**、说明此版本限制，并且仍可移除。
- 对于已归档置顶项，Session Pins 不会调用 `sessions.open()`，也不会报告虚假成功。
  插件不使用延迟选择变通方案、私有 API、宿主补丁或定时器。
- 无法再解析的失效（stale）id 会显示为 **不可用：_id_**。详情中不显示**打开**，
  但保留**取消固定**和**返回**。
- 如果会话在操作前消失或 Harness 拒绝打开，菜单会保持可用、播报本地化错误，并保留
  取消固定这一恢复路径。

## 浏览器本地持久化

置顶列表以有版本、保序的 id 列表存入 `localStorage`，键名为
`dsh.session-pins.v1`。输入会被校验：格式错误的数据回退为空列表；非字符串和空 id
会被移除；重复 id 保留第一次出现的位置；最多保留 100 个置顶项。

持久化仅限当前浏览器，不会跨设备、浏览器 profile、不同浏览器或不同源同步。同源
（same-origin）标签页会在插件启用期间通过浏览器 `storage` 事件协调；写入数据的标签页
会直接更新自身，因为浏览器不会把该 `storage` 事件回发给写入文档。如果
`localStorage` 被禁用或抛错，当前页面仍可在内存中使用置顶功能，但刷新后不会保留。

## 发布后安装

GitHub 仓库和标签会在发布步骤中创建。只有在对应版本已经发布后，才能运行以下命令。

把 `v0.1.0` Git 标签安装到内置 Web profile：

```sh
dsh plugin --profile web add github:alooshxl/dsh-session-pins#v0.1.0
```

升级到另一个 Git 标签时，用新标签再次执行 `add`；不要声称 `update` 能选择 Git
引用。例如：

```sh
dsh plugin --profile web add github:alooshxl/dsh-session-pins#v0.1.1
```

如需不可变安装，把占位符替换为完整的 40 字符提交 SHA：

```sh
dsh plugin --profile web add github:alooshxl/dsh-session-pins#<40-character-commit-sha>
```

移除插件：

```sh
dsh plugin --profile web remove @dsh-external/dsh-session-pins
```

启动内置 Web profile：

```sh
dsh web
```

等价的显式启动命令是：

```sh
dsh --profile web
```

包内跟踪了已审核的 `lib/` 产物。因此，从 Git 安装时既不需要安装构建 allowlist，也
没有安装阶段的 `prepare`、`install` 或 `postinstall` 生命周期。

## 安全与宿主边界

- 置顶、取消置顶、持久化和打开会话都不需要 API key 或其他凭据。
- 包不会读取凭据文件，不会携带临时浏览器 profile，也不包含 Harness 私有源码。
- 产品行为只存在于浏览器客户端入口；Node 入口仅用于包注册和浏览器模块发现。
- 集成只使用已发布的 Harness 客户端服务和公开的 `sidebar.footer.action` 插槽，不包含
  宿主补丁、monkey patch 或兼容层。

## 本地开发

使用 Node 22 和 pnpm 11.7.0：

```sh
git clone https://github.com/alooshxl/dsh-session-pins.git
cd dsh-session-pins
pnpm install --frozen-lockfile
```

冻结的开发依赖图只允许精确版本的
`@deepseek-ai/dsh-subprocess-local@0.1.0-rc.6` 和 `node-pty@1.1.0`
这两个传递宿主依赖运行生命周期脚本；Linux 上启动已发布的 rc.6 Web profile
需要它们。其余检测到的脚本全部拒绝。这些仅用于开发验证的宿主包不属于打包插件，
也不属于插件的安装契约。

GNU Make 检查点为：

```sh
make fmt && make test && make lint
```

没有 GNU Make 时，运行完全等价的命令：

```sh
pnpm run format && pnpm run test && pnpm run lint
pnpm run typecheck
```

运行完整的发布检查：

```sh
pnpm run build
pnpm run format:check
pnpm run typecheck
pnpm run verify:self-contained
pnpm run verify:package
git diff --check
git status --short --untracked-files=all -- lib
```

`pnpm run verify:package` 会通过兼容的包管理器调用完成本地 dry-run 包清单校验。

最后一条 `git status` 命令必须没有输出：已跟踪或未跟踪的生成产物漂移都会阻断发布。

## 贡献、讨论与许可证

请通过
[GitHub issues](https://github.com/alooshxl/dsh-session-pins/issues)
报告缺陷或兼容性结果，并通过
[pull requests](https://github.com/alooshxl/dsh-session-pins/pulls)
提交聚焦的改动。功能背景见
[Discussion #63](https://github.com/deepseek-ai/deepseek-harness/discussions/63)。

本项目采用 [MIT License](LICENSE)。
