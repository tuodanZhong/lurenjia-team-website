# dsh-web-auto-open

DSH（DeepSeek Harness）Web 一键启动插件：**运行 `dsh web`，浏览器自动打开**。

[GitHub](https://github.com/ChengChe106/dsh-web-auto-open) · [npm](https://www.npmjs.com/package/dsh-web-auto-open) · [dsh-plugin topic](https://github.com/topics/dsh-plugin)

## 有什么用

DeepSeek Harness 的 Web 界面默认需要两步：先在终端启动服务器，再手动打开浏览器输入 `http://127.0.0.1:3080`。

装了这个插件后，启动只需一步：

```bash
npx @deepseek-ai/dsh web
```

服务器一监听成功，插件会自动用系统默认浏览器打开 Web 界面——不用复制网址、不用额外脚本、不用记端口。

- 支持 Windows / macOS / Linux
- 服务器端口为 `0`（系统随机分配）时也能拿到真实端口并正确打开

## 安装（推荐 npm）

```bash
dsh plugin add dsh-web-auto-open
```

如果 `dsh` 没有全局安装，用 npx 方式执行：

```bash
npx --yes @deepseek-ai/dsh plugin --profile web add dsh-web-auto-open
```

## 如何启用

插件声明为 profile bundle，**安装后下一次启动 `dsh web` 即自动生效**，无需任何额外配置。

验证是否已生效：

```bash
dsh --profile web --dump-config
# 输出中应包含以下片段：
# - id: web-open
#   name: dsh-web-auto-open
```

### 可选配置

在 `~/.dsh/profiles/web/cordis.patch.yml` 里覆盖 `web-open` 行即可：

```yaml
- id: web-open
  config:
    autoOpen: false   # 关闭自动打开
    delayMs: 1000     # 服务器就绪后再延时 1 秒打开浏览器
```

## 原理

- 插件声明 `inject: ["webServer"]`，等 Loader 全部启动完成后读取 `webServer.port`（监听成功后才赋值）
- 通过官方 `@deepseek-ai/dsh-native-command` 调用系统命令打开浏览器：
  Windows `cmd /c start` / macOS `open` / Linux `xdg-open`
- 与官方 `dsh-web-app` 打印 URL 用的是同一套就绪判定习惯，安全可靠

## 开发者

- 仓库：https://github.com/ChengChe106/dsh-web-auto-open （欢迎 Star / Issue）
- 发布新版本：`npm version patch && npm publish && git push --tags`
- 协议：MIT
