# agent-diagram

**技术文档配图，不该让 README 难堪。**

别再往 README / PR 里贴通用 Mermaid 方块。一个 Agent Skill → 自包含 HTML/SVG，浏览器直接打开。

优先支持 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)，兼容 Claude Code 与 Cursor。

完整双语说明见主文档 [README.md](README.md)。

<p align="center">
  <img src="docs/screenshots/mermaid-slop.png" alt="通用自动配图" width="48%">
  <img src="docs/screenshots/agent-diagram-architecture.png" alt="agent-diagram 架构图" width="48%">
</p>
<p align="center"><em>左：典型 Agent Mermaid · 右：agent-diagram</em></p>

---

## 为什么做这个

每次让 Agent「画个架构图」，得到的都是同一套圆角方块。放进任何仓库都长一个样，也配不上其余文档。

我想要的是 **软件工程文档** 用的图：插件树、时序、分层、重构前后对比——不用打开 Figma。所以把工作流打成一个 Skill，**DeepSeek Harness 一键安装** 放在最前面。

不做 27 种内容站图。**8 种开发者高频图。** 打开 `.html` 即可，无构建。

---

## 安装

**DeepSeek Harness（一条命令）：**

```bash
curl -fsSL https://raw.githubusercontent.com/nanjingya/agent-diagram/main/install.sh | bash
```

安装到 `~/.dsh/skills/agent-diagram`。然后执行 `dsh web`，让 Agent 画一张插件架构图。

```bash
git clone https://github.com/nanjingya/agent-diagram.git && cd agent-diagram && ./install.sh
./install.sh --project   # 仅当前仓库
```

**Claude Code / Cursor：**

```bash
cp -R skills/agent-diagram .agents/skills/
cp -R skills/agent-diagram ~/.cursor/skills/   # 用户级
```

---

## 试一下

复制到会话里：

```
Load skill agent-diagram and draw a plugin-composition diagram for the DeepSeek Harness web profile. Save to docs/diagrams/.
```

更多提示词：

```
Draw a sequence diagram for an agent turn: user message → LLM → tool execute → reply
```

```
Before/after diagram: monolithic handler vs capability seams (provider, consumer, tool)
```

预期产出：一份自包含 `.html`，任意浏览器可打开。

---

## 八种工程图

| 类型 | 用途 |
|---|---|
| architecture | 模块、服务、数据流 |
| sequence | API 或 Agent 调用时序 |
| flowchart | 分支逻辑 |
| layer-stack | 分层架构 |
| plugin-composition | Cordis 插件树、dsh 配置层 |
| before-after | 重构前后对比 |
| comparison-table | 方案对比表 |
| state-machine | 状态流转 |

可打开示例：[web profile 插件构图](docs/diagrams/example-plugin-composition-web-profile.html)

这不是 [diagram-design](https://github.com/cathrynlavery/diagram-design) 的复刻。对方偏内容站 / 品牌配图（27 种）。本仓库偏 README、PR、工程文档，并以 DeepSeek Harness 为首发安装路径。

---

## 兼容

- [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) — `dsh web`、headless、ACP
- Claude Code — `.agents/skills/`
- Cursor — `.cursor/skills/` 或 `.agents/skills/`

---

## 许可

MIT — 见 [LICENSE](LICENSE)。
