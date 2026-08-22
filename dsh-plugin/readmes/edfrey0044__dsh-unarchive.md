# dsh-unarchive

[English](README.md) | 中文

为 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) 恢复已归档的会话。归档只会把会话从所有分组视图（工作区分组、未分组、平铺列表、搜索）中隐藏，从不删除数据。这个插件补上了缺失的逆操作：两个入口把会话从注册表级全局归档集合中移除，让它在原位置重新出现。

## 提供的入口

| 入口 | 位置 | 行为 |
| --- | --- | --- |
| `/unarchive` | GUI 命令面板（`/` 菜单）或任意命令入口 | 不带参数列出归档会话（id + 尽力而为的标题）；带会话 id 则恢复该会话 |
| `unarchive_session` | 模型工具（任意会话可用） | 省略 `sessionId` 时列出归档会话；传入 `sessionId` 恢复一个 |

两个入口都能让会话在所有已连接的 GUI 客户端里实时恢复（`host/archived-sessions-changed`），且重启后仍然生效。会话日志和工作区记账席位完全不受影响。

## 要求

除标准 DeepSeek Harness profile 外无额外要求。插件是**自包含**的：

- 当所在构建提供 `workspaceRegistry.unarchiveSession` 时，走这条持久化核心 API；
- 否则直接写入 workspace 域的 `archivedSessionIds` 全局数据——这正是 `archiveSession` 读写的那份持久化、可实时刷新的数据。

**自包含模式的已知限制：** 直接写域会让 workspace 注册表的内存缓存陈旧，直到下次重启。在此之前，会话会实时恢复显示，但（a）刷新页面会再次隐藏它，（b）再做归档/工作区变更可能把它重新归档。重启 dsh 后即完全恢复正常。

## 安装

以 profile bundle 方式安装（推荐），在本仓库检出目录执行：

```sh
dsh plugin --profile web add github:edfrey0044/dsh-unarchive
# 或发布到 npm 之后：
dsh plugin --profile web add dsh-unarchive
```

重启 `dsh web`（或你的 profile）。由于本包声明了 `dsh.bundle.patch`，补丁层会自动加入 profile 的层栈。

手动组合：在 profile 的 `cordis.patch.yml` 中加一行，并把包安装进 profile：

```yaml
# ~/.dsh/profiles/<name>/cordis.patch.yml（向 profile 根插入一条）
- insert:
    - id: dsh-unarchive
      name: dsh-unarchive
```

```sh
cd ~/.dsh/profiles/<name>
pnpm add github:edfrey0044/dsh-unarchive
```

## 用法

先看归档了哪些会话，再恢复：

```
/unarchive
Archived sessions:
- session-0a701da0-449d-4997-bf87-a4b6aae7ceee  (张雪峰谈2026文科女生报考西财中外学院)
- session-b96a78f1-b6bf-439b-9570-c054307e6adb  (张雪峰视角：西财中外合作报考建议)

/unarchive session-0a701da0-449d-4997-bf87-a4b6aae7ceee
Session session-0a701da0-449d-4997-bf87-a4b6aae7ceee restored; it is visible again in the workspace at its original position.
```

英文演示（GUI 命令面板里的 `/unarchive`）：

![dsh-unarchive 演示](assets/demo.png)

也可以直接在任意会话里对 agent 说"把归档的会话恢复一下"，模型会替你调用 `unarchive_session`。

会话 id 也存在于磁盘：`~/.dsh/sessions/<项目>/<会话id>/`（或 `$DSH_HOME/sessions/...`），归档集合本身在 `~/.dsh/storages/workspace.json` 的 `global.archivedSessionIds`。

## 工作原理

归档时会话在 workspace 记账中的 `sessionIds` 席位保持不变，只做一次"展示集合"写入把 id 放进 `archivedSessionIds`；取消归档就是逆写入，所以会话会回到原位置。

当构建提供核心 API（`WorkspaceRegistry.unarchiveSession`）时插件优先走它；在标准构建上则通过 `ctx.storageDomain` 直接写 workspace 域的 `archivedSessionIds` 全局数据。该写入是持久化的，并会发出 `domain/changed`，宿主据此向所有已连接客户端推送 `host/archived-sessions-changed`。自包含路径的唯一限制是注册表的内存缓存（见上文"要求"）。

## 开发

实现是纯 ESM（`lib/index.js`）+ 手写类型声明，无构建步骤。

- `npm test`：基于桩的单元测试（假注册表，不启动 DSH）。
- 端到端验证：在真实 harness 检出里挂载插件 + 真实 `storage-domain`/`workspaceRegistry`，用临时世界驱动捕获的命令处理器。场景结构见 `tests/`。

## 许可证

MIT
