# 记忆压缩插件

[**English**](README.md) | **中文**

[![License](https://img.shields.io/github/license/songoao25/dsh-auto-compact)](LICENSE)
[![Release](https://img.shields.io/github/v/release/songoao25/dsh-auto-compact)](https://github.com/songoao25/dsh-auto-compact/releases)
[![CI](https://img.shields.io/github/actions/workflow/status/songoao25/dsh-auto-compact/ci.yml)](https://github.com/songoao25/dsh-auto-compact/actions)
[![Last Commit](https://img.shields.io/github/last-commit/songoao25/dsh-auto-compact)](https://github.com/songoao25/dsh-auto-compact/commits/main)
[![Stars](https://img.shields.io/github/stars/songoao25/dsh-auto-compact)](https://github.com/songoao25/dsh-auto-compact)
[![Dependabot](https://img.shields.io/badge/dependabot-enabled-025e8c?logo=dependabot)](https://github.com/songoao25/dsh-auto-compact/security/dependabot)

为 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) 提供增强的自动上下文压缩默认配置。

DeepSeek Harness 已内置自动上下文压缩（`dsh-compaction-basic`），但默认触发阈值为模型上下文的 80%，对大上下文模型来说偏晚。本工具将默认阈值调低至 **75%**，并添加按路由策略，让历史更早得到整理，长会话保持流畅。

## 工作原理

DeepSeek Harness 会为每个 **agent 预设**（每个会话）运行一个独立的 `compaction-basic` 实例；profile 层的补丁无法到达该子树。因此本工具直接向 `~/.dsh/.agent-presets/` 下每个已安装预设的 `compaction-basic` 条目注入配置。

- 默认：上下文占用达到 **75%** 时触发压缩，保留最近 **20%** 原文。
- 按路由策略：
  - ChatGPT / Codex GPT-5.6（27.2 万上下文）：达到 **70%** 触发；
  - OpenCode Go DeepSeek V4（声明 100 万上下文）：达到 **65%** 触发。
- 保留 `dsh-compaction-basic` 既有的摘要、重试与安全降级行为（摘要失败保留原历史，绝不静默丢失上下文）。
- 手动 `/compact` 与工具结果裁剪仍然可用。

## 安装

```bash
cd dsh-auto-compact
./install.sh
```

随后重启 DeepSeek Harness。回滚：

```bash
./uninstall.sh
```

### 重要说明：出厂预设

本工具**只注入用户安装的预设**（位于 `~/.dsh/.agent-presets/`）。DSH 的出厂预设（`standard`、`code`、`cordis`、`minimal`）自带默认的压缩配置（80% 触发，16% 保留），且为只读——本工具不会修改它们。

如需为出厂预设启用增强压缩：

1. 将其复制到用户预设目录：
   ```bash
   cp -r /opt/homebrew/lib/node_modules/@deepseek-ai/dsh/presets/<预设名> ~/.dsh/.agent-presets/
   ```
2. 再次运行 `./install.sh` 注入增强配置。
3. 在 DSH 会话设置中选择复制后的预设。

## 安装器做什么

- 查找 `~/.dsh/.agent-presets/` 下所有 `agent.cordis.yml`。
- 向每个预设的 `compaction-basic` 条目注入策略块。
- 将每个修改过的文件备份为 `agent.cordis.yml.bak-auto-compact`。
- 幂等：标记注释防止重复注入。
- 跳过已自行配置 `compaction-basic` 的预设（此时请手动合并）。
- 绝不修改 DSH 安装目录中的只读出厂预设。

## 配置

所有值位于 `scripts/inject.mjs` 的 `CONFIG_BLOCK`。如需不同阈值，先修改再运行 `./install.sh`。预览：

```bash
node scripts/inject.mjs --dry-run
```

| 键 | 默认值 | 含义 |
|---|---|---|
| `thresholdRatio` | 0.75 | 估算用量达到模型上下文该比例时触发压缩 |
| `retainRatio` | 0.20 | 保留最近该比例的窗口原文 |
| `modelPolicies` | – | 按 `provider/model` 的单独覆盖 |

## 安全说明

- 摘要失败时保留原历史并记录警告。
- 自动恢复有次数上限，绝不无限循环重试。
- 工具不含任何密钥与个人路径。
- 通过 `./uninstall.sh` 可完全还原。

## 许可证

MIT © songoao25
