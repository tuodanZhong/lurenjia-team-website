# stock-watch：DSH 股票观察站

一个面向 DeepSeek Harness（DSH）的客户端插件。它在 DSH 左侧边栏底部提供一个 📈 入口，用来查看 A 股持仓和自选股的实时行情。持仓页显示盈亏，自选页只显示行情。

## 先看安全说明

- 持仓数据只从你自己电脑上的一个 JSON 文件读取。
- 插件只把本机配置中的股票信息传给当前 DSH 页面，不会上传到本项目作者的服务器。
- 行情请求发送到腾讯行情接口时只包含股票代码，不包含你的数量、成本价或 API Key。
- 仓库里的 `holdings.example.json` 只有假数据。请不要把真实的 `holdings.json`、截图、账号信息或 API Key 提交到 GitHub。
- 默认情况下，DSH Web 服务只监听本机地址。如果你主动把 DSH 暴露到局域网或公网，能访问 DSH 的人也可能读取这个本地插件路由返回的持仓摘要，请不要这样配置。
- 插件只保留允许的字段：持仓使用 `code`、`name`、`quantity`、`costPrice`，自选使用 `code`、`name`。其他字段会被丢弃。

## 安装

### 从 GitHub 安装

```powershell
dsh plugin --profile web add github:Bob-Bo1/dsh-stock-watch
```

然后在 DSH Web profile 的 `cordis.patch.yml` 中确认有这段注册配置：

```yaml
- insert:
    - id: stock-watch
      name: stock-watch
```

重启 DSH Web：

```powershell
dsh web
```

如果你使用的是 `dsh.cmd`，把上面的 `dsh` 换成 `dsh.cmd` 即可。

### 本地开发安装

```powershell
git clone https://github.com/Bob-Bo1/dsh-stock-watch.git D:\Tools\stock-watch
dsh plugin --profile web add link:D:\Tools\stock-watch
```

本地路径可以替换成你实际保存插件的目录。安装后同样需要确认 `cordis.patch.yml` 已注册插件，再重启 DSH。

## 关联自己的股票数据

安装并重启 DSH 后，直接打开左下角的 📈 按钮即可在网页里管理数据。

### 在网页里添加

面板底部有两个页面：

- **持仓**：添加股票名称或代码，再填写买入份数和买入价格。
- **自选**：添加股票名称或代码即可，不需要填写数量和价格。

点击面板底部的“＋添加”，输入名称或代码后搜索。若有多个匹配结果，选择正确的一项，插件会把代码和名称写入本机的 `holdings.json`。股票名称会先在 Host 端解析为代码，浏览器不会直接修改文件。

点击底部的“修改”后，选择一只股票即可编辑。持仓可以修改股票名称、买入份数和买入价格；自选可以修改股票名称。编辑表单中也提供“删除这只股票”，删除前需要确认。持仓页和自选页分别管理自己的列表；删除持仓不会影响同一只股票在自选中的记录。打开股票插件、切换持仓/自选页面时，插件会立即重新读取数据并刷新行情，后台仍会按设置的间隔继续更新。

网页添加失败时，可以继续使用下面的 JSON 文件方式。

推荐把持仓文件放在 DSH workspace 根目录：

```text
你的 DSH workspace\holdings.json
```

最简单的做法：

1. 复制仓库里的 `holdings.example.json`。
2. 将副本改名为 `holdings.json`。
3. 把示例股票替换成自己的数据。
4. 将文件放到 DSH workspace 根目录。
5. 打开 DSH 左下角的 📈 按钮查看结果。

DSH workspace 通常就是启动 `dsh web` 时所在的目录。你也可以用环境变量指定一个本机文件：

```powershell
$env:DSH_STOCK_HOLDINGS = 'D:\Private\stocks\holdings.json'
dsh web
```

相对路径会按 DSH workspace 解析。环境变量优先级高于默认的 `workspace\holdings.json`。

如果你希望无论从哪个目录启动 DSH 都使用同一个文件，可以在 Windows 用户环境变量中固定路径：

