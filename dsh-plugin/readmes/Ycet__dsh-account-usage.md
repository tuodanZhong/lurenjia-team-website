[English](README_en.md) · [简体中文](README.md)

# dsh-account-usage

DeepSeek Harness（DSH）网页界面插件：在**设置面板**新增独立「**账户**」页，一站式查看：

- **DeepSeek 开放平台**（platform.deepseek.com/usage 同源数据）
  - 充值余额 / 赠送余额
  - 累计消费金额、本月消费金额、本月 tokens
  - 每日**消费金额柱状图**
  - 所选时间维度内的**消费金额、API 请求次数、tokens** 汇总
  - 按模型明细表（deepseek-v4-flash / deepseek-v4-pro / 其他）：请求次数 + 输入/缓存/输出 tokens + 费用
  - 可切换**时间维度**（今天 / 近7天 / 近30天 / 近90天 / 本月 / 上月 / 自定义，默认「本月」）
- **OpenCode Go** 套餐用量（opencode.ai 官方端点）
  - 5 小时滚动 / 每周 / 每月 三个窗口的**用量百分比**、**下次重置时间**与**重置倒计时**

页面顶部以 `deepseek` / `opencode go` 两个文字标签切换展示；两面板均提供「跳转」按钮，在新标签页打开对应官方页面。

## 目录

