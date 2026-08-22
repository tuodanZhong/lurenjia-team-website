# DSH Effort Tweak

[English](README.md) | 中文

DSH Effort Tweak 为 DeepSeek Harness 自定义提供商中的每个模型增加一个轻量的“推理力度”设置页，用来解决模型推理能力必须手动编辑 `llm-pi-ai` 配置的问题。

## 功能

- 在 DSH Web UI 中增加“设置 → 推理力度”。
- 列出 `llm-pi-ai.providers.<提供商>.models` 中明确配置的模型。
- 逐个模型选择 `关闭`、`极低`、`低`、`中`、`高`、`很高` 或 `最高`。
- 保留模型的其他字段和已有的提供商自定义传输值。
- 通过 DSH 设置服务保存，不需要手动修改配置文件。

页面不会显示只有内置模型目录、没有显式 `models` 列表的提供商。请先在 DSH 官方“模型”页面中为自定义提供商添加模型，再打开本插件页面调整推理力度。

## 一键安装

### Windows PowerShell

```powershell
irm https://raw.githubusercontent.com/Toukaiteio/dsh-effort-tweak/main/scripts/Install-DshEffortTweak.ps1 | iex
```

安装到其他 Profile 且不自动启动 Web UI：

```powershell
$script = "$env:TEMP\Install-DshEffortTweak.ps1"
Invoke-WebRequest https://raw.githubusercontent.com/Toukaiteio/dsh-effort-tweak/main/scripts/Install-DshEffortTweak.ps1 -OutFile $script
& $script -Profile work -NoStart
```

### macOS 与 Linux

```bash
curl -fsSL https://raw.githubusercontent.com/Toukaiteio/dsh-effort-tweak/main/scripts/install-dsh-effort-tweak.sh | bash
```

安装到其他 Profile：

```bash
curl -fsSL https://raw.githubusercontent.com/Toukaiteio/dsh-effort-tweak/main/scripts/install-dsh-effort-tweak.sh -o install-dsh-effort-tweak.sh
bash install-dsh-effort-tweak.sh --profile work --no-start
```

脚本会下载最新 GitHub Release 压缩包；如果 GitHub 提供 SHA-256 摘要则会先校验，并将归档保留在 `DSH_HOME/plugin-archives/dsh-effort-tweak/` 以便后续解析依赖，然后通过 `dsh plugin` 安装。默认安装完成后启动 `web` Profile，使用 `--no-start` 或 `-NoStart` 可关闭自动启动。

## 本地开发

要求 Node.js 22.19 或更新版本，以及 pnpm 10。

```bash
pnpm install
pnpm check
pnpm pack --pack-destination artifacts
```

CI 会执行类型检查、单元测试、bundle 集成测试、构建，并上传插件压缩包。推送与版本号一致的标签（例如 `v0.1.0`）后，Release workflow 会自动创建 GitHub Release 并上传压缩包。

## 配置格式

插件编辑的是 `llm-pi-ai` 命名空间中的模型字段：

```yaml
providers:
  my-gateway:
    models:
      - id: my-reasoning-model
        reasoningEfforts:
          off: null
          low: low
          high: high
```

模型的 `reasoningEfforts` 映射决定 DSH 模型选择器能够提供哪些推理力度。已有档位会保留原来的传输值；新启用的档位会使用对应的标准名称初始化。

## 许可证

MIT，详见 [LICENSE](LICENSE)。
