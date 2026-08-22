# DSH Skin Universe

中文 | [English](README.en.md)

![DSH Skin Universe 初恋时刻主题](docs/screenshots/theme-first-love.png)

面向 DeepSeek Harness Web 的完整功能扩展与主题合集。保留任务看板、Git 图谱、右侧文件/变更面板、SSH、移动端远程、主题联动桌宠、实时令牌统计和统一设置中心，并只提供五套定制主题。

这是一个由 [SpringBrand](https://springbrand.ai) 开源的项目。更多 DeepSeek Harness 相关内容见 [SpringBrand DeepSeek Harness](https://springbrand.cloud/deepseek-harness)。

四套 IP 主题均标注为“非官方同人主题”，与相关权利方不存在隶属、授权、赞助或背书关系。完整声明见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

## 五套主题

### 初恋时刻（First Love）

三张成年女性电影感肖像自动淡入轮换，搭配雨后自然光、清透玻璃面板和专属初恋伙伴。浅色面板经过专门减薄，背景人物和环境保持清晰，同时保留输入区可读性。

![初恋时刻](docs/screenshots/theme-first-love.png)

### 蛛网都市（Spider Verse）

**非官方同人主题。** 城市高空、红蓝英雄配色和蛛网纹理构成漫画电影氛围。

![蛛网都市](docs/screenshots/theme-spider-verse.png)

### 宝可梦黄昏（Pokemon Sunset）

**非官方同人主题。** 金色原野、旅途夕阳和伙伴剪影构成温暖冒险氛围。

![宝可梦黄昏](docs/screenshots/theme-pokemon-sunset.png)

### 木叶忍界（Naruto Konoha）

**非官方同人主题。** 木叶街道、火影岩和橙黑忍者配色构成热血界面。

![木叶忍界](docs/screenshots/theme-naruto-konoha.png)

### 鬼灭藤夜（Demon Slayer Night）

**非官方同人主题。** 藤花月夜、羽织纹样和深靛夜景构成沉浸式夜间界面。

![鬼灭藤夜](docs/screenshots/theme-demon-slayer-night.png)

## 完整功能

### 皮肤中心

设置中心内仅展示上述五套主题。支持亮/暗预览、即时试穿、退出还原、一键应用和背景遮挡调节。

![仅含五套主题的皮肤中心](docs/screenshots/feature-skin-center.png)

### 任务看板

五列状态覆盖待规划、待办、进行中、已完成和已失败；任务可交给真实 DSH 会话执行，也支持 cron 定时执行。

![任务看板](docs/screenshots/feature-task-board.png)

### SSH 远程连接

支持密钥/密码认证、导入 `~/.ssh/config`、Web 终端、SFTP、端口转发、集群执行和 Agent 直连。

![SSH 远程连接](docs/screenshots/feature-ssh.png)

### 移动端远程

扫码或复制链接后，可在移动端查看与新建会话、收发消息、切换模型、调整思考强度和权限。局域网与公网隧道模式均保留。

| 桌面配对 | 移动端布局 |
| --- | --- |
| ![移动端配对](docs/screenshots/feature-mobile-remote.png) | ![移动端布局](docs/screenshots/feature-mobile-layout.png) |

### Git 图谱、右侧面板与实时状态

保留分支/提交图谱、文件预览、源码/预览切换、SCM stage/unstage/discard、面板宽度持久化、桌面宠物与实时 token/TPS/缓存统计。

![右侧文件与变更面板](docs/screenshots/feature-right-panel.png)

## 安装

DSH 插件安装到 profile；`dsh web` 使用 `web` profile。

### 从 npm 安装（推荐）

包已发布，装的是预构建产物，不需要克隆、不需要本地构建，也不会遇到下面那条 `allowBuilds` 提示：

```sh
dsh plugin --profile web add @linxin666/dsh-web-ui-all
dsh web
```

只要皮肤，不要功能插件：

```sh
dsh plugin --profile web add @linxin666/dsh-skins
```

### 从源码安装

需要 Node.js >= 22 与 pnpm。改代码或跑本仓库脚本时用这条路径。

```sh
# 1. 克隆仓库
git clone https://github.com/springbrand-lab/dsh-skin-universe.git
cd dsh-skin-universe

# 2. 安装依赖并构建
pnpm install
pnpm -r build

# 3. 链接全部功能包并注册聚合插件
node scripts/link-profile.mjs
dsh plugin --profile web add link:$(pwd)/packages/dsh-web-ui-all

# 4. 启动
dsh web
```

只安装皮肤聚合包：

```sh
node scripts/link-profile.mjs
dsh plugin --profile web add link:$(pwd)/packages/dsh-skins
```

命令行切换主题：

```sh
node scripts/dsh-skin list
node scripts/dsh-skin use first-love
node scripts/dsh-skin use spider-verse
node scripts/dsh-skin use pokemon-sunset
node scripts/dsh-skin use naruto-konoha
node scripts/dsh-skin use demon-slayer-night
node scripts/dsh-skin use official
```

若首次安装提示 `ERR_PNPM_IGNORED_BUILDS`，按提示把 `cloudflared`、`cpu-features`、`ssh2` 加入 profile 的 `pnpm-workspace.yaml` `allowBuilds` 后重试。

## 验证与卸载

安装后重启 `dsh web`，侧边栏应出现“任务看板”和“SSH”，设置页的 Skin Center 应显示 `5`。也可执行 `dsh --profile web --dump-config` 检查挂载配置。

```sh
dsh plugin --profile web remove @linxin666/dsh-web-ui-all
```

技术细节见 [docs/plugins.md](docs/plugins.md)。

## 来源与版权

| 包 | 来源 | 版权 |
| --- | --- | --- |
| 功能插件与原始框架 | `zhu1090093659/dsh-web-ui` | BSD-3-Clause，保留上游版权声明 |
| 五套主题 | SpringBrand Skin Lab | BSD-3-Clause（主题代码）；IP 主题为非官方同人作品 |

from [springbrand deepseek harness plugin](https://springbrand.ai/deepseek-harness)
法律声明与第三方归属见 [LICENSE](LICENSE) 和 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
