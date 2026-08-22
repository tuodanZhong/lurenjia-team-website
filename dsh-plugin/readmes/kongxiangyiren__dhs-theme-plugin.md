# @kongxiangyiren/dhs-theme-plugin

DSH 主题管理插件（静态版）：在 **设置 → 主题** 提供主题大分类，内置两套主题，
支持上传自定义 JS 主题并一键切换，数据持久化在磁盘上（换浏览器不丢）。

## 功能

- **设置 → 主题** 大分类（与"通用"平级）
- 内置主题：**森林绿** / **海洋蓝**（13 个 alias token 覆盖 + 质感特效 CSS：辉光、网格/波纹、暗角、霓虹光带）
- **上传自定义 JS 主题**：`__ModuleLoader__.load` 格式单文件，支持 `overrideTokens` 改色、注入 CSS、`slots` 注册 UI 组件、`require("react")`，**无文件大小限制**
- **点击切换**：上传主题出现在主列表，点一下即应用；切换内置主题自动停用上传主题；同一时刻只有一个生效
- **磁盘持久化**：Host 半部注册 `webServer` 路由 `GET/POST /api/theme-plugin`，数据存放在 DSH home（`~/.dsh/dhs-theme-plugin.json`），浏览器无关

## 安装

```bash
# 从 npm 安装（首选）
dsh plugin --profile web add @kongxiangyiren/dhs-theme-plugin

# 或从 git 直装（纯 JS 无 prepare，无需 allowBuilds 授权）
dsh plugin --profile web add git+https://github.com/kongxiangyiren/dhs-theme-plugin

# 或本地目录（开发/验证）
dsh plugin --profile web add ./
```

`dsh plugin` 会把包加入 profile 的 `dsh.profile.bundles` 层列表。之后正常启动：

```bash
npx @deepseek-ai/dsh web
```

## 卸载

```sh
 dsh plugin --profile web remove @kongxiangyiren/dhs-theme-plugin
```

## 使用

1. 打开 **设置 → 主题**
2. 点击列表项切换：跟随系统 / 浅色 / 深色 / 森林绿 / 海洋蓝 / 已上传主题
3. 上传主题：点 **选择 JS 文件**，选一个主题脚本（见 `examples/`）
4. "已上传主题"区可查看状态（应用中/未应用）并**删除**

## 主题文件格式

上传文件必须是浏览器 bundle 格式（与 dsh.client 包相同）：

```js
window.__ModuleLoader__.load({
  id: 'my-theme',
  factory: require => {
    var module = { exports: {} };
    var exports = module.exports;
    function apply(ctx) {
      ctx.effect(
        () =>
          ctx.theme.overrideTokens('my-theme', {
            '--dsw-alias-bg-base': { light: '#ffffff', dark: '#0f1115' },
            '--dsw-alias-brand-primary': { light: '#7c3aed', dark: '#a78bfa' }
          }),
        'my-theme tokens'
      );
    }
    exports.apply = apply;
    return module.exports;
  }
});
```

apply 收到的迷你 ctx 提供：`theme` / `slots` / `effect` / `on` / `once` / `timeout` / `interval` / `get` / `console`；
factory 内支持 `require("react")`。注意：上传的 JS 会在页面中直接执行，只使用可信文件。

## 示例

- `examples/cyberpunk-theme.js` — 黑底荧光绿终端风：网格、扫描线、霓虹光带、glitch
- `examples/nekogirl-theme.js` — 粉色猫娘风：粉色调、猫耳、樱花花瓣、喵酱按钮、输入框猫猫（演示 `require("react")` + `slots` UI）

## 目录结构

```
theme-plugin/
├── package.json      # 包清单；files: ["lib", "README.md"]
├── README.md
├── lib/
│   ├── index.js      # Host 半部：/api/theme-plugin 路由（磁盘持久化）
│   └── client.js     # 浏览器 bundle：主题注册、设置页、上传/执行/切换/清理
└── examples/         # 可上传的示例主题（不随包发布）
```

## 开发与更新

1. 修改源码副本 `lib/client.js` / `lib/index.js`（如 `theme-plugin/` 目录）
2. 同步到 `~/.dsh/profiles/node_modules/@kongxiangyiren/dhs-theme-plugin/`
3. 刷新页面（Host 半部改动需重启应用）

## 持久化

每个上传的主题以**独立 .js 文件**存储（内容即 dsh client bundle，一个主题一个文件）：

- 主题文件：`~/.dsh/dhs-theme-plugin-themes/<id>-<hash>.js`
- 索引（元数据 + 选中）：`~/.dsh/dhs-theme-plugin.json`

```json
{
  "themes": [{ "id": "my-theme", "name": "my-theme", "file": "my-theme-a1b2c3.js", "active": true }],
  "selected": "ocean"
}
```

`active` 记录启用状态，`selected` 记忆森林绿/海洋蓝等自定义主题选中。旧版内嵌源码的索引会在首次读取时自动拆分为独立文件。
