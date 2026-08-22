# dsh-port-guard

> DeepSeek Harness 插件 · 端口占用处置 / DSH plugin for triaging port conflicts

dev server 启动报 `EADDRINUSE: address already in use`——最常见的前置障碍。但**不是所有 EADDRINUSE 都该 kill**。

The classic blocker before any dev server starts. But **not every `EADDRINUSE` should be killed**.

## 核心洞察：EADDRINUSE 有三条路，不是只有"杀"

| 情况 | 占端口的是谁 | 正确动作 |
|---|---|---|
| **A. 自己的、还在正常服务的 dev server** | 上次会话遗留的同项目 dev server | **复用**，比重启快 |
| **B. 别人的项目 / 不该杀的进程** | 另一个项目 / 系统服务 | **换端口绕开**，不抢杀 |
| **C. 确认是僵尸/残留进程** | 已死但端口没释放 / 重复拉起的 | **精确 PID kill** |

**先判断属于哪种，再决定动作。不无脑 kill。**

## 定位 + 取证 Identify & investigate

```bash
./scripts/port-guard.sh 8080
```

脚本会打印占用进程的完整身份信息：

```bash
# 定位
lsof -nP -iTCP:8080 -sTCP:LISTEN
# 身份：启动时刻/运行时长/有无控制终端
ps -o pid,ppid,lstart,etime,tty,%cpu,rss,command -p "$PID"
# 工作目录 → 属于哪个项目
lsof -a -p "$PID" -d cwd -Fn | grep '^n' | sed 's/^n//'
# 子进程（有子进程的别直接杀父，先看树）
pgrep -P "$PID"
```

**判读组合**：

| 观察 | 含义 |
|---|---|
| `PPID=1` | 父进程已退出，被 launchd 收养 —— 孤儿 |
| `tty=??` | 没有控制终端，不是人在终端里跑的 |
| `fd0 → /dev/null`，`fd1/fd2 → 某个 .log` | `nohup cmd > log 2>&1 &` 指纹 → agent/脚本起的 |
| `tty=ttys00X` | 人在终端窗口起的，杀之前更该问一声 |
| `etime` 好几天 + `%cpu 0.0` + `rss` 极小 | 挂了很久的僵尸 watcher（可能 watch 源码目录，某天突然醒来写产物） |

## 三种处置 Three paths

```bash
# A. 复用：确认进程还活着（kill -0 只检测不杀）
kill -0 "$PID" && echo alive

# B. 换端口绕开，不杀别人的
PORT=18080 node index.js

# C. 精确 kill（先 SIGTERM 给优雅退出机会，不行再 SIGKILL）
./scripts/port-guard.sh 8080 --kill
```

## 安全红线 Safety rules

1. **先判断该不该杀**——EADDRINUSE 不等于该杀（复用 > 重启）。
2. **绝不 `killall node` / `pkill -f node`**——精确 PID，不误伤其他正常服务。
3. **PID < 100 绝不杀**——系统进程。
4. **别人的进程不杀**——换端口绕开。
5. **命令行看不懂 / 不确定是什么**——停下报告用户，不擅自杀。

## 安装 Install

```sh
# 发布到 npm 后
dsh plugin --profile demo add dsh-port-guard

# 或从 GitHub 安装
dsh plugin --profile demo add github:PangYiMing/dsh-port-guard
```

## 许可证 License

[MIT](./LICENSE)
