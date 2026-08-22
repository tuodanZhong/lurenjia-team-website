# dshp

**把一整套 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) 配置变成一个文件分享出去。**

[English](README.md) | 中文

```sh
npx dshp ls
```

---

## 为什么做这个

dsh 能启动 profile、能把安装转发给 pnpm，但它**建不了空 profile、列不出你有哪些、克隆不了一套能跑的配置、也没法把配置交给别人**——今天这些全是在 `~/.dsh/profiles` 底下手工操作。

而这恰恰要紧：「一切皆插件」意味着你的配置**本身就是一叠层**，值得分享的单位是整叠，不是一个个插件。

## 分享一套配置

```sh
dshp export web -o my-setup.dshp
```

```yaml
# dsh profile — reproduce with: dshp import <this-file>
dshp: 1
name: web
bundles:
  - @deepseek-ai/dsh-base
  - @deepseek-ai/dsh-web-app
  - dsh-cloudflare-browser-run
plugins:
  dsh-cloudflare-browser-run: "^0.1.1"
patch: |
  - id: session-title
    config:
      fallbackMaxWords: 12
```

短到可以直接贴进帖子里。对方那边：

```sh
dshp import my-setup.dshp
```

它会写好 profile、用 dsh 自己的 pnpm 装插件，然后 `dsh --profile web` 就能起。这条链路是端到端验证过的：在一个全新的 `$DSH_HOME` 里复现出 132 个条目、与原版完全一致的启动树，patch 也精确还原。

## 放心折腾

```sh
dshp clone web web-试验田      # 秒完成，node_modules 一起带走
dsh plugin --profile web-试验田 add some-experimental-plugin
dshp diff web web-试验田
```

```
web -> web-试验田

plugins
  + some-experimental-plugin@^0.2.0
```

搞砸了就 `dshp rm web-试验田 --yes`，你原来能跑的那套一根汗毛都没动。

## 命令

| | |
|---|---|
| `dshp ls` | 列出 profile，带 bundle/插件数量和占用空间 |
| `dshp show <name>` | 加载顺序、插件、patch |
| `dshp new <name> [--web\|--headless]` | 建 profile —— dsh 自己建不了空的 |
| `dshp clone <from> <to>` | 连 `node_modules` 一起复制 |
| `dshp export <name> [-o FILE]` | 导出可移植文件（默认输出到 stdout） |
| `dshp import <file> [--as NAME] [--no-install]` | 复现一套 profile |
| `dshp diff <a> <b>` | 差在哪 |
| `dshp rm <name> --yes` | 删除 |

## profile 到底是什么

`$DSH_HOME/profiles/<name>` 下面：

- `package.json` —— `dependencies` 是插件，`dsh.profile.bundles` 是有序的层栈
- `cordis.patch.yml` —— 你自己的 id 定向覆盖
- `cordis.yml`、`pnpm-workspace.yaml` —— 样板，可重新生成

所以复现一套配置只需要三样东西：插件版本、bundle 顺序、patch。可移植文件装的正是这三样。

bundle 的**顺序**是格式的一部分：它决定谁 patch 谁，所以只是调换顺序也会被 `diff` 当成真实差异报出来。

patch 块是逐字节原样搬运、不重新序列化的，因为里面可能有 `!!js` 表达式（`root: !!js dshHomePath('sessions')`），YAML 往返会把它弄坏或执行掉。本工具任何时候都不会执行你的配置。

## 安装与卸载

当 CLI 用：`npx dshp ls`，不需要安装。

当插件用：

```sh
dsh plugin --profile web add github:asdf17128/dshp   # 安装
dsh plugin --profile web remove dshp                 # 卸载
```

卸载后 `list_profiles` 和 `export_profile` 两个工具消失，你的 profile 分毫未动——
这个插件只读。

## 兼容性

基于 `@deepseek-ai/dsh` **0.1.0-rc.5** 验证。它读的 profile 结构（`package.json` 里的
`dsh.profile.bundles`、`cordis.patch.yml`）是 dsh 自己的格式，那里一旦变动会最先受影响。

## 环境要求

Node 18+。`import` 需要一个可用的 `dsh`（优先本地 `node_modules/.bin/dsh`，否则用 `PATH` 上的），因为它走 dsh 自己的 pnpm 装依赖；其余命令都是纯文件操作。

## 相关

[dsh-doctor](https://github.com/asdf17128/dsh-doctor) —— 检查 profile 里哪些 patch 已经悄悄失效了。

## 许可

MIT
