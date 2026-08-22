# dsh-llm-headers

为 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) 的自定义 LLM API 请求注入 HTTP Headers（典型用途：改写 `user-agent`，例如网关要求 UA 带指定品牌字样）。

## 原理

DeepSeek Harness 的 LLM 适配器（`dsh-llm-deepseek`、`dsh-llm-pi-ai`）都通过全局 `fetch` 发出模型请求。本插件在加载时包装 `globalThis.fetch`：**仅对 URL 匹配 `urlPatterns` 的请求**，把配置的 `headers` 逐项 `set()` 上去（覆盖同名头，包括适配器的强制 attribution `user-agent` —— 即部署者白标替换场景），其余请求原样透传。提供商无关，一次配置同时作用于所有 LLM provider。

配置不写死：插件把 `Config` schema 注册为 `llm-headers` 用户配置命名空间，**Web UI 的 settings 页面会自动渲染该命名空间的编辑表单**，修改保存后下一个请求即生效（live 热重载，无需重启）。

## 安装

### 作为 bundle（发布形态）

把本目录作为一个包安装进 profile：

```sh
dsh plugin --profile <name> add /path/to/llm-headers
```

`dsh` 会追加 `llm-headers` 到 profile 的 bundle 层，默认配置下插件处于惰性状态（`headers` 为空），不会改写任何请求。

### 本地源码加载（开发形态）

在任一 `cordis.yml`（或 patch overlay）里按路径引用源码，仅用于开发调试：

```yaml
- insert:
    - id: llm-headers
      name: /absolute/path/to/llm-headers/src/index.ts
```

## 配置

```yaml
- id: llm-headers
  name: dsh-llm-headers
  config:
    headers:
      user-agent: opencode/1.0
    urlPatterns:
      - /chat/completions
```

| 字段          | 类型                     | 默认                    | 说明                                 |
| ------------- | ------------------------ | ----------------------- | ------------------------------------ |
| `headers`     | `Record<string, string>` | `{}`                    | 注入的请求头；同名覆盖，空表示不注入 |
| `urlPatterns` | `string[]`               | `['/chat/completions']` | URL 子串匹配规则，命中任一项即注入   |

### 通过 Web UI 配置

安装到含 Web 界面的 profile 后：

1. 打开 Web UI → Settings（设置）页面；
2. 「插件」→「插件配置」应看到本插件的 **LLM 请求头**卡片（服务端注册已就绪）；
3. 填写 `headers` 与 `urlPatterns` 保存，写入 user-settings 文档并实时生效（`applies: live`）。

UI 保存的值优先级高于 cordis.yml 中的 `config`（作为 base 层）。

### 通过 settings.yaml 配置（备用）

```yaml
llm-headers:
  headers:
    user-agent: opencode/1.0
  urlPatterns:
    - /chat/completions
```

保存即热重载（`applies: live`），无需重启。

## 开发

依赖全部来自 npm registry（`@deepseek-ai/cordis`、`@deepseek-ai/schemastery`、`@deepseek-ai/dsh-settings` 及构建工具），克隆后直接安装即可；其余 `@deepseek-ai/*` 包（宿主侧的适配器、settings provider 等）由 DeepSeek Harness 安装提供，本插件不直接依赖。

```sh
pnpm install         # 同时安装 lefthook pre-commit 钩子（lint + 空白检查）
pnpm typecheck       # tsc --noEmit
pnpm test            # vitest：fetch 代理行为矩阵 + 客户端逻辑/RPC/集成
pnpm test:coverage   # v8 覆盖率门禁：src 逐文件 100%，CI 以此为准
pnpm lint            # oxlint + stylistic/sonarjs，规则集与 deepseek-harness 一致（无分号、单引号）
pnpm lint:fix        # 全仓自动修复
pnpm duplication     # jscpd 重复检测
pnpm hygiene         # build + knip + publint 发布前检查
pnpm build           # tsdown 产出 lib/（ESM + 类型声明）
pnpm test:e2e        # 自动化冒烟（需 DEEPSEEK_API_KEY，见下文）
```

门禁与代码风格（含 pre-commit 钩子）与宿主 [deepseek-harness](https://github.com/deepseek-ai/deepseek-harness) 对齐；提交需通过 `pnpm lint && pnpm test:coverage && pnpm duplication && pnpm hygiene`。

### 端到端冒烟（`e2e/`）

`e2e/echo-server.mjs` 是一个记录请求头并返回模拟流式响应的本地服务器，配合 `e2e/overlay.yml` 验证自定义头真的到达了 provider 请求。**把哪个 provider 设为默认路由，就把它的 `baseURL` 临时指向 echo**——例如本机使用 pi-ai 的 opencode 路由时，在 `$DSH_HOME/settings.yaml` 的 `llm-pi-ai.providers.opencode` 下临时加一行 `baseURL: http://127.0.0.1:8734`：

```sh
node e2e/echo-server.mjs            # 终端 A：启动并逐请求打印 URL 与 user-agent
pnpx @deepseek-ai/dsh --profile headless --patch E:/absolute/path/llm-headers/e2e/overlay.yml "Reply ok"  # 终端 B：发布版 CLI，启动比源码 pnpm dsh 更快
```

服务器终端应打印来自该任务请求的 `user-agent: <overlay 里配置的值>`。**验证完成后务必还原 settings.yaml**；新 profile 与 `./.sessions` 等产物按需清理。

上述流程已脚本化为 `e2e/smoke.mjs`（`pnpm test:e2e`）：自动备份并改写 settings.yaml、启动 echo、跑一个 headless 任务、断言收到配置的 user-agent，最后无论成败都还原并清理。需要 `DEEPSEEK_API_KEY`；可用 `DSH_HOME` / `PROFILE` / `PROVIDER_SECTION` / `ECHO_PORT` / `PLUGIN_FILE` 覆盖默认值（见脚本头部注释）。

## 说明与限制

- `user-agent` 覆盖即部署者白标替换：仓库的强制 attribution 决策（`dsh-llm/src/attribution.ts`）本身不允许抑制归因，但允许通过 identity 替换为部署者品牌；本插件在 HTTP 层做等价替换，仅当你在 `headers` 中**显式**配置该头时才生效，未配置时 attribution 原样保留。
- 多个插件同时包装 `fetch` 会互相覆盖；本插件在卸载时只在自己仍是当前包装器的情况下恢复原值，不破坏后续包装者。
- 请求 URL 无法分类（如跨 realm 的 `Request` 实例）时原样透传。
- `urlPatterns` 中的空字符串会被忽略，不会误匹配全部 URL（fetch 层派生时过滤出非空模式集合）。
- Web 卡片保存携带最后一次读取的 revision（乐观并发）：配置在别处被修改时，保存会以冲突提示拒绝并自动刷新显示；「恢复默认」按钮清空用户层，回到 cordis.yml `config` 与 schema 默认值。
- `./client` 入口（`lib/client.js`）是供宿主 Web 模块加载器消费的闭包工厂，不面向第三方，因此不发布类型声明；确需 TS 消费请自行声明。
