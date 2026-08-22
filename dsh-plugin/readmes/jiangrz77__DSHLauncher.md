# DSH Launcher

一键在后台启动 DeepSeek Harness 的网页版，并用 **DSH Launcher 自带的原生面板**（WKWebView 窗口）打开 —— **不需要 Safari，也不改动系统默认浏览器**。

## 需要什么（依赖）

| 依赖 | 用途 | 安装方法 |
| --- | --- | --- |
| macOS 12+ | 运行环境 | 系统自带 |
| Xcode 命令行工具 | 编译启动器 | 终端运行 `xcode-select --install` |
| dsh（DeepSeek Harness） | 被启动的服务 | 装好 Node.js 后运行 `npm i -g @deepseek-ai/dsh` |

> 其实不装 `dsh` 也能用：启动器会自动探测 `command -v dsh` 或 npx 缓存，只有都找不到时才需要装。

## 快速开始

1. 构建（只需一次）：

   ```bash
   bash build-app.sh
   ```

2. 双击 **DSHLauncher.app**：
   - 服务没在跑 → 自动后台启动 `dsh web`，就绪后在**原生面板**中打开 `http://127.0.0.1:3080`
   - 服务已经在跑 → 面板直接显示（重复双击安全）
   - 关掉面板窗口 = 退出启动器 = 停止它自己启动的服务（已经在跑的服务不受影响）

3. 想停掉后台服务：

   ```bash
   bash stop-dsh.sh
   ```

## 配置（可选）

首次运行会自动生成 `~/.dsh-launcher.conf`，需要时改这几项：

```bash
PORT=3080          # 端口
OPEN_MODE=panel    # panel=原生面板（默认）；browser=改用 BROWSER 打开
BROWSER=Safari     # 仅 OPEN_MODE=browser 时使用
DSH_CMD=           # 自定义 dsh 命令（留空自动探测）
START_TIMEOUT=120
CHECK_INTERVAL=2
PATCH_STATS_LINE=1 # 每次启动自动精简底部统计行措辞（设为 0 关闭）
PATCH_SIDEBAR=1    # 右侧面板占宽时仍保持完整左侧边栏
PATCH_FILES_PANEL=0 # 可选：右侧 Files 面板隐藏根目录文件夹名、首层条目对齐、收起缩略栏（默认关闭，置 1 启用）
DSH_CLIENT_NODE_MODULES= # 自定义 DSH_CMD 时指定对应的 node_modules 根目录（通常留空）
USAGE_DISPLAY=1    # 在左侧栏显示用量与计费入口（设为 0 关闭）
BILLING_CURRENCY=CNY
BILLING_MODEL=deepseek-v4-pro # 或 deepseek-v4-flash；自动跟随 DeepSeek 官方时段价格
# 下列为可选的每百万 tokens 手动单价；全部留空时使用上述模型的官方价格
BILLING_UNCACHED_INPUT_PER_MTOK=
BILLING_CACHE_READ_PER_MTOK=
BILLING_CACHE_WRITE_PER_MTOK=
BILLING_OUTPUT_PER_MTOK=
```

> 想回到用 Safari 打开：把 `OPEN_MODE` 改成 `browser` 即可（依旧不会改系统默认浏览器）。

## 侧边栏增强

启动器会向 DSH 左侧栏注入两个小插件（默认开启，可用 `USAGE_DISPLAY=0` 关闭）：

| 插件 | 位置 | 内容 |
| --- | --- | --- |
| **用量与计费入口** | 左侧栏底部 | 实时显示「本会话用量 / 全部用量 · tokens · 费用」；点击打开用量面板：累计输入/缓存/输出、按项目汇总、16 周活动热图、30 天费用柱状图 |
| **项目用量卡片** | 悬浮左侧栏项目时 | 在 DSH 原悬浮卡里追加一行：tokens、会话数、缓存命中率、估算费用 |

另有**左栏保持完整**补丁（`PATCH_SIDEBAR=1`）：右侧面板打开导致内容区变窄时，左栏不再自动折叠成图标栏（手动折叠按钮仍可用）。

费用默认按 `BILLING_MODEL` 对应的 DeepSeek 官方人民币价格估算（含峰谷时段），也可用四项 `BILLING_*` 单价手动覆盖。预估仅供参考，不代表最终账单。

## 常见问题

- **双击提示「无法打开」**：系统设置 → 隐私与安全性 → 点「仍要打开」。
- **dsh / node 找不到**：装好依赖后重试，或用 `DSH_CMD` 写死完整命令。
- **端口被占用**：改配置里的 `PORT`。
- **面板里点外链**：非本地链接会用系统默认浏览器打开。
- **面板内快捷键**：`⌘C / ⌘V / ⌘X / ⌘A / ⌘Z`（`⇧⌘Z` 重做）在输入框和文本上可用，另有 `⌘R` 刷新页面、`⌘W` 关闭窗口、`⌘Q` 退出。
- **想改图标**：改 `src/AppIcon.svg` 后运行 `bash make-icon.sh`（需 Chrome），再 `bash build-app.sh`。
- **看日志**：`~/Library/Logs/dsh-web.log`。
- **聊天窗口底部的统计行太长**：运行 `bash src/patch-stats-line.sh` 可把措辞精简（如「工具调用」→「工具」、「首 token 平均」→「首字」、「缓存命中」→「命中」、「输入 X tok · 输出 Y tok」→「输入 X · 输出 Y tok」），所有指标都保留。改完在面板里按 `⌘R` 刷新即可；`--revert` 可还原。启动器每次启动会自动重放该补丁（`PATCH_STATS_LINE=1`），所以 dsh 升级/重装后也会自动恢复精简措辞，无需手动处理。
- **左侧边栏消失、只剩图标栏**：打开右侧 Explorer 后，DSH 会因为内容区低于 1024px 自动折叠左栏。Launcher 启动时会自动保持完整左栏（`PATCH_SIDEBAR=1`），手动收起按钮仍可用；也可运行 `bash src/patch-sidebar.sh` 后按 `⌘R` 刷新。
- **右侧 Files 面板外观（可选）**：`bash src/patch-files-panel.sh` 可隐藏面板头部显示的根目录文件夹名（如 "DSHLauncher"）、把第一层文件/文件夹行的左边距对齐到头部标题，并修复面板收起后无法重新打开的问题；`--revert` 还原。该补丁默认关闭（`PATCH_FILES_PANEL=0`），置 1 后每次启动自动重放。
- **用量与计费**：见上方「侧边栏增强」。图表按 GMT+08 自然日统计（跨午夜会话会拆分到正确日期）；node 过旧（< 22.15）或日志不可读时回退为按会话创建日期归因并在图中注明。
