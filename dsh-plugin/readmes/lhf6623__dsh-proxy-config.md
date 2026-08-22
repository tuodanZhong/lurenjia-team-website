# dsh-proxy-config

DeepSeek Harness 代理配置插件：把 HTTP / SOCKS 代理写入 process.env，让插件安装时
spawn 的 pnpm/git 子进程自动继承代理（解决国内 codeload.github.com 被墙限速导致的安装卡死）。
带设置页，配置持久化到 $DSH_HOME/proxy-config.json。

## 安装

    dsh plugin --profile web add github:lhf6623/dsh-proxy-config

安装后重启 harness，在 设置 → 插件 → 网络代理 里启用并填写代理地址。

## 配置

- enabled: 是否启用
- http: HTTP/HTTPS 代理地址，如 http://127.0.0.1:7890
- socks: SOCKS 代理地址，如 socks5://127.0.0.1:7891

代理变量会注入 process.env；另设 no_proxy 让本机/回环地址（127.0.0.1 / localhost / ::1）直连、不绕代理。

## 卸载 / 清理

卸载前请先在「网络代理」设置页点「清除配置」，再执行：

    dsh plugin --profile web remove dsh-proxy-config

「清除配置」会删除 $DSH_HOME/proxy-config.json 并移除进程内的代理变量；否则配置会残留。
插件被停止时也会自动清除进程内的代理变量。
