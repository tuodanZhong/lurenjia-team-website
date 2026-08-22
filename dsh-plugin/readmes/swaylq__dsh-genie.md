<h1 align="center">🪔 dsh-genie</h1>

<p align="center"><b>让愿望活过这一次会话。</b></p>

<p align="center">
  <a href="https://github.com/deepseek-ai/deepseek-harness">DeepSeek Harness</a> 本来就会自己写插件，<br>
  只是留不住。这个包补的是后半截。
</p>

<p align="center">
  <a href="README.md">English</a> | 中文
</p>

---

## 缺的那一半

DeepSeek Harness 自带一套自引用工具集 —— `cordis_inspect`、`cordis_define`、`cordis_run` ——
agent 可以现场写一个插件，热挂进正在跑的进程。你说一句想要什么，它当场造出来，当场就能用。

然后你一重启，没了。这是那套工具集官方 README 的原话：

> 动态包只存在于共享 DSH 进程内存中。……它不会创建插件文件、安装任何包、修改 `cordis.yml`
> 或个人／项目配置、**跨重启存续，也不能自动转为正式插件**。若要保留实验结果，应让 agent
> 通过常规开发流程实现普通的本地、项目或仓库插件。

`dsh-genie` 就是把这句「常规开发流程」压成了一次工具调用。

## 完整闭环

```
你   ▸ 以后我每次说「发车」，就把改动全暂存、生成 message 提交

     ▸ agent 写好插件，cordis_run 挂上                    ← DSH 自带
     ▸ 你试了一下，好用
     ▸ 「留着」
     ▸ genie_keep dyn-1 → dsh-wish-ship-it                ← 本包

     ▸ 重启
     ▸ 还在。
```

两个让这件事真正舒服的细节：

- **不用 pnpm、不联网、不需要构建授权。** 实现的愿望直接写进 `$DSH_HOME/genie/`，
  再软链到启动器本来就会查找模块的地方。对比一下从 git 装插件的常规路径：作者得提供
  `prepare` 脚本，你还得给一次 `allowBuilds` 授权 —— 那等于允许该包的代码在安装时于你机器上执行，
  而且不在 agent 的任何沙箱里。
- **它就是一堆文件。** 每个愿望都是一个能读的目录，里面是 `package.json`、`cordis.patch.yml`
  和 `index.js`。你可以读它、改它、`git init` 它、发布它。授予之后 dsh-genie 再也不碰它。

## 安装

```sh
dsh plugin --profile web add github:swaylq/dsh-genie
```

然后重启 `dsh`。就这样 —— 纯 JavaScript，没有构建步骤，所以没有 `prepare` 脚本，
也没有任何东西需要你授权。

