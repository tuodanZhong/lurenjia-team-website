# dsh-gif-background

[![CI](https://github.com/alcohol-101/dsh-gif-background/actions/workflows/ci.yml/badge.svg)](https://github.com/alcohol-101/dsh-gif-background/actions/workflows/ci.yml)

[English](README.md) | 中文

给 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)（DSH）Web 界面添加自定义背景的独立插件：设置页一个开关 + 一个本地背景库（图片 / GIF / 动态壁纸），官方默认主题与 dsh-web-ui 皮肤中心两套显示机制，互不干扰。

## 功能

- 开启 / 关闭开关（localStorage 持久化，默认开启）。
- 背景库：添加（上传 `gif / jpg / jpeg / png / webp`，100 MB 上限）、删除、重命名、刷新；删除当前使用中的素材会自动回退到内置背景。
- 官方主题（无皮肤）：背景直接绘制到布局框架（AppFrame）自己的 `background-image` 上，并注入一套 rgba 半透明 token 覆盖让面板透出背景；内置背景走短 URL API——几 MB 的 base64 塞进 CSS 声明会被浏览器解析器静默丢弃。
- 皮肤模式：与 dsh-web-ui 皮肤中心的皮肤共存，背景层显示在皮肤面板后方，皮肤自己的配色不受影响。
- 素材 API 仅本机可用（loopback-only），不会暴露到外部。

## 安装

前置：DSH 0.1.x。安装后重启 `dsh web`，浏览器 Ctrl+F5。

### 从 npm 安装（推荐）

```sh
dsh plugin --profile web add dsh-gif-background
```

### 从仓库安装（开发调试）

```sh
git clone https://github.com/alcohol-101/dsh-gif-background.git
dsh plugin --profile web add "link:<克隆下来的目录路径>"
```

## 使用

设置 → 插件 → 「自定义背景」卡片：

- 勾选「开启背景」显示 / 隐藏背景；
- 「添加」上传本地图片或 GIF，上传后自动选中；
- 点击列表项切换背景；「rename」行内重命名（回车确认、Esc 取消）；「x」删除；
- 「刷新」重新扫描素材目录——也可以直接把文件放进 `gifs/` 目录再点刷新。

## 工作原理

两套机制，按页面状态自动切换：

1. **官方默认主题**（未启用皮肤中心的皮肤）：把当前背景画到 AppFrame 元素上，同时给 body 注入一套 rgba 半透明 token 覆盖（`--dsw-alias-bg-base`、`-bg-layer-1/2/3`、`-bg-module-platform`、`--dsw-specific-sidebar-fill`，亮 / 暗两套），面板变半透明后背景透出来。
2. **皮肤模式**：只保留 `z-index:-1` 的全屏背景层 + 遮罩层，皮肤自己的半透明 `#root` 表面自然透出背景。

注意：dsh-web-ui 皮肤中心即使没有启用任何皮肤，也会在 `<body>` 上常驻一个 `data-dsh-skin-center` 作用域属性。旧版本曾因此误判为皮肤模式，导致官方主题下背景不显示；现版本已把该属性加入白名单，只把皮肤自己的 body 属性当作皮肤。

## 目录结构

```
dsh-gif-background/
├── client/
│   ├── client.template.js   # 浏览器端源码（__GIF_BASE64__ 占位符）
│   └── build.mjs            # 构建脚本：把 gifs/builtin.gif 内嵌进 lib/client.js
├── lib/
│   ├── index.js             # 服务端：素材库 API（loopback-only）
│   └── client.js            # 浏览器端构建产物（已入库，link 安装无需构建）
├── gifs/
│   └── builtin.gif          # 内置背景（设置卡片上传的素材不入库）
├── docs/
│   ├── 维护指南.md            # 面向维护者的逐段代码导读
│   └── CHANGELOG.md           # 版本更新日志
├── .github/workflows/ci.yml # CI：构建校验 + 旧标识守卫
├── cordis.patch.yml         # dsh bundle patch：声明插件行
├── CONTRIBUTING.md          # 贡献指南
└── package.json             # dsh.client 注入声明 + 导出
```

## 开发

- 改浏览器端：编辑 `client/client.template.js`，然后 `node client/build.mjs` 重建 `lib/client.js`。
- 改服务端：编辑 `lib/index.js`。
- 服务端改动需要重启 `dsh web`；只改浏览器端的话 Ctrl+F5 即可。
- 每次 push 会自动跑 CI：产物过期或旧标识回潮都会失败，失败会邮件通知你。
- 不熟悉代码？先读 `docs/维护指南.md`（逐段导读 + 速查表）和 `CONTRIBUTING.md`。

踩坑记录（写给自己，也写给后来的人）：

- 几 MB 的 base64 塞进 CSS `background-image` 会被浏览器静默丢弃 → 内置背景改走短 URL API。
- `MutationObserver` 对同值 `setAttribute` 也会触发回调（whatwg/dom#520）→ 属性写入必须加同值守卫，否则观察器无限重入、页面卡死。
- webserver 的 `prefix` 路由按 `pathname.startsWith(prefix + '/')` 匹配，prefix 不能带尾斜杠；同一路径只注册一个 `exact` 路由，按 method 分发。
- 皮肤检测见上文「工作原理」里的 data-dsh-skin-center 说明。

## 自己做 GIF 壁纸

一段 ffmpeg 参考命令（缩放 + 抖动调色板，无限循环）：

```sh
ffmpeg -y -i input.mp4 -t 33 \
  -vf "fps=8,scale=840:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=160:stats_mode=diff[p];[s1][p]paletteuse=dither=floyd_steinberg:diff_mode=rectangle" \
  -loop 0 builtin.gif
```

想要无缝循环，先截段再用 `xfade` 把片段和它自己交叉淡化衔接，最后再调色板化。

## 常见问题

**开关开了，官方主题下却看不到背景？**

Ctrl+F5 后按顺序在控制台（F12）检查：

1. `document.body.attributes` 应有 `data-dsh-gif-bg="on"`，且没有 `data-dsh-gif-bg-skin`；
2. `document.querySelector('[data-dsh-frame]').style.backgroundImage` 应包含素材 URL；
3. `getComputedStyle(document.body).getPropertyValue('--dsw-alias-bg-base')` 应是 rgba 半透明值。

第 1 步不成立说明启用了皮肤中心的皮肤——皮肤模式下背景显示在皮肤面板后面。

**想调整官方主题下的面板透明度？**

改 `client/client.template.js` 里 `SKINLESS_CSS` 的 rgba 数值（亮 / 暗两套），重建后 Ctrl+F5。

**内置背景怎么换？**

替换 `gifs/builtin.gif` 后运行 `node client/build.mjs` 重建；或者直接在设置卡片里「添加」上传自己的素材并选中。

## 许可

[Apache-2.0](LICENSE)
