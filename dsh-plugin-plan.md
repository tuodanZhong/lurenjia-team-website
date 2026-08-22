# DSH 插件市场（/dsh-plugin）建设计划

> 目标：在 ip.midonghub.com/dsh-plugin 上线一个「路人甲风格」的 DSH 插件小市场。
> 参考 dsh.so/zh 的感觉，但只做 MVP：搜索、登录、管理员后台（访问统计）。
> 设计风格沿用主站：暖白、克制、赤陶色点缀，文案讲人话。

---

## 更新（已按原型风格补齐，2026-08）

已实现并本地验证：
- **P1** 市场静态页（index.html）+ 1581 个插件数据 + 前端搜索 ✅
- **P2** FastAPI 后端（api/main.py）：注册/登录/退出、httpOnly session、访问统计上报、插件 API ✅
- **P3** 管理后台（admin.html）：今日/7日/30日 PV·UV、30 天趋势折线图（Chart.js）、页面排行、插件上下架/编辑/实测标记/删除、用户列表 ✅
- 登录限流（每 IP 每分钟 10 次尝试）、密码 PBKDF2 加盐哈希 ✅
- 主站导航已加「插件市场」入口 ✅
- 部署脚本 deploy-dsh-plugin.sh（systemd + Caddy 反代 /dsh-plugin/api/* → 127.0.0.1:8787）✅ 待执行

### 部署（你确认后执行）
1. 在本机项目根目录：`bash dsh-plugin/deploy-dsh-plugin.sh`
2. 可选首次管理员密码：`DSH_ADMIN_PASSWORD=你的密码 bash dsh-plugin/deploy-dsh-plugin.sh`
3. 完成后访问 https://ip.midonghub.com/dsh-plugin/
4. 查管理员初始密码：`sudo journalctl -u dsh-plugin-api | grep 初始密码`（首次建库时输出）

### 待办/已知限制
- data.db 在服务器上生成，重建代码不会覆盖已有数据（plugins 首次启动导入，之后靠后台管理）
- 普通用户登录目前只识别身份（记录登录），提交/收藏等留待后续
- 访问统计的 UV 按匿名访客 id（localStorage）+ IP 哈希去重，够用但不精确
