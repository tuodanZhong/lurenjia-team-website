# DeepSeek Harness 轨迹图谱

[English](README.md)

**dsh-plugin-trajectory-graph** 会在 DeepSeek Harness 原有的“对话”和“轨迹”旁增加“图谱”标签，把结构化轨迹快照投影为从左到右的交互式执行图。插件只改变轨迹的查看方式，不修改任务、会话或模型执行过程。

![真实会话中的逐 Turn 轨迹图谱，展示并行工具分支与汇合关系](docs/images/trajectory-graph-showcase.png)

## 主要功能

- 提供会话总览和相互独立的逐 Turn 图谱，默认选择最新 Turn。
- 使用 User、Context、Model、Tool、Tool Group、Sub-tool、Agent、Compaction、Final、Retry、Error 等语义节点。
- 同一 Step 的并行工具调用纵向分支，并汇合到下一 Model 或 Final 节点。
- 支持搜索、节点类型筛选、折叠/展开、缩放、适应画布和加载更早轨迹。
- 在画布空白区域按住鼠标左键即可向任意方向拖动画布，滚动鼠标滚轮会以指针位置为中心缩放；原生滚动条仍然保留。
- 搜索、筛选、折叠、节点选择和缩放状态按 Turn 隔离。
- 根据节点类型提供不同详情；快照包含相关数据时，工具节点可以查看参数、结果、Schema、时序、原始数据和来源引用。
- 会话执行期间实时更新，仅有流式文字变化时复用稳定布局。
- 保守构图：Harness 没有提供持久证据时，不猜测代理委派或因果边。
- 完全本地展示，不上传轨迹数据，也不修改会话。

## 环境要求

| 组件 | 要求 | 用途 |
| --- | --- | --- |
| Node.js | 20或更高版本 | 插件构建和受支持的 DeepSeek Harness 运行环境要求。 |
| DeepSeek Harness | 0.1.0-rc.6 或 0.1.0-rc.7 | 0.3.0 已针对这两个版本的轨迹契约完成验证；下方示例默认使用 rc.7。 |
| pnpm | 10或更高版本 | DSH插件命令会调用 pnpm 完成安装，因此它必须位于系统 PATH。 |
| 浏览器 | 当前版本的 Chromium 内核浏览器 | 用于访问 DeepSeek Harness Web UI。 |

检查本机环境：

~~~powershell
node --version
npx --yes @deepseek-ai/dsh@0.1.0-rc.7 --version
pnpm --version
~~~

如果系统提示找不到 pnpm：

~~~powershell
npm install --global pnpm@10
~~~

## 安装插件

