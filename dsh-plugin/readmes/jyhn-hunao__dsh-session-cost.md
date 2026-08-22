# dsh-session-cost

DeepSeek Harness 插件：按会话统计模型上报的 token 用量，并以人民币显示估算费用。

- `session_cost` 模型工具：让 agent 查询一个或多个对话的消耗（不传 `sessionIds` 时查当前对话）。
- `/session-cost [sessionId]` 命令：面向用户，不带参数时查当前对话；`/session-cost-config` 查看当前价格表。
- 侧边栏会话列表每行金额：见 [已知依赖](#已知依赖)。

数据来自会话日志中模型上报的 `usage`（`assistant/message` / `assistant/chunk`），与内置 token 统计同源，非估算；费用按模型价格表换算。

## 效果

侧边栏会话列表每一行末尾显示该会话的累计费用（¥）：

![效果图](assets/screenshot.png)

## 安装

从 GitHub 安装（源码安装无需构建：本包为纯 JS，无 build 步骤）：

```sh
dsh plugin --profile <name> add github:jyhn-hunao/dsh-session-cost
```

首次安装若 pnpm 提示构建脚本未授权，在 profile 的 `pnpm-workspace.yaml` 加入 `allowBuilds: dsh-session-cost: true` 并重试（本包实际没有构建脚本，该提示可安全允许）。

## 使用

```text
/session-cost                 # 当前对话的累计消耗
/session-cost <sessionId>     # 指定会话
/session-cost-config          # 查看当前价格表
```

让 agent 查询时直接说「查一下每个对话消耗了多少钱」即可触发 `session_cost` 工具。

## 价格表

默认价格表（元 / 每百万 tokens，DeepSeek 常规费率）：

| 模型 | 输入 | 缓存命中 | 缓存写 | 输出 |
| --- | --- | --- | --- | --- |
| deepseek-chat | 2 | 0.5 | 2 | 8 |
| deepseek-reasoner | 4 | 1 | 4 | 16 |
| *（回退） | 2 | 0.5 | 2 | 8 |

> ⚠️ DeepSeek 自 2026-08-17 起执行峰谷定价，高峰时段费率更高。默认值为常规费率估算，请按你的实际结算费率覆盖。

在 profile 的 `cordis.patch.yml` 中按 id 覆盖整行 config（**整表替换**，未列出的模型回退到 `*`）：

```yaml
- patch:
    - id: session-cost
      config:
        pricing:
          deepseek-chat: { inputPerM: 2, cacheReadPerM: 0.5, cacheWritePerM: 2, outputPerM: 8 }
          deepseek-reasoner: { inputPerM: 4, cacheReadPerM: 1, cacheWritePerM: 4, outputPerM: 16 }
          '*': { inputPerM: 2, cacheReadPerM: 0.5, cacheWritePerM: 2, outputPerM: 8 }
```

## 已知依赖

侧边栏会话列表每行金额（`lib/client.js`）注册到 `sidebar.workspaces.sessionRow` 插槽，该插槽是 DSH 官方仓库的本地扩展（ui-workspace 新增的行级插槽），**官方原版 DSH 尚未包含**。在官方原版上：

- `session_cost` 工具与 `/session-cost` 命令正常工作；
- 侧边栏行内金额静默不生效（插槽未声明，Client 贡献等待而不报错）。

要让行内金额生效，需要安装带 `sidebar.workspaces.sessionRow` 插槽的 DSH 构建（或在官方仓库合入对应补丁：`ui-workspace` 的 `contract/slots.ts` 声明插槽、`WorkspaceBrowser`/`Rows.tsx` 渲染每行 `rowSlot`）。

## 结构

```
dsh-session-cost/
├── package.json       # dsh.bundle（patch 层）+ dsh.client（浏览器 bundle）
├── cordis.patch.yml   # 插入插件行
├── index.js           # Host 端：工具 + 命令 + 价格表（纯 JS，零依赖）
├── lib/client.js      # Client 端：会话行金额（手写 bundle，免构建）
└── README.md
```

## License

MIT
