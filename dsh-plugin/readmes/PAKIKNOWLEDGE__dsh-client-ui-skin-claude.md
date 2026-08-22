# dsh-client-ui-skin-claude

[![awesome · DSH plugin](https://awesome-dsh-plugin.com/badge.svg)](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin) [English](README.en.md) | 中文

Claude 风格的 DSH Web 界面皮肤：暖黑画布、陶橙点缀、衬线 UI，跟随原生亮/暗主题。

![暗色](docs/dark.png) · ![亮色](docs/light.png)

## 特性

- 暖黑（#141413）画布 + Anthropic 陶橙（#d97757）点缀
- 衬线界面字体（Georgia），代码用等宽栈
- 细滚动条、陶橙选中 / 焦点、胶囊徽章
- 亮 / 暗双主题，跟随系统切换

## 安装

从 npm 安装（推荐，预构建免授权）：

```sh
dsh plugin --profile web add @pakiknowledge/dsh-client-ui-skin-claude
```

或从 GitHub 安装：

```sh
dsh plugin --profile web add github:PAKIKNOWLEDGE/dsh-client-ui-skin-claude
```

装完重启 `dsh web`，刷新页面。

## 切换

同一时刻只启用一个皮肤。编辑 `~/.dsh/cordis.patch.yml`：

```yaml
# dsh-skin managed 段之外
- insert:
    - id: ui-skin-claude
      name: '@pakiknowledge/dsh-client-ui-skin-claude'
```

（并把当前启用皮肤的 `disabled: true` 加上。）配置 watcher 几秒内热加载，刷新页面生效。

## 卸载

1. 删除 `~/.dsh/cordis.patch.yml` 里的 `ui-skin-claude` insert 行
2. `dsh plugin --profile web remove @pakiknowledge/dsh-client-ui-skin-claude`
3. 重启 `dsh web`

## 许可

MIT
