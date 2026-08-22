# dsh-bookmark

[English](README.md) | 简体中文

面向 DeepSeek Harness Web UI 的 Codex 风格长对话导航插件。插件在对话区域侧边 gutter 中显示紧凑导航条，每一根短线对应一条用户消息；悬停可预览当前轮次，点击可直接跳转到对应消息。

## 功能

- 每条用户消息或 steering 消息对应一根短线。
- 默认 12px 短线，悬停时提供 Codex 风格的三级邻线渐变效果。
- 最接近当前视口位置的消息以黑色短线高亮。
- Hover 卡片展示用户消息标题及后续助手回复摘要。
- 支持点击和键盘操作跳转到对应轮次。
- 自动跟随当前选中的会话，包括历史会话。
- 必要时通过 DSH 原生会话 API 加载更早历史记录。
- 侧栏宽度或对话布局变化后自动重新定位。

## 安装

直接从 GitHub 安装：

```bash
dsh plugin --profile web add github:leilei3167/dsh-bookmark
```

安装后重启 Web profile：

```bash
dsh web
```

更新已经安装的插件：

```bash
dsh plugin --profile web update dsh-bookmark
```

更新后需要彻底停止并重新启动 `dsh web`，浏览器才会加载新的 client bundle。

## 使用方式

- **悬停短线：** 当前短线和附近短线逐级展开，同时展示用户提问及助手回复摘要。
- **点击短线：** 平滑滚动到对应用户消息。
- **键盘导航：** 聚焦短线后使用 `ArrowUp` 或 `ArrowDown`，`Enter` 和 `Space` 使用按钮原生操作。
- **当前位置：** 最接近视口锚点的短线显示为黑色。

## 隐私

插件完全运行在 DSH Web 客户端，不读取 API Key，也不会把对话内容发送到外部服务。对话数据来自当前 DSH 会话快照以及页面已经渲染的聊天节点，仅保留在浏览器内存中。

## 开发

要求 Node.js 22 或更高版本，以及 pnpm。

```bash
pnpm install
pnpm run typecheck
pnpm test
pnpm run build
```

安装本地源码进行测试：

```bash
dsh plugin --profile web add link:/absolute/path/to/dsh-bookmark
```

## 实现说明

导航数据来自 DSH 客户端的 `sessions` 服务，并通过稳定的 `[data-chat-anchor-key]` / `[data-chat-flow-kind]` 属性关联页面消息。DOM 选择器只作为兼容兜底，不依赖宿主页面的哈希 class 名。

执行 `pnpm run build` 时，生成的 `lib/client.js` 会被包装为 DSH 所需的 `window.__ModuleLoader__` 格式。

## 检索与发布

仓库已添加 `deepseek-harness`、`dsh`、`dsh-plugin` GitHub topics，便于 DSH 插件发现工具检索。发布 npm 版本前，请先验证干净环境安装，然后执行：

```bash
npm publish --access public
```

## License

MIT
