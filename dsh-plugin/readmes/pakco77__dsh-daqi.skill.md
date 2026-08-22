<p align="center">
  <img src="assets/daqi-icon.png" width="160" alt="dsh-daqi 达奇">
</p>

<h1 align="center">dsh-daqi.skill</h1>

<p align="center"><strong>一个点子孵化器。</strong></p>

<p align="center">
  <a href="https://github.com/topics/dsh-plugin"><img src="https://img.shields.io/badge/dsh-plugin-252520?style=flat-square" alt="dsh plugin"></a>
  <a href="https://agentskills.io/"><img src="https://img.shields.io/badge/Agent-Skills-555047?style=flat-square" alt="Agent Skills"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-777064?style=flat-square" alt="MIT License"></a>
  <img src="https://img.shields.io/badge/Local--first-9A9A94?style=flat-square" alt="Local-first">
</p>

---

你随口说的每个痛点、每个想法，达奇都在营地帮你记下；账本会去重、会养大、会记得每一票干到哪了。你才是点子王——数据全在你自己电脑里，不读对话，不上传。

**营地三要素**：账本（痛点 · 点子 · 待办）、马厩（干到哪一票了）、观火观己（跨 Agent 对你的认知）。

对了，这个达奇永远不会背叛你，而摩根，在马厩里，随时陪你干一票。

**牛仔，开始你的荒野之旅吧！**

<p align="center">
  <img src="assets/camp-demo.gif" width="640" alt="达奇营地实况">
  <br><em>营地实况：扫 Agent → 勾选 → 深读 → 提交，全程闭环。</em>
</p>

## 装进 DSH

```text
请安装 daqi.Skill：npx skills add pakco77/dsh-daqi.skill
安装 daqi、context-fold、project-fold。装完验证能发现 daqi。
```

再把 MCP 桥写进 DSH profile 的 `cordis.patch.yml`（重启 DSH 后工具注册为 `mcp__daqi__*`）：

```yaml
[
  {
    name: mcp-client,
    config: {
      transport: stdio,
      serverName: daqi,
      command: python3,
      args: [
        ~/.agents/skills/daqi/scripts/daqi_mcp.py,
        --store,
        ~/.daqi,
      ],
    },
  },
]
```

## 三条预设指令

| 指令 | 干什么 |
|---|---|
| `/daqi-search` | 扫描点子：扫本地 Agent → 指定工作区 → 提炼候选，确认后入库 |
| `/daqi-camp` | 打开营地面板（macOS 自动开浏览器） |
| `/daqi-deep <项目>` | 深挖项目进程（长耗时，带进度；无 API key 时用本机 Agent 执行） |

## 营地怎么转

- 说「我发现……」「我有个想法……」，达奇自动记账——痛点进「痛点发现」，想法进「点子」，证据齐了进「计划」；
- 营地页 `~/.daqi/camp.html`：扫本地 Agent → 勾选 → 浅读/深读 → 提交，全程在页面里闭环，写操作都要你确认；
- 换 Agent 说「达奇：开工」，一条主线、一个下一步；
- 删除要二次确认；扫描永不读对话。

主仓库：[pakco77/daqi.skill](https://github.com/pakco77/daqi.skill)

[MIT](LICENSE) © 2026 Pakco
