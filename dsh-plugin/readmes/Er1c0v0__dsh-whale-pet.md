# dsh-whale-pet

[English](./README.md)

一个运行在 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) Web UI 中的鲸鱼娘桌面宠物插件。

| 待机 | 悬停挥手 | 工作中 | 已完成 |
|:---:|:---:|:---:|:---:|
| ![待机动画](https://raw.githubusercontent.com/Er1c0v0/dsh-whale-pet/main/docs/idle-preview.gif) | ![悬停挥手](https://raw.githubusercontent.com/Er1c0v0/dsh-whale-pet/main/docs/hover-preview.gif) | ![工作动画](https://raw.githubusercontent.com/Er1c0v0/dsh-whale-pet/main/docs/working-preview.gif) | ![完成动画](https://raw.githubusercontent.com/Er1c0v0/dsh-whale-pet/main/docs/ready-preview.gif) |

## 主要功能

- 映射 Harness 的五种状态：待机、工作中、需要操作、任务完成和遇到问题。
- 待机时抱着 DeepSeek 鲸鱼标识启发的抱枕，40 秒后入睡，鼠标悬停或键盘聚焦时会惊醒并播放一次友好的三姿势挥手。
- 使用 Harness 提供的展示元数据生成隐私安全的工作摘要；气泡会根据宠物和视口位置自动避让，不遮挡人物并保持在页面内。
- 支持拖拽、键盘移动、位置重置、折叠/恢复、减少动态效果、中英文界面。
- 仅使用官方 `shell.overlay` 插槽，不修改 Harness，也不抓取界面文字。

## 安装

需要 Node.js 22.19+ 或 24+，以及 DeepSeek Harness 0.1.0-rc.6。

```bash
dsh plugin --profile web add dsh-whale-pet@0.1.0
dsh --profile web --dump-config
dsh --profile web
```

配置中应只出现一条 `dsh-whale-pet`；宠物会显示在 Web UI 右下角。

卸载：

```bash
dsh plugin --profile web remove dsh-whale-pet
dsh --profile web --dump-config
```

## 状态映射

| 优先级 | 会话条件 | 宠物状态 |
|---:|---|---|
| 1 | 会话已移除 | 遇到问题 |
| 2 | 等待审批、计划确认或回答 | 需要操作 |
| 3 | 正在运行 | 工作中 |
| 4 | 存在明确的打开、代理或发送错误 | 遇到问题 |
| 5 | 运行中的会话正常停止 | 完成 1600 毫秒 |
| 6 | 无会话、冷启动/加载中或已稳定 | 待机 |

## 开发与验证

```bash
pnpm install --frozen-lockfile
pnpm check
pnpm test:visual
npm pack
node scripts/smoke-harness.mjs --package ./dsh-whale-pet-*.tgz
```

待机资源、帧顺序和交互时序统一以 `src/client/idle-animation.json` 为单一数据源。`pnpm assets:check` 会强制检查 700,000 字节的运行时 WebP 上限；当前资源占用 679,044 字节，继续增加美术资源前需先评估体积。

美术与验证规则见 [CONTRIBUTING.md](./CONTRIBUTING.md)。

## 隐私与许可证

插件只读取当前会话状态和工具主动提供的展示元数据，不读取工具参数、提示词、模型推理或会话正文，也不发送分析请求。偏好仅保存在浏览器本地。

代码采用 [MIT](./LICENSE)，美术采用 [CC BY 4.0](./LICENSES/CC-BY-4.0.txt)；来源与哈希见 [ASSET_ATTRIBUTION.md](./ASSET_ATTRIBUTION.md)。