- [界面预览](#界面预览)
- [版本要求](#版本要求)
- [安装](#安装)
- [升级](#升级)
- [故障排查](#故障排查)
- [配置](#配置)
  - [DeepSeek 平台令牌](#deepseek-平台令牌必需仅影响-deepseek-面板)
  - [OpenCode Go Key](#opencode-go-key通常无需配置)
- [工作原理](#工作原理)
  - [数据源](#数据源)
- [环境变量（可选调优）](#环境变量可选调优)
- [已知限制](#已知限制)
- [开发](#开发)
- [License](#license)

## 界面预览

### DeepSeek 用量页面

![DeepSeek 用量页面](docs/deepseek-usage.png)

显示充值余额、累计消费、本月消费统计，消费金额柱状图，以及按模型（deepseek-v4-flash / deepseek-v4-pro）的请求次数和 token 消耗详情。

### OpenCode Go 用量页面

![OpenCode Go 用量页面](docs/opencode-go-usage.png)

显示 5 小时滚动、每周、每月三个窗口的用量百分比、限额参考和重置倒计时。

## 版本要求

| 依赖 | 要求 |
|---|---|
| DSH | `0.1.0-rc.6` 系列（插件 peerDependencies 声明；同一 rc 系列均可） |
| Node | 跟随 DSH 自身要求（Node 18+，宿主使用内置 fetch） |
| pnpm | `dsh plugin` 内部转发需要 |

插件宿主半面**不依赖任何 `@deepseek-ai` 包**（仅 node 内置 + 自身代码），credentials 服务为可选访问——即使 DSH 包面发生重命名/移除，插件也不会导致 dsh 启动失败，只会返回「未配置凭据」类提示。

## 安装

需要 DSH CLI 与 pnpm（`dsh plugin` 内部转发到 pnpm）。

```sh
# 从 GitHub 安装：
dsh plugin --profile web add github:Ycet/dsh-account-usage
```

包声明了 `dsh.bundle` 补丁层，`dsh plugin` 会自动把加载项合入 profile 的 bundle 层（无需手动编辑 cordis.patch.yml）。手动方式：

```yaml
# ~/.dsh/profiles/web/cordis.patch.yml
- insert:
    - id: account-usage
      name: dsh-account-usage
```

然后：

1. 重启网页应用：`dsh web`
2. 打开 http://127.0.0.1:3080 并刷新页面
3. 设置面板出现「账户」页

## 升级

```sh
dsh plugin --profile web update dsh-account-usage
# 或重新 add（git 依赖按最新默认分支重新解析）
```

## 故障排查

| 现象 | 处理 |
|---|---|
| dsh 启动失败 | 先运行 `dsh --profile web --dump-config` 定位组合错误；确认 DSH 版本为 rc.6 系列；确认 profile 内快照与源码一致（`node_modules/dsh-account-usage` 内容） |
| 设置面板无「账户」页 | 硬刷新（Ctrl+F5）；确认 bundle 层含 dsh-account-usage（见上）；客户端问题不影响 dsh 启动 |
| 提示未配置凭据 | 见下方「配置」；凭据服务缺失时插件只会降级提示，不会崩溃 |

> 注：设置面板中「账户」的人形图标依赖本机 DSH 外壳的一行小补丁（见仓库内 `docs/` 或发布说明），未打补丁时显示齿轮图标，不影响功能。

## 配置

### DeepSeek 平台令牌（必需，仅影响 DeepSeek 面板）

用量接口是平台控制台的私有接口，需要你的平台登录令牌：

1. 登录 https://platform.deepseek.com
2. 打开 DevTools → Console，执行：

   ```js
   JSON.parse(localStorage.getItem('userToken')).value
   ```

3. 两种写入方式任选：
   - 在插件「账户」页的令牌输入框直接粘贴并保存（写入 `~/.dsh/.credentials.yaml` 的 `DEEPSEEK_PLATFORM_TOKEN`）；
   - 或手动追加到 `~/.dsh/.credentials.yaml`：

     ```yaml
     DEEPSEEK_PLATFORM_TOKEN: <令牌>
     ```

令牌只存储在本机凭据库，浏览器与网络请求均不携带它往返上游以外的任何位置。

### OpenCode Go Key（通常无需配置）

插件按以下顺序自动查找：

1. DSH 凭据 `OPENCODE_GO_API_KEY`（`~/.dsh/.credentials.yaml`，在「设置 → 模型」配置 opencode-go 时通常已存在）；
2. OpenCode 自身的 `~/.local/share/opencode/auth.json`（`opencode-go` 条目，type 为 `api`）。

## 工作原理

双面插件（宿主 + 浏览器），数据通道为宿主注册的同源 HTTP 路由（与 `dsh-deepseek-quota` 同款模式，无需 Typert 清单）：

| 部分 | 文件 | 作用 |
|---|---|---|
| 宿主 | `index.js` | 注册三条 `GET /api/account-usage/*` 精确路由：平台概要、区间用量（按月拉取+聚合）、OpenCode 配额；经 `ctx.credentials` 解析密钥，固定白名单上游 URL，15s 超时 + 30s 缓存 |
| 解析聚合 | `lib/aggregate.js` | 纯函数：平台信封解包后的每日/每模型 token、费用、请求次数聚合（无依赖，可独立测试） |
| 浏览器 | `client.js` | 手写惰性 CJS 客户端包：注册 `settings.section`（id `account`），渲染账户页（SVG 柱状图、维度选择器、模型表、配额进度条），挂载期间每 60s 自动刷新 |
| 组合 | `cordis.patch.yml` | `dsh.bundle` 补丁层，安装时自动合入 |
| 测试 | `test/aggregate.mjs` | fixture 单测：`node test/aggregate.mjs` |

### 数据源

| 用途 | 端点 | 认证 |
|---|---|---|
| 账户概要 | `platform.deepseek.com/api/v0/users/get_user_summary`（+`/get_user_info`） | `Bearer <userToken>` |
| 每日 token 明细 | `platform.deepseek.com/api/v0/usage/amount?month=&year=` | `Bearer <userToken>` |
| 每日费用明细 | `platform.deepseek.com/api/v0/usage/cost?month=&year=` | `Bearer <userToken>` |
| OpenCode Go 配额 | `opencode.ai/zen/go/v1/usage`（官方） | `Bearer <sk-opencode-…>` |

## 环境变量（可选调优）

| 变量 | 默认 | 说明 |
|---|---|---|
| `DSH_ACCOUNT_USAGE_TIMEOUT_MS` | `15000` | 上游请求超时（毫秒） |
| `DSH_ACCOUNT_USAGE_CACHE_MS` | `30000` | 平台数据缓存 TTL（毫秒） |
| `DSH_ACCOUNT_USAGE_MAX_MONTHS` | `3` | 单次查询可覆盖的最大月份数（超出自动裁剪） |

## 已知限制

- DeepSeek 平台用量接口为**未公开的私有接口**，字段可能随平台升级变化；插件对响应做防御式解析，字段缺失时降级为「—」而非报错。若页面长期显示「—」，请重新抓包确认字段并反馈。
- 「累计消费金额」「API 请求次数」字段不在公开文档中：累计消费按命名启发式在概要响应中搜索（找不到则显示「—」），请求次数读取模型条目上的 `count/requests/request_count/req_count/calls` 字段。两者均在真实令牌实测后校准。
- OpenCode Go 的限额（$12/$30/$60）为套餐参考值，端点未返回限额；套餐调整时以 opencode.ai 页面为准。
- 服务绑定 `0.0.0.0` 时本插件路由对局域网可达（与 DSH 其他本地插件相同的既有限制，默认 `127.0.0.1` 无此问题）。

## 开发

```sh
node test/aggregate.mjs      # 聚合/解析单测
node test/routes.mjs         # 宿主路由冒烟测试（模拟 ctx + 模拟 fetch）
node test/client-render.mjs  # 客户端 bundle 预检（模拟加载器 + SSR 渲染页面）
node test/package-shape.mjs  # 包声明形状校验（防加载器 fail-loud）
node --check index.js        # 语法检查
```

修改代码后按「发布流程」提交推送（见仓库 git 历史与 tag），使用者通过 `dsh plugin --profile web update dsh-account-usage` 升级。

> 维护说明：每次发布前运行全部测试，并参考本仓库 `docs/`（若有）执行干净环境安装验证。

## License

MIT
