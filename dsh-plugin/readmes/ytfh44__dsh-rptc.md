# dsh-rptc — RPTC 模式（可复用 PTC）

RPTC（**R**eusable **P**rogram-**T**ool **C**omposition）是一个 DeepSeek Harness 的 agent preset（模式）。它平时是**标准模式与 PTC 模式的超集**，并且能把 PTC 中一次串联的数个工具**固化为一个可复用工具**。

- **普通模式**：全部原生工具 schema 直接可调用（标准模式的全部能力：shell、文件、检索、Skills、计划、目标、子代理、工作流、压缩……）。
- **PTC 模式**：`run_code` + 生成的 TypeScript SDK，用一段程序把多个工具串联成一次往返。
- **RPTC 特有**：`rptc_define / rptc_update / rptc_undefine / rptc_list / rptc_persist` 五个工具 + `rptc:rules` 系统提示词纪律——把反复出现的链固化为工具，参数化一切变化量，链可引链；**持久化只在用户明确命令后**发生，写进 preset 自己的组装文件。

实现方式：DSH 的 `code`（PTC 模式）preset 拷贝 + `tool-presentation(mode: both)` + 一个零依赖插件（`preset/lib/`）。详见 [DESIGN.md](DESIGN.md)。

## 安装

### 方式一：npm（推荐）

```powershell
# 1. 装进 harness 的 web profile（官方命令，转发 pnpm，从 npm registry 安装）
dsh plugin --profile web add dsh-rptc

# 2. 运行随包安装器：把包内 preset/ 接进 roster（默认混合布局，见下）
npx dsh-rptc install --default   # --default：顺便把新会话默认模式设为 rptc
```

（也可以 `npm install -g dsh-rptc` 全局安装后运行 `dsh-rptc install --default`。）

### 方式二：git 直装（无需 npm 账号）

```powershell
dsh plugin --profile web add git+https://github.com/ytfh44/dsh-rptc.git
npx dsh-rptc install --default
```

`install` 做的事：

- 在 `$DSH_HOME/.agent-presets/rptc` 建立**真目录**：`preset.yml` 与 `agent.cordis.yml` 为同步拷贝（重装时自动保留持久化区块），`lib/` 与 `skills/` 为 junction（Windows）/ 符号链接（POSIX）指向包内——插件代码与 skill 与包实时同步。整目录 junction 不可行：roster 的 `scanRoot` 用 `isDirectory()` 过滤，链接目录会被跳过。
- `--copy`：全部拷贝（升级同样保留持久化区块）。
- `--default`：把 `$DSH_HOME/settings.yaml` 的 `agent-presets.default` 改为 `rptc`（只影响之后新建的会话）。

## 本机开发安装（还没推 git 时）

```powershell
# 方式一：file: 依赖（等价于 git 安装的本地版）
dsh plugin --profile web add file:C:/path/to/dsh-rptc
node node_modules/dsh-rptc/install.mjs install --default

# 方式二：直接运行仓库里的安装器（不装 node_modules，只接线 roster）
node C:/path/to/dsh-rptc/install.mjs install --default
```

## 升级 / 卸载

```powershell
dsh plugin --profile web update dsh-rptc   # 拉新版本
dsh-rptc install                            # 重新接线（lib/skills 本就是实时的；拷贝模式保留持久化区块）

node node_modules/dsh-rptc/install.mjs uninstall --reset-default
dsh plugin --profile web remove dsh-rptc
```

## 测试

```powershell
node test/engine.test.mjs             # 链引擎 + 持久化区块单元测试（无需 harness）
node test/integration.probe.mjs       # 集成探针：真实宿主服务上的完整生命周期（见文件头说明）
```

## 使用

1. 新建会话时选择 **RPTC 模式**（或它已是默认）。
2. 机械多步流程用 `run_code` 串联（PTC 一如既往）。
3. 链第二次出现 → `rptc_define` 固化（链规约：`$params.*` 参数引用、`$n.*` 步骤结果引用、链可引链）。
4. 用户明确命令 → `rptc_persist {acknowledged: true}` 写入 `preset/agent.cordis.yml` 的持久化区块，此后所有新会话自动加载。

详细规矩见 preset 自带的 `solidify-workflows` skill（会话内可用 skill 工具加载）。

## 布局

```
preset/                    # 随包携带的 preset（id: rptc）
  preset.yml               # 模式元信息（RPTC 模式 / order 5）
  agent.cordis.yml         # 组装：code 拷贝 + mode:both + rptc 组 + 持久化区块
  lib/chain.js             # 链引擎：规约编译 + 嵌套分发（零裸依赖）
  lib/rptc.plugin.js       # 核心插件：rptc 服务 + 5 个管理工具 + rptc:rules 提示词段
  lib/rptc-tool.js         # 持久化工具工厂（每个持久化工具一行引用它）
  skills/solidify-workflows/SKILL.md
install.mjs                # 安装器（bin: dsh-rptc）
DESIGN.md                  # 设计决议记录
```

## 设计要点（详见 DESIGN.md）

- **超集**：`mode: both`——原生 schema 与 run_code 并存，无 code-only 限制。
- **固化**：声明式链规约 → `ctx.tools.register`（agent 层），`execute` 用 `ctx.tools.execute` 嵌套分发（parent token），每步走完整流水线。
- **持久化**：`rptc_persist` 幂等快照重写 `agent.cordis.yml` 的 `# ── RPTC persisted ──` 区块，触碰代际 stamp，新会话加载新代际。
- **零裸依赖**：插件文件不 import 任何包（只有 node: 内建与包内相对文件），因此无论 preset 落在 `.agent-presets` 还是 node_modules 都能加载。

## 已知限制

- 声明式步骤是"固定顺序 + 参数/结果引用"的链；需要分支/循环/并发/错误恢复时，用**程序步**（`{program: "<TS body>"}`）——完整的 run_code 程序内嵌为一步，`$params`/`$n` 常量与 `tools.*` SDK 绑定照常可用（见 `solidify-workflows` skill）。
- 程序步要求代码运行时（RPTC 模式自带）；声明式步骤不需要。
- 运行时固化的工具对同一进程内所有 RPTC 会话可见（同代际共享）；持久化使其跨重启。
- 链规约的参数 schema 是模型引导，引擎校验引用而非完整 schema 约束。
- 程序文本中的 `$<n>` 形 token 一律按步骤引用解析（如 "价格 $1.99" 会被当作引用步骤 1）。
