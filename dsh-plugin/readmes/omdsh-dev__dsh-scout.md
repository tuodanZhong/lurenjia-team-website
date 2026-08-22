# dsh-tool-scout

[English](README.md) | **中文**

面向 **DeepSeek Harness** 的模型侧环境探测工具：按需向 agent 提供当前运行环境（平台、shell、用户、时区……）、PATH 上可解析的命令、已安装软件及其版本、以及 CPU/内存/磁盘资源 —— 无需猜测，也不用浪费工具调用去跑慢速的发现命令。

## 安装

本包是一个 dsh **bundle**：自带补丁层（`cordis.patch.yml`），安装后自动加入 profile 的图层栈。

```sh
# 从公开版 Harness 源码检出执行：
cd /path/to/deepseek-harness
pnpm dsh plugin --profile web add /path/to/dsh-scout
```

然后重启 `dsh` 进程。profile 的 `dsh.profile.bundles` 会加入 `@deepseek-ai/dsh-tool-scout`，`environment_probe` 工具进入目录。

## 工具

### `environment_probe`

| 参数 | 类型 | 说明 |
|---|---|---|
| `scope` | string、枚举数组或 `all` | 单个类别、**类别数组**（按请求顺序每个类别返回一个结果对象）、或 `all`（全部）。类别：`environment`（默认）—— 平台/内核/架构/主机名/用户/家目录/cwd/Node 版本/shell/时区/locale/endianness/pid/dsh home；`commands` —— 哪些命令名在 PATH 上可解析（仅 stat，不启子进程）；`software` —— 已安装工具的 `--version` 探测（短超时子进程、短时缓存）；`resources` —— 会话工作区所在磁盘的 CPU 核数/负载、内存总量、磁盘用量、电池状态与设备信息（型号/厂商/CPU）；`apps` —— macOS 应用 bundle；`serial` —— 串口（`/dev/cu.*`、`ttyUSB*`、`COM`）；`usb` —— USB 设备；`network` —— 本机 IP 与接口（纯 Node）；`gpu` —— GPU 名称与显存；`ports` —— TCP 监听套接字（地址/端口/可见的所属进程）；`services` —— 系统服务状态（running/stopped/failed…）；`workspace` —— 当前目录的项目工具链信号（包管理器/版本钉/构建标记，纯文件读取、零子进程）；`printers` —— 打印机与默认目标。 |
| `names` | string[] | 限定只探测这些命令/软件/应用/打印机名（替换配置的默认列表；对 `apps`/`printers` 是按显示名或 Bundle ID 的大小写不敏感精确匹配）。`environment`/`resources`/`serial`/`usb`/`network`/`gpu`/`ports`/`services`/`workspace` 忽略。 |

`apps`（仅 macOS；其他平台报告不可用）列出配置的应用目录里的 app bundle：显示名、版本、Bundle ID 来自每个 bundle 的 `Contents/Info.plist`，纯 Node 解析（二进制 bplist00 与 XML）—— 无 shell、无 Spotlight 依赖。

`battery` 与 `device` 挂在 `resources` 内。电池：macOS 用 `pmset -g batt`、Linux 读 sysfs（`/sys/class/power_supply`）、Windows 经 PowerShell CIM 查询；给出百分比、状态（charging/discharging/charged/ac/unknown）与平台可报的预估剩余时长。设备：macOS 用 `sysctl hw.model`、Linux 读 DMI sysfs 加 `/proc/cpuinfo`、Windows 经 CIM 查询；给出型号、厂商与 CPU 品牌 —— 刻意不含序列号。无电池的机器（台式机、虚拟机）如实返回 `battery.available: false`，绝非报错。

硬件类别面向嵌入式/机器人调试：`serial` 列串口（macOS `cu.*`/`tty.*`，Linux `ttyUSB`/`ttyACM`/`ttyAMA`/`ttyTHS`/`ttyS`，Windows COM）；`usb` 列 USB 设备（macOS `system_profiler SPUSBDataType`，profiler 空树时回退 `ioreg`；Linux `lsusb`；Windows PnP）；`network` 是纯 `os.networkInterfaces()`（零子进程）；`gpu` 覆盖 `system_profiler`/`nvidia-smi`+`lspci`/CIM。慢后端（`system_profiler`、`lsusb`、CIM）结果按 `softwareCacheTtlMs` 缓存。调试小车一条调用搞定：`{ scope: ['serial', 'usb', 'network'] }`。

