# dsh-gbc-ui · GirlsBangCry

DeepSeek Harness Web GUI 的自研皮肤插件：深海宫殿背景、**旋转角色舞台**
（14 名成员立绘轮播 + 群像底幕）与黑粉蕾丝装饰界面。

> 工程脚手架与 DOM 兼容层仿照 [dsh-deep-whale/maid-atelier](https://github.com/Small-tailqwq/dsh-deep-whale)
> 皮肤实现，素材为 maid-atelier 原图的黑粉 GBC 重绘版本（由用户提供），
> 按 CC BY-NC-SA 4.0 署名链分发，见 `NOTICE`。

## 效果

| 亮色模式 | 暗色模式 |
|---|---|
| ![亮色](preview/light.webp) | ![暗色](preview/dark.webp) |

## 功能

- **深海宫殿背景**：亮色用白昼宫殿图，暗色自动切换为暗化/偏蓝变体。
- **角色舞台**：右下角轮播 14 名成员立绘（7 位 GBC 成员 + 5 张 Tomo +
  2 张 Aono，默认 30s 一张，淡入淡出），背后有群像底幕；聊天气泡展开时
  舞台自动退让避让。
- **左侧立绘**：输入框左侧一张立绘（可被输入框覆盖），同样加入成员轮播，
  支持手动切换。
- **🖼️ 立绘/背景面板**：浮动按钮打开，支持「右侧 / 左侧」两个标签页，
  网格点选任意成员、上传自定义立绘与背景（自动压缩、localStorage 持久化）、
  开关自动轮播、恢复默认。
- **🎸 快捷开关**：右下角浮动按钮，一键开/关角色舞台（记忆到 localStorage）。
- **Subaru 动画**：左侧侧边栏内置 GIF 动画。
- **黑粉装饰层**：底部蕾丝饰带、侧栏角落卷边、输入框雕花边框、
  设置面板花边、工作区缎带/盾徽、新建会话粉色胶囊按钮。
- **设置**（localStorage `gbc-ui-settings`）：`enabled`、`rotateInterval`（秒）、
  `dim`（背景压暗 0~1）、`blur`（背景模糊 px）、`accent`（主色 `#e84855`）、
  `customPortrait` / `customBackdrop` / `customLeftPortrait`（上传的图片）。

## 安装

```sh
dsh plugin --profile web add github:U1s1-king/dsh-gbc-ui#semver:v0.0.1
```

> 如果不会安装，直接告诉你的 agent：
> “嘿，bro 帮我安装这个插件 https://github.com/U1s1-king/dsh-gbc-ui”

安装后重启 dsh web 并硬刷新页面（Ctrl+Shift+R）。若与其它皮肤并存，
在 profile 的 `cordis.patch.yml` 中把要停用的皮肤条目置为 `disabled: true`。

## 开发

```sh
pnpm install        # devDeps：tsdown / lightningcss / vitest / jsdom / cordis
pnpm build          # tsdown 双产物 -> lib/index.js（host）+ lib/client.js（浏览器 bundle）
pnpm test           # vitest jsdom 冒烟测试
```

素材管线（源图在 `D:\dsh-GBC-GUI`）：

```sh
powershell -ExecutionPolicy Bypass -File scripts/gen-assets.ps1   # PNG -> assets/*.webp
node scripts/gen-art.mjs                                          # webp -> src/client/*-art.generated.ts
powershell -ExecutionPolicy Bypass -File scripts/retheme-css.ps1  # 重跑调色（需先恢复 gbc-atelier.module.css 基线）
```

## 许可

CC BY-NC-SA 4.0（署名-非商业性使用-相同方式共享）。完整署名链见 `NOTICE`；
角色立绘素材为使用者提供，版权归原作者，公开发布前请自行确认授权。
