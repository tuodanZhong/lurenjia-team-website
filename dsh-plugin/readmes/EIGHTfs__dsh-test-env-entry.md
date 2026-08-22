# dsh-test-env-entry —— DSH 测试环境入口插件

在 DSH Web UI 侧边栏底部（设置上方）添加「测试环境 🧪」入口，点击展开浮层面板：
- **状态卡片**：主实例（3081/反代 3080）、测试实例（3083-3182/反代 3084）、纯环境（dsh-clean-env）的运行状态、端口、可点击访问链接；当前所在环境卡片高亮并标注「(当前)」
- **操作按钮**：**打开正式环境/打开测试环境（互相跳转）** / 启动测试环境 / 停止测试环境（带二次确认）

**互相跳转设计**（2026-08-18 用户反馈优化）：
- 插件装在测试实例上，「打开测试实例」在自己身上没意义 → 改为**动态互跳**：
  `location.port` 在 3083-3182（测试环境）时显示「🏠 打开正式环境」→ 跳 3080；
  反之显示「🧪 打开测试环境」→ 跳 3084
- **主实例方向**：主实例 `~/.dsh` 是 EROFS 只读装不了插件，配套油猴脚本
  `dsh-test-env-jump.user.js`（Tampermonkey 安装，match 3080/3081），在正式环境侧边栏
  注入「🧪 测试环境」按钮 → 新标签打开 3084，实现正式⇄测试双向跳转

数据与操作来自宿主 API：`/api/dsh-test-env/status|start|stop`。

**多测试实例并存**：DSH 测试环境理论上可以同时跑多个实例（如 3083 dsh-test-home、
3085 dsh-sm-test、3090 等，各用独立 DSH_HOME）。面板的「测试实例」卡片会列出当前
全部并存端口，启停操作按目标端口精确匹配，不会误伤其他实例。

## 结构

```
dsh-test-env-entry/
├── package.json          # name=dsh-test-env-entry，dsh.bundle.patch + dsh.client(platform: web)
├── cordis.patch.yml      # insert 注册
├── control.sh            # 启停辅助脚本（插件 detached 调用，避免 pkill 自匹配坑）
├── dsh-test-env-jump.user.js  # 正式环境侧油猴脚本（主实例 EROFS 装不了插件 → 浏览器注入入口）
├── lib/
│   ├── index.js          # host 半边：apply + prefix 路由 /api/dsh-test-env/*
│   └── client.js         # client 半边：sidebar.footer.action slot 注入浮层面板（互跳）
└── test-apply.mjs        # mock ctx 测试（14 项断言，node test-apply.mjs 在安装目录跑）
```

## API

| 路由 | 方法 | 说明 |
|---|---|---|
| `/api/dsh-test-env/status` | GET | 探测主实例/测试实例/反代/纯环境端口状态、URL、脚本路径 |
| `/api/dsh-test-env/start` | POST | 重启测试实例 + 反代（detached，页面断开后重连） |
| `/api/dsh-test-env/stop` | POST | 停止测试实例 + 反代（detached，当前页面断开） |

## 安装（测试实例 dsh-test-home）

1. 插件源码在 `workspace/dsh-test-env-entry/`，已复制到
   `dsh-test-home/profiles/web/node_modules_local/dsh-test-env-entry/`
2. profile `package.json` dependencies 已加 `"dsh-test-env-entry": "file:./node_modules_local/dsh-test-env-entry"`
3. profile `cordis.patch.yml` 已追加 insert（id: dsh-test-env-entry）
4. `node_modules/dsh-test-env-entry -> node_modules_local/dsh-test-env-entry` 软链已建

改源码后同步：`cp lib/*.js control.sh dsh-test-home/profiles/web/node_modules_local/dsh-test-env-entry/{lib/,}/` 然后重启测试实例。

## 验证状态（2026-08-18 实测）

- ✅ host 加载：实例日志 `[dsh-test-env-entry] 已启动`
- ✅ boot entries 含 `dsh-test-env-entry`，`/plugins/dsh-test-env-entry/client.js` → 200
- ✅ `/api/dsh-test-env/status`：主/测试/反代状态正确（3083 与 3085/3090 并存时全部列出）
- ✅ mock 测试 14/14（apply、路由、status 结构、未知路由放行、start/stop 接管）
- ✅ **start 真实验证**：调用后旧实例被杀、新实例起在 3083（父进程=systemd，setsid 生效）、反代 3084 恢复、页面重连、35s 后仍存活
- ✅ **stop 真实验证**：3083 + 3084 精确停止，主实例 3081 不受影响
- ⚠️ client 面板 UI 未在浏览器人工目检（React 组件结构照 session-manager 已验证模式，需页面刷新后人工确认浮层渲染）

## 已知坑（务必遵守）

1. **`pkill -f` 自匹配自杀**：`spawn('setsid', ['bash', '-c', code])` 时，若 code 字符串里含
   `dsh-test-proxy.sh` 等字面量，`pkill -f 'dsh-test-proxy\.sh'` 会匹配到外层 bash 自己的命令行，
   把自己杀掉 → 后续步骤全部不执行。**解法：启停逻辑放独立 control.sh，插件只 spawn
   `bash control.sh start|stop`，命令行不含脚本名**（`[d]` 方括号技巧只防模式文本本身，防不住
   同命令行里其他真实路径字面量）。
2. **JS 模板字符串 `${p}` 插值**：在模板串里拼 shell 变量 `$p` 时必须写 `"$p"`（普通字符串拼接），
   写 `${p}` 会被 JS 求值为 handler 里的 `url.pathname`，生成永远不匹配的 grep。
3. **精确按端口操作**：测试环境可能与 3085/3090 等并存多个实例，启停必须按
   `ps ... --port N` 精确找 PID kill，**不能**用 stop 脚本的 fallback（`grep 'bin.js web' | head -1`
   会误杀其他实例）。
4. **日志路径**：`/tmp` 在沙箱视角不可见，control.sh 日志写到 `workspace/.dsh-test-env-entry.log`。
5. **/tmp 下脚本可执行但跨命令不可见**：调试 detached 时日志务必落 workspace。
6. 沙箱对 bash 命令拉起的后台进程可能回收，插件内一律 `setsid` + `detached: true` + `unref()`。

## 访问

- 测试实例（反代）：http://10.10.10.121:3084
- 主实例（反代）：http://10.10.10.121:3080
