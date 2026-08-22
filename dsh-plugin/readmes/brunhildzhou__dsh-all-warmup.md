# All-WarmUp

[![npm version](https://img.shields.io/npm/v/dsh-all-warmup)](https://www.npmjs.com/package/dsh-all-warmup) [![npm downloads](https://img.shields.io/npm/dm/dsh-all-warmup)](https://www.npmjs.com/package/dsh-all-warmup) [![License: MIT](https://img.shields.io/npm/l/dsh-all-warmup)](LICENSE)

> ⚠️ **状态：已停止开发 | Status: development stopped (ARCHIVED)**
>
> 项目已存档（2026-08）。最终方案满足"第一真实请求不出现 `Let me`"的验收标准。完整过程与实验记录见 [CONCLUSION.md](CONCLUSION.md)。
> The project is archived. The final design meets the acceptance bar (no `Let me` on the first real request). Full history and experiments: [CONCLUSION.md](CONCLUSION.md).

全局"无感提升"热身层插件（DeepSeek Harness）。

任何会话（任何非极简模式、所有层 subagent、压缩后）都自动走同一套流程：

```
用户发第一条真实消息
  ↓
插件把原始消息批次暂存到 next-step inbox
  ↓
第一步以 warmup 锚消息进入模型：
  Minimal 人设 + 当前 preset 的 bash/str_replace_editor 两工具
  + We need answer the next user message.
  ↓
模型回复 → 作为正常 user/assistant 历史保留
  ↓
第二步领取暂存的原始消息批次（最终方案关键）：
  保持 Minimal 人设 + 已验证 Minimal 8 工具头部
  （bash 替换为当前 preset 自己的 schema，保证执行器契约一致）
  ↓
真实 prompt 的第一个模型请求保持在 “We” 轨迹上
  ↓
第三步及以后：
  才恢复用户原模式 system / 完整 tools / runtime 上下文
```

## 安装

### 方式一：bundle 安装（推荐）

```sh
dsh plugin --profile web add dsh-all-warmup
```

或从 GitHub 直接安装：

```sh
dsh plugin --profile web add github:brunhildzhou/dsh-all-warmup
```

### 方式二：手动挂载

- 位置：`$DSH_HOME/profiles/web/all-warmup/`（6 个文件 + 测试）
- 挂载：`$DSH_HOME/profiles/web/cordis.patch.yml` 一行 insert
- 生效方式：配置文件保存后自动热重载（官方 watchUserPatches 契约），无需重启
- 官方包零修改

## 卸载

删掉 `cordis.patch.yml` 里 all-warmup 那一行（或删除文件）→ 保存即失效。

## 配置

```yaml
- insert:
    - id: all-warmup
      name: dsh-all-warmup
      config:
        excludePresets: [minimal]   # 排除清单（默认排除官方极简模式）
        realFirstTools: verified8   # verified8（默认）| native-pair | original
```

## 行为

- **任何模式**（官方 preset 或自定义）都触发；`excludePresets` 可加排除
- **子代理层层热身**：delegationDepth 不短路，每层子代理第一个请求同样走热身
- **压缩后重新热身**：compaction/end 后边界重置，下一条真实消息再走一次
- **首轮形态不变式**：warmup 步骤作为正常 user/assistant 轮次保留；真实消息的第一个模型请求携带这段历史前缀
- **轨迹锚定（v7）**：warmup 步骤 = Minimal 短人设 + 当前 preset 的 bash/str_replace_editor 两工具；**真实消息的第一个请求保持 Minimal 人设 + 已验证 Minimal 8 工具头部**，避免 promotion 后一次性切回完整 Standard 目录把轨迹拉回 `Let me`
- **延迟恢复原模式**：真实消息的第一个请求完成后，才恢复用户原模式 system / 完整 tools / runtime 上下文
- **工具样式同步**：warmup 两工具与 8 工具中的 `bash` 都使用当前 preset 自己的模型 schema，避免 minimal bash（只要求 `command`）与 standard 执行器（要求 `description`）不一致
- **容错**：warmup 路由失败时保留原始批次，绝不阻塞/吃上下文

## 已验证（2026-08）

- 单测 36/36：epoch 阶段跟踪、消息过滤、runtime snapshot 剥离、minimal 工具模板、v7 `realFirstToolSchemas`
- headless（deepseek-v4-pro）：
  - step1 = warmup 锚消息 + Minimal system + 当前 preset 两工具
  - step2 = 真实 prompt + Minimal system + 8 工具头部
  - step3+ = 恢复用户原模式 system/tools/runtime 上下文
  - 对交接文档中的标准评测 prompt，step2 多轮复测中真实 prompt 首个模型请求不再以 `Let me` 开路
- Web 实测：新建 standard session，确认 step1 46 字符 system + 2 工具，step2 46 字符 system + 8 工具，step3 恢复完整 standard system + 31 工具
- Web 热重载：patch / 插件副本更新后新 session 生效

## 实验记录

开发过程中的主要尝试与效果（完整数据见 [CONCLUSION.md](CONCLUSION.md)）：

| 尝试 | 效果 |
|---|---|
| 早期方案：warmup 后立即恢复 full standard | ❌ 真实轮轨迹回到 `Let me`（post-promotion regression） |
| 请求头绑架：header 换 minimal，standard 内容塞进消息 | ❌ 模型对可见内容整体条件化，standard 出现在任何位置都触发 `Let me` |
| resident 工具集 + `dev_tool_search` 按需解锁 | ⚠️ 文件任务全程零 `Let me`；复杂搜索任务仍出现；暴露面最小，架构方向正确 |
| `dev_tool_search` description 四种变体 | ⚠️ 影响工具发现效率与路径；对轨迹无决定性影响；`index` 版最优 |
| minimal 身份句重复 1/5/10 次 | ⚠️ 5 次压住第一步 `Let me`；工具解锁后仍回退；不产生更多 `We` |
| **最终折中方案：第一真实请求保持 Minimal + verified8** | ✅ 满足验收标准：第一真实请求 `Let me=0` |

**核心结论**：轨迹是逐请求重新条件化的结果，不是可继承的会话状态。standard system/tool 内容出现在任何模型可见位置都可能触发 `Let me`。

## 效果评测（初步）

最终方案修复的是"真实 prompt 第一跳"的轨迹锚定。已知边界：
- 真实 prompt 第一跳之后恢复完整 Standard 目录，后续工具轮仍可能出现 `Let me`（社区项目 xiaobright/dsh-anchored-standard 称之为 post-promotion regression）；
- 若要求全程 `We`，需要采用 resident 小工具集 + 按需解锁，而不是在第二轮之后恢复完整 Standard；
- 最接近完整目标的现成方案是 [xiaobright/dsh-anchored-standard](https://github.com/xiaobright/dsh-anchored-standard)（自包含 preset），如未来需要全程 anchored 可优先评估直接采用。

## 后续方向（已停止开发）

项目已存档，不再自行开发。如未来需要：
- [ ] 保持当前线上方案，只满足第一真实请求不出现 `Let me`
- [ ] 需要全程 anchored 时，直接安装并评估 `dsh-anchored-standard` preset
- [ ] 如需再迭代，可基于 [CONCLUSION.md](CONCLUSION.md) 快速恢复上下文

## 使用与署名

MIT License。如果你参考或改编了本插件的代码：

- 欢迎 fork 本项目，在 fork 仓库中改造和发布
- 参考了本插件代码后，如果在你的项目 README 中提及本仓库 作者会在心灵上感谢你哈哈
- 任何分发都必须保留 LICENSE 文件与版权声明（MIT 强制要求）

## 致谢

- [xiaobright/dsh-anchored-standard](https://github.com/xiaobright/dsh-anchored-standard) — epoch 追踪设计与"你是谁"热身概念的来源，改编细节见 NOTICE
- [deepseek-ai/deepseek-harness](https://github.com/deepseek-ai/deepseek-harness) — 插件运行的 Cordis 生态
