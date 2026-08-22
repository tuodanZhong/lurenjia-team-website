# 🐾 Emoji Desktop Pet · 表情桌面宠物

> A draggable emoji desktop pet for the [DeepSeek Harness](https://github.com/deepseek-ai) (DSH) web UI, built as a **dynamic Cordis plugin**. 表情桌面宠物是一个漂浮在 DeepSeek Harness 网页界面上的可拖拽 emoji 桌面宠物，基于 DSH 动态 **Cordis 插件** 架构构建——无需修改仓库、无需重启进程，即装即用、随时可卸载。

Emoji Desktop Pet 用系统原生 emoji 作为宠物形象（零图片资源、任意分辨率清晰），支持拖拽、动画、点击互动与角色切换。它注册在 DSH Web 的 `shell.overlay` 插槽上，悬浮于界面所有内容之上，却不遮挡任何操作。

**关键词 / Keywords：** DeepSeek Harness · DSH · Cordis · 动态插件 · 桌面宠物 · emoji 宠物 · desktop pet · web UI 插件 · React · JavaScript

---

## ✨ Features 功能特性

| 特性 | 说明 |
| --- | --- |
| 🐱 **40 个内置角色** | 猫、狗、狐狸、熊猫、机器人、幽灵、外星人等（全部为系统原生 emoji，零图片资源） |
| 🖱️ **拖拽移动** | 可拖到窗口任意位置，自动限制在窗口边界内，拖动时暂停动画 |
| 🎨 **待机动画** | 漂浮、左右摇摆、呼吸（纯 CSS keyframes，GPU 合成，不占用 JS 主线程） |
| 💬 **点击互动** | 戳一下会"吧唧"压扁 + 随机冒气泡 |
| 📏 **三档大小** | 96 / 144 / 192 px，双击循环切换 |
| 🎰 **角色切换** | 右键切换下一个角色；中键弹出 6 列角色选择面板 |
| ♻️ **生命周期安全** | 所有副作用（样式表、定时器、插槽注册）随插件停止/更新自动清理 |

## 🎮 Controls 操作方式

| 操作 | 行为 |
| --- | --- |
| 左键单击 | 随机气泡 + 压扁动画 |
| 双击 | 循环切换大小 96 → 144 → 192 px |
| 右键 | 切换到下一个角色 |
| 中键（滚轮键） | 打开/关闭角色选择面板 |
| 拖动 | 移动宠物位置（自动夹边） |

## 🐱 Characters 角色列表

🐱 🐈 🐶 🐺 🦊 🐻 🐼 🐨 🐰 🐹 🐭 🐷 🐮 🐯 🦁 🐸 🐵 🐧 🐤 🦉 🦄 🐢 🐙 🦖 🐉 🐞 🐝 🐳 🐬 🐟 👾 👻 🤖 👽 🧸 🎃 🍄 😺 😻 🥚

## 📦 How to Install 如何安装

### 中文说明

本插件是 **DeepSeek Harness Web 界面**的动态插件（Dynamic Cordis Plugin），通过 DSH 的 `cordis_define` 工具定义、`cordis_run` 运行：

1. 将 `src/pet-plugin.js` 中的插件对象作为 `code.client` 提交给 `cordis_define`（`inject: ['timer']` + `apply(ctx)` 结构，纯 JavaScript，无 JSX/TypeScript）；
2. 调用 `cordis_run` 激活，首次运行需在页面中批准（Client 插件需要授权）；
3. 宠物会出现在页面右下角的 `shell.overlay` 浮层中；
4. 不需要时用 `cordis_stop` 暂停、`cordis_undefine` 彻底移除。

> 说明：动态插件是进程级的临时扩展——宠物（以及它的位置/角色选择）在 DSH 进程重启后消失。这是动态插件机制的设计定位；如需持久化能力，请将代码固化到 host 组合层。

### English

This is a **dynamic Cordis plugin** for the DeepSeek Harness web UI. Define it with the DSH `cordis_define` tool using the plugin object in `src/pet-plugin.js` as `code.client`, then activate with `cordis_run` and approve the first run. The pet appears in the additive `shell.overlay` slot at the bottom-right. Stop with `cordis_stop`, remove entirely with `cordis_undefine`.

> Dynamic plugins are process-local: the pet and its state disappear on DSH restart. This is by design for temporary runtime extensions; persist capabilities by moving code into the host composition layer.

## 🏗️ How It Works 工作原理

- 插件的 **Client 半区**（浏览器）注册到 `shell.overlay` 插槽——一个全屏、默认点击穿透的浮层，宠物自身 opt-in 指针事件，因此悬浮但不挡操作；
- **纯 JavaScript**：无 JSX、无 TypeScript、无打包器；React 通过 `React.createElement` 使用；
- 动画由 CSS keyframes 驱动；气泡与交互使用可销毁的 `timer` mixin；
- `window` 访问做了防御（`typeof window !== 'undefined'`），非浏览器环境也能优雅降级；
- 样式通过 `styles.insert` 注入、定时器由 `timer` 服务管理、插槽注册随生命周期自动清理——**所有副作用都可逆**。

## 📁 Project Structure 项目结构

```
emoji-desktop-pet/
├── src/
│   └── pet-plugin.js   # Client 半区插件源码（单文件、零依赖）
├── package.json
├── README.md
└── LICENSE
```

## 📄 License 许可证

[MIT](./LICENSE)

---

**相关链接 / Related：** [DeepSeek Harness](https://github.com/deepseek-ai) · [Cordis](https://github.com/cordiverse/cordis)
