# 修复dsv4p0813过拟合标准预设

一个可直接加载到 **DSH（DeepSeek Harness）** 的 agent 预设。

| 项 | 值 |
|---|---|
| preset id | `fix-dsv4p0813-overfit` |
| 显示名 | 修复dsv4p0813过拟合标准预设 |
| 组成 | 标准模式（standard）全部工具 + 首行提示词替换为极简模式开头 |

## 它是什么

- **工具集**：与标准模式完全一致 —— bash/pwsh、文件读写与检索、Skills、计划模式、目标、子代理、工作流、web 检索、ask_user_question、todo 等。
- **提示词**：仅把 standard 的 persona 首行替换为极简模式那句：

  ```
  You are a helpful software engineer assistant.
  ```

  未设置 `complete: true`，因此标准模式其余的提示拼接（identity、Web 方向、工具引导、agent-instructions 等）照常保留。
- **用途**：针对 dsv4p0813 模型过拟合场景的调参预设。

## 前置条件

- 已安装 DSH（DeepSeek Harness）。
- DSH 版本需提供本预设引用的 `@deepseek-ai/dsh-*` 包（本预设从 `standard` 复制而来，随 DSH 主版本兼容）。

## 安装

从 GitHub 获取本仓库（clone 或下载 ZIP 并解压均可），然后：

1. 把 `fix-dsv4p0813-overfit/` 整个目录放进用户 preset 根目录：

   ```bash
   mkdir -p ~/.dsh/.agent-presets
   cp -r fix-dsv4p0813-overfit ~/.dsh/.agent-presets/
   ```

   > 若你设置了 `DSH_HOME` 环境变量，请放到 `$DSH_HOME/.agent-presets/` 下。

2. **目录名 `fix-dsv4p0813-overfit` 就是 preset id，不要改名。** 改名会导致 DSH 无法按预期发现它。

## 使用

启动会话时，在预设选择列表中选择「修复dsv4p0813过拟合标准预设」（id: `fix-dsv4p0813-overfit`）即可。

（可选）在用户设置中把它设为默认 preset：

```yaml
agent-presets:
  default: fix-dsv4p0813-overfit
```

## 目录结构

```
<仓库根目录>/
├── README.md                    # 本说明文件
└── fix-dsv4p0813-overfit/       # preset 目录（目录名即 preset id）
    ├── agent.cordis.yml         # 组装文件：工具与提示词（必需，真正的 preset）
    └── preset.yml               # 展示元信息：名称与描述（可选）
```

- `agent.cordis.yml` 决定这个 preset 的能力。
- `preset.yml` 只承载选择器里显示的名称/描述，写坏或缺失不影响挂载。

## 校验（可选）

挂载校验可通过 roster 服务执行：

```js
await ctx.agentPresets.standingKeyFor('fix-dsv4p0813-overfit')
```

正常返回即说明组装可用；抛错会指出具体的失败原因。