已经自己挂了 `@deepseek-ai/dsh-tool-cordis`？见[组合](#组合)。

## 装完多了什么

| | |
|---|---|
| `genie_keep` | 把 agent 刚验证好的动态包变成永久插件。只在动态包 runner 已组合时出现。 |
| `genie_wish` | 同样的事，但直接从 agent 写的代码来，跳过原型步骤。 |
| `genie_list` | 本机所有愿望，以及它在当前 profile 里是否生效。 |
| `genie_revoke` | 撤销一个愿望。默认保留源码。 |
| `/wish` | 给人看的那一面：授予了什么、哪些在生效、代码在哪。 |

这个组合包还会挂上 `@deepseek-ai/dsh-tool-cordis`，也就是 DeepSeek Harness 自带的那套自我改造工具集。
它随每份安装一起发货，但官方 `web` profile 默认不挂 —— 它的 runner 倒是挂着的，
所以打开它一个包都不用装。

## 原理

关于启动器的三个事实，全部来自公开文档，没有用任何私有接口：

1. **profile 解析组合包有两个锚点** —— 先是 dsh 安装目录，然后是 profile 目录。
   Node 从 `<profile>/package.json` 开始的父级查找会走到 `$DSH_HOME/profiles/node_modules`，
   那是启动器维护的扁平回退目录，让内置插件从任意 profile 都能解析到。
2. **那个目录实际上只增不减。** `healProfilesModuleFallback` 会保留正确的链接、
   给搬过家的重新指向，但从不清理不归它管的东西 —— 所以种在那儿的软链能活过每一次启动。
3. **`dsh plugin` 不会回收这个层。** 它的对账逻辑只移除「名字曾经或现在是 profile
   `dependencies` 键」的组合包。dsh-genie 只写 `dsh.profile.bundles`，从不写 `dependencies`，
   所以你之后 `dsh plugin add` 别的东西，愿望不受影响。

于是「实现一个愿望」就是：写包 → 软链进回退目录 → 往 profile 的有序组合包列表尾部追加一个名字。
没有安装器，没有注册表，没有构建。

有一个坑值得单独说，因为每个人都会踩一次：**Node 解析一个包自己的 import 时，
用的是它的真实目录，不是找到它的那条软链。** 放在 `$DSH_HOME/genie/` 的愿望，
父级查找会走 `genie` → `$DSH_HOME` → `~`，永远碰不到回退目录。所以 dsh-genie
在愿望旁边种了一条 `$DSH_HOME/genie/node_modules` → `$DSH_HOME/profiles/node_modules`，
把所有内置包重新放回查找路径上。同样的道理，dsh-genie 自己**不声明任何运行时依赖** ——
它通过 *profile* 去加载 `@deepseek-ai/dsh-tools`，和启动器解析自家组合包的方式一样，
所以无论你是 `link:` 本地检出、git 安装、npm 安装，还是手动丢一个目录进去，它都能跑。

## 信任立场

这一节请在安装前读，不要装完再读。

**一个被实现的愿望，就是每次启动都会执行的普通代码，拿着 harness 的完整上下文。**
这既是本包的意义，也是它的全部风险。dsh-genie 并没有给 agent 增加它原本没有的能力 ——
一个有 bash 权限的 agent 本来就能写出这些文件 —— 但它确实把这件事从「一串看得见的操作」
压成了「一次工具调用」，而这种便利恰恰值得说清楚。

设计上做了这些事：

- **写它的那次会话里，什么都不会跑起来。** 一次授予只是写文件加改一份 manifest。
  代码要到下次重启才加载，而重启只有你能做。那次重启就是检查点，每个工具结果都会这么说。
- **验证不靠执行。** 生成的模块用 `node --check` 做解析检查，只解析不求值。
  解析不过的愿望什么都装不上。
- **一切可列举、可撤销。** `/wish` 和 `genie_list` 会列出每个愿望和它的源码路径；
  `genie_revoke` 负责移除。撤销只接受 `dsh-wish-*` 开头的名字，所以打错一个参数
  也不可能把 `dsh-base` 从列表里删掉。
- **愿望名是一个校验过的路径段。** 没有 scope、没有点号、没有路径穿越。

它**不做**的事：不给愿望加沙箱、不替你审代码、不会再问你第二遍。
如果换成一个 agent 写的脚本你不读就不敢跑，那就在重启之前把愿望读一遍 ——
工具结果把确切路径交给你，就是为了这个。

上游对它所依赖的那套工具集，立场是一样的，值得复述一次：`cordis_run` 背后的 vm 沙箱
「隔离全局变量，但不是安全边界……应当像对待 bash 访问一样对待该工具集」。

## 组合

这个组合包插入两行：`genie-tool-cordis` 和 `genie`。如果你 profile 里已经有别的东西挂了
`@deepseek-ai/dsh-tool-cordis`，两次注册会抢同一批工具名，加载会**大声失败**（这是 DSH 有意为之）。
在你自己 profile 的 `cordis.patch.yml` 里关掉我们这行即可：

```yaml
- id: genie-tool-cordis
  disabled: true
```

`genie` 行上的配置：

| 键 | 默认 | 含义 |
|---|---|---|
| `allowUpdate` | `true` | 是否允许 `mode: "update"` 覆盖已有的愿望 |

## 已知限制

- **保留下来的动态包换了 realm。** `cordis_define` 的代码跑在 vm 沙箱里，那里 Node 全局变量
  要么不存在、要么被重定向到 Cordis 服务。留下来的愿望跑在普通 Node 里，所以针对那些
  façade 写的代码可能需要改。`genie_keep` 会要求模型在代码碰到这些东西时主动说明，
  但它没法替你改代码。
- **层是追加的。** 一个愿望叠在 `dsh-base`、模式组合包和它之前装的每个插件之上。
  patch 是整个 `config` 替换而不是深合并，所以想覆盖已有行的愿望必须把那行需要的每个键都重写一遍。
- **DSH 还是开发者预览。** 上游明说会有破坏性变更。本包依赖的是有文档的启动器行为而不是内部实现，
  但「有文档」和「稳定」现在还不是一回事。
- **浏览器半只存不挂。** `genie_keep` 会把 `client.js` 存在 host 半旁边备查，
  把浏览器半接进 Web UI 目前仍是手工活。

## 开发

```sh
npm test          # 19 个测试，跑在真实的一次性 Harness home 上，不联网
```

`lamp.js` 是全部安装机制，不 import 任何 DSH 的东西 —— 纯 `node:fs`，可以单独测。
`index.js` 是插件那一面。

## 许可证

[MIT](LICENSE)

基于 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)（MIT）与
[Cordis](https://github.com/cordiverse/cordis) 构建。与 DeepSeek 官方无关联。
