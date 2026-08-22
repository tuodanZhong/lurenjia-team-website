# dsh-plugin-origin-split

把 DeepSeek Harness Web 端「设置 → 插件」里的插件列表按来源分成两个标签页:**原生插件**(随 Harness 发布)与**自定义插件**(用户自己安装,包括自己编写的插件)。

## 安装

在 profile 目录(如 `~/.dsh/profiles/<name>`)安装依赖:

```bash
pnpm add dsh-plugin-origin-split
```

在 profile 的 `cordis.patch.yml` 追加一条 insert,让宿主 Loader 加载该包(浏览器端 `dsh.client` 声明由此被扫描到):

```yaml
- insert:
    - id: plugin-origin-split
      name: 'dsh-plugin-origin-split'
```

重启 dsh 并刷新 Web 页面。

## 使用

打开 **设置 → 插件**,点击「原生插件」或「自定义插件」标签页。

- **自定义插件**:按"包"列出你在 profile 里手动安装的插件(来自 `package.json` 的 dependencies/bundles 与补丁条目),如 `@tt-a1i/archify-dsh`、`dsh-plugin-origin-split`。每张卡片显示模块名、版本、来源类型(依赖/包)与其 Loader 条目。
- **原生插件**:列出所有随 Harness 发布的 Loader 条目,含模块短名、条目 ID、启停状态与 Cordis 挂载状态。

## 分类规则

模块名以 `@deepseek-ai/` 开头(含 `dsh-*`、`cordis-plugin-*` 等 Harness 自带包)或 `cordis:` 开头 → 原生;其余(如 `dsh-cc-tui`、`dsh-working-activity`)→ 自定义。

## 工作原理

- 宿主端:`webServer` 注册 `/plugins/dsh-plugin-origin-split/manual.json`,读取当前 profile 的 `package.json`(依赖 + `dsh.profile.bundles`)与 Loader 条目,返回手动安装的包列表。
- 客户端:「自定义」标签页优先拉取该路由;路由不可用(如宿主端尚未重载)时回退到 `remote.pluginInventory` 的条目分类。「原生」标签页始终按条目分类渲染。

## License

MIT
