# dsh-collapsed-assistant

DSH web client plugin：把每条助手消息的**工具调用折叠成一个内嵌圆角开关**，正文始终完整显示（官方配色），并带彩色文件变更统计 footer。

## 效果

```
[> 工具图标 N] 正文第一行……
 正文第二行……
（点击圆按钮 → 下方展开该消息的工具列表，每行点击打开详情弹窗，hover 显示"轨迹"按钮）
+2 文件  e3 文件  -0 文件  +140 行  -25 行
```

- **正文不折叠**：始终完整显示，官方 markdown 样式（`16px/28px`、`label-primary`、蓝色链接）
- **圆角开关 `[> 最后工具图标 N]`**：内嵌在正文第一行开头（inline），N = 本条消息的工具调用数；有失败工具时带红点。点击展开/折叠下方的工具列表
- **工具行**：每行点击（或"查看"）打开**详情弹窗**（悬浮于全窗口，内容对齐官方详情面板：工具名 + 状态徽标 + 参数 JSON + 输出/错误 + 子调用列表，Esc / 点外部 / ✕ 关闭）；hover 行尾出现**"轨迹"按钮**，点击在轨迹视图中定位该调用（官方 Inspect 语义）
- **文件变更 footer**：彩色胶囊 `+新增文件`(绿) `e修改文件`(黄) `-删除文件`(红) `+新增行`(绿) `-删除行`(红)，全零不显示；每个胶囊可点击展开：
  - **行数项**（`+N 行` / `-N 行`）→ 展开显示实际增/删行内容（绿/红，官方 Edit 工具展开区风格，等宽字体 + 行级底色）
  - **文件项**（`+N 文件` / `eN 文件` / `-N 文件`）→ 展开为文件路径下拉框；**左键点击**在侧边栏 Explorer 中选中该文件（需 [dsh-better-sidebar](https://github.com/GammaChineYov/DSH-better-sidebar) 提供 `ctx.betterSidebar.revealInExplorer`，否则回退为打开文件）；**右键**打开侧边栏 Explorer 的右键菜单（`ctx.betterSidebar.openExplorerMenu`，否则回退为本地复制路径菜单）
- **Think/推理**折叠为一行；**上下文注入**折叠为一行
- **最后一条消息**的工具默认展开，新消息到达后旧的自动收起
- 无正文的纯工具步骤独立成组折叠

实现上替换了 `conversation.chat.node` 槽位的三个键：`assistant-step`、`tool-call`、`context`（内置精简 markdown 渲染器，无外部依赖；完整 KaTeX/高亮等官方特性不在内，需要时可停用本插件恢复原版）。

## 安装

```sh
# 方式一：git 安装（推荐；本仓库已提交构建产物 lib/，git 安装无需构建权限）
dsh plugin --profile web add git+https://github.com/GammaChineYov/dsh-collapsed-assistant.git

# 方式二：本地目录
dsh plugin --profile web add link:C:/Users/PC/dsh-collapsed-assistant

# 方式三：npm（若已发布）
dsh plugin --profile web add dsh-collapsed-assistant
```

安装后**重启 dsh web 生效**；验证组合树：`dsh --profile web --dump-config | grep collapsed-assistant`。

> ⚠️ 若你当前会话里还运行着同名的**动态插件**（`collp-*`，通过 cordis_define 创建），两者会同时注册相同槽位键。装本包前请先停用/删除动态版（`cordis_stop` / `cordis_undefine`），只保留一种。

## 卸载

```sh
dsh plugin --profile web remove dsh-collapsed-assistant
```

## 结构

- `lib/client.js` — 浏览器端 bundle（官方 `window.__ModuleLoader__.load` 闭包格式，纯 JS 已提交，无需构建）
- `lib/index.js` — Host 端空插件（占位，client-only）
- `cordis.patch.yml` — bundle patch（`insert` 插件行）
- `package.json` — `dsh.bundle.patch` + `dsh.client` 声明

发布规范参考 [DeepSeek Harness 官方文档](https://github.com/deepseek-ai/deepseek-harness/blob/master/docs/user/develop/basic/publish.md)：bundle = 声明 `dsh.bundle.patch` 的 npm 包 + `cordis.patch.yml`；git 安装取源码/构建产物——本仓库直接提交构建产物，避免 `prepare` 构建权限问题。

## License

MIT
