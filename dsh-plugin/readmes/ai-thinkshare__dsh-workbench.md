# dsh-workbench

DeepSeek Harness（DSH）侧栏工作台插件：把原生侧栏升级为一个完整的工作台——工作区/会话/文件浏览、会话置顶、运行状态指示、多标签文件预览、`@` 文件引用，以及终端式的输入历史 ↑/↓ 召回。

![侧栏 · 会话](https://github.com/ai-thinkshare/dsh-workbench/raw/main/docs/images/sidebar-sessions.png)

## 功能特性

### 📂 侧栏工作区浏览器

替换原生侧栏（`sidebar.workspaces` 槽位），提供：

- **工作区切换器**：顶部下拉切换工作区，带「工作区」栏目标题、会话计数、添加/移除
- **会话页**：当前工作区的会话列表，支持重命名 / 分叉 / 归档 / 置顶
- **文件页**：目录树浏览（懒加载展开）+ 变更文件——后者直接镜像原生会话"产物"投影（diff/edit 卡片 + 成功的工具调用才计入），与聊天区的产物 chips 完全同源
- 字号体系对齐原生侧栏（标题 14px / 元信息 12px），无违和感

![侧栏 · 文件](https://github.com/ai-thinkshare/dsh-workbench/raw/main/docs/images/sidebar-files.png)

### 📌 会话置顶

会话行 `···` 菜单 →「置顶」：置顶会话浮到列表顶部（组内仍按时间倒序），行尾显示图钉徽标。置顶与运行状态互不遮挡、可共存。状态存于浏览器 `localStorage`，跨刷新、跨 `dsh` 重启保留。

### 🟣 运行状态点

会话行首按原生 `sessionStatuses` 优先级显示实时状态：

| 状态 | 样式 | 数据源 |
|---|---|---|
| 等待审批 / 等待计划确认 / 等待回答 | warn 色实心点 | `pendingInteraction` |
| 运行中 | 像素环追逐动画（复刻原生 StateDot） | `running` |
| 当前选中 | accent 色圆点 | — |
| 空闲 | 灰点 | — |

列表快照 mutation 驱动，会话开始/结束运行时状态点实时跳动，无需轮询。

### 🪟 多标签文件预览

点击目录树或变更文件中的任意文件，右侧滑出预览面板（`shell.overlay`）：

- 支持 Markdown（内联图片）、HTML（沙箱 iframe）、代码（行号 + 选中行引用）、图片
- 多标签、拖拽调宽、可收起为侧边条
- 代码视图选中行后可一键引用到对话（如 `README.md:12-18`）
- 超大文件渲染上限与超时降级，不会卡死页面

![文件预览](https://github.com/ai-thinkshare/dsh-workbench/raw/main/docs/images/preview-panel.png)

### 💬 composer 增强

- **自适应宽度文件 chip**：引用 chip 贴合文件名宽度，悬停显示 × 快速删除，自绘光标始终对齐可视文本
- **`@` 文件引用源**：输入 `@` 即可检索当前工作区目录树内的文件
- **输入历史 ↑/↓ 召回**：草稿为空时按 ↑ 填入最近一条已发消息，↑/↓ 前后翻，↓ 越过最新一条恢复原草稿，任意其他键退出导航。数据源与聊天渲染同源（含历史窗口回放），按会话隔离；IME 组态、非空草稿、含 chip 草稿三种情况下不劫持按键。

## 安装

前置要求：已安装 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) CLI（`dsh`）。

```bash
# 1. 安装到 web profile（npm 安装，推荐）
dsh plugin --profile web add @sjshare/dsh-workbench

# 或 GitHub 直装
dsh plugin --profile web add github:ai-thinkshare/dsh-workbench

# 本地开发安装（link 到源码目录）
dsh plugin --profile web add link:/absolute/path/to/dsh-workbench
```

```yaml
# 2. 在 ~/.dsh/profiles/web/cordis.patch.yml 顶部数组中加入 insert 条目
- insert:
    - id: dsh-workbench
      name: '@sjshare/dsh-workbench'
```

```bash
# 3. 重启生效
dsh web
```

侧栏底部出现 "chip 自适应宽度 · 光标视觉对齐" 状态行即安装成功。

## 临时禁用

想对照原生侧栏效果时，无需改配置，浏览器刷新即生效：

| 方式 | 操作 | 场景 |
|---|---|---|
| URL 参数 | 访问 `http://127.0.0.1:3080/?workbench=off` | 一次性对比 |
| localStorage | `localStorage.setItem('workbench-disabled','1')` 后刷新 | 持续禁用 |
| 恢复 | `localStorage.removeItem('workbench-disabled')` 后刷新 | 回到插件效果 |

彻底卸载：`cordis.patch.yml` 注释掉 insert 条目 + 重启。

## 已知限制与安全说明

### 路径访问白名单（安全模型）

浏览器半与 DSH Web 应用同源，因此 Host RPC（`POST /workbench/rpc`）对所有涉及路径的方法（`wb/list-dir` / `wb/read-file` / `wb/file-url` / `wb/read-asset`）实施白名单校验，仅允许读取：

1. **已注册工作区**的路径（`workspaceRegistry`）
2. **任一会话的工作目录**（会话头部的 `cwd`）

白名单根在每次请求时从 Host 服务动态获取（3 秒 TTL 缓存），工作区增删几乎即时生效。请求路径先做词法归一化（折叠 `.` / `..`）再做前缀比对，阻止目录穿越；范围外的请求返回 `{error}`，预览面板会显示相应提示。纯函数 `normPathLexical` / `pathUnderRoots` 带单元测试（`npm test`）。

**已知边界**：白名单内的符号链接仍可指向范围外文件——创建这样的链接本身需要本机写权限，与 DSH 整体信任级别相同。如需读取白名单外路径（例如预览位于所有工作区之外的产物文件），在启动 `dsh web` 的环境中设置 `DSH_WORKBENCH_UNRESTRICTED=1` 恢复不受限读取，自担风险。

### 其他限制

- **置顶状态存于浏览器 localStorage**（会话 API 暂无元数据接口），换浏览器/设备不同步；归档已置顶的会话不会清除其置顶记录，恢复归档后置顶仍在
- 变更文件面板依赖原生 deliverables 投影，会话历史窗口未装载的早期 turn 不计入
- DSH 尚在 0.1.0-rc 阶段，本插件跟随 rc 版本开发，API 变化可能导致不兼容

## 工作原理（一句话版）

- **Host 半**（`index.js`）：注册 `POST /workbench/rpc` 同源路由，提供 6 个 `wb/*` 处理器（工作区/会话/目录/文件/图片）；所有涉及路径的方法经白名单守卫（见上文安全模型）
- **Client 半**（`lib/client.js`）：`__ModuleLoader__` 格式，注册 `sidebar.workspaces` / `conversation.input.dock` / `shell.overlay` 三个槽位 + `@` 引用源；变更文件与输入历史直接消费客户端会话投影，不走 RPC

## 开发

```bash
# 改 lib/client.js（UI） → 浏览器刷新页面即可
# 改 index.js（Host 路由） → 重启 dsh web
# 路径守卫测试（纯函数 + mock 路由集成）：
npm test

# Host 冒烟测试（正向：任一已注册工作区的路径应返回目录内容）：
curl -s -X POST http://127.0.0.1:3080/workbench/rpc \
  -H 'content-type: application/json' \
  -d '{"method":"wb/list-dir","args":{"path":"/path/to/a/registered/workspace"}}'

# Host 冒烟测试（反向：白名单外路径应返回 {"error":"…已拒绝：…"}）：
curl -s -X POST http://127.0.0.1:3080/workbench/rpc \
  -H 'content-type: application/json' \
  -d '{"method":"wb/read-file","args":{"path":"/etc/passwd"}}'
```

坑位备忘：

- 客户端计时只能用文件内自带的 `later()/every()` 助手——框架计时 API 是动态沙箱注入能力，持久插件直接调用会抛 TypeError（症状：UI 永远"加载中"但请求全 200）
- `callHost` 走 `fetch POST /workbench/rpc`；新增 RPC 方法在 `index.js` 的 `handlers` 表加条目即可，两端协议 `{method, args} → JSON 值`
- CSS 注入用单一 `<style data-workbench-css>` 标签且 textContent 始终同步——"存在即跳过"会在 HMR 时留下缺 keyframes 的旧标签，动画静默失效

## License

MIT
