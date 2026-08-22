# dsh-change-trace

DeepSeek Harness 的**变更叙事与指令追溯**插件：每条人类指令的卡片展示文件改动、工具调用结果、思考节选，以及**子代理工作流树**（可点击钻入子代理自己的会话）。

![change-trace 卡片：指令变更叙事、工具调用、子代理工作流树](docs/screenshot.png)

## 快速安装（推荐）

需要已安装 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)（`npx @deepseek-ai/dsh web`）。

```sh
# 1. 安装 bundle（含 host 运行时 + 浏览器卡片插件）
dsh plugin --profile demo add dsh-change-trace-bundle

# 2. 启动
dsh --profile demo web
```

安装后，每个会话里：
- 每条人类指令下方出现 change-trace 卡片（变更叙事 / 文件改动 / 工具调用 chips / 思考节选）；
- 指令派生了子代理时，卡片出现**子代理工作流树**——节点带 ✓/✗ 状态，点击展开摘要，点"打开会话"钻入子代理自己的卡片。

## 手动配置

如果不想用 bundle，也可以直接把两个插件装进 profile，在 `$DSH_HOME/profiles/<name>/cordis.patch.yml` 加：

```yaml
- insert:
    - id: change-trace
      name: dsh-change-trace
      config:
        narrator: template

    - id: ui-change-trace
      name: dsh-client-ui-change-trace
```

## 配置

| 字段 | 默认 | 含义 |
|---|---|---|
| `narrator` | `template` | 叙事策略：确定性模板，或 `llm`（自然语言摘要，模板兜底） |
| `provider` / `model` | 部署默认 | LLM 叙事器的路由与模型 |
| `timeoutMs` | `15000` | 单次 LLM 叙事请求时限 |

## 给开发者

```sh
git clone <你的仓库地址> dsh-change-trace
cd dsh-change-trace
pnpm install
pnpm -r run build      # 构建两个包到 lib/
pnpm test              # vitest
```

## ⚠️ 当前分发状态（重要）

**独立 npm 分发暂时被官方发布缺口阻塞**：

- ✅ **host 插件**（`dsh-change-trace`）：依赖已对齐官方 `0.1.0-rc.6`，依赖链可独立安装（pnpm 自动安装 peer 失败时加 `--config.auto-install-peers=false`）；
- ❌ **client 插件**（`dsh-client-ui-change-trace`）：依赖链上的 `@deepseek-ai/dsh-compact` 与 `@deepseek-ai/dsh-type-meta` **未发布**（官方 npm 404），暂时无法独立 npm 分发；
- ✅ **当前最可靠的分发方式：fork 分发**——把 deepseek-harness monorepo（含本插件）推到你的 GitHub，别人 `git clone` → `pnpm install && pnpm run build && pnpm dsh web`，插件直接可用。

## 发布到 npm（等官方发布完整后）

1. **改包名**：把三个 `package.json` 的 `name` 改成你的 scope（如 `@你的名字/dsh-change-trace`），`cordis.patch.yml` 里的 `name` 同步改；
2. 登录 npm：`npm login`；
3. 发布三个包（根 bundle + 两个插件）：
```sh
pnpm publish -r
```
4. 完成后别人就能：`dsh plugin --profile demo add @你的名字/dsh-change-trace-bundle`

> 注意：`workspace:*` 依赖在 `pnpm publish` 时会被自动替换为真实版本。

## 结构

```text
dsh-change-trace/
├── package.json          # bundle：dsh.bundle 声明（分发入口）
├── cordis.patch.yml      # ★ 插件插入点：两个插件的配置行
├── packages/
│   ├── change-trace/         # host 插件：分析/叙事/事件追加/查询（Node 端）
│   └── client-ui-change-trace/  # client 插件：卡片与子代理树（浏览器端）
└── vitest.config.ts
```

## 已知限制

- **host 包基于官方 npm 发布版 `0.1.0-rc.6` 适配**；若官方后续 API 变更，需同步升级；
- **官方 npm 发布不完整**（`@deepseek-ai/dsh-compact`、`@deepseek-ai/dsh-type-meta` 缺失），独立 client 分发需等官方补发；当前推荐 fork 分发；
- client 插件需要 web 端能加载用户插件（`dsh plugin` 安装 + profile 配置行）；
- 冲突检测是启发式（行重叠判定）；
- LLM 叙事器需要已配置的 LLM 适配器，失败自动回退模板。