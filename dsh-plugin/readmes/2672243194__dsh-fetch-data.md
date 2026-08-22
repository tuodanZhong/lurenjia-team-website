# dsh-fetch-data

🌐 [English](README.md) | **中文**

![dsh-fetch-data](docs/banner.svg)

**DeepSeek Harness 结构化数据提取插件**——拦截页面真实调用的数据 API（XHR/fetch JSON），按字段精确取回评论点赞、榜单、价格、表格等结构化数据——这是文本提取器（read_url）扁平化 HTML 时丢失的信息。

**read_url 回答"这页讲了什么"，fetch_data 回答"这页背后的数据到底是多少"。**

## 为什么做它

| | read_url（文本提取） | **fetch_data（本插件）** |
|---|---|---|
| 读什么 | 干净正文 / Markdown | 页面背后的 **JSON 数据接口** |
| 输出 | 模型可读的文本 | **结构化字段**（`{标题, 播放量}` 一一对应） |
| 强项 | 读文章、读文档 | **精确归属**——哪个数字对应哪一行 |
| 弱点 | 扁平化后数字与条目对应关系丢失 | 需要 playwright（浏览器引擎） |

真实案例：小黑盒帖子里 `read_url` 读出的 `"60125"` 无法判断是 60 赞+125 收藏还是别的；`fetch_data` 拦截 `/bbs/app/link/tree` 直接返回 `{user, up, content}`——一清二楚。

## 工具

**`fetch_data(url, api?, fields?, maxItems?)`** — 捕获页面数据接口并提取字段

| 参数 | 类型 | 默认 | 说明 |
|---|---|---|---|
| `url` | string | 必填 | 要捕获数据接口的 http(s) 页面 |
| `api` | string | 自动 | 从结构模式的接口清单里指定一个（如 `"/x/web-interface/ranking/v2"`）；省略时自动选择 |
| `fields` | string | 结构模式 | 逗号分隔的字段路径，数组用 `[]`：`"data.list[].title,data.list[].view"` |
| `maxItems` | number | 20 | 每个提取字段的数组截断数（1–100） |

**两种模式：**

**1. 结构模式**（不传 `fields`）——返回自动选中接口的 2 层结构 + **全部 JSON 接口清单**（路径·大小·是否含数组），模型可再带 `api=` 指定：
```
页面 25 个 JSON 接口
选中: /x/web-interface/ranking/v2 (137763B)
结构: { code: number, message: string, ttl: number, data: { note: string, list: [100] { aid: number, ... } } }

接口清单（可传 api=<路径> 指定其中一个再提取字段）:
  /x/web-interface/nav · 249B
  /x/vip/ads/materials · 1140B · 含数组
  ...
```

**2. 字段模式**（带 `fields`）——精确提取，数组按 `maxItems` 截断：
```
data.list[].title (前5条):
  用MC还原《神的随波逐流》 【B萌应援】
  WasteTheFallen丨首曝PV＆实机演示：凝视深渊，人性渐泯
  ...
data.list[].stat.view (前5条):
  2428730
  10326863
  ...
```

## 自动选接口逻辑

对捕获的 JSON 按"**含数组 + 体量最大**"评分（数据接口通常大且含数组，埋点/配置接口小），无数组时退而取最大。可 `api=` 手动覆盖。

## 真实世界验证（2026-08-16，v0.1.3）

14 站全量实测：**12 OK / 2 纯静态站预期报错 / 0 崩溃**——由 `multi-site.mjs`（已提交）驱动。自动滚动（懒加载捕获）+ JSONP 解析已实测。

| 站点 | 结果 |
|---|---|
| B 站排行榜 | ✅ 自动选中 `/x/web-interface/ranking/v2`（139KB，`list[100]`），提取标题+播放量一一对应 |
| 掘金 | ✅ 自动选中 `/recommend_api/v1/article/recommend_all_feed`，提取文章标题 |
| 微博 | ✅ 捕获 `/ajax/feed/hottimeline`（240KB）+ `/ajax/statuses/config`（745KB，超大配置边界） |
| QQ 新闻 | ✅ 捕获 `/getQNChannels`（304KB，36 个接口） |
| 豆瓣 | ✅ 捕获 `/rexxar/api/v2/search/hots` |
| 淘宝 | ✅ 捕获 20 个 JSON 接口（含 mtop 配置 824KB，超大配置边界） |
| 京东 | ✅ 捕获 `/wp-json/news/list` + `/category/get` |
| 知乎/百度/CSDN/网易/小黑盒 | ✅ 捕获各自 JSON 接口（部分为配置/菜单接口——用结构模式清单选数据接口） |
| example.com / 阮一峰博客（纯静态） | ✅ 返回清晰"未捕获到任何 JSON 接口"，不崩溃 |

- **18 个零依赖断言**（字段路径提取器/选择逻辑/结构摘要/静态资源过滤/截断精确性/description 守卫/JSONP 解析）+ **22 个真实拦截断言**（含滚动触发懒加载捕获 + JSONP 提取）全绿。

## 为什么省 token

- **两段式**：结构模式只返回"菜单"（不是 137KB 全量），字段模式只返回指定列——绝不 dump 全量 JSON；
- **固定开销精简**：工具 description 压缩到约 300 字符（唯一每次调用都发送的内容）；静态 schema（KV 缓存友好）；
- **清单排序**：含数组 + 体量大的接口排最前，模型一眼找到数据接口；静态资源 JSON（B 站 `/bfs/svg-next/...`）已过滤并内联计数；
- **尺寸格式化**：`136KB` 而非 `139070B`；数组按 `maxItems` 截断、值限 200 字符；
- 紧凑文本 render；一行式清晰报错。

## 架构（DSH 合规）

- 浏览器单例复用，**卸载时 `ctx.effect` 关闭**（时间可组合性）；
- **每次调用独立浏览器 context**——跨调用不残留 cookie/状态，降低反爬波动；
- **`domcontentloaded` + settle 等待**替代 `networkidle`（心跳轮询站永不空闲）；
- **自动滚动**触发懒加载数据接口（feed/无限列表）；**JSONP** 响应自动剥离包裹；
- 协作超时：`timeoutMs` + `exec.signal`；
- 除 Node 内置外零依赖；**playwright 是必需引擎**（拦截是核心，不是可选增强）。

## 安装

```bash
# playwright 是本插件必需（网络拦截核心）
cd <DSH profile 目录>
npm i playwright && npx playwright install chromium

# 添加插件
dsh plugin --profile web add github:2672243194/dsh-fetch-data
```

## 边界

- **登录墙接口拿不到**（与 read_url 同边界）；
- 每个站的接口结构不同——用结构模式的接口清单发现；
- 自动滚动 + JSONP 已覆盖多数懒加载/JS 延迟数据；剩余缺口（登录墙、纯 SSR 页面）会返回明确报错而非瞎猜。

## 支持

如果 dsh-fetch-data 对你有帮助，欢迎在 GitHub 点个 ⭐ Star。完全免费开源（MIT）；Star 数量是我判断是否继续投入迭代的直接依据。

## License

MIT
