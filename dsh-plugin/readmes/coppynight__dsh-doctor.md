<h1 align="center">dsh-doctor</h1>

<p align="center">
  <strong>DeepSeek Harness 的 flutter-doctor 风格诊断与修复工具</strong><br/>
  一个官方 repository-plugin（`.dsh-plugin` 格式）＋同名终端 CLI：安装级 + harness 内检查，
  能修的自动修（settings 恢复 / 交互补 key），不能修的输出可直接复制的手动命令。
</p>

<p align="center">
  <img src="https://badgen.net/badge/license/BSD-3-Clause/blue" alt="license" />
  <img src="https://badgen.net/badge/format/official%20plugin/8257D0" alt="official plugin" />
</p>

## 能力地图

| 能力面 | 入口 | 说明 |
|---|---|---|
| `/doctor` 命令 | 在会话输入 `/doctor` | harness 内运行全部检查（含 harness 级），输出 flutter 风格报告 |
| 终端 CLI | `node bin/dsh-doctor.mjs` | web 挂掉时仍可运行；`--fix` 应用安全修复并交互补 key |
| 安装级检查 | 两个入口共用 | privilege / node / git / pnpm / 安装布局 / staging 残留 / PATH / 所有权 / hooks / 凭据 / git 状态 |
| harness 级检查 | 仅 `/doctor` | 挂载插件状态 / repository 插件 / sessions / settings / 凭据链 / web.log |
| 修复 | `--fix` | settings 备份恢复（自动）；凭据交互补写（CLI）；其余输出精确手动命令 |

## 安装

本插件是官方 **repository-plugin**（`.dsh-plugin/` + `package.json#dsh.entry`）。安装 =
在 `$DSH_HOME/cordis.patch.yml`（机器级补丁层，对每个 profile 生效）里加一条
**patch 条目**——按 `id` 命中 dsh-base bundle 内置的空 `repository-plugins` 行，
用你的源列表覆盖它的 `config`：

```yaml
# $DSH_HOME/cordis.patch.yml —— 顶层必须是一个 patch 条目「数组」，
# 写成 `repository-plugins:` 开头的 keyed map 会被 dsh 拒绝加载。

- id: repository-plugins                     # ① 目标行：dsh-base 已内置该 id（空配置）
  name: '@deepseek-ai/dsh-repository-plugin' # ② 行的插件名：与内置行一致，仅声明、不修改
  config:
    repositories:                            # ③ 要安装的 repository 插件源（可列多个）
      - 'github:coppynight/dsh-doctor#c4683a9eba5102681fd399c3e292a34ef7f3616d&path:/.dsh-plugin'
```

**源字符串解剖**（每个字段的意思与改法）：

| 片段 | 含义 | 何时改 |
|---|---|---|
| `github:` | 源类型（只支持 GitHub） | 不 |
| `dsh-external/dsh-doctor` | owner/repo | 不 |
| `#c4683a9e…` | **commit 哈希**——安装按它锁定，缓存按它不可变 | **更新插件时换成新提交哈希** |
| `&path:/.dsh-plugin` | 插件子目录；省略则默认 `/.dsh-plugin` | 本仓库只有一个插件，无需改 |

本仓库是公开镜像（开发主场：`dsh-external/dsh-doctor`）。公开源安装**无需凭据**。
改完配置后重启 dsh（Node half 改动需重启，仅凭据变化则不需要）。

### 案例 1：首次安装（可照抄）

```sh
# 1. 把上面那段 YAML 写进 $DSH_HOME/cordis.patch.yml
# 2. 预填充安装缓存（官方 @deepseek-ai/dsh-repository-plugin 未发布期的过渡步骤，见下文）
node scripts/prepare-cache.mjs
# 3. 重启 dsh（Node half 改动需重启）
# 4. 在会话里输入 /doctor 验证：应输出 flutter 风格报告，plugins 检查显示全部 active
```

### 案例 2：更新插件

```sh
# 1. 克隆仓库并切到新提交（或直接拿 GitHub 上的新哈希）
SHA=$(git -C <clone 路径> rev-parse HEAD)
# 2. 把 cordis.patch.yml 里的 #c4683a9e… 换成 #$SHA
# 3. 重新预填充缓存（ref 变了，缓存键随之变化）
node scripts/prepare-cache.mjs --ref=$SHA
# 4. 重启 dsh
```

