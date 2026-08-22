<div align="center">

# 🛡️ dsh-plugins

**为 [dsh(DeepSeek Harness)](https://deepseek-harness.github.io/deepseek-harness/) 打造的社区插件集合**

一个个独立的 npm 包,给 dsh profile 扩展登录墙、指标采集、日志、自定义命令,以及 cordis
插件系统能挂载的一切能力。

[`dsh-auth-plugin`](#-插件列表) · [贡献你的插件](CONTRIBUTING.md) · [向上游 dsh 提 PR](#-贡献到上游-dsh)

![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)
![dsh-plugin topic](https://img.shields.io/badge/topic-dsh--plugin-orange)
![npm scope](https://img.shields.io/badge/npm-%40dsh--plugins-red)

[English](README.md) · **简体中文**

</div>

---

## 👋 你好

dsh 是开源的,核心理念就一句话:**一切皆插件**。核心只交付运行时——命令、web
路由、工具网关、登录墙全是
[cordis bundle](https://deepseek-harness.github.io/deepseek-harness/develop/basic/publish),
按需 `add` 到 profile 即可。

`dsh-plugins` 是社区维护的 bundle 集合。每个插件都是独立 npm 包,放在
`plugins/<名称>/` 下,按 profile 安装:

```sh
pnpm dsh plugin --profile my-profile add ./plugins/<名称>
pnpm dsh --profile my-profile
```

不用 fork dsh,不用改 core 代码。**add 完就走。**

## 📦 插件列表

| 包名 | 版本 | 状态 | 提供的能力 |
|---|---|---|---|
| [`dsh-auth-plugin`](plugins/auth) | 0.1.0 | 🟡 POC | Web GUI 登录遮罩 + `/login` `/logout` `/whoami` 命令 + `tools/pre-execute` 权限拦截 |

具体安装步骤、配置项、已知限制见各插件目录下的 `README.md`。

## 🚀 快速上手(使用者)

```sh
# 1. 装好 dsh,有一个 profile(没有就 dsh 自动 init)
pnpm dsh --profile demo --help

# 2. 把仓库里的插件挂进去
pnpm dsh plugin --profile demo add ./plugins/auth

# 3. 启动 dsh,插件就生效了
pnpm dsh --profile demo
```

卸载:

```sh
pnpm dsh plugin --profile demo remove dsh-auth-plugin
```

## 🧩 加一个插件(贡献者)

Fork 仓库 → 在 `plugins/<你的插件>/` 里写 bundle → 开 PR。完整流程见
[CONTRIBUTING.md](CONTRIBUTING.md),最短路径:

```sh
mkdir plugins/<你的插件>
# 复制 plugins/auth/{package.json,cordis.patch.yml,index.js,README.md} 作为模板
# 改 name / id / config,写你的 apply(ctx, config)
```

每个插件独立——不共享状态、不共享中心配置、不依赖中心构建流水线,改一个不影响其他。

## 📁 目录结构

```
dsh-plugins/
├── plugins/                  # 一个子目录一个插件(各自独立 npm 包)
│   └── auth/                 # dsh-auth-plugin
│       ├── cordis.patch.yml  # bundle manifest(id: auth,name: dsh-auth-plugin)
│       ├── index.js          # cordis apply() — host/web 端
│       ├── package.json
│       └── README.md
├── AGENTS.md                 # 工程约定(给 AI 看的)
├── CONTRIBUTING.md           # 怎么往这里加新插件
├── CODE_OF_CONDUCT.md
├── LICENSE                   # MIT
├── SECURITY.md               # 安全问题怎么报
├── SUPPORT.md                # 哪里问问题、提 bug
├── pnpm-workspace.yaml
├── package.json              # 仓根:共享脚本(build/lint/test)
├── tsconfig.base.json        # 共享 TS 配置(给以后用 TS 的插件)
├── .oxlintrc.json            # 共享 lint 规则
└── .editorconfig
```

每个 `plugins/<name>/` 都是一个独立的 npm 包,名字格式 `dsh-<能力名>-plugin`。要加插件就
新建一个同级目录,其他东西一概不动。

## 安装一个插件

在 harness 仓库下(`pnpm dsh` 已经能用):

```sh
pnpm dsh plugin --profile <name> add ./plugins/<plugin>
pnpm dsh --profile <name>
```

`pnpm dsh plugin remove <plugin>` 撤销安装。

## 🛠 本地开发

每个插件都依赖 dsh 包(`@deepseek-ai/dsh-commands` 等),按版本范围声明。
第一次 clone 后装一次:

```sh
pnpm install
```

### SSH / GitHub 认证

本仓默认假设你能用 SSH 推到 `git@github.com`。Windows + WSL 双系统下,SSH
密钥通常放在 WSL(`~/.ssh/id_ed25519_*`),Windows 上的 OpenSSH 没有 key——
直接 `git push` 会 `Permission denied (publickey)`。一次性同步:

```sh
# 在 WSL bash 里
mkdir -p /home/dfy/.ssh-staging
cp ~/.ssh/id_ed25519_* ~/.ssh/known_hosts ~/.ssh/config /home/dfy/.ssh-staging/
cp /home/dfy/.ssh-staging/* /mnt/c/Users/11404/.ssh/
rm -rf /home/dfy/.ssh-staging
```

(`id_ed25519_*` 替换成你实际有的 key 名;`config` + `known_hosts` 这一步可选,
但能避免首次跑时重复确认 host。)在 PowerShell 里验证:

```sh
ssh -T git@github.com
# 期望:Hi <user>! You've successfully authenticated, but GitHub does not provide shell access.
```

### 编辑工作流

- **Windows 改 + WSL 跑 git**:正常编辑器打开文件,git 操作走 `wsl -e bash`,
  那里 SSH agent 已经把 key 加载好了。
- **纯 WSL**:直接 `/home/dfy/workspace/dsh-plugins/` 编辑,Windows 通过
  `\\wsl$\Ubuntu\home\dfy\workspace\dsh-plugins` 看同一份文件。

### dsh 本体的源码 checkout

`auth` 插件需要从兄弟目录 `deepseek-harness/` 的 `apps/web/dist/index.html`
读 SPA dist。如果你的 layout 不一样,设 `DSH_DIST_PATH` 或者改插件里的
dist 解析逻辑。

## ⬆ 贡献到上游 dsh

dsh 本体目前**还不接受外部 PR**——见
[deepseek-ai/deepseek-harness/CONTRIBUTING.md](https://github.com/deepseek-ai/deepseek-harness/blob/master/CONTRIBUTING.md)。
等它开放时:

1. 套用 dsh 的目录约定:`packages/<group>/<name>/`(我们用 `plugins/<name>/`),加
   `tsconfig.json` 和 `tsdown` 构建流水线,导出 host(`./`)和 client(`./client.js`)两个入口。
2. 给 GitHub 仓库打 `dsh-plugin` topic,让生态目录能 pick up。
3. 往 `deepseek-ai/deepseek-harness` 开 PR。

本仓的目录结构就是为了这一刻设计的——一个插件的文件能 1:1 映射到未来
`packages/<group>/<name>/` 子树。搬到上游就是 copy-paste + 配置改名,不用重写。

## 🚢 发布

每个插件独立发布到 npm。bump 版本后:

```sh
pnpm -F dsh-<能力名>-plugin publish
```

要协调多插件 release(3+ 插件时):上 [changesets](https://github.com/changesets/changesets)
或 [release-please](https://github.com/googleapis/release-pending)——两个都跟
pnpm workspaces 开箱即用。

## 🏷 命名约定

插件作为**无作用域** npm 包发布,名字格式 `dsh-<能力名>-plugin`:

| 字段 | 规则 | 例子 |
|---|---|---|
| 目录 | `plugins/<短名>/` | `plugins/auth/` |
| npm 包名 | `dsh-<能力名>-plugin` | `dsh-auth-plugin` |
| patch `id` | 小写能力短名(不带 `dsh-` 前缀) | `auth` |
| patch `name` | 与 npm 包名完全一致 | `dsh-auth-plugin` |

`dsh-<能力名>-plugin` 模式让以后的插件(`dsh-metrics-plugin`、`dsh-tools-plugin`、……)命名一致,
同时绕开 npm 上已经撞过的 `dsh-auth`(那个被一个
[无关的 nginx-fronted auth bundle](https://www.npmjs.com/package/dsh-auth)占了)。
`-plugin` 后缀跟仓库的 `dsh-plugin` 名字呼应——仓库是「plugin 集合」,每个成员是 `dsh-...-plugin`。

## 💬 社区

- 🐛 **插件 bug**:先翻该插件 `plugins/<name>/README.md` 的「Known limitations」
  看是不是已知问题;确认是 bug 就 [Issues](../../issues)。
- 💡 **插件想法 / 讨论**:[GitHub Discussions](../../discussions)。
- 🔒 **安全问题**:见 [SECURITY.md](SECURITY.md)。
- 📜 **社区准则**:[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)。

## 📄 许可证

[MIT](LICENSE),每个插件沿用,除非另有说明。

---

<sub>用 🛡️ 由 dsh 社区维护。欢迎贡献插件——见
[CONTRIBUTING.md](CONTRIBUTING.md)。</sub>