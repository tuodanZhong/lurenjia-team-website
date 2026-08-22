# dsh-pet — 桌面宠物插件（宠物 + 实用工具）

[![Awesome DSH Plugin](https://awesome-dsh-plugin.com/badge.svg)](https://awesome-dsh-plugin.com)

一个 DeepSeek Harness (dsh) WebUI 客户端插件：右下角桌面宠物，**宠物陪伴 + 实用工具**二合一——精灵图多帧动画、agent 状态联动、自由拖拽、闹钟、番茄钟、皮肤分离。

> ⚠️ 皮肤版权：`assets/zhuangfangyi.png` 与 `zhuangfangyi.sheet.png` 为默认皮肤（来自用户提供的图片，透明化 + AI 动作帧处理）。若为游戏官方立绘/同人图，**仅限个人使用，勿商用**。换皮肤时请使用你有权使用的素材。

## 效果图

![精灵图动画系统](docs/screenshot-states.png)

![使用场景](docs/screenshot-scene.png)

## 特性

- **精灵图动画**：5 状态 × 32 帧（idle/thinking/working/done/sleeping），canvas 逐帧渲染（无重影闪烁），帧率可调 1-32
- **agent 状态联动**：agent 开始 → 思考（1.8s）→ 工作（弹跳）→ 完成（庆祝跳跃）
- **自由拖动**：pointer events 拖拽，松手自动保存位置
- **闹钟**：每天/一次两种模式；"已触发"标记持久化，重启不重复响
- **番茄钟**：工作/休息循环，宠物脚下倒计时，到点通知+宠物说话；**状态持久化**（墙钟时间驱动，刷新/重启不重置）
- **便签**：国风祥云告示牌（白底绿框+四角祥云），宠物侧边循环显示
- **久坐/喝水提醒**：间隔提醒（持久化防重置），到点通知+宠物说话
- **提醒互斥**：闹钟/番茄钟/提醒共用 10s 冷却，防通知轰炸
- **右键设置面板**：启用/大小/位置/透明度/**皮肤下拉+预览**/台词/帧率/入睡秒/闹钟/番茄钟/便签/提醒
- **皮肤分离**：素材走 `/pet-assets/<文件名>`，皮肤下拉选择 + 自定义输入 + 实时预览
- **纯前端驱动**：设置存 `localStorage`，不依赖 host settings 服务

## 安装

```bash
./install.sh && dsh web
# 或 DSH_PROFILE=~/.dsh/profiles/其他名字 ./install.sh
```

install.sh 自动：复制插件包到 profile 的 node_modules → 从 dsh 安装树复制依赖（schemastery 零依赖叶子）→ 注册插件行 → 验证 loader 解析。

> 包声明 `dsh.bundle.patch`，未来 npm 发布后可直接 `dsh plugin --profile web add dsh-pet`。

## 交互

- **左键点击**：说话（随机台词气泡）
- **右键**：设置面板
- **拖拽**：任意位置
- **agent 跑任务**：思考→工作→庆祝动画
- **闲置 60s**（可配）：入睡；点击/拖拽唤醒

## 配置项（localStorage: `dsh-pet:settings`）

| 字段 | 默认 | 说明 |
|---|---|---|
| enabled / width / right / bottom / opacity | true / 180 / 24 / 20 / 1 | 基础外观 |
| image | zhuangfangyi.sheet.png | 皮肤（下拉 + 自定义） |
| lines | 默认台词 | 随机台词 |
| fps | 6 | 精灵图帧率 |
| sleepAfter | 60 | 闲置入睡秒（0=禁用） |
| alarmEnabled / alarmTime / alarmMessage / alarmMode | false / 09:00 / 默认 / repeat | 闹钟（repeat=每天 / once=一次） |
| pomodoroEnabled / pomodoroWork / pomodoroBreak | false / 25 / 5 | 番茄钟 |

## 项目结构

```
dsh-pet/
├── package.json        # dsh.client + dsh.bundle.patch
├── cordis.patch.yml    # bundle patch（插件行）
├── lib/
│   ├── index.js        # host 半部：/pet-assets 素材路由
│   └── client.js       # 浏览器半部：宠物/动画/拖拽/闹钟/番茄钟/设置面板
├── assets/             # 皮肤（zhuangfangyi.png 单图 + zhuangfangyi.sheet.png 精灵图）
├── scripts-gen-sheet.py # 程序化生成精灵图（Pillow）
├── prepare_sheet.py    # AI 动作条拆帧拼精灵图
├── deps-copy.py        # 依赖复制助手
├── install.sh / uninstall.sh
└── README.md
```

## 精灵图格式

- 网格：32 列 × 5 行（行 = 状态：idle/thinking/working/done/sleeping）
- 文件名含 `.sheet.` 即视为精灵图（如 `xxx.sheet.png`）
- 生成：`python3 scripts-gen-sheet.py`（程序化）或 `python3 prepare_sheet.py`（AI 动作条拆帧）
- AI 动作条生成：`gen_strips.sh`（mmx + subject-ref + 自动质检重试）

## 卸载

```bash
./uninstall.sh && dsh web
```

## 已知说明

- 设置存 localStorage（按浏览器）；单机个人使用最佳
- 精灵图 thinking/done 为 AI 帧，其余程序化——后续可替换更高质量动作帧
