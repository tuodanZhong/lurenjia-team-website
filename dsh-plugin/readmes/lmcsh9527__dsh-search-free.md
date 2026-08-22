# dsh-search-free

[**English**](README.md) · **简体中文**

为 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)（DSH）提供的免费多层网络搜索 + 抓取 provider。

> **为什么有这个项目**：官方 `@deepseek-ai/dsh-web-search-exa@0.0.1-rc.1` 引用了 npm 上不存在的 `@deepseek-ai/dsh-environment`，无法加载；官方 DeepSeek 搜索又需要充值余额。本插件开箱即用，提供免费可用的搜索栈。

## 功能

- **搜索 provider `freesearch`**，多层自动降级：
  1. **Exa** — 语义搜索（质量优先，使用你的 Exa key）
  2. **Tavily** — 通用搜索（免费档约 1000 次/月）
  3. **Bing RSS** — 零 key、零成本兜底
- **抓取 provider `native`** — 原生 fetch，跟随重定向，自动区分 HTML/文本
- **模型工具 `web_fetch`** — 与标准工具同契约（仅在不存在时注册）

代码中不内嵌任何密钥：密钥来自插件行配置（`exaApiKey` / `tavilyApiKey`）。key 为空则跳过对应层。

## ⚠️ 安装防坑（先读这个——v0.1.1）

**不要在运行中的 DSH profile 目录里执行 `npm install` / `pnpm add` / `pnpm install`**
（`$DSH_HOME/profiles/<profile>`）。pnpm 会创建一个**影子 `node_modules`**，其布局
与 profile 真实的依赖树不一致；运行中的实例懒加载模块时会从它加载，导致整个
工具管线崩溃，报错：

```
Cannot read properties of undefined (reading 'prepare')
```

这是我们踩过的坑。解法：删掉那个影子 `node_modules`（实例会重新解析父级/全局树），
改用**符号链接**挂载插件：

```sh
# 适用于有父级 hoisted 树的 profile（web/desktop）
ln -s <插件路径>/dsh-search-free "$DSH_HOME/profiles/node_modules/dsh-search-free"
```

v0.1.1 同时**彻底移除了 `@deepseek-ai/schemastery` 依赖**：插件自带 schemastery 副本
可能与宿主 DSH 的副本冲突。配置现在是普通对象（无需校验）。

## 安装

```sh
# 从 npm 安装
npm i dsh-search-free
# 或从 GitHub 安装
npm i github:lmcsh9527/dsh-search-free
```

然后在 profile 补丁（`cordis.patch.yml`）中挂载：

```yaml
- id: web
  config:
    searchProvider: freesearch

- insert:
    - id: web-search-free
      name: 'dsh-search-free'
      config:
        exaApiKey: <EXA_API_KEY>        # 可选；为空跳过 Exa 层
        tavilyApiKey: <TAVILY_API_KEY>  # 可选；为空跳过 Tavily 层
```

## 使用

- `web_search` 走 `freesearch`（Exa → Tavily → Bing 自动降级）。
- `web_fetch` 抓取任意 HTTP(S) URL 并转为可读文本（HTML 去标签，上限 2 万字符）。

## 测试

```sh
EXA_API_KEY=... TAVILY_API_KEY=... npm test
```

使用 mock ctx 对真实接口进行端到端测试。

## 许可证

[MIT](LICENSE) © lmcsh9527