每个 scope 都只读：模型输入永远不会进 shell；只读白名单环境变量（绝不暴露完整 `process.env`）；版本探测用 `execFile(name, ['--version'])`，带每次超时、并发上限与进程内 TTL 缓存。

canonical 结果是按 `scope` 判别的 JSON 对象（原始数字，非格式化字符串），Code Mode 消费者可以直接用字段；渲染文本保持人类可读：

```
[environment]
platform: darwin (Darwin 24.5.0)
arch: arm64
hostname: dev-machine.local
user: developer
home: /Users/developer
cwd: /Users/developer/Projects/dsh-scout
node: v24.19.0
shell: /bin/zsh
timezone: Asia/Shanghai
locale: zh-CN
endianness: LE
pid: 1234
dsh home: /Users/developer/.dsh
```

## 配置

| 字段 | 默认 | 说明 |
|---|---|---|
| `commandCandidates` | `ls cat grep sed awk find xargs tar unzip curl wget git ssh rsync make gcc python3 node docker` | `commands` scope 未给 `names` 时检查的命令名。 |
| `softwareList` | `git node npm pnpm yarn bun python3 pip3 go rustc cargo java gcc clang make cmake docker kubectl curl wget jq rg fd gh sqlite3 ros2 arduino-cli platformio esptool.py openocd avrdude` | `software` scope 未给 `names` 时探测的软件名（含嵌入式/机器人工具链）。 |
| `softwareProbeTimeoutMs` | `3000` | 每次 `--version` 子进程超时。 |
| `softwareCacheTtlMs` | `60000` | 软件事实的保鲜时长；`0` 关闭缓存。 |
| `maxNames` | `50` | 单次调用 `names` 上限（防止模型失控扇出无界探测）。 |
| `appDirs` | `/Applications`、`~/Applications` | `apps` 探测扫描的目录（`~` 展开为家目录）。 |
| `maxApps` | `300` | 单次 `apps` 探测枚举的 app bundle 上限；`0` 表示不按条目数截断。 |
| `maxPorts` | `128` | 单次 `ports` 探测报告的监听套接字上限；`0` 表示不按条目数截断。 |
| `maxServices` | `200` | 单次 `services` 探测报告的服务上限；`0` 表示不按条目数截断。 |
| `workspaceMarkers` | 见 `docs/design.md` 第 3 节 | `workspace` 探测匹配的标记文件名清单。 |
| `workspaceVersionFiles` | `.nvmrc .node-version .tool-versions .python-version .ruby-version .go-version .terraform-version` | `workspace` 读取内容的版本钉文件清单。 |

补丁行示例（写在 profile 的 `cordis.patch.yml`，按 id 覆盖 bundle 行）：

```yaml
- id: tool-scout
  name: '@deepseek-ai/dsh-tool-scout'
  config:
    softwareProbeTimeoutMs: 2000
    softwareCacheTtlMs: 0
    maxNames: 30
```

### 为什么设置页没有 scout 卡片

Web GUI 的"插件配置"区只渲染自带浏览器端卡片的插件（`settings.plugin.item` 槽位；目前只有内置的 `bash`/`agent-loop`/`web-search` 三张）。本包刻意保持纯 Host 侧 out-of-tree 插件：不会出现在该区，配置走上面的 profile 补丁层——安装、配置、升级都不需要改动主仓库。

## 提示词段落

插件贡献 `tool:scout` 提示词段落（order 107）：

> Probe the runtime environment with `environment_probe` before assuming a platform, shell, command availability, software versions, resource limits, listening ports, service state, project toolchain, or printers; request only the `scope` you need.

## 设计说明

- **不依赖执行缝**。工具直接读 Node API、跑无 shell 的 `execFile` 探测；不要求 bash 执行器或文件系统提供者，最小组合也能工作。
- **纯 Node 解析 plist**。应用元数据来自自包含的 bplist00 解析器（外加 XML plist 回退），无原生或第三方依赖。标记表遵循 CoreFoundation 真实编码（0x5 ASCII / 0x6 UTF-16 / 0x4 data）—— 网上流传的 "0x6/0x7" 表与真实 `Info.plist` 不符。
- **不泄露秘密**。`environment` 只读白名单环境变量；完整 `process.env` 永不暴露。
- **工作量可控**。名字可含展示名称常见的空格与标点，但空白、路径穿越、路径分隔符、NUL、前导选项和超长值会被拒绝；名字会去重、限数。子进程贯穿取消信号、有固定超时，取消结果不会写入 TTL 缓存。app、端口和服务上限可设为 `0`，获取当前权限范围内的完整快照。
- **仓库文件限长读取**。`workspace` 只接受配置的 basename，拒绝穿越路径；生产 reader 不读取最终符号链接，并通过限长文件句柄读取 `package.json` 和版本钉后再解析。
- **失败也是事实**。可执行文件缺失是 `found: false`；探测超时或工具静默是 `found: true` 且无版本；statfs 失败是 `disk.ok: false` 带错误信息。只有基础设施失败（校验、取消）才产生工具错误。
- **Invariant companion 按需启用**。包仍导出 `@deepseek-ai/dsh-tool-scout/invariant` 供诊断 profile 使用，但通用 bundle 不会自动激活，因为标准 profile 不提供可选的 `invariants` 服务。

