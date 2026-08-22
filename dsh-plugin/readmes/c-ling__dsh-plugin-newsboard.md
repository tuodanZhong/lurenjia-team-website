# dsh-plugin-newsboard

DeepSeek Harness 的快讯看板：页面右上角一个轻量浮窗（拖拽标题栏即可移动，位置自动保存），由宿主侧抓取内置 RSS/JSON 来源并缓存，浏览器只负责轮询展示。默认不弹通知、不发声、不打断任务。

[English](README-en.md)

[![dsh-plugin topic](https://img.shields.io/badge/topic-dsh--plugin-blue)](https://github.com/topics/dsh-plugin)
[![license](https://img.shields.io/badge/license-MIT-green)](LICENSE)

## 功能

- **轻量浮窗**：收起时是右上角一个 300px 小胶囊（快讯看板 + 未读数 + 最新标题），点击展开为 360px 看板；收起或展开后都可直接拖拽移动，位置自动保存到本地。展开面板背景参考 goldboard 的深色浮窗风格。
- **实时抓取**：宿主侧每 5 分钟并发抓取内置来源（单源 10 秒超时），结果去重、排序、缓存到本地。
- **AI 圈 / 技术圈分类**：面板内一键切换 `全部 / AI 圈 / 技术圈`，支持当前消息搜索。
- **英文消息中文双语**：默认调用当前已配置的模型，也可在设置页切换为传统翻译 API（百度翻译、有道翻译、DeepL 等有免费额度的平台）把英文标题/摘要翻译成中文并随消息缓存；百度翻译支持在“通用翻译”和“大模型翻译”之间切换，两者共用同一套 AppID/密钥，仅切换请求接口。翻译成功时优先展示中文，原文以子标题展示，失败时自动退回原文；取不到简介时显示「暂无简介」。
- **不打扰**：没有 toast、没有系统通知、没有声音；只有新消息时胶囊上的未读数字变化。
- **设置页**：设置 → 快讯看板，可开关来源、配置英文消息中文翻译（模型或传统 API）、包含/排除关键词、刷新间隔、展示条数和时间窗。
- **双语 UI**：中文 / English 随设置 → 通用 → 语言实时切换。

内置来源：

| 类别 | 来源 |
| --- | --- |
| AI 圈 | Hacker News AI 检索、OpenAI News、Google AI Blog、TechCrunch AI、The Verge AI、arXiv cs.AI |
| 技术圈 | Hacker News 首页、Lobsters、Ars Technica、IT之家、少数派、Solidot |

## 安装

从 GitHub 安装到 web profile（需要 `pnpm` 在 `PATH` 上；没有则用下面的 corepack 方式）：

```sh
npx @deepseek-ai/dsh plugin --profile web add "github:c-ling/dsh-plugin-newsboard#v1.1.3"
```

或使用已有的 `dsh` 命令：

```sh
dsh plugin --profile web add "github:c-ling/dsh-plugin-newsboard#v1.1.3"
```

pnpm 不在 `PATH` 上时：

```sh
cd ~/.dsh/profiles/web
corepack pnpm add "github:c-ling/dsh-plugin-newsboard#v1.1.3"
```

> `dsh plugin` 把参数原样转发给 pnpm，直接从仓库拉取包（pnpm 9+，本机需装有 `git`）。
> 安装时若看到 `declares no dsh.bundle — installed as a plain dependency` 的提示属正常现象：
> 本插件不是 profile bundle 层，而是通过下面的 loader 行激活。

然后在 `~/.dsh/profiles/web/cordis.patch.yml` 增加一行插入：

```yaml
- insert:
    - id: dsh-plugin-newsboard
      name: 'dsh-plugin-newsboard'
```

重启 `dsh web`（client-modules 按进程缓存包裁决，新包必须重启宿主），然后硬刷新页面，
右上角即出现「快讯看板」胶囊。

## 验证

```sh
# 客户端 factory bundle
curl -s http://127.0.0.1:3080/plugins/dsh-plugin-newsboard/client.js | head -c 60

# 当前配置
curl -s http://127.0.0.1:3080/dsh-plugin-newsboard/config

# 当前抓到的消息
curl -s http://127.0.0.1:3080/dsh-plugin-newsboard/feed | head -c 500
```

第一条应输出 `window.__ModuleLoader__.load({` 开头的 factory bundle；页面右上角能看到浮窗胶囊。

## 更新

```sh
dsh plugin --profile web add "github:c-ling/dsh-plugin-newsboard#v1.1.3"
# 或：npx @deepseek-ai/dsh plugin --profile web add "github:c-ling/dsh-plugin-newsboard#v1.1.3"
# 或：cd ~/.dsh/profiles/web && corepack pnpm add "github:c-ling/dsh-plugin-newsboard#v1.1.3"
```

用新的 `#v<version>` 重新执行安装命令即可升级依赖；`cordis.patch.yml` 中的 loader 行保持不变。
重启 `dsh web`，然后硬刷新页面。

## 卸载

```sh
cd ~/.dsh/profiles/web
corepack pnpm remove dsh-plugin-newsboard   # 或 dsh plugin --profile web remove dsh-plugin-newsboard
```

同时删除 `cordis.patch.yml` 中对应的 insert 行，然后重启 `dsh web`。
配置与抓取缓存位于 `$DSH_HOME/storages/dsh-plugin-newsboard/`，卸载后会保留，可手动清理。

## 开发

本地开发建议直接 link（把 `<path>` 换成本仓库绝对路径）：

```sh
cd ~/.dsh/profiles/web
corepack pnpm add "link:<path>/dsh-plugin-newsboard"
```

```sh
node --check lib/index.js lib/client.js
node --test
```

- 宿主半部 `lib/index.js`：普通 Cordis 插件，零运行时依赖；内置来源抓取、去重过滤、
  磁盘缓存、`/dsh-plugin-newsboard/{config,feed,refresh}` 路由。
- 客户端半部 `lib/client.js`：手写 factory-CJS bundle，无构建步骤；
  `inject: ["slots", "locale"]`，通过 `shell.overlay` 挂浮窗、`settings.section` 挂设置页。
- 默认预置一批 AI/技术关键词（DeepSeek / OpenAI / Claude / Gemini / LLM / Agent / 模型 / 开源 / 芯片等）；清空关键词则显示所选来源全部消息。命中标题或摘要中的任意一个才保留，排除词命中即隐藏。

## 已知限制

- 看板依赖各来源站点的 RSS/JSON 可访问性；个别来源失败会显示「N 个来源暂不可用」，不影响其余来源。
- 首次打开（无缓存）时最多等待约 10 秒完成首轮抓取；之后由缓存即时响应。
- 插件故意不做推送/声音打扰；如需任务结束提醒请配合 `dsh-plugin-notify` 使用。

## License

[MIT](LICENSE)

