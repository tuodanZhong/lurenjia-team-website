# dsh-chatflow-rail

[English](README.md) | 中文

一个给 dsh Web GUI 的插件：在对话流**左侧**加一条**对话流导航条**——每条短横线对应一条用户消息，位置与真实内容 1:1 映射——顶部再配一张**上一消息卡片**。

## 截图

| 上一消息卡片 + 导航条 | 导航条悬浮预览 |
| --- | --- |
| ![导航条与上一消息卡片](screenshots/rail-and-card.png) | ![悬浮预览](screenshots/hover-preview.png) |

不用在长对话里翻来翻去找位置，导航条把整个对话摊成一张地图：短横线聚成紧凑的小块，每条是一条用户消息；鼠标移过时横线向指针两侧平滑展开（越靠近指针越宽越深），越过预览阈值就浮出 `#N/M · 时间` + 内容的卡片。点横线——或点轨道任意位置——视图平滑滚到那条消息，落点自动避开顶部卡片。

当某条用户消息滚出视口上方时，顶部浮出一张原生风格的卡片，显示 `上一消息 #N/M · 时间` 加 3 行预览；点它就能跳回去。卡片是挂在 shell 点击穿透层上的悬浮层：空态完全透明，对话顶部保持干净，没东西可显示时什么都不占。运行中发送的跟进消息（`steering`）同样计为锚点；插件还会自动展开 dsh 的历史窗口，让导航条覆盖整个对话——而不是只有对话流渲染出来的尾部窗口。

## 安装

插件是 git 托管的 bundle，pnpm 默认会阻止它的构建脚本，所以先放行，再安装。

```sh
# 1. 放行插件的构建（prepare）脚本——在
#    ~/.dsh/profiles/web/pnpm-workspace.yaml 里加：
#      onlyBuiltDependencies:
#        - dsh-chatflow-rail

# 2. 从 GitHub 仓库安装（prepare 会在安装时构建 lib/；lib/ 是构建产物，未提交）
dsh plugin --profile web add github:veritas501/dsh-chatflow-rail

# 3. 重启 dsh web，然后刷新页面
dsh web
```

说明：

- `dsh plugin` 相当于给 web profile 加一个依赖。bundle 型插件需要在 profile 的 `dsh.profile.bundles` 里出现它的完整包名才会被加载（新版 dsh 会自动加；如果你的版本没加，请手动补上）。bundle patch 在下次启动时生效，浏览器在刷新后拉到新 bundle 修订版。
- 开发这个插件本身时，改用本地检出安装：先 `pnpm build`，再 `dsh plugin --profile web add file:/path/to/dsh-chatflow-rail`。
- 导航条由浏览器半边（`dsh.client` → `lib/client.js`）绘制；Node 半边（`lib/index.js`）是 no-op，只为满足 loader 的根模块契约。

## 开发

- `pnpm run build` — 经 tsc + tsdown 产出浏览器 bundle（`lib/client.js`）与 Node 半边（`lib/index.js`）。
- `src/client/model/*` — React-free 纯逻辑（几何、布局、上一消息选择、平滑滚动、锚点收集、分页）；可调常量在 `src/client/model/constants.ts`。
- `src/client/view/*` — TSX 组件与 CSS Modules（lightningcss 编译，注入为 `style[data-plugin="dsh-chatflow-rail"]`）。
- `pnpm test` — model 层 vitest 行为测试；`pnpm run typecheck` — 类型门禁。
- `--dev` 的 `dsh web` 会自动热加载重建的 bundle——改完 `pnpm run build` 一般就能看到效果。

## License

MIT © veritas501
