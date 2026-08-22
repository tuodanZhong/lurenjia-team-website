# dsh-whale-bg

[English](README.md) | 简体中文

一个非官方的 DeepSeek Harness Web UI 背景插件，将 DeepSeek 鱼形轮廓重建为
由不同尺寸粒子组成的动态效果。

<picture>
  <source
    type="image/webp"
    srcset="https://raw.githubusercontent.com/gooosie/dsh-whale-bg/main/docs/assets/dsh-whale-bg-preview.webp"
  >
  <img
    src="https://raw.githubusercontent.com/gooosie/dsh-whale-bg/main/docs/assets/dsh-whale-bg-preview.gif"
    alt="dsh-whale-bg 粒子效果动画预览"
  >
</picture>

> 这是一个社区项目，与 DeepSeek 不存在从属、维护或背书关系。鱼形几何数据
> 复用自采用 MIT 许可证的 DeepSeek Harness 仓库，详情参见
> [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

主要功能：

- **入场动画**——粒子从散落状态逐渐组装成鱼形
- **待机游动**——轮廓边缘保持松散，尾部带有行波效果
- **悬停交互**——带三次衰减和单粒子角度扰动的径向推力
- **手电筒照明**——鱼形平时近乎不可见，光线随光标移动并照亮附近粒子
- **主题适配**——浅色主题使用正片叠底和深蓝色，深色主题使用滤色和辉光
- **30 FPS 渲染**——限制装饰层的资源开销

## 兼容性

本插件基于 `@deepseek-ai/dsh@0.1.0-rc.6` 的 Web profile 开发并完成测试。
DeepSeek Harness 目前仍处于开发者预览阶段，后续版本可能需要同步调整插件。

## 安装

请先按照 [DeepSeek Harness 官方说明](https://github.com/deepseek-ai/deepseek-harness#run)
安装 `dsh` 命令，然后将已发布的插件安装到 DSH 的 Web profile：

```sh
dsh plugin --profile web add dsh-whale-bg@0.1.0
dsh web
```

如需从源码目录安装：

```sh
git clone https://github.com/gooosie/dsh-whale-bg.git
cd dsh-whale-bg
npm ci
npm run check
dsh plugin --profile web add .
dsh web
```

`dsh web` 固定启动名为 `web` 的 profile，因此插件必须安装到该 profile。
从源码安装时，DSH 会链接到当前源码目录；插件保持安装期间，请勿移动或删除
这个目录。

`dsh.bundle` 补丁会插入 `whale-bg` 配置行，`dsh.client` 声明则会将浏览器端
模块挂载为 `/plugins/dsh-whale-bg/client.js`。

可以通过以下命令检查合成后的配置：

```sh
dsh web --dump-config
```

卸载插件：

```sh
dsh plugin --profile web remove dsh-whale-bg
```

## 开发

```sh
npm ci
npm run build   # tsdown -> ESM Host + DSH ModuleLoader Client
npm test        # 检查清单、入口、模块交接、依赖注入和主题 API
npm run check   # 严格类型检查 + 全新构建 + 包级验证
npm run watch
```

## 项目结构

```text
dsh-whale-bg/
├── package.json       # dsh.bundle 与 dsh.client 清单
├── cordis.patch.yml   # 插入 whale-bg 配置层
├── tsdown.config.ts   # ESM Host 与 CJS Client 构建配置
├── scripts/            # 包级回归验证
├── README.md           # 英文文档
├── THIRD_PARTY_NOTICES.md
└── src/
    ├── index.ts       # 无行为的 Host 入口，用于 Loader 扫描
    └── client.ts      # 鲸鱼粒子背景的浏览器端实现
```

## 参数调整

所有可调参数均位于 `src/client.ts`：

| 参数 | 位置 | 默认值 |
| --- | --- | --- |
| 粒子密度 | `SAMPLE_SIZE`、`MODEL_STEP` | 60、0.18 |
| 鱼形尺寸与位置 | `computeLayout` | 不超过 720×540，居中 |
| 手电筒半径 | `lightDistance / 7` | 7 个模型单位 |
| 待机最低可见度 | `light = 0.05 + …` | 0.05 |
| 鼠标推力半径 | `distance < 4.9` | 4.9 个模型单位 |
| 帧率 | `1000 / 30` | 30 FPS |

## 贡献与许可证

欢迎参与贡献，具体要求参见 [CONTRIBUTING.md](CONTRIBUTING.md)。项目代码采用
[MIT License](LICENSE)，第三方资产说明和非官方声明参见
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