```powershell
[Environment]::SetEnvironmentVariable('DSH_STOCK_HOLDINGS', 'D:\你的固定目录\holdings.json', 'User')
```

设置后请完全重启 DSH Web。这个环境变量只保存文件路径，不会把持仓内容上传到 GitHub。

### 文件格式

```json
{
  "refreshSeconds": 5,
  "holdings": [
    {
      "code": "sz000001",
      "name": "示例股票",
      "quantity": 100,
      "costPrice": 10.5
    }
  ],
  "watchlist": [
    {
      "code": "sh600028",
      "name": "示例自选"
    }
  ]
}
```

字段说明：

| 字段 | 必填 | 说明 |
|---|---|---|
| `code` | 是 | `sh`、`sz` 或 `bj` 加 5～6 位数字，例如 `sz000001` |
| `name` | 否 | 自定义名称；不填时使用行情接口返回的名称 |
| `quantity` | 是 | 持仓数量，必须大于 0 |
| `costPrice` | 是 | 成本价，必须大于 0 |
| `refreshSeconds` | 否 | 行情刷新间隔，支持 1～3600 秒，默认 5 秒 |

`watchlist` 中的每一项只需要 `code` 和可选的 `name`。持仓和自选可以同时出现同一只股票。

文件保存后，插件会自动重新读取。页面可见时按设置的间隔刷新行情，页面不可见时会暂停行情请求。

## 数据和计算范围

- 行情来自腾讯公开行情接口，网络异常时会保留上一组成功数据。
- 涨跌颜色按 A 股习惯显示：红色上涨，绿色下跌。
- 盈亏按“现价 - 成本价”乘以数量计算。
- 自选页不计算持仓盈亏，只显示现价、涨跌幅和今日涨跌额。
- 当前版本没有计入手续费、印花税、分红和融资成本。
- 这是本机观察工具，不构成投资建议，也不会执行买卖操作。

## 常见问题

### 左下角没有 📈 按钮

确认三点：

1. 已通过 `dsh plugin --profile web add ...` 安装插件。
2. `cordis.patch.yml` 中存在 `id: stock-watch` 的注册项。
3. 已完全重启 DSH Web，而不是只刷新浏览器页面。

### 显示“暂无持仓”

检查：

- 文件名是否为 `holdings.json`。
- 文件是否放在 DSH workspace 根目录。
- 是否设置了 `DSH_STOCK_HOLDINGS`，且路径确实存在。
- JSON 是否能正常解析，代码是否带 `sh`、`sz` 或 `bj` 前缀。

### 网页添加失败

- 确认 DSH Web 已完全重启，Host 路由已经加载。
- 如果页面提示“股票服务未加载”，说明当前 DSH 进程还在使用旧版 Host；请退出并重新启动 DSH Web，单纯刷新网页不够。
- 名称搜索需要网络访问腾讯 Smartbox 搜索接口。
- 代码建议使用带市场前缀的格式，例如 `sh600547`、`sz000001`。
- 持仓的买入份数必须是正整数，买入价格必须大于 0。

### 如何避免误提交真实持仓

真实文件名请使用 `holdings.json`，仓库已通过 `.gitignore` 忽略它。提交前仍建议检查：

```powershell
git status --short
git diff --cached
```

确认提交内容中只有 `holdings.example.json`，没有自己的股票代码、数量和成本价。

## 开发检查

```powershell
npm run check
npm pack --dry-run
```

`npm pack --dry-run` 应只显示插件代码、README、示例数据、许可证和 `package.json`，不应包含真实持仓文件或 `node_modules`。

## 插件结构

```text
stock-watch/
├─ lib/index.js          # DSH Host 侧：本地数据、搜索和保存路由
├─ lib/client.js         # DSH Client 侧：切换、添加和行情面板
├─ holdings.example.json # 假数据示例，公开安全
├─ package.json          # npm 与 DSH 插件清单
├─ LICENSE
└─ README.md
```

## 许可证

MIT License，详见 [LICENSE](LICENSE)。