### 案例 3：卸载

把该条目从 `$DSH_HOME/cordis.patch.yml` 删掉（或整条注释掉）→ 重启 dsh。
缓存可顺手清掉：`rm -rf $DSH_HOME/cache/repository-plugins`（不清也不影响运行）。

**安装前置（官方私有 rc 库阶段，2026-08-13 实测）**：`@deepseek-ai/dsh-repository-plugin`（`dsh-plugin-prepare` 的提供者）尚未发布到任何可达 registry，而它是 loader 硬校验的 devDep（不能移除），RepositoryCache 的 `pnpm install` 会 404。上面的 `scripts/prepare-cache.mjs` 按 loader 的 cache 契约预填充，让 loader 跳过安装（详见 [decisions/implemented/process/2026-08-13-repository-plugin-prepack-bridge.md](decisions/implemented/process/2026-08-13-repository-plugin-prepack-bridge.md)）。官方发布该包后删除此步骤即可。

## 使用

### `/doctor`（harness 内）

```
/doctor                     # 全部检查，flutter 风格报告
/doctor --check plugins     # 单项检查
/doctor --fix               # 诊断 + 应用安全修复（settings 恢复）
/doctor --json              # 机器可读输出
/doctor -v                  # 每条结论附明细
```

### 终端 CLI（web 挂掉也能用）

```sh
node bin/dsh-doctor.mjs          # 诊断（有 error 时 exit 1）
node bin/dsh-doctor.mjs --fix    # 诊断 + 修复（settings 自动；DEEPSEEK_API_KEY 隐藏输入补写）
node bin/dsh-doctor.mjs --json   # 机器可读
node bin/dsh-doctor.mjs --list   # 检查目录
```

### 修复边界（诚实原则）

| 修复 | 方式 |
|---|---|
| settings.yaml 缺失/为空 | `--fix` 自动备份并写入最小合法文档 |
| DEEPSEEK_API_KEY 缺失 | 终端 `--fix` 隐藏输入补写 `~/.dsh/.env`（chmod 600，绝不回显）；harness 内给指引不代输密钥 |
| PATH / 所有权 / staging / hooks | 不越权代劳——输出可直接复制的手动命令 |

## 检查目录

| id | 说明 | 级别 |
|---|---|---|
| privilege | 不得以 root 运行 | 安装 |
| node | Node 须满足 ^22.19.0 \|\| >=24.0.0 | 安装 |
| git | git 存在且 ≥2.26（worktree hooks） | 安装 |
| pnpm | pnpm 可用 | 安装 |
| install-layout | source 容器 / current 链接 / launcher 解析 | 安装 |
| staging-leftovers | 失败运行不得堆积 staging 工作树 | 安装 |
| path | dsh bin 目录在 PATH | 安装 |
| ownership | dsh home 无 root 属主残留 | 安装 |
| hooks-path | 全局 core.hooksPath 不得被静默替换 | 安装 |
| credentials | DEEPSEEK_API_KEY 已配置 | 安装 |
| repository-git-state | 仓库 git 状态可写 | 安装 |
| plugins | 已挂插件全部 active（failed/pending 点名） | harness |
| repository-plugins | 声明的 repository 源有安装痕迹、形状合法 | harness |
| sessions | 会话存储可写 | harness |
| settings | settings.yaml 存在且非空 | harness |
| credentials-chain | 进程环境 → cwd/.env → $DSH_HOME/.env 某层提供 key（不回显值） | harness |
| web-log | web.log 无近期错误行 | harness |

## 与 out-of-band 医生的关系

本插件运行在 **harness 内**（能看挂载插件、repository 列表、sessions 等内部状态），
终端 CLI 与 web 解耦。它不替代任何 out-of-band 医生（如 web 全挂时的 `dsh-doctor`
自助脚本）：一个在内、一个在外，按场景互补。

## 开发

```sh
node scripts/gates/run.mjs   # 门禁：package-contract / secrets / prepared / unit（58 测试）
```

生成的 `dsh-plugin.mjs` 与 `dsh-plugin-assets/` 是 `dsh-plugin-prepare` 的产物（入库，
勿手改；`prepared` 门禁守护存在性与 manifest 名）。每次非平凡改动随附
`decisions/implemented/` 决策记录。
