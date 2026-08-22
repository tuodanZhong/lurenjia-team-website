# dsh-browser-control

> DeepSeek Harness 插件 · 操控浏览器 / DSH plugin for controlling browsers

通过 **CDP（Chrome DevTools Protocol）** 驱动浏览器：复用日常 Chrome 登录态、导航、抓 console / pageError / networkError、截图、执行任意 JS。

核心资产：
- `scripts/launch.sh` — 登录态复用的 CDP 启动器（起 `:9222` 调试实例）
- `scripts/drive.mjs` — CDP 驱动：导航 / 截图 / console / eval / mobile 仿真

Drives browsers over **CDP (Chrome DevTools Protocol)**: reuse your everyday Chrome login state, navigate, capture console / pageError / networkError, screenshot, and eval JS.

## 快速开始 Quick start

```bash
./scripts/launch.sh   # 起 :9222 调试实例（复用日常 Chrome 登录态；已在跑则复用）

node scripts/drive.mjs "<url>" \
  --out /tmp/shot.png \
  [--mobile] [--wait 4000] [--eval "<expr>"]
```

输出 JSON：`title` / `url`（注意 SPA 跳转后的最终地址）/ `bodyPreview` / `console` / `pageErrors` / `networkErrors` / `screenshot` 路径。

## 为什么绕这一圈（登录态复用原理）

新版 Chrome 禁止在**默认 user-data-dir** 上开 `--remote-debugging-port`。`launch.sh` 的做法：把日常 Chrome 的登录态文件（Cookies / Login Data / Local Storage / IndexedDB 等）**只读拷贝**到隔离目录 `/tmp/chrome-e2e-profile`，再用隔离目录起调试实例。单向不回写、懒同步（仅首次或 `--refresh`）、端口探测复用、精确 pkill——详见 [docs/cdp-login-reuse.md](docs/cdp-login-reuse.md)。

## 能力与避坑

- **canvas / 可视化库（G6 / echarts / D3 / WebGL）截图**：后台 tab 的 raf 会被节流导致截图空白，修法是新建 tab + `Page.bringToFront` + 踢 raf，且**别用 `getImageData` 判渲染**——见 [docs/cdp-canvas-pitfalls.md](docs/cdp-canvas-pitfalls.md)
- `--mobile`：390x844 视口 + iPhone UA 仿真
- `--eval`：在页面执行任意 JS（验证 DOM 状态 / 读 window 全局 / 调库 API）

## DSH 工具 Tools

安装插件后，以下 `browser_*` 工具自动注册进 agent 的工具集：

| 工具 | 说明 |
|---|---|
| `browser_status` | 探测 CDP 实例是否在跑（默认 9222） |
| `browser_launch` | 幂等启动 CDP 调试 Chrome（复用日常登录态；`refresh` 强制重同步） |
| `browser_kill` | 关闭 CDP 调试实例 |
| `browser_open` | 导航到 URL 并返回 title / 最终 URL / 文本预览 / console / pageError / networkError / 截图 |
| `browser_screenshot` | 导航并截图，返回截图路径 |
| `browser_eval` | 导航后在页面执行 JS 表达式并返回结果 |

```sh
# 安装后直接在 agent 会话里用自然语言触发：
#   "browser_launch 起 Chrome，然后 browser_open 打开 https://example.com 截图给我看"
dsh plugin --profile demo add dsh-browser-control
```

## 路线图 Roadmap

- [x] 登录态复用启动器（`scripts/launch.sh`，含 `--refresh` / `--kill` / `--status`）
- [x] CDP 驱动（`scripts/drive.mjs`：导航 / 截图 / console / eval / mobile）
- [x] 封装为 DSH 工具（6 个 `browser_*` tools）
- [ ] 点击 / 填表 / 表单交互
- [ ] Playwright 后端
- [ ] 多标签 / 多窗口管理

## 安装 Install

```sh
# 发布到 npm 后
dsh plugin --profile demo add dsh-browser-control

# 或从 GitHub 安装（源码安装需要 prepare 构建）
dsh plugin --profile demo add github:PangYiMing/dsh-browser-control
```

## 许可证 License

[MIT](./LICENSE)
