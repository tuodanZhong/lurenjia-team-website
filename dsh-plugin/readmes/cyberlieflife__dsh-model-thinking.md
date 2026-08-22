# dsh-model-thinking

DSH Web GUI 插件：为 **自定义模型**（OpenAI-compatible 的 `llm-pi-ai` 提供方）增加**思考强度（thinking intensity / reasoning effort）配置**。

官方设置页的「模型」卡片刻意不提供 reasoning-effort 控件（它属于**按模型**的能力），本插件把这一层配置做成独立的设置分区：

- **按提供方**：默认思考强度（`providers.<route>.reasoning`）——请求未显式选择级别时自动生效；
- **按模型**：思考能力开关（`reasoningEfforts`：`false` 关闭 / 级别表启用）、思考强度级别及其**线格式**（wire spelling）、推理分派兼容（`compat.thinkingFormat` / `supportsReasoningEffort`）。

所有写入都落在既有 `llm-pi-ai` 用户设置段（`settings.mutate` 路径操作 + revision 围栏），**不改动 DSH 源码**。配置后：

- 会话 composer 的模型选择器会为这些模型显示思考强度级别（adapter 通过 `resolveModelInfo` 暴露）；
- 未选择级别时使用提供方默认强度（adapter 的 `defaultEffort` 物化路径）。

## 界面

设置面板 → 「思考强度」（位于「模型」与「插件」分区之间）：

```
┌ 提供方卡片 ─────────────────────────────┐
│ Jasper  [jasper]  [未保存] [用户已配置]  │  默认思考强度: [高]
│ ┌ 模型行 ───────────────────────────┐  │
│ │ DeepSeek-V4-Flash  [思考能力: 启用思考] │
│ │ 思考强度级别:                       │  │
│ │  ☑ 关闭 [线格式留空]  ☐ 最低  ☑ 高 [high] │
│ │ 推理分派兼容: thinkingFormat [继承]    │  │
│ │               supportsReasoningEffort [继承] │
│ └───────────────────────────────────┘  │
└────────────────────────────────────────┘
[放弃] [保存]
```

## 思考强度级别

`off / minimal / low / medium / high / xhigh / max`（pi-ai `ModelThinkingLevel`）。每个勾选的级别可以填写独立的**线格式**值（发给端点的参数，默认等于级别名；`off` 留空 = 不发送该参数）。启用思考时至少要有一个非 `off` 级别。

## 安装（web profile）

```powershell
# 1. 构建（需要 node >= 20 + pnpm）
pnpm install
pnpm build          # 产出 lib/（node 半 + client 半）

# 2. 挂载到 web profile —— 一条命令：
#    pnpm add 到 profile + 自动加入 dsh.profile.bundles（因本包声明了 dsh.bundle.patch）
dsh plugin --profile web add link:<本插件绝对路径>

# 3. 重启 dsh web 并硬刷新浏览器（Ctrl+Shift+R）
```

> 等价的手工步骤：在 `~/.dsh/profiles/web/package.json` 的 dependencies 加
> `"dsh-model-thinking": "link:<绝对路径>"`，把 `dsh-model-thinking` 追加到
> `dsh.profile.bundles`，然后在 profile 目录 `pnpm install`。bundle 层会自动应用本包的
> `cordis.patch.yml`（插入 `model-thinking` 插件行），浏览器端经
> `dsh.client` 声明加载 `/plugins/dsh-model-thinking/client.js`。

卸载：`dsh plugin --profile web rm dsh-model-thinking`（或手工移除依赖 + bundles 条目 + `pnpm install`）。
### 从 GitHub 安装

```powershell
dsh plugin --profile web add github:cyberlieflife/dsh-model-thinking
```

包的 `prepare` 脚本会在安装时自动构建（本机需 node >= 20 + pnpm）。pnpm 默认会拦截依赖的构建脚本：
如果安装时提示 build script 被忽略，在 profile 目录的 `pnpm-workspace.yaml` 的 `allowBuilds` 下按提示加入对应键
（如 `dsh-model-thinking: true`），然后重跑上面的命令。


## 数据形态（写入 `~/.dsh/settings.yaml` 的 `llm-pi-ai` 段）

```yaml
llm-pi-ai:
  providers:
    jasper:
      reasoning: high            # 默认思考强度
      models:
        - id: deepseek-v4-flash
          reasoningEfforts:
            off: null            # off 不发送参数
            high: high
          compat:
            thinkingFormat: deepseek      # 端点期望的思考参数格式
            supportsReasoningEffort: true # 端点接受 reasoning_effort
```

这些字段本就是 `dsh-llm-pi-ai` 适配器理解的配置（`PiAiProviderProfile` / `PiAiModelProfile`），
写错会被适配器的设置校验拒绝（页面显示保存失败原因），不会留下坏配置。

## 开发

- `pnpm typecheck` —— tsc 全量检查
- `pnpm test` —— ops 构建器单元测试（vitest，node 环境）
- `pnpm build` —— `tsc` 出类型 + `tsdown` 出 lib（node 半 ESM；client 半 CJS closure，经 `window.__ModuleLoader__.load` 注册，react/cordis 走平台模块表）

### 结构

```
src/
  index.ts                 # host 半（占位 apply；浏览器面在 ./client）
  invariant.ts
  client/
    index.tsx              # client 半入口：locale + settings.section 注册
    locales.ts             # zh / en 词典
    model-thinking.ts      # 纯模型：级别/线格式/draft/ops 构建器
    controller.ts          # 控制器：describe -> draft -> mutate（revision 围栏）
    thinking-section.tsx   # 设置分区 UI
    section.module.css     # 自包含样式
tests/
  ops.spec.ts
```

### 设计约束

- 不修改 DSH 源码；只经 `cordis.patch.yml` + profile 机制挂载；
- client bundle 纯度门：禁止 value-import 其他 `@deepseek-ai/*` 包（类型导入被擦除不触发）；
- 写入用路径操作而非重建整个 `providers` 子树，避免丢弃页面未编辑的字段（headers/retryPolicy 等）；
- 并发修改冲突（`settings-conflict`）时重新加载并提示，不覆盖他人的写入。

## 许可

MIT