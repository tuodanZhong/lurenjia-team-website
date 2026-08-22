# DSH 插件集

[DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)（`dsh`）Web GUI 的自用插件集合。

## 插件

| 插件 | 功能 | 目录 |
|---|---|---|
| **dsh-client-ui-skins** | 换肤：8 套配色 + 自定义取色器 + 背景壁纸 | [./dsh-client-ui-skins](./dsh-client-ui-skins) |
| **dsh-client-ui-market** | 插件市场：浏览/搜索/安装/卸载/一键重启 | [./dsh-client-ui-market](./dsh-client-ui-market) |
| **dsh-client-ui-recharge** | 充值助手：侧边栏一键直达 DeepSeek 官方充值页 + 余额显示/预警 | [./dsh-client-ui-recharge](./dsh-client-ui-recharge) |
| **dsh-client-ui-billing** | 花费/余额插件：右上角悬浮余额 + 会话消费/token + 侧边栏逐会话金额 | [./dsh-client-ui-billing](./dsh-client-ui-billing) |
| **dsh-ds-attach** | DS 风格附件：回形针上传、拖拽上传、文本提取（PDF/DOCX/XLSX/TXT）文件卡片 | [./dsh-ds-attach](./dsh-ds-attach) |

## 前置条件

- 已全局安装 dsh：`npm i -g @deepseek-ai/dsh`
- 已有 web profile（首次运行 `dsh web` 会自动初始化）

## 安装

每个插件单独安装，两种方式任选其一。

### 方式一：dsh plugin（需要 pnpm）

```sh
# 在克隆下来的本仓库目录里执行
dsh plugin --profile web add ./dsh-client-ui-skins
dsh plugin --profile web add ./dsh-client-ui-market
dsh plugin --profile web add ./dsh-client-ui-recharge
dsh plugin --profile web add ./dsh-client-ui-billing
dsh plugin --profile web add ./dsh-ds-attach
```

`dsh plugin add` 会把插件作为依赖装进 profile，但不会自动挂载——仍需在补丁里加行（见下）。

### 方式二：手动拷贝（无 pnpm 环境）

把插件目录拷到 profile 的 node_modules：

```powershell
Copy-Item .\dsh-client-ui-skins "$env:USERPROFILE\.dsh\profiles\node_modules\" -Recurse
Copy-Item .\dsh-client-ui-market "$env:USERPROFILE\.dsh\profiles\node_modules\" -Recurse
Copy-Item .\dsh-client-ui-recharge "$env:USERPROFILE\.dsh\profiles\node_modules\" -Recurse
Copy-Item .\dsh-client-ui-billing "$env:USERPROFILE\.dsh\profiles\node_modules\" -Recurse
Copy-Item .\dsh-ds-attach "$env:USERPROFILE\.dsh\profiles\node_modules\" -Recurse
```

## 挂载（两种方式都要做）

编辑 `$DSH_HOME/profiles/web/cordis.patch.yml`，追加：

```yaml
- insert:
    - id: ui-skins
      name: dsh-client-ui-skins
- insert:
    - id: dsh-market
      name: dsh-client-ui-market
- insert:
    - id: dsh-recharge
      name: dsh-client-ui-recharge
- insert:
    - id: dsh-billing
      name: dsh-client-ui-billing
- insert:
    - id: ds-attach
      name: dsh-ds-attach
```

然后重启 `dsh web`（插件清单只在启动时扫描）。装好 dsh-client-ui-market 之后，后续插件可以直接在「设置 → 常规 → 插件市场」里搜索/安装/卸载/一键重启。

## 使用

- **换肤**：设置 → 常规 → 皮肤（配色 + 背景图）。
- **插件市场**：设置 → 常规 → 插件市场。
- **充值助手**：侧边栏底部「充值」按钮 → 打开 DeepSeek 官方充值页（余额即见，低于 ¥5 标红）。
- **花费/余额**：右上角悬浮余额框 + 对话框下方消费/token + 侧边栏逐会话金额。
- **DS 附件**：输入框回形针上传按钮 / 拖拽上传 PDF、DOCX、XLSX、TXT，文件卡片展示解析状态（不写入输入框）。

各插件的详细说明见各自目录下的 README。

## 卸载

从 `cordis.patch.yml` 删除对应行，删除 `$DSH_HOME/profiles/node_modules/<插件名>`，重启。
