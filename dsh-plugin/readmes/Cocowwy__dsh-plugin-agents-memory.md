# dsh-plugin-agents-memory

[English](README.en.md) | 简体中文

这是一个 DeepSeek Harness Web 插件，用于直接在设置页面编辑用户全局的 `AGENTS.md`。你可以在其中保存常用仓库、编码偏好、工作流规则，以及希望跨项目长期生效的其他指令。

## 功能

- 在 DeepSeek Harness Web 中新增 **设置 → 全局记忆**。
- 无需离开浏览器即可读取和编辑 `$DSH_HOME/AGENTS.md`。
- 文件不存在时自动创建带基础结构的初始文档。
- 使用原子写入保存，并将文件权限保持为 `0600`。
- 使用 revision 检查，避免一个浏览器标签页静默覆盖另一个标签页的修改。
- 内容大小上限为 256 KiB。
- 浏览器不能指定文件路径；Host 接口固定操作 `$DSH_HOME/AGENTS.md`，并且只接受回环地址请求。

DeepSeek Harness 本身已经通过 `agent-instructions` provider 加载 `$DSH_HOME/AGENTS.md`。本插件只为这个既有指令来源提供一个方便的页面编辑器。

## 环境要求

- 支持 Web profile 和客户端插件的 DeepSeek Harness
- Node.js 20 或更高版本
- 本地 Web 会话（`127.0.0.1` 或 `::1`）

## 安装

使用一条命令将插件安装到 DSH Web profile：

```bash
dsh plugin --profile web add "github:Cocowwy/dsh-plugin-agents-memory"
```

如需固定安装某个版本：

```bash
dsh plugin --profile web add "github:Cocowwy/dsh-plugin-agents-memory#v0.1.2"
```

安装后重启正在运行的 `dsh web`，刷新页面，然后进入 **设置 → 全局记忆**。插件包已经携带 DSH bundle 元数据，不需要手动修改 `package.json` 或 bundles。

## 本地开发安装

克隆仓库后，通过同一个 DSH 命令安装本地目录：

```bash
git clone https://github.com/Cocowwy/dsh-plugin-agents-memory.git
dsh plugin --profile web add "/你的绝对路径/dsh-plugin-agents-memory"
```

安装后重启 `dsh web`。

## 使用方法

打开 **设置 → 全局记忆**，编辑 Markdown 内容并点击 **保存**。内容会写入：

```text
$DSH_HOME/AGENTS.md
```

没有设置 `DSH_HOME` 时，实际路径是：

```text
~/.dsh/AGENTS.md
```

如果文件不存在，打开页面时会自动创建以下基础结构：

```markdown
# Personal Development Context

## Repositories

## Coding Preferences

## Workflow Rules
```

DeepSeek Harness 会感知保存后的指令文件。新会话会加载最新内容，运行中的 instruction provider 也可以向活跃会话报告后续文件变化。

不要在 `AGENTS.md` 中保存密码、API Key、访问令牌或其他敏感信息。该文档会作为模型可见的上下文。

## 卸载

```bash
dsh plugin --profile web remove dsh-plugin-agents-memory
```

随后重启 `dsh web`。卸载插件不会删除 `$DSH_HOME/AGENTS.md`。

## 安全模型

浏览器接口具备以下限制：

- 只接受回环地址客户端；
- 要求插件专用请求头；
- 只支持 `GET` 和 `PUT`；
- 不提供路径参数；
- Host 始终将目标解析为 `$DSH_HOME/AGENTS.md`；
- 使用 revision 检查和原子写入；
- 拒绝超过 256 KiB 的文档。

这是面向本地开发环境的便利工具，不是网络文档服务。不要将 DSH Web 服务暴露给不受信任的网络。

## 开发

```bash
npm test
npm run check
```

## 许可证

[MIT](LICENSE)
