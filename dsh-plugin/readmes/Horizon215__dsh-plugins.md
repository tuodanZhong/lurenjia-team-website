# dsh-plugins

[中文](#中文) | [English](#english)

Community client-UI plugins for [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (`dsh`) — 社区开发的 DeepSeek Harness 客户端 UI 插件。

---

## 中文

两个即装即用的 Web UI 插件。当前从 GitHub 源码安装（npm 包稍后发布）：

```sh
git clone https://github.com/Horizon215/dsh-plugins.git
cd dsh-plugins
pnpm install && pnpm build
dsh plugin --profile web add file:./packages/prompt-templates file:./packages/token-stats
```

装完重启 `dsh web` 即可（插件声明了 `dsh.bundle`，会自动装配进 profile，无需手动改配置）。

### 📊 dsh-token-stats —— Token 用量与成本统计

![每轮用量条](assets/token-stats-chip.png)

- **每轮用量条**：每轮对话末尾显示 `输入 · 输出 | 缓存命中率 | 耗时 | ≈成本`
- **汇总仪表盘**（设置 → 用量与成本）：跨会话累计 tokens、缓存命中率、估算总成本
- **使用趋势图**：累计用量面积图，支持 今天（按小时）/ 近 7 天 / 近 30 天 切换，随对话动态增长
- **价格预设**：内置 DeepSeek V4-Flash / V4-Pro / Kimi K3（人民币与美元）刊例价，可选手动微调；改价后所有展示实时重算

![设置页](assets/token-stats-settings.png)

### 📝 dsh-prompt-templates —— 提示词模板库

![模板管理](assets/prompt-templates-modal.png)

- 输入框右侧新增模板按钮，保存常用提示词
- 一键**插入**到草稿（自动空行拼接）或**插入并发送**
- 模板增删改查，两步删除防误触
- 数据保存在浏览器 localStorage，不上传任何服务器

### 兼容性

- 需要 dsh ≥ `0.1.0-rc.5`（在 `0.1.0-rc.5` / `0.1.0-rc.6` 上验证通过）
- 仅 Web UI（`dsh web`），TUI/headless 不受影响
- 所有数据仅存浏览器本地；成本为估算值，以供应商账单为准

### 卸载

```sh
dsh plugin --profile web remove @your-scope/dsh-prompt-templates @your-scope/dsh-token-stats
```

### 本地开发

```sh
pnpm install
pnpm typecheck   # 类型检查（对齐官方 monorepo 的严格度）
pnpm build       # 产出 packages/*/lib/client.js
```

构建预设 `build/client-bundle.mjs` 提取自官方仓库的 `packages/client/tsdown.client.ts`（MIT），
包含模块表 externals、纯净性检查和 CSS Modules 内联，与官方插件的构建产物结构完全一致。

---

## English

Two drop-in client-UI plugins for the DeepSeek Harness web UI. Install from source (npm packages coming soon):

```sh
git clone https://github.com/Horizon215/dsh-plugins.git
cd dsh-plugins
pnpm install && pnpm build
dsh plugin --profile web add file:./packages/prompt-templates file:./packages/token-stats
```

Restart `dsh web` afterwards — the packages declare `dsh.bundle`, so they join the profile automatically (no manual config edits).

### dsh-token-stats — token usage & cost

- **Per-turn chip** under each completed turn: `input · output | cache hit | duration | ≈cost`
- **Aggregate dashboard** (Settings → Usage & Cost): cross-session totals, cache-hit bar, estimated cost
- **Usage trend**: cumulative area chart with Today (hourly) / 7 days / 30 days ranges, growing live as turns complete
- **Price presets**: DeepSeek V4-Flash / V4-Pro / Kimi K3 list prices (CNY & USD), freely editable; every display reprices live

### dsh-prompt-templates — prompt template library

- Composer toolbar button opens a manager modal: create / edit / delete templates
- **Insert** appends to the draft (blank-line joined); **Insert & send** fires immediately
- Templates persist in browser localStorage — nothing leaves the machine

### Compatibility & privacy

- Requires dsh ≥ `0.1.0-rc.5` (verified on rc.5/rc.6), web UI only
- All data stays in browser localStorage; costs are estimates — your provider invoice wins

### Development

```sh
pnpm install && pnpm typecheck && pnpm build
```

The build preset (`build/client-bundle.mjs`) is extracted from the upstream repo's
`packages/client/tsdown.client.ts` (MIT) — module-table externals, the bundle-purity
gate, and CSS Modules inlining included, producing byte-structure-identical artifacts
to first-party plugins.

## License

MIT
