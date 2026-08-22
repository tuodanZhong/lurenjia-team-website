# DSH 插件集合（dsh-plugins）

DeepSeek Harness（dsh）官方规范开发的插件集合。每个子目录是一个独立的**组合包（bundle）**——带 `dsh.bundle` manifest 的 npm 包，通过官方 `dsh plugin` 命令安装进 profile。

## 收录的插件

| 插件 | 版本 | 目录 | 说明 |
|---|---|---|---|
| **dsh-vision** | 0.2.2 | [`dsh-vision/`](dsh-vision/) | `vision_read` 工具：给纯文本主模型"借眼睛"，SenseNova 主 + Zhipu GLM 兜底双模型回退链（0.2.2 修复 providerOrder 空数组 bug） |
| **dsh-sensenova-image** | 0.2.2 | [`dsh-sensenova-image/`](dsh-sensenova-image/) | `generate_image` 工具：通过商汤 SenseNova U1 Fast 生成无水印图片并保存到本地（0.2.2 修复取消/异常时报 `[object Object]` 的问题） |
| **dsh-client-stats-decimal** | 0.2.2 | [`dsh-client-stats-decimal/`](dsh-client-stats-decimal/) | 统计行缓存命中率显示两位小数（98.00%）——官方 Slot 机制 shadow 内置 stats 行 |

## 每个插件的标准结构（官方 bundle 规范）

```
<plugin-name>/
├── package.json          # dsh.bundle manifest: { "bundle": { "patch": "./cordis.patch.yml" } }
├── cordis.patch.yml      # 配置层：插件行按包名引用（name: <plugin-name>）
├── lib/                  # 插件模块（ESM，"files" 与 "main" 指向这里）
└── packs/                # 分发产物（npm pack 生成的 tgz，无需构建即可安装）
```

## 安装（官方方式）

dsh 官方安装入口是 `dsh plugin --profile <name> <args...>`，在 profile 目录内转发给 pnpm。首次使用会自动初始化 profile（`@deepseek-ai/dsh-base` 作为第一个 bundle），声明了 `dsh.bundle` 的包会被追加进 `dsh.profile.bundles`。

**方式 1：tarball（推荐，无需构建）**

```sh
cd dsh-plugins
dsh plugin --profile web add ./dsh-vision/packs/dsh-vision-0.2.2.tgz
dsh plugin --profile web add ./dsh-sensenova-image/packs/dsh-sensenova-image-0.2.2.tgz
dsh plugin --profile web add ./dsh-client-stats-decimal/packs/dsh-client-stats-decimal-0.2.2.tgz
```

**方式 2：仓库目录（源码 checkout，pnpm 链接）**

```sh
dsh plugin --profile web add ./dsh-vision
dsh plugin --profile web add ./dsh-sensenova-image
dsh plugin --profile web add ./dsh-client-stats-decimal
```

**方式 3：git 托管（从 git 安装拉取的是源码，需 `prepare` 构建脚本 + `allowBuilds` 授权，详见[官方文档](https://deepseek-harness.github.io/deepseek-harness/develop/basic/publish)）**

```sh
dsh plugin --profile web add github:you/dsh-plugins#<sha>
```

**验证已挂载**：

```sh
dsh --profile web --dump-config
# 输出中应出现三个 bundle 层：
#   # == dsh-vision
#   # == dsh-sensenova-image
#   # == dsh-client-stats-decimal
```

**卸载**：

```sh
dsh plugin --profile web remove dsh-vision
dsh plugin --profile web remove dsh-sensenova-image
dsh plugin --profile web remove dsh-client-stats-decimal
```

## 配置与密钥

- **dsh-vision**：`SENSENOVA_API_KEY`、`ZHIPU_API_KEY`（任一即可）；插件行 config 见各插件 README
- **dsh-sensenova-image**：`SENSENOVA_API_KEY`（与 dsh-vision 共用同一个商汤 key）
- 插件行 config 可在你的 profile `cordis.patch.yml` 中按 id 覆盖（后应用层按行胜出，patch 替换整行 config）

**密钥填写（以 dsh-vision 为例）** —— 编辑 `$DSH_HOME/.credentials.yaml`（默认 `~/.dsh/.credentials.yaml`）：

```yaml
SENSENOVA_API_KEY: sk-你的商汤key
ZHIPU_API_KEY: 你的智谱key.id格式
```

> 两个 key 任一即可；都配则回退链完整。密钥每次请求时现解析（凭据库 → 环境变量），**改完无需重启**即可生效。

## 加载顺序（官方机制）

生效配置按层组合：profile 的 `dsh.profile.bundles` 列表（按加入顺序）→ profile 的 `cordis.patch.yml` → home 级 `$DSH_HOME/cordis.patch.yml` → 每个 `--patch` overlay。后应用层按行胜出。

## 发布 / 分发

- **npm registry**：`npm publish`（需在发布时构建好 `lib/`）→ 用户 `dsh plugin add <包名>` 安装预构建代码
- **tarball**：`npm pack` → 用户 `dsh plugin add ./<包>.tgz`（本仓库 `packs/` 已提供）
- **git**：需要 `prepare` 脚本（从源码构建 lib/），用户需 `allowBuilds` 授权

## 更新日志

见 [CHANGELOG.md](CHANGELOG.md)。最新：**dsh-vision 0.2.2**（2026-08-15）修复 `providerOrder` 空数组默认值导致的 `VISION_NO_PROVIDER` 报错——0.2.1 及更早版本的用户请升级并重启 dsh。

## 第三方声明

这些插件是第三方自研，**非 deepseek-ai 官方发布**。安装插件等于在你的机器上运行第三方代码，权限与你自己相同——装之前请先阅读源码。

## License

MIT（根目录与各插件目录各一份）
