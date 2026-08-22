# @cuttlefish520/dsh-token-meter

DeepSeek Harness 的实时 Token 用量浮窗插件（供应商无关）。A real-time, provider-agnostic token usage dashboard for DeepSeek Harness — a draggable floating panel in the style of Claude Desktop.

## 功能 Features

- **供应商无关**：拦截 `llm/stream` 统一出口，任何走 Harness `llm` 服务的供应商（DeepSeek、OpenAI、Anthropic…）都会被统计；供应商返回官方 `usage` 时自动采用精确值，否则按字符数/4 估算。
- **实时面板**：流式输出 token 实时跳动（呼吸灯），每 1 秒刷新。
- **统计卡**：会话、消息、总 Token、活跃天数、当前/最长连续、高峰时段、最爱模型。
- **分布**：按供应商 / 按模型的 Token 条形图 + 最近调用列表。
- **交互**：
  - 拖动位置（面板顶部标题栏）
  - 调整大小（右下角手柄，最小 260×200）
  - 最小化 / 展开（标题栏「—」/ 右上角胶囊）
  - 重置统计（标题栏「重置」）
  - 侧边栏底部常驻开关「⏱ Token 开/关」
  - 全局快捷键 **`Ctrl/Cmd + Shift + M`** 一键显示/隐藏（自动避开输入框）

## 安装 Install（已验证的正确方法）

DeepSeek Harness 的 host 组合位于 **profile 根目录**，通常为：

| 系统 | 路径 |
| --- | --- |
| Windows | `%USERPROFILE%\.dsh\profiles\<profile>\`（如 `C:\Users\你\.dsh\profiles\web\`） |
| macOS / Linux | `~/.dsh/profiles/<profile>/` |

该目录里 `cordis.yml` 是主配置（内容为空列表 `[]`，由 bundle + patch 合成，**不要改它**）。**插件要写进 `cordis.patch.yml`**（用户补丁层，YAML 数组）。

### 第 1 步：把 npm 包安装到 profile 的 node_modules

```bash
cd <profile 根目录>     # 例如 cd C:\Users\你\.dsh\profiles\web
npm install @cuttlefish520/dsh-token-meter --save --registry https://registry.npmjs.org/
```

> ⚠️ 两个坑：
> 1. **镜像源**：如果你平时用 npmmirror 等镜像，务必加 `--registry https://registry.npmjs.org/`，否则装不到本包。
> 2. **npm install 会修剪（prune）** package.json 里未列出的其它手工安装的插件——典型症状是重启后报 `Cannot find package '@xxx/yyy'`。如果 profile 里还有别的本地/手工插件，请先把它们也写进 `package.json` 的 `dependencies` 再执行安装。

### 第 2 步：在 cordis.patch.yml 末尾追加插件行

```yaml
- insert:
    - id: token-meter-dashboard
      name: '@cuttlefish520/dsh-token-meter'
```

格式与文件中已有的其它插件条目一致（`insert` 块内的条目追加到组合树末尾）。

### 第 3 步：重启 DeepSeek Harness

重启后浮窗即常驻、跨重启生效。浏览器端 bundle 由启动时的 `dsh-client-modules` 扫描 `dsh.client` 声明自动注入，无需手工构建。

## 为什么必须挂在 host 组合（而不是 agent preset）

浏览器 client bundle（`dsh.client`）只会从 **host loader 的条目**中被发现（`dsh-client-modules` 扫描 `ctx.loader.entries()`）；agent preset 是「直接挂载的子树」，不在 `loader.entries()` 里。所以浮窗 UI 无法通过 preset 提供，必须挂 host 组合（即上面的 `cordis.patch.yml`）。

## 卸载 / 回滚 Uninstall

1. 从 `cordis.patch.yml` 删除上面追加的 3 行（建议改前先备份该文件）；
2. `npm uninstall @cuttlefish520/dsh-token-meter`；
3. 重启 Harness。

## Host HTTP 路由

| 路由 | 方法 | 说明 |
| --- | --- | --- |
| `/token-usage/state` | GET | JSON 快照（live 调用 + 聚合统计 + 最近调用） |
| `/token-usage/reset` | POST | 清空内存统计 |

## 说明 Notes

- 统计是**进程内内存态**：Harness 重启后清零。
- 输出 token 在供应商不返回 `usage` 时按 `字符数/4` 估算，属于近似值。
- 面板位置/大小是浏览器内存态，刷新页面回到默认（右上角 340px）。

## License

MIT
