# dsh-skill-manager

> DSH（DeepSeek Harness）技能分类管理器：自由分类 / 标签 / Collections（集合文件夹）+ 设置面板「技能管理」。
> Manage and organize your agent skills by category, tags and collections in DeepSeek Harness.

把散乱的上百个 agent skills 按你的方式分类整理：给每个技能打上**分类（category）**和**标签（tags）**，放进可点击的**集合文件夹（Collections）**，在 DSH Web 的设置面板里一目了然地浏览、筛选、启用/停用。

## 功能特性

- 🗂️ **自由分类**：给技能 frontmatter 写入 `metadata.category`，分类可自由创建、随时修改；
- 🏷️ **标签**：写入 `metadata.tags`（逗号分隔，支持多个）；
- 📁 **集合文件夹（Collections）**：把多个技能组织成命名集合（如「AI视频工作流」），一个技能可属于多个集合；
  - 顶部筛选区点击集合芯片 → 左侧只显示该集合内的技能；
  - 集合内可直接点击技能查看简介、启用/停用、移除；
- 🔍 **浏览与筛选**：搜索、按分类筛选、按集合筛选；
- 👁️ **点击预览**：左侧点击技能行即展开简介卡片（描述 / 适用场景 / 标签 / 启用状态）；
- 🔌 **启用 / 停用**：一键写入 frontmatter 的 `disable-model-invocation`（DSH 原生识别——停用后模型不再自动加载该技能），面板与命令均可操作；
- 🎯 **输入框集合挑选**：输入 `/` + 文件夹名 → 显示 📁 集合文件夹 → 点击弹出该文件夹的技能列表（带简介、可「← 返回」、保留滚动位置）；
- ⌨️ **斜杠命令**：`/skillmgr ...` 全部功能可在对话输入框直接使用，命令不经模型；
- 💾 **纯本地、无服务依赖**：分类写进技能文件本身（兼容任何 agent），集合存本地 JSON。

 ## 图片演示 
<img width="805" height="805" alt="image" src="https://github.com/user-attachments/assets/ebf743ee-46bf-468a-92ca-52fe9e9a1476" />
<img width="829" height="480" alt="image" src="https://github.com/user-attachments/assets/798899f6-3cf7-455a-86d8-0862505c193d" />
<img width="869" height="325" alt="image" src="https://github.com/user-attachments/assets/c96fe9a7-b12e-41ef-81c9-e7839e7f144c" />



## 环境要求

- DeepSeek Harness（`dsh web`）0.1.0-rc.6+
- Node.js ≥ 20

## 安装

### 1) 安装（推荐：bundle 插件）

本插件声明了 `dsh.bundle` manifest，可直接用 DSH 的命令安装：

```bash
dsh plugin --profile web add github:LIU20030725/dsh-skill-manager
```

手动方式（在 DSH 的 **web profile 目录**，通常是 `~/.dsh/profiles/web`）：

```bash
cd ~/.dsh/profiles/web
pnpm add github:LIU20030725/dsh-skill-manager
```

> 💡 若 `github:LIU20030725/dsh-skill-manager` 依赖解析失败，可改用完整 git URL：
> `pnpm add git+https://github.com/LIU20030725/dsh-skill-manager.git`

### 2) 挂载插件

编辑该目录下的 `cordis.patch.yml`，在顶层数组中加入：

```yaml
- insert:
    - id: skill-manager
      name: 'dsh-skill-manager'
```

### 3) 重启 Web

```bash
# 停止当前 dsh web 进程后重新启动（若有 dsh-web-service 守护会自动拉起）
dsh web
# 或
node <dsh安装路径>/node_modules/@deepseek-ai/dsh/lib/bin.js web
```

重启后刷新页面：设置 → **技能管理** 面板出现；对话输入 `/skillmgr help` 可查看命令。

> ⚠️ **必须重启**：客户端面板 bundle 与宿主命令注册均在 Web 启动时加载，配置热更新无法加载新插件。

## 使用

### 设置面板「技能管理」

1. **左侧**：全部技能列表；顶部「全部 / 分类芯片 / 📁集合芯片」筛选；点技能行展开简介卡片；
2. **右侧**：选中技能后可
   - 设置**分类**（自由输入或从已有分类中选择）；
   - 设置**标签**（逗号分隔）；
   - 勾选**所属集合**（加入/移出）；
   - **启用 / 停用**（写入 `disable-model-invocation`）；
3. **底部集合区**：新建集合、点击展开查看集合内技能（可点技能查看详情、直接启用/停用、移除）。

### 输入框集合挑选

在对话输入框中输入 `/` 后继续输入集合（文件夹）名（如 `/AI视频`），下拉菜单「集合技能」分组会显示匹配的 📁 集合文件夹（含每个集合的技能数量；输入 `/` 时还会显示「未分类技能」文件夹）。