1. 从仓库的 [GitHub Releases](https://github.com/TangRj-Git/trajectory-graph/releases) 页面下载 **dsh-plugin-trajectory-graph-0.3.0.tgz**。
2. 把 TGZ 文件保存在一个长期不移动的本地目录中，不要解压。
3. 执行下面的命令，把示例路径替换成实际下载位置，将插件安装到默认 **web** Profile：

~~~powershell
npx --yes @deepseek-ai/dsh@0.1.0-rc.7 plugin --profile web add "C:\你的目录\dsh-plugin-trajectory-graph-0.3.0.tgz"
~~~

安装成功时，终端会在 dependencies 下显示 **dsh-plugin-trajectory-graph**，并以 **Done** 结束。

可以检查 Harness 最终组合配置中是否包含插件：

~~~powershell
npx --yes @deepseek-ai/dsh@0.1.0-rc.7 web --dump-config | Select-String "trajectory-graph"
~~~

## 启动和使用

在默认3080端口启动 web Profile：

~~~powershell
npx --yes @deepseek-ai/dsh@0.1.0-rc.7 web --port 3080
~~~

打开 **http://127.0.0.1:3080**，选择一个存在轨迹数据的会话，然后切换到：

~~~text
对话  |  轨迹  |  图谱
~~~

使用 Turn 导航器可以单独查看一次用户请求，也可以选择“会话总览”查看整个会话。点击节点会打开结构化详情。在画布空白区域按住鼠标左键可以横向或纵向拖动，滚动鼠标滚轮会以指针位置为中心缩放。原生滚动条以及工具栏中的缩放和“适应”按钮仍然可用；工具栏还可以搜索内容、开关节点类型或折叠嵌套分组。

每个 Profile 只需安装一次。正常关闭和重新启动 Harness 不需要重复安装。

## 更新和卸载

卸载当前版本：

~~~powershell
npx --yes @deepseek-ai/dsh@0.1.0-rc.7 plugin --profile web remove dsh-plugin-trajectory-graph
~~~

更新时先卸载旧版，再下载新的 TGZ，使用同样的插件安装命令安装，最后重新启动 Harness。

## 兼容性

**0.3.0** 已支持并验证 DeepSeek Harness **0.1.0-rc.6** 和 **0.1.0-rc.7**，安装和启动示例默认使用 rc.7。插件以结构化方式读取内置 trajectory 快照。其他 Harness 版本可能改变数据契约，因此在声明兼容新版本之前，需要重新构建、执行完整测试并进行页面验收。

## 开发技术栈

| 范围 | 组件 |
| --- | --- |
| 主程序集成 | @deepseek-ai/cordis、cordis.patch.yml |
| Harness客户端契约 | 兼容 DeepSeek Harness rc.6 和 rc.7 的 locale、runtime、slots、conversation、trajectory 包；开发依赖使用 rc.7 |
| 界面 | React 18、React DOM 18 |
| 投影与布局 | TypeScript 语义投影器、确定性分层 DAG 布局、筛选和逐 Turn 状态 |
| 构建 | TypeScript 5.9、esbuild |
| 测试 | Vitest、Testing Library、user-event、jsdom |
| 包管理 | pnpm 10或更高版本 |

安装开发依赖并验证项目：

~~~powershell
npx pnpm@10 install
npm test
npm run typecheck
npm run build
~~~

生成可分发的插件安装包：

~~~powershell
npm run pack:plugin
~~~

安装包生成到：

~~~text
dist/dsh-plugin-trajectory-graph-0.3.0.tgz
~~~

## 项目结构

~~~text
src/client.tsx                          注册“图谱”会话视图
src/components/TrajectoryGraphView.tsx 协调 Turn 状态、筛选、布局和详情
src/components/TurnNavigator.tsx       会话总览和逐 Turn 导航
src/components/GraphNodeCard.tsx       语义节点卡片和节点操作
src/components/GraphDetailsPanel.tsx   按类型组织的节点详情标签
src/graph/snapshot.ts                  验证 Harness 轨迹快照
src/graph/turns.ts                     把数据划分成相互独立的 Turn
src/graph/projector.ts                 把事件和请求投影为语义 DAG
src/graph/layout.ts                    计算确定性的分层分支位置
src/graph/filter.ts                    搜索、类型筛选和折叠可见性
scripts/build.mjs                      生成 Harness 浏览器端 bundle
tests/                                 投影、布局、UI、契约和性能测试
~~~

**cordis.patch.yml** 会把插件插入内置 Web bundles 之后。Host入口保持最小化；**src/client.tsx** 注册本地化的 trajectory-graph 会话视图，并从当前会话读取已有的 trajectory 快照。

## 当前限制

- 这是执行轨迹查看器，不是可以编辑节点的工作流设计器。
- Harness rc.6 和 rc.7 并非在所有执行路径中都提供持久可靠的 Agent 身份，因此插件不会根据工具名称或模型文本推断 Agent 分支。
- 超大轨迹仍可能横向延伸，建议结合逐 Turn 导航、搜索、筛选、折叠和“适应”按钮使用。
- 没有结构化轨迹快照的会话无法生成图谱节点。

## 隐私和安全

插件运行在本地 DeepSeek Harness Web UI 中，仅为展示读取会话已有的轨迹快照。它不会上传数据、调用外部统计服务、修改提示词、改变工具调用或修改会话历史。

## 许可证

[MIT](LICENSE) © 2026 TangRj-Git
