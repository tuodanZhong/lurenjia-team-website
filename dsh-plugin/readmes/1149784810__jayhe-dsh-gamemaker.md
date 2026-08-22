# jayhe-dsh-gamemaker

为 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) 打造的游戏开发角色子代理：三个专用子代理提供者 + 两个随包附带的 Agent 预设。

[English](./README.md)

## 提供什么

| 工具 / 提供者 | 角色 | 模式 |
| --- | --- | --- |
| `game-planner-provider`（工具 `game_planner`） | 规划者 | 子代理被**真正挂载**到极简系列预设：固定完整 persona、无运行时上下文、只有两个工具——持久 shell + `str_replace_editor`（Windows 下 bash 自动换成 pwsh） |
| `game-executor-provider`（工具 `game_executor`） | 执行者 | 硬 PTC（Code Mode）：子代理在自身作用域声明 `presentAs('code')`，模型只见 `run_code` + 生成的 SDK |
| `game-reviewer-provider`（工具 `game_reviewer`） | 审查者 | 与规划者相同：真实极简预设，只读使用 |

随包预设：

- `game-dev`（游戏开发工坊）——主控：开工前强制问询（技术路线 WEB/UE/Unity/Godot、游戏类型等全部细节）、五阶段流水线、每次模式切换的显式【模式切换】宣告。
- `game-minimal`（兼容极简模式）——与官方 `minimal` 预设完全一致，外加一个特例：Windows 下持久 bash 替换为部署自带的 `pwsh` 工具。

## 工作原理

规划者/审查者子代理在创建窗口内通过 `ctx.agentPresets.mount(childCtx, 'game-minimal')` 把子代理作用域重挂到该预设的常驻挂载上，因此拿到的是**真实极简组合**（固定 persona、抑制运行时上下文、仅两个工具），而不是 persona + toolFilter 的近似。执行者子代理加入父预设后在自己的作用域声明 `presentAs('code')`——硬 PTC：直接原生调用会被拒绝，一切操作只能走 `run_code` 程序。

由于双工具极简子代理无法自己调用委派工具，规划者负责产出调度清单（`docs/plan.md`：模块列表 + 文件边界 + 对外接口 + 验收标准），主控按清单并行分派执行者，用 `job_output(wait: true)` 阻塞等待或依赖系统任务完成通知（禁止 goal 轮询），随后把合并交回规划者、审查交给审查者。

## 环境要求

- 具备 `subagents`、`agentPresets`、`codeRuntime` 主机服务的 dsh 部署（标准 web profile 三者齐全）。
- Node >= 18（ESM），安装脚本需要 bash。

## 安装

```bash
# 1. 把插件包加入 web 配置档案（开发期可用 link: 软链）
export PATH=/usr/local/nodejs22/bin:$PATH        # pnpm 可能不在默认 PATH
dsh plugin --profile web add jayhe-dsh-gamemaker
# 开发期：  dsh plugin --profile web add link:/绝对路径/jayhe-dsh-gamemaker

# 2. 从本机 dsh 安装链接内部接缝包
bash node_modules/jayhe-dsh-gamemaker/install/link-dsh-deps.sh

# 3. 把随包预设安装进用户预设目录
bash node_modules/jayhe-dsh-gamemaker/install/install-presets.sh

# 4. 在 ~/.dsh/profiles/web/cordis.patch.yml 加入主机行
#    参见 install/cordis.patch.example.yml

# 5. systemd 重启 dsh 并刷新页面
systemctl restart dsh
```

然后新建会话选择「**游戏开发工坊**」预设即可。

## 依赖说明

插件消费 `@deepseek-ai/dsh-subagent`、`@deepseek-ai/dsh-llm`、`@deepseek-ai/dsh-session`。这些包随 dsh 部署自带、不走 npm 锁定：公共 registry 上只有更旧的 rc 版本且 API 面不同。`install/link-dsh-deps.sh` 会自动探测 dsh CLI 路径并链接部署自带副本（可用 `DSH_ROOT` 覆盖），保证与运行中的 harness API 完全一致。

## 配置

提供者插件接受一个可选字段：

```yaml
- id: game-roles
  name: 'jayhe-dsh-gamemaker'
  config:
    minimalPreset: game-minimal   # 规划者/审查者子代理所挂载的预设 id
```

## License

MIT