## Scope 设计

已实现的 `ports`（监听端口）、`services`（服务状态）、`workspace`（项目工具链信号）、`printers`（打印机）详细设计见 [docs/design.md](docs/design.md)：数据源与平台回退链、canonical schema、渲染示例、安全边界、失败模式、Token 成本、测试策略与决策记录。

## 技能（skill）

`skills/env-probe/` 提供 `env-probe` 技能：按任务类型选择需要的 `environment_probe` scope（决策表）、一次数组调用拿全、以及结果解读约定（`available: false` 语义、逐 scope 字段与平台怪癖见 `references/reading-results.md`）。按 Anthropic skill-creator 方法论编写：frontmatter 承载触发条件、正文用祈使句、示例用真实调用与输出、细节放引用文件按需加载。`.agents/skills/env-probe` 是指向 `skills/env-probe/` 的符号链接，开发环境与 bundle 共用单一事实源。

**随 bundle 自动分发**：本包的 `cordis.patch.yml` 额外插入 `skill-filesystem-scout` 行——一个只挂载本包 `skills/` 目录的 host 层 filesystem provider（`includeDefaultRoots: false`，不碰项目/用户根；`providerName: 'scout'` 避免与 preset 实例重名）。`bundledSkillDir` 用 `!!js` 表达式在启动时从 `baseUrl`（Loader 锚定的 profile 目录）+ profile 的 `node_modules` link 推导。因此**任何安装了 scout 的 profile，其所有 agent 会话的 skill 目录自动包含 `env-probe`**（端到端由 `tests/loader-skills.spec.ts` 验证：真实 Loader 组合 + 真实 patch 文件 + 真实 bundle link）。重启 dsh 进程后生效。

## 开发

```sh
pnpm install                    # 安装可独立构建所需依赖
pnpm run link:harness           # 可选手动刷新；测试脚本会自动执行
pnpm run build                  # 生成声明并打包 ESM 运行时
pnpm run test                # vitest：单元 + 注册表管线 + Loader 真实组合
pnpm run test:coverage       # 同一套测试并执行逐文件覆盖率门槛
pnpm run typecheck           # 源码与测试对照当前 DSH API
pnpm run verify:self-contained  # manifest 与包边界检查
node scripts/verify-profile.mjs  # 生产形态校验：web profile 的 bundle 层，从 profile 目录启动（需已安装 dsh）
```

公开版 DeepSeek Harness 检出默认位于 `../deepseek-harness`；如果位于其他位置，请设置 `DSH_REPO_ROOT`。测试脚本会自动刷新 Harness 链接。改动 `src/` 后运行 `pnpm run build` —— profile 安装使用 `link:` 语义，dsh 下次启动即用新 `lib/`。

## Model Experience

### 系统提示词

#### 模型看到什么

该插件注册范围内的每个请求都包含上面逐字引用的 `tool:scout` 指导。

#### Token 影响

插件激活期间每个请求的固定小额输入成本，与 scope 选择无关。

#### KV Cache 影响

注册范围与提示词文本不变时前缀稳定；插件激活/卸载可能使该段落的复用失效。

### 工具 schema

#### 模型看到什么

生成的 `environment_probe` schema：`scope` 枚举、可选 `names` 数组、按 scope 判别的输出联合。插件加载期间工具始终可见。

#### Token 影响

工具可见的每个请求都有固定 schema 成本。

#### KV Cache 影响

工具定义不变时前缀稳定；改变广告参数的配置变更可能使复用失效。

### 工具输出

#### 模型看到什么

