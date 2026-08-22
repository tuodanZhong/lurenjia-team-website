# @deepseek-ai/dsh-api-cost

> 让 DeepSeek API 的每一分花费，都看得见。💰

一个挂在 **DeepSeek Harness Web** 侧边栏的小组件：实时告诉你**这次对话烧了多少 token、花了多少钱、账户还剩多少余额**。悬停徽章弹出完整详情，点击徽章直接跳进设置页的仪表盘；token 明细、7 日趋势、CSV 对账、月度预算告警、明暗主题，应有尽有。

- 🔥 **零依赖界面**：纯 React + 内联样式 + 手写柱状图，不引入任何图表/图标/UI 库
- 🌗 **明暗主题**：跟随系统自动切换，也可手动锁定白天 / 夜晚，记住你的选择
- 🧾 **官方账单核对**：导入 DeepSeek 平台的官方 CSV 一键对账，按官方单价重算、偏差一目了然
- 💾 **本地账本**：每次调用写入 JSONL 账本，重启后按当前价表重算，老数据金额永远可复现

---

## ✨ 功能一览

| 功能 | 说明 |
|---|---|
| 💰 实时余额 | 直连官方 `get-user-balance`，API Key 不出服务器 |
| 📊 消耗统计 | 本对话 / 今日 / 本月 / 全局，按模型拆分 token 与金额 |
| 📈 7 日趋势 | V4 Pro / V4 Flash 双模型柱状图，金额 / Token 一键切换 |
| 🧾 CSV 对账 | 导入官方 amount CSV，本地金额按**官方单价**重算后对比，同时展示 Token 与请求数 |
| 🎯 价格校准 | 从官方 CSV 自动提取单价，写入本地价表 |
| 🔔 预算告警 | 月度限额超了可推 webhook，花钱心里有数 |
| 🚀 一键充值 | 面板里直达 DeepSeek 用量页 |
| 🌗 明暗主题 | 跟随系统 / 白天 / 夜晚，三处面板同步响应 |
| 📦 数据不丢 | 每次调用落盘，历史金额按当前价表重算 |

---

## 🚀 安装

两种方式任选其一，装完即自动激活，无需改任何配置文件。

### 方式一：下载 .tgz（推荐）

到 GitHub Releases 页面下载 `deepseek-ai-dsh-api-cost-0.1.0.tgz`，然后：

```sh
pnpm dsh plugin --profile web add ./deepseek-ai-dsh-api-cost-0.1.0.tgz
```

### 方式二：git 下载（clone）

```sh
git clone https://github.com/MoyunLee/dsh-api-cost.git
pnpm dsh plugin --profile web add file:./dsh-api-cost
```

> 仓库已提交预构建的 `lib/client.js`，本地安装直接用它，**无需构建、无需授权**。
> 网页「Download ZIP」解压后，同样用 `file:` 方式安装即可。

### 启动

```sh
pnpm dsh web
```

打开 `http://127.0.0.1:3080`，左下角就是「余额 / 花费」徽章。

---

## 🔑 配置 API Key（可选）

余额查询需要 DeepSeek API Key，二选一：

```sh
# 环境变量
DEEPSEEK_API_KEY=sk-… dsh web
```

或写入 `$DSH_HOME/.credentials.yaml`：

```yaml
DEEPSEEK_API_KEY: sk-…
```

优先级：进程环境变量 > `.credentials.yaml` > `.env` 层。不配 Key 时余额显示 `--`，token 与金额统计照常工作。

---

## 📖 使用指南

- **侧边栏徽章**：左下角两行「余额 ¥X / 花费 ¥Y」；生成中会在花费后面显示 `+¥Z` 实时增量。
- **悬停徽章**：弹出完整详情——余额、本对话 / 今日 / 本月、Token 详情（分模型 + 总计）、
  7 日趋势（双模型，金额/Token 切换）、最近调用、外观模式与账单管理。
- **点击徽章**：直接跳转到设置页「用量与消耗」。
- **设置页「用量与消耗」**（也可点侧边栏齿轮进入）：完整仪表盘——余额、今日/本月费用、
  各模型今日消耗 Token 与消耗金额、今日 Token 详情、7 日趋势、外观模式、账单管理。
- **CSV 对账**：点「核对官方 CSV」选官方导出的 `amount-*.csv`。本地金额会先按 CSV 里的
  官方单价重算，再与官方金额对比（避免本地价表与扣费单价不同造成的假偏差），并同时展示
  官方/本地 Token 与请求数。「按官方价格校准」可把官方单价写入本地价表。
- **导出 / 重置**：一键导出本地账本 CSV；重置会清空全部累计记录（有确认提示）。

---

## ⚙️ 配置

配置写在 profile 用户层 `$DSH_HOME/profiles/web/cordis.patch.yml`，按行 id 覆盖、与内置默认值**合并**，只写要改的字段即可：