点击某个 📁 文件夹，会**弹出一个小下拉页**展示该集合内的所有技能（带简介）：

- 点选技能 → 输入框自动填入 `/技能名`，回车直接调用；
- 左上角「← 返回」→ 回到全部集合列表（保持原滚动位置）；
- 支持 ↑↓ 方向键选择、Enter 确认、Esc 关闭。

适合技能很多、记不清每个技能用途时，按文件夹逐级浏览挑选。

### 斜杠命令（全部功能等价）

```
/skillmgr help
/skillmgr catalog                                 # 全部技能 + 集合（JSON）
/skillmgr get <name>                              # 单个技能详情（JSON）
/skillmgr set-category <name> <分类|->            # 设置分类；- 清除
/skillmgr set-tags <name> <tag1,tag2|->           # 设置标签；- 清除
/skillmgr set-enabled <name> <on|off>             # 启用 / 停用
/skillmgr collection list                         # 列出集合
/skillmgr collection create <名称>                # 新建集合
/skillmgr collection rename <旧名> <新名>         # 重命名
/skillmgr collection delete <名称>                # 删除集合
/skillmgr collection add <名称> <skill...>        # 把技能加入集合
/skillmgr collection remove <名称> <skill...>     # 从集合移除技能
/skillmgr collection clear <名称>                 # 清空集合
```

## 数据与存储

- **分类 / 标签**：直接写入技能文件 `SKILL.md` 的 YAML frontmatter（`metadata:` 下的 `category` / `tags`），不依赖嵌套目录，兼容所有 agent：
  ```yaml
  ---
  name: ai-video-script
  description: 生成 AI 视频脚本
  metadata:
    category: 视频创作
    tags: [视频, 脚本]
  ---
  ```
- **启用/停用**：写入顶层 `disable-model-invocation: true`（DSH 原生字段）。
- **集合（Collections）**：存于 `$DSH_HOME/skill-manager/collections.json`（默认 `~/.dsh/skill-manager/collections.json`）。

## 管理范围

可管理任何带磁盘路径、可写的技能（`SKILL.md` 所在文件），典型位置：

| 来源 | 路径 |
|---|---|
| 用户技能（本插件默认推荐） | `~/.agents/skills/<name>/SKILL.md`、`$DSH_HOME/skills/<name>/SKILL.md` |
| 项目技能 | `<项目根>/.dsh/skills`、`<项目根>/.agents/skills` |
| DSH 内置技能 | `node_modules/...`（**只读**，面板中可见但写入会报错） |

## 卸载

```bash
cd ~/.dsh/profiles/web
pnpm remove dsh-skill-manager
# 并从 cordis.patch.yml 删除对应 insert 行，重启 dsh web
```

删除本插件**不会**删除技能文件里的分类/标签（它们属于技能本身），也不会删除 `collections.json`（如需清理手动删除该文件）。

## 工作原理（给开发者）

- **宿主半边**（`lib/index.js`）：cordis 插件，`inject: ['skills', 'commands']`；通过 `ctx.skills.list/get` 以 `scope: agent` 读取会话可见的技能目录，读写 frontmatter 用 `yaml`，集合存本地 JSON；注册 `skillmgr` 斜杠命令。
- **浏览器半边**（`lib/client.js`）：按 DSH 客户端插件 bundle 规范（`window.__ModuleLoader__.load`）打包，注册 `settings.section`（「技能管理」）；数据与操作通过 `ctx.remote.commands.execute` 调用宿主命令（与 DSH 自带 `/permission` 同一条可靠通道）。
- **开发脚本**：`scripts/test-manual.mjs`（mock ctx 自测命令逻辑）、`scripts/make-catalog.mjs`（生成本地技能目录报告）。

## 常见问题（FAQ）

**Q: 面板显示 0 个技能？**
A: 确认插件已随 Web 重启加载；命令按当前会话 agent 的作用域查询技能，若在全新会话中先创建/打开一个会话再打开面板。

**Q: 内置技能（node_modules 里的）不能打标签？**
A: 是的，内置技能是只读的。请把要管理的技能放在 `~/.agents/skills` 或 `$DSH_HOME/skills`。

**Q: 停用技能后有什么效果？**
A: 写入 `disable-model-invocation: true`，DSH 模型目录不再包含该技能（模型不会自动加载），但它仍保留在你的库中、仍可手动调用。

**Q: 改了代码如何生效？**
A: 把改动同步到 profile 的 `node_modules/dsh-skill-manager`（或重新 `pnpm add file:<路径>`）后重启 `dsh web`。

## License

[MIT](./LICENSE)