渲染器按请求顺序输出各 scope 区块。app、端口和服务汇总同时报告返回数量与可见总数；有上限时明确写出 `truncated`，不会让部分结果看起来像完整结果。服务仍按问题优先排序（failed → activating → running → stopped），canonical JSON 同步提供 `total` 与 `truncated`。

#### Token 影响

调用前零结果 token。输出随数据变化；版本行与 `names` 有界，而 `maxApps: 0`、`maxPorts: 0`、`maxServices: 0` 会刻意允许完整可见快照，因此输出可能很大。

#### KV Cache 影响

追加式；新内容跟在可复用前缀之后，不使既有 KV 缓存失效。

### 工具错误

#### 模型看到什么

校验与策略失败归一为 `Error: <message>`。本包稳定文案：`invalid probe name: <name>`、`too many probe names: expected at most <N>, got <M>`、`tool call aborted`。

#### Token 影响

只有失败的调用增加这些保留 token。

#### KV Cache 影响

追加式；新内容跟在可复用前缀之后，不使既有 KV 缓存失效。

## 已知限制与待办

- **电池/设备探测按平台实现且可注入** —— 各平台解析器是纯函数并有单测，但子进程后端（macOS 的 pmset/sysctl、Windows 的 PowerShell CIM）运行在任何已挂载沙箱执行器之外，与 `--version` 探测同样的只读、短超时纪律；Linux 只读 sysfs。Windows 上报依赖已安装 PowerShell 且 CIM 可用。
- **硬件探测按平台实现且存在真实主机怪癖** —— macOS 的 `system_profiler SPUSBDataType` 在部分主机/系统版本上报空树；探测回退 `ioreg`（仅名字，无 vendor/product id）。`lsusb`/`nvidia-smi`/`lspci`/CIM 的可用性决定 Linux/Windows 覆盖面；后端缺失是事实（`available: false`），绝非报错。
- **应用枚举仅限 macOS** —— `apps` scope 在其他平台报告 `available: false` 并附原因；没有 Windows 注册表或 Linux 桌面枚举。默认不扫 Apple 的 `/System/Applications`（系统应用是配置噪音）；需要可加入 `appDirs`。
- **plist 解析器只覆盖应用需要的 bplist00 子集** —— 日期、UID、128 位整数、float 宽度 real 解析为 `null`（绝非失败），对探测读取的三个键无影响；plist 无法解析的 bundle 计入 `skipped`。
- **版本探测绕过沙箱** —— `--version` 探测以无 shell 的 `execFile` 子进程运行，使用 harness 进程自身权限，在任何已挂载的沙箱执行器之外。它们是只读、短超时、名字白名单的，但部署若连 `--version` 执行也要约束，需要在包外加策略缝（例如 `tools/pre-execute` 规则）。
- **shell 内建与别名不可见** —— `commands` scope 只报 PATH 可解析的可执行文件；内建、函数、别名从不检测。
- **`--version` 假设常规 CLI** —— 需要不同标志、启动慢、或对 stdout/stderr 无输出的工具报 `found` 但无版本；每次超时兜底。
- **PATHEXT 仅 Windows 生效（设计如此）** —— POSIX 上命令解析只查裸名字；后缀机制只在 win32 部署被调用。
- **软件事实有 TTL 缓存** —— `softwareCacheTtlMs` 窗口内的 `software` 探测可能报告已过期的版本；追求新鲜度时设 `softwareCacheTtlMs: 0`。
- **进程可见性受权限限制（ports/services，设计如此）** —— 无特权时 lsof/ss/launchctl 只报当前用户可见的进程与服务；地址/端口是内核级可见的（含 Linux `/proc/net/tcp` 回退），进程名与 pid 只对自有进程出现。
- **macOS `launchctl list` 可能不可达** —— 在 dsh agent 等非 GUI bootstrap 域上下文里 `launchctl list` 退出码 1 且零输出，此时 `services` 如实报 `available: false (launchctl list failed with exit 1)`；`launchctl print gui/<uid>` 作为备选尚未实现。
- **`workspace` 只探测 cwd 白名单信号** —— 不递归、不执行任何子进程（敌意仓库安全）；`.env` 只报存在性，内容永不读取。未匹配的标记不在结果里，`markers: (none)` 是事实。
- **`printers` 的 lpstat 非零退出按事实处理** —— `lpstat` 在"无目的地"时报 exit 1 并输出到 stderr（含中文「未添加目的位置」）；探测用宽容 runner 保留输出，得到 `printers: (none found)` 而非错误。Windows 上报依赖 PowerShell 与 CIM。
