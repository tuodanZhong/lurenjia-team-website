# dsh-skill-search · 按需技能搜索器 🔍

DeepSeek Harness 插件：让海量技能库「零预加载、按需搜索」。

## 解决的问题

dsh 默认在启动时把每个技能的 name/description 注入模型上下文——几百个技能就是数万 token 的固定开销，装一万个技能直接爆上下文。本插件换一种架构：**启动时什么都不注入**，需要时用关键词搜索磁盘上的 SKILL.md（rg 快路径 + Node 兜底），AI 只读命中的那份全文并执行。

## 用法

- 工具：`skill_search`
- 参数：`query`（必填，中英文关键词；匹配目录名 / frontmatter 的 name 与 description / 正文开头）、`limit`（默认 10）

示例（用户说「搜技能：去AI味」）：

```json
{ "query": "去AI味", "libraries": ["C:\\Users\\…\\.codex\\skills"], "count": 1,
  "skills": [ { "name": "humanizer", "description": "去掉 AI 味…", "path": "…\\去AI味\\SKILL.md" } ] }
```

AI 随后只 read 该 path 的全文并照做——上下文成本恒为「一份 SKILL.md」，与技能库规模无关。

## 配置

在 profile 的 cordis.patch.yml 给插件行加 config 可指向多个技能库：

```yaml
- insert:
    - id: dsh-skill-search
      name: dsh-skill-search
      config:
        dirs:
          - C:\\Users\\Equinox\\.codex\\skills
```

## 可靠性

- 纯只读；零运行时依赖；无自定义会话事件；无 HTTP 路由；
- rg 不可用时自动降级纯 Node 遍历；
- 共享同一份文件：技能库在别处（如 Codex）更新，本插件即刻看到新内容，无需复制同步。

## License

MIT
