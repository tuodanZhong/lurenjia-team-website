# dsh-bisect-debug

> DeepSeek Harness 插件 · 二分定位 / DSH plugin for bisecting bugs

"bug 在当前代码里，但不知道具体在哪"——用**二分法把搜索范围每轮砍一半**，快速锁定到具体函数/边界/commit。

"Bugs live somewhere in this code, but where?" — **halve the search space every round** with bisection, down to the exact function, boundary, or commit.

## 三种二分法 Three modes

| 模式 | 切什么 | 适用场景 | 需要什么 |
|---|---|---|---|
| **① 代码二分** | 注释/disable 一半代码 | "bug 在当前代码里，缩小到具体函数/组件" | 当前代码 + 可复现的 bug |
| **② 边界二分** | curl/log 沿数据流逐层验证 | "不知道是前端还是后端的锅" | 数据流节点图（≥3 层） |
| **③ commit 二分** | git bisect 切提交历史 | "之前还好好的，不知道哪次改坏的" | git 历史 + 好/坏 commit |

**先判断用哪种**：有明确好/坏时间点 → ③；跨层问题不确定哪层 → ②；确定在当前代码里 → ①（最常用）。

## ① 代码二分（注释/disable，最常用）

```
范围里有 N 个候选（函数/组件/中间件/import）
→ 注释掉后半 N/2 个
→ bug 消失 → 根因在被注释的后半里，继续二分后半
→ bug 还在 → 根因在前半里，继续二分前半
→ 反复直到缩小到具体函数/具体行
```

标记法（方便恢复，不丢原代码）：

```js
// [bisect-disabled] <OriginalComponent />
// <OriginalComponent />
```

注意：有依赖关系的模块不能乱注释（会引入新报错）；注释后验证的是"bug 还在不在"而不是"有没有新报错"；**每轮只注释一半**。

## ② 边界二分（curl/log 沿数据流）

任何 bug 都是"数据在某个环节不再正确"。**沿数据流逐跳验证**，找到数据正确到达的最后一站：

```
上游 ──→ 节点A ──→ 节点B ──→ 节点C ──→ 下游（用户看到的现象）
```

从中间节点验证——midpoint 正确则 bug 在下游，错误则 bug 在上游。不同架构的验证方式：

| 架构 | 验证方式 |
|---|---|
| HTTP 前后端 | `curl` 直连后端 API，绕过前端 |
| 微服务链 | 逐服务 curl 或查日志 |
| 数据库 | DB 客户端直接查 |
| 浏览器渲染 | DevTools Network + Console |
| 函数调用链 | 调用方/被调用方各加 log |

真实案例：点击授权报 405 → 3 个 curl（MCP 登录 200 ✅ / 网关 POST 405 / 下游 API 422 ✅）→ 结论：网关 nginx 拦截 POST。**全程 3 个 curl，0 行代码改动。**

先用**边界二分定层**，再在该层内用**代码二分定函数**。

## ③ commit 二分（git bisect run）

把"好/坏判定"固化成**退出码脚本**（exit 0=好，exit 1=坏，exit 125=跳过），交给 `git bisect run` 全自动收敛：

```bash
# 1. 确认好/坏 commit（good 从 tag/log 推断，不问用户）
git merge-base --is-ancestor <good> <bad>   # 校验 good 在 bad 祖先链上

# 2. 写判定脚本 .temp/bisect-judge.sh
npm run build >/dev/null 2>&1 || exit 125
code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 30 "http://localhost:8080/")
[ "$code" = "200" ] && exit 0 || exit 1

# 3. 全自动跑
git bisect start
git bisect bad <bad-commit>
git bisect good <good-commit>
git bisect run bash .temp/bisect-judge.sh

# 4. 收尾（必做）
git bisect reset
```

注意：base 过期要校验（upstream 合入新文件会误导二分）；启动前工作区必须干净；`git bisect reset` 必做。

## 执行纪律 Discipline

1. **连续改了 ≥2 处还没解决 → 停下，回到二分**（最强反偷懒规则）。
2. **每轮只切一半，测完再切下一半**——禁止一次改多处再测。
3. **现象优先，代码最后**——先用 curl/log/ping 确认现象和边界，不要一上来就读代码。
4. bug 不可复现时调整策略：总是复现 → 直接二分；间歇复现 → 加诊断日志等下一次；只发生一次 → 最大日志注入 + 部署监控。
5. 不好结果也有参考价值——宁可跑完次优解留数据，不中途停下等拍板。

## 跳过二分的情况 When to skip

从现象到根因 ≤ 2 步，不进二分：编译器已指出文件+行号 / 用户明确说了根因 / 改一行就能验证 / 已知版本依赖问题。

## 安装 Install

```sh
# 发布到 npm 后
dsh plugin --profile demo add dsh-bisect-debug

# 或从 GitHub 安装
dsh plugin --profile demo add github:PangYiMing/dsh-bisect-debug
```

## 许可证 License

[MIT](./LICENSE)