```yaml
- id: api-cost
  config:
    # 覆盖/新增模型价格（¥/百万 token：input=缓存未命中 / cacheRead=缓存命中 / cacheWrite / output）
    prices:
      my-model:
        input: 3.0
        cacheRead: 0.1
        cacheWrite: 3.0
        output: 9.0

    # 峰谷计费（默认关闭；北京时间高峰 9:00–12:00、14:00–18:00，谷时段半价）
    peak:
      enabled: true
      peakHours: [[9, 12], [14, 18]]
      peakMultiplier: 1.0
      offpeakMultiplier: 0.5

    # 月度预算告警（0 = 关闭；超限可选 webhook 通知一次）
    budget:
      monthlyLimit: 50
      webhookUrl: 'https://example.com/hook'

    # 余额校准（expected = initialBalance − 本地累计；偏差超阈值提示）
    calibration:
      enabled: true
      initialBalance: 100
      deviationThreshold: 0.05
```

### 内置默认价表（¥/百万 token）

| 模型 | input（缓存未命中） | cacheRead（缓存命中） | cacheWrite | output |
|---|---|---|---|---|
| deepseek-v4-flash | 3.0 | 0.10 | 3.0 | 9.0 |
| deepseek-v4-pro | 9.0 | 0.30 | 9.0 | 27.0 |

> 官方定价可能随时调整：实际扣费单价以 [官方定价页](https://api-docs.deepseek.com/zh-cn/quick_start/pricing)
> 为准；对账时会自动按你导入 CSV 里的官方单价重算，不依赖这张表。

---

## 🔧 开发者

### 本地开发（含热更新）

`scratch-plugin/*` 已注册为 workspace 成员，可以 `link:` 安装并开启热更新：

```sh
pnpm install                                             # 装 peer 依赖
pnpm dsh plugin --profile web add ./scratch-plugin/api-cost   # 裸路径 = link 到源码
```

两个终端：

```sh
# 终端 A：改 src/client/index.js 后自动重打 lib/client.js
cd scratch-plugin/api-cost && pnpm watch:client

# 终端 B：web 服务（client 改动自动热更新）
pnpm dsh web --patch ./scratch-plugin/cordis.yml
```

- **client 半**（`src/client/index.js` → `lib/client.js`）：`dsh web` 内置的 `dsh-client-hmr`
  监测 bundle 变化并热更新浏览器。
- **host 半**（`src/index.js`）：作者仓库根的 `scratch-plugin/cordis.yml` 里用 `--patch`
  重新启用了 web 组合包默认关掉的 `hmr` 行，保存源码后框架会卸载并重载该插件。
  ⚠️ 官方把这条标记为「重载生命周期未测试」，异常时删掉该 overlay 里那节 `id: hmr` 并重启即可回退。
  （这段 hmr 覆盖只存在于作者仓库根的 overlay，**不会随 tarball/npm/GitHub 发布给用户**。）

### 构建与打包（发版）

```sh
cd scratch-plugin/api-cost

# 1) 改代码：前端 src/client/index.js；后端 src/index.js（纯 ESM，无需构建）

# 2) 只改前端才需要重打 bundle（tsdown 从仓库根解析，插件自身不装）
pnpm build:client

# 3) 打包（只打包不构建，务必先 build）
pnpm pack

# 4) 提交 + 推送（装了 gh 就再上传 Release）
git add -A
git commit -m "改动说明"
git push origin main --tags
```

> **改 client → build → pack 三步一个都不能少**，否则 `.tgz` 里的 `lib/client.js` 是旧代码。
> 发布包刻意不含 `devDependencies`（react/tsdown 是构建期/外部依赖，运行时不需要），所以
> `file:` 安装零构建、零链接，不会触发跨盘 symlink。
>
> 版本升级：大改动 bump `package.json` 的 `version` 并打新 tag `v0.x.0`；
> 覆盖 Release 附件：`gh release upload v0.1.0 deepseek-ai-dsh-api-cost-0.1.0.tgz --clobber`。

---

## 🗑️ 卸载

不想用了，一行命令移除插件（会同时删掉依赖和 profile 里的插件层）：

```sh
pnpm dsh plugin --profile web remove @deepseek-ai/dsh-api-cost
```

然后重启 `dsh web` 即彻底停用。

> 插件产生的**本地账本数据**在 `$DSH_HOME/api-cost/`（默认 `%USERPROFILE%\.dsh\api-cost\`），
> `dsh plugin remove` 不会删它。想连数据一起清干净，手动删掉这个目录：
>
> ```powershell
> Remove-Item -Recurse -Force "$env:USERPROFILE\.dsh\api-cost"
> ```
>
> 浏览器里的外观模式偏好存在 localStorage（键 `dsh-api-cost-theme`），清浏览器站点数据时一并清掉即可。

---

## 📝 说明与限制

- 只统计**插件启用之后**产生的调用，历史会话不回溯（已有账本会按当前价表重算金额）。
- 未在 `prices` 中配置的模型按 0 元计费（token 照常累计）——先看量再看价。
- 余额接口每分钟缓存一次；API Key 通过凭据服务解析，不会进入浏览器。
- 重置/校准接口要求自定义头 `x-dsh-api-cost: confirm`，可防跨站 CSRF；但仍属本机个人工具，**若把服务暴露到公网，请自行加鉴权**。
- 峰谷按北京时间（UTC+8）判断，不依赖本机时区。
- 「点击徽章跳转设置页」通过设置面板的 DOM 触发按钮实现（harness 暂无公开的
  「打开设置面板到指定 section」API）；若 harness 后续改动该面板结构，此跳转可能失效，
  设置页本身仍可经侧边栏齿轮正常进入。

## 📄 License

[MIT](./LICENSE)
