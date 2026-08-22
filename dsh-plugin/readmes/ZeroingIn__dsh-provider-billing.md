# dsh-provider-billing

[English](README.md) | 中文

[![npm version](https://img.shields.io/npm/v/dsh-provider-billing?logo=npm)](https://www.npmjs.com/package/dsh-provider-billing)

DeepSeek Harness 提供方账户余额插件（独立维护，不在官方仓库内）。在 **Models** 设置页的每个提供方行内显示该路由所存 API 密钥对应的余额，每个路由带刷新控件。密钥从不离开宿主：浏览器只发送路由 id，宿主从配置面解析端点和凭据后，询问提供方的 OpenAI 兼容 `/user/balance` 端点。

**宿主要求**：本插件渲染在 Models 页的 `settings.models.row` 贡献洞中，该洞只由较新的 harness 构建声明。旧版宿主**不受支持**：插件会打印明确的加载失败报错，而不是静默降级。请勿在不受支持的宿主上安装。

## 安装

三种方式等价，任选其一：

### 1. npm

```sh
dsh plugin --profile web add dsh-provider-billing
```

已发布到 npm：[`dsh-provider-billing`](https://www.npmjs.com/package/dsh-provider-billing) —— 最省事的方式：tarball 自带构建好的 `lib/` 与 `cordis.patch.yml`，安装时不执行任何构建。

### 2. GitHub

```sh
dsh plugin --profile web add github:ZeroingIn/dsh-provider-billing
```

GitHub 直装获取的是**源码**：安装时 pnpm 会运行本包的 `prepare` 脚本（`tsdown`，完全自包含——不依赖兄弟 checkout，不从 npm 解析 `@deepseek-ai/*`）。pnpm ≥10 会要求先显式放行构建脚本——把 pnpm 打印的包键加入 profile 的 `pnpm-workspace.yaml`：

```yaml
allowBuilds:
  dsh-provider-billing: true
```

放行 = 允许在安装时执行本包代码。如需锁定构建，可在包名后追加 commit：`github:ZeroingIn/dsh-provider-billing#<sha>`。

### 3. tarball

```sh
pnpm pack        # 产出 dsh-provider-billing-0.1.1.tgz
dsh plugin --profile web add ./dsh-provider-billing-0.1.1.tgz
```

### 本地开发

```sh
dsh plugin --profile web add link:/绝对路径/dsh-provider-billing
```

`link:` 直接链接本目录：改代码 → `pnpm build` → 宿主半改动重启 `dsh web`，仅客户端改动刷新浏览器即可（客户端 bundle 实时服务在 `/plugins/dsh-provider-billing/client.js`）。稳定后切 npm/GitHub 分发。

## 配置

```yaml
- id: provider-billing
  name: dsh-provider-billing
  config:
    providers: [deepseek-official]
```

`providers` 指名可检查的提供方路由（目录中不存在的路由不会出现）。UI 固定为 Models 行内形态（`settings.models.row`）——没有其他形态，不做向下兼容。

## 工作原理

- **宿主半**（`src/index.ts`）：一个插件行通过 `ctx.connection.rpc.handle(..., { authority: 'loopback' })` 注册回环钉住的通用 RPC 通道（`/provider-billing`，端点 `list`/`query`），回环围栏由 Connection 强制（与特权 `/api` 方法同一道围栏）。`query` 解析路由的已存密钥与端点（profile → `<ROUTE>_API_KEY` 派生 → 适配器默认，每个都先查凭据 seam 再查信任环境，先命中者胜出）后请求 `/user/balance`。
- **浏览器半**（`src/client/`）：注册进 Models 页的 `settings.models.row` 洞渲染余额卡片（双语：`余额` / `Balance`）。宿主无行洞时打印明确的加载失败报错。

## 开发

```sh
pnpm install     # 仅工具链——@deepseek-ai/* peers 由安装它的 harness 提供
pnpm typecheck   # 需要 tsconfig.local.json（见下）
pnpm test        # vitest：通道/查询 + 行内卡片
pnpm build       # tsdown + tsc 声明 → lib/{index,invariant,client}.js + lib/types
pnpm pack        # tarball
```

**本地 harness checkout**：npm 上已发布的 `@deepseek-ai/*` rc 包依赖树不完整，因此本包把它们声明为 peerDependencies（由安装它的 harness 满足），类型与测试运行时从本地 harness checkout 解析。创建 `tsconfig.local.json`（已被 gitignore；`pnpm typecheck`、`pnpm test` 与 `pnpm build` 读取它），扩展 `tsconfig.json`，加上输出 `lib/types` 的声明 emit 配置，并把每个 `@deepseek-ai/*` 说明符用 `paths` 指向 checkout 的构建类型：

```jsonc
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "noEmit": false,
    "declaration": true,
    "emitDeclarationOnly": true,
    "outDir": "lib/types",
    "paths": {
      "@deepseek-ai/cordis": ["<HARNESS_CHECKOUT>/vendor/cordis/lib/types"],
      "@deepseek-ai/dsh-llm": ["<HARNESS_CHECKOUT>/packages/llm/llm/lib/types"],
      "@deepseek-ai/dsh-settings": ["<HARNESS_CHECKOUT>/packages/settings/settings/lib/types"],
      "@deepseek-ai/dsh-credentials": ["<HARNESS_CHECKOUT>/packages/credentials/credentials/lib/types"],
      "@deepseek-ai/dsh-launch-environment": ["<HARNESS_CHECKOUT>/packages/util/launch-environment/lib/types"],
      "@deepseek-ai/dsh-host-apiproxy": ["<HARNESS_CHECKOUT>/packages/host/apiproxy/lib/types"],
      "@deepseek-ai/dsh-host-apiproxy/api": ["<HARNESS_CHECKOUT>/packages/host/apiproxy/lib/types/api"],
      "@deepseek-ai/dsh-invariants": ["<HARNESS_CHECKOUT>/packages/runtime-diagnostics/invariants/lib/types"],
      "@deepseek-ai/dsh-client-connection": ["<HARNESS_CHECKOUT>/packages/client/connection/lib/types"],
      "@deepseek-ai/dsh-client-connection/client": ["<HARNESS_CHECKOUT>/packages/client/connection/lib/types/client"],
      "@deepseek-ai/dsh-client-locale/client": ["<HARNESS_CHECKOUT>/packages/client/locale/lib/types/client"],
      "@deepseek-ai/dsh-client-runtime/client": ["<HARNESS_CHECKOUT>/packages/client/runtime/lib/types/client"],
      "@deepseek-ai/dsh-client-test-runtime": ["<HARNESS_CHECKOUT>/packages/test-support/client-runtime/lib/types"],
      "@deepseek-ai/dsh-client-ui-settings/client": ["<HARNESS_CHECKOUT>/packages/client/ui-settings/lib/types/client"],
      "@deepseek-ai/dsh-client-ui-settings-models/client": ["<HARNESS_CHECKOUT>/packages/client/ui-settings-models/lib/types/client"],
      "@deepseek-ai/dsh-client-ui-slots": ["<HARNESS_CHECKOUT>/packages/client/ui-slots/lib/types"],
      "@deepseek-ai/dsh-host-webserver": ["<HARNESS_CHECKOUT>/packages/host/webserver/lib/types"]
    }
  },
  "include": ["src"]
}
```

测试从同一文件派生运行时 alias（把 `/lib/types` 替换为 `/src`）。

## 已知限制

- 只服务 `/user/balance` 约定（DeepSeek 官方形态）；余额 API 不同的提供方会报告自己的错误。
- 端点错误走闭合 wire 分类法的 `internal` 分支（携带描述性消息）。
- npm tarball 不含 `lib/types`，除非发布机先跑了 `pnpm build`（运行时不受影响）。
- `row` 形态要求 `settings.models.row` 行洞；不支持的宿主构建会失败出声。

## 许可证

[MIT](LICENSE)
