# dsh-install-desktop

**DeepSeek Harness 桌面版一键安装插件** —— dsh 生态的分发入口。

在 dsh 中执行 `/install-desktop`，插件自动检测当前平台 → 查询 [deepseek-harness-desktop](https://github.com/Myoontyee/deepseek-harness-desktop) 的最新 GitHub Release → 下载对应安装包（带实时进度）→ 启动安装。安装完成后，桌面壳自身的自动更新负责后续升级，本插件无需再管。

- 平台支持：**Windows x64**（NSIS 静默安装 `/S`）· **macOS Apple Silicon**（打开 dmg）· **Linux x64**（AppImage）
- Intel Mac（darwin-x64）未发布安装包，检测到时明确提示
- 重复安装检测：常见安装路径 + Windows 注册表卸载项；已安装时提示「已安装，可升级」
- 交互全程中文，UI 为杂志风白底卡片（`#fafafa` 白底、细边框、黑字），与桌面壳风格一致

## 安装

在目标 dsh profile 目录中安装插件包并注册（以默认 web profile 为例）：

```bash
# 1. 安装插件包
cd ~/.dsh/profiles/web
pnpm add dsh-install-desktop

# 2. 在 cordis.patch.yml 末尾追加：
#    - insert:
#        - id: install-desktop
#          name: dsh-install-desktop

# 3. 重启 dsh（重新启动 dsh web / dsh headless）
```

> 前提：插件以 `@deepseek-ai/cordis`、`@deepseek-ai/dsh-commands` 为 peer 依赖，运行时由 dsh 安装提供（`$DSH_HOME/profiles/node_modules` 回退解析，无需手动安装）。

## 使用

在 dsh 对话中输入 `/` 打开命令菜单，选择「**安装桌面版**」（或直接输入 `/install-desktop` 回车）：

1. 自动检测平台与已安装状态
2. 查询最新版本，下载安装包（对话流中出现实时进度卡片）
3. 启动安装：Windows 静默安装；macOS 打开 dmg（手动拖入 Applications）；Linux 直接运行 AppImage
4. 结果以命令卡片回显（下载位置、安装指引）

已安装时直接提示「已安装 vX.Y.Z（安装路径）」，无需重复安装；如需覆盖安装：

```
/install-desktop --force
```

## 工作原理

| 步骤 | 说明 |
| --- | --- |
| 平台检测 | `process.platform` + `process.arch` → win32-x64 / darwin-arm64 / linux-x64；其余提示不支持 |
| 已安装检测 | Windows：注册表卸载项（HKCU/HKLM）+ 常见安装路径；macOS：`/Applications/DeepSeek Harness.app`；Linux：`~/.local/bin`、`/opt`、`/usr/bin`、desktop 入口 |
| 版本查询 | `https://api.github.com/repos/Myoontyee/deepseek-harness-desktop/releases/latest`（tag_name 去 v 前缀） |
| 资产选择 | `DeepSeek.Harness_<ver>_x64-setup.exe` / `_aarch64.dmg` / `_amd64.AppImage` |
| 下载 | Node fetch 流式写入临时目录，进度按 ≥100ms 节流上报 |
| 进度展示 | 宿主写入 `desktop-install/run\|progress\|done` session 事件，浏览器端折叠为对话流进度卡片 |
| 启动安装 | Windows `spawn(exe, ['/S'])`；macOS `open <dmg>`；Linux `chmod +x` 后运行 AppImage |

## 开发

```bash
pnpm install
pnpm run typecheck   # tsc --noEmit
pnpm run build       # tsc → lib/types，tsdown → lib/index.js（宿主）+ lib/client.js（浏览器 bundle）
node smoke.mjs       # 冒烟测试（平台/资产/Release API/已安装检测）
```

## 说明

- 安装包直接来自官方仓库 Release，本插件只负责分发；安装后的自动更新由桌面壳自身完成。
- Linux 用户也可在 Release 页面下载 `.deb` 包用 `sudo dpkg -i` 安装。
- 插件无后端服务、无遥测；唯一的外部请求是 GitHub Releases API 与 Release 资产下载。

## License

MIT
