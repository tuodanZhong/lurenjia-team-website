# better-session-management

[English](./README_EN.md) | 中文

<!-- 主题标签：cordis · dsh-plugin · deepseek-harness -->

[![dsh-plugin](https://img.shields.io/badge/topic-dsh--plugin-6366f1)](https://github.com/topics/dsh-plugin)
[![cordis](https://img.shields.io/badge/framework-cordis-8b5cf6)](https://github.com/cordiverse/cordis)
[![DeepSeek Harness](https://img.shields.io/badge/platform-DeepSeek%20Harness-10b981)](https://github.com/deepseek-ai/DeepSeek-Harness)

一个面向 [DeepSeek Harness (DSH)](https://github.com/deepseek-ai/DeepSeek-Harness) 的**插件包（dsh bundle）**，在会话（session）原语之上提供链式上下文视图、子会话（sub-session）、`/btw` 一次性问答与工作区/会话树管理，让长对话中的"分支继续"与"临时插话"更可控。

[安装方式](#安装)

## 功能特性

### 🔗 链条视图（插件链）

![链条视图：指令 → 插件链（思考/工具调用/工具输出）→ 助手反馈](asset/chain_view.png)

- 对话视图新增「链条视图」页签：按「指令 → 插件链（思考/工具调用/工具输出）→ 助手反馈」分组渲染。
- 插件链步骤盒可展开查看调用参数、工具输出与错误详情；气泡可折叠为最后反馈。
- 顶部「加载更早」分页沿用对话视图同源分页，加载时保持阅读位置；打开会话自动定位到末尾。
- 与对话视图对齐的同款 Markdown 渲染（标题/表格/列表/引用）；代码块渲染为独立圆角「代码窗口」——行号列与代码列竖线分割、长行不换行横向滚动。
- 用户指令气泡同样渲染 Markdown，并保留原始换行。

### 🌿 子会话（sub-session）
- 在任意轮次边界创建子会话：继承父会话上下文至该边界，之后独立工作，血缘持久记录于子会话 header。
- 两种继承模式（设置页可选，默认「摘要快建」）：
  - **摘要快建（window）**：以父会话最近 24 轮转录为种子（毫秒级创建，早期历史以转录摘要呈现）；
  - **完整继承（full）**：复制边界之前的全部历史（与分支同成本）。
- 创建入口：助手消息操作条「创建子会话」图标、反馈操作条「分支/创建子会话」按钮、模型工具 `bsm_create_sub`。
- 创建后自动打开新子会话；主会话对应轮次尾部出现子会话卡片，左侧会话栏嵌套显示于父会话之下。
- 子会话以**普通会话身份**创建（无 subagent origin）：不占用「子代理」徽章、不触发任何自动上下文注入、无 agent-busy 栅栏。
- 「压缩注入主会话」：子会话内可将其内容按 简洁摘要/详细纪要/结论+行动项 三种模板压缩后**静默注入**主会话（不自动开启新轮次）。

### 💬 btw（by the way）

![btw 问答卡片：问题、回答与耗时；可销毁 / 创建子会话 / 发送给主会话](asset/btw_introduction.png)

- 输入框 `/btw <问题>` 发起**一次性只读临时问答**：仅一次提问机会，回答后立即销毁全部运行态，界面只保留主会话中的问答卡片（问题 + 回答 + 耗时）。
- 只读工具白名单：`read` / `read_image` / `glob` / `grep` / `web_search` / `skill`——不改文件、不执行命令、不创建子代理。
- 回答不自动注入主会话（无结算通知、无唤醒）；想继续追问请用卡片上的「**创建子会话**」把 btw 完整问答转录迁入子会话继续工作，或「发送给主会话」手动压缩注入。
- 「**btw 思考深度**」设置：低（off，最快）/ 中（high，标准，默认）/ 高（max，最深入），选择后即同步生效，控制思考长度与耗时。

### 🗂 会话栏（工作区 > 会话 > 子会话）

![左侧会话栏：工作区文件夹 → 主会话（缩进）→ 子会话（↳ 缩进）](asset/session-manage-tree.png)

- 左侧会话栏替换为三级树：工作区文件夹 → 会话（含分支会话）→ 子会话；主会话相对文件夹缩进一级，子会话再缩进一级并带 `↳` 前缀。
- ▸/▾ 仅折叠/展开（左侧箭头），点击标题打开会话；悬停可重命名/删除。
- 删除 = 持久归档：live agent 卸载、会话从所有列表隐藏（插件更新/进程重启后依然隐藏；DSH 暂无物理删除 API，磁盘日志保留但不可见）。
- 工作区悬停可删除：其下会话同步归档；未归入任何工作区的会话按 cwd 自动合成文件夹，始终可见。
- btw 派生会话不出现于任何会话列表。

### ⚙️ 其他
- 反馈操作条：复制 / 分支 / 创建子会话 / 点赞 / 点踩（与原生反馈打通）。
- 设置页：气泡整合方案、默认折叠链条框、高亮反馈、Markdown 渲染、子会话继承模式、btw 思考深度、显示宽度。
- 主题变量对齐的 Markdown 样式，明暗主题自适应。

## 设计原则

- **构建在 session 原语之上**：子会话 = 真实会话 fork（血缘持久化、可独立续聊），而非子代理（sub-agent）包装；不主动向主会话通信，不触发任何自动上下文注入或主会话自动执行。
- **显式优于自动**：所有回传（压缩注入）均为手动触发；btw 一次性、无结算通知。
- **无侵入副作用**：不调用 DSH 官方 fork RPC（分支走自有创建路径）；经未追踪原始 agent registry 创建子会话，owner=undefined，与 DSH 官方 fork 语义一致。

## 目录结构

```
better-session-management/
├── package.json             # dsh.bundle 清单（+ dsh.client 浏览器半声明）
├── cordis.patch.yml         # bundle 层：挂载 Host 半
├── index.js                 # Host 半（子会话/btw 服务、Typert Remote RPC、模型工具）
├── client.js                # Client 半（链视图、卡片、会话栏、设置页；模块加载器格式）
├── src/                     # 动态插件源码镜像（开发调试用；bundle 由脚本生成）
│   ├── host.js              # 动态版 Host（harness RPC）
│   ├── client2.template.js  # 动态版 Client 模板（__ICONS_JSON__ 占位符）
│   └── icons.json           # IconPark 图标目录（30 个，Apache-2.0）
├── scripts/
│   ├── build-client.cjs      # 动态版客户端构建（图标占位 + 分块转义 + 语法检查）
│   └── build-bundle.cjs      # bundle 移植生成器（src/host.js + dist 客户端 → index.js/client.js）
├── asset/                    # 界面截图（仅供仓库 README 展示，不进 npm 包）
├── README.md / README_EN.md
```

## 安装

> 需要 DSH 的 `dsh` CLI（[官方文档：Package and install a plugin](https://deepseek-harness.github.io/deepseek-harness/en/develop/basic/publish)）。

### 方式一：从 GitHub 安装（推荐）

`--profile` 指定安装目标：一个 profile 就是一份可运行的插件组合（保存在 `$DSH_HOME/profiles/<名称>/` 下，名称可自定义，例如 `web`、`demo`、`work`、`default`）。以名为 `demo` 的 profile 为例：

```bash
dsh plugin --profile demo add github:boyun-zhang/better-session-management
dsh --profile demo
```

本插件为纯 JavaScript、无构建步骤，通常无需额外授权；若 pnpm 提示 allowBuilds，按提示把包名加入该 profile 的 `pnpm-workspace.yaml` 后重试即可。

### 方式二：本地目录 / npm / tarball

```bash
dsh plugin --profile demo add ./better-session-management   # 本地 checkout
# 或发布到 npm / pnpm pack 出的 .tgz 后：
# dsh plugin --profile demo add <pkg 名或 ./xxx.tgz>
```

安装完成后 `dsh --profile demo --dump-config` 应能看到 `# == dsh-better-session-management` 配置层。

### 开发/热修：动态插件部署（可选）

本仓库保留动态插件源码（`src/host.js` + `src/client2.template.js`），适合不重启服务地热修实验（DSH 会话内）：

```bash
node scripts/build-client.cjs          # -> dist/client.chunked.js
```

随后在 DSH 会话中用 `cordis_define`（`plugin.kind: "new"`，`code.host` = `src/host.js` 全文，`code.client` = `dist/client.chunked.js` 全文）并 `cordis_run` 激活；更新用 `cordis_define`（`kind: "existing"`）+ `cordis_run`（`update`）。动态插件为进程级定义，DSH 重启后需重新部署。

## 使用指南

| 操作 | 方式 |
| --- | --- |
| 创建子会话（摘要快建/完整继承） | 助手消息操作条图标 / 反馈操作条按钮 / 模型工具 `bsm_create_sub` |
| 分支（完整继承） | 反馈操作条「分支」按钮（自有创建路径，不用官方 fork RPC） |
| btw 临时问答 | 输入框 `/btw <问题>` |
| 查看子会话/btw | 主会话轮次尾部卡片、左侧会话栏树 |
| 打开子会话 | 卡片「打开子会话」或侧栏点击标题 |
| 压缩注入主会话 | 子会话头部「压缩注入主会话」三档模板；btw 卡片「发送给主会话」 |
| 重命名/删除 | 侧栏悬停行：✏️ 重命名 / 🗑 删除（归档） |
| 设置 | 设置 → 会话管理 |

## 已知限制

- btw 记录为进程内一次性记录（符合其一问一答的语义）；bundle 形态随 profile 持久，动态插件形态在 DSH 重启后需重新部署。
- DSH 没有物理删除会话的 API：「删除」= live agent 卸载 + 持久归档隐藏，磁盘日志保留但所有界面不可见。
- 侧栏覆盖了 DSH 原生工作区浏览区（工作区新建/切换对话框随之替换；「新建会话」仍可用）。
- 重命名仅支持已加载（live）会话：冷会话请先打开再重命名。

## 致谢

- 图标：[IconPark](https://iconpark.oceanengine.com/official)（字节跳动开源图标库，Apache-2.0）。
- 会话与子代理底层能力由 DeepSeek Harness 提供。
