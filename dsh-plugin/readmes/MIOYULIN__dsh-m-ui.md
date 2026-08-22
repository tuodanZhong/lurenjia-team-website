# dsh-client-ui-mobile-mono

> **DSH Mobile UI** — Mobile adaptation plugin (移动端适配插件) for the **DeepSeek Harness (DSH) Web UI**: phone browsers automatically get a **drawer layout** (抽屉式布局), full-screen **bottom-sheet settings** (设置弹窗), a **monochrome black & white theme** (黑白主题), and more. Zero impact on desktop.

[![Version](https://img.shields.io/badge/version-0.4.20-black)](./ui-v2/package.json)
[![License: MIT](https://img.shields.io/badge/license-MIT-black)](#license)
[![Platform](https://img.shields.io/badge/platform-DSH%20Web%20%7C%20mobile%20browser-black)](#compatibility)

**中文** · English summary below

为 DeepSeek Harness（DSH）Web UI 提供手机浏览器自动适配：侧栏/详情面板变成覆盖式**抽屉**（左缘右滑呼出、拖拽跟手）、设置弹窗全屏化 + 底部标签栏、发送栏统计折叠化、Session log 移动适配，并向所有端注入**黑白单色主题**（light/dark）。桌面端零影响。

**English**: A client-side plugin for the DeepSeek Harness (DSH) Web UI that turns the desktop three-column layout into a mobile-friendly experience: sidebar and details panels become overlay drawers with edge-swipe gestures, the settings dialog becomes a full-screen sheet with a bottom tab bar, composer stats collapse into an expandable chip, and a monochrome (black & white) theme is applied on every device. Desktop is untouched.

## Features 特性

- **Mobile drawer layout 移动抽屉布局** — sidebar / details become overlay drawers; edge-swipe to open, drag with velocity-based commit
- **Monochrome theme 黑白主题** — 90+ official design tokens remapped to grayscale; light & dark modes
- **Full-screen settings 全屏设置** — bottom tab bar, animated section switches, per-device prefs card (theme / drawer width / gestures / model-name hiding), persisted in `localStorage`
- **Stats fold 统计折叠** — session stats (turns / LLM time / tools / TTFT / speed / cache / tokens / context usage) collapse into a chip under the composer
- **Session log adaptation** — toolbar, ledger rows and inspector adapted for touch; inspector becomes a full-width slide-in sheet
- **Motion system 动效** — one easing curve across drawers, sheets, menus, switches, segmented controls; `prefers-reduced-motion` respected
- **Performance 性能** — no `backdrop-filter`, transform-only press feedback, tap-highlight disabled globally (no flicker / jank on mobile)

## Install 安装

```sh
git clone https://github.com/MIOYULIN/dsh-client-ui-mobile-mono.git
cd dsh-client-ui-mobile-mono/ui-v2
./install.sh          # installs into ~/.dsh/profiles/web by default
```

Restart DSH, then hard-refresh (Ctrl/Cmd+Shift+R) the Web UI in your phone browser.

Uninstall: `./uninstall.sh` · Local dev: `pnpm dsh web --patch /abs/path/dsh-client-ui-mobile-mono/ui-v2/cordis.patch.yml`

Plugin source: [`ui-v2/lib/client.js`](./ui-v2/lib/client.js) · Details: [ui-v2/README.md](./ui-v2/README.md) · Maintainer guide: [MAINTAINING.md](./MAINTAINING.md)

## Compatibility 兼容性

- DSH Web（`@deepseek-ai/dsh-client-runtime` / `dsh-client-ui-layout`）
- Modern browsers (`ResizeObserver` / `MutationObserver` / `DOMMatrixReadOnly` / `:has()`)

## Keywords 关键词

deepseek harness · dsh · dsh plugin · dsh web ui · dsh-client · mobile ui · mobile-first · responsive · drawer layout · bottom sheet · monochrome · black and white · grayscale theme · 移动端 · 手机端 · 抽屉 · 黑白主题 · 单色 · 适配 · 插件

## License

MIT
