#!/usr/bin/env bash
# 路人甲官网一键部署脚本
# 用法：在本机（脚本与 luren-site.tar.gz 同目录）终端执行  bash deploy.sh
# 作用：上传站点 -> 远程解压 -> 自动挑一个空闲端口 -> 用独立 systemd 服务常驻
#      只占用挑中的那个空闲端口，不动服务器上已有的任何服务/端口。
set -e

SERVER="ubuntu@43.143.122.43"
PKG="luren-site.tar.gz"
REMOTE_DIR="/home/ubuntu/luren-website"

if [ ! -f "$PKG" ]; then
  echo "找不到 $PKG，请把本脚本和 luren-site.tar.gz 放在同一目录再运行。"
  exit 1
fi

echo "[1/3] 上传站点包到服务器 /tmp ..."
scp "$PKG" "$SERVER:/tmp/luren-site.tar.gz"

echo "[2/3] 远程解压 + 探测空闲端口 + 启动服务 ..."
ssh -t "$SERVER" 'bash -s' <<'REMOTE'
set -e
REMOTE_DIR="/home/ubuntu/luren-website"
mkdir -p "$REMOTE_DIR"
tar -xzf /tmp/luren-site.tar.gz -C "$REMOTE_DIR"
rm -f /tmp/luren-site.tar.gz

# 固定使用 8088 端口（已在安全组/对外侧固定，不再自动探测）
PORT="${LUREN_PORT:-8088}"
echo ">> 固定使用端口: $PORT"
# 若 8080 被“非本站”进程占用，给出提醒（本站自己的旧实例会在下面 restart 时自动释放）
if ss -tlnH | awk '{print $4}' | sed 's/.*://' | grep -qx "$PORT"; then
  if ! sudo ss -tlnpH 2>/dev/null | grep ":$PORT " | grep -qi 'python\|luren'; then
    echo "!! 警告：端口 $PORT 似乎被非本站进程占用，重启本服务可能无法绑定，请先确认后再继续。"
  fi
fi

# 独立 systemd 服务：仅监听 $PORT，重启后自动拉起，不影响其它服务
sudo tee /etc/systemd/system/luren-web.service >/dev/null <<UNIT
[Unit]
Description=Luren Jia static website
After=network.target

[Service]
User=ubuntu
WorkingDirectory=$REMOTE_DIR
ExecStart=/usr/bin/python3 -m http.server $PORT --bind 0.0.0.0
Restart=always

[Install]
WantedBy=multi-user.target
UNIT

sudo systemctl daemon-reload
sudo systemctl enable luren-web.service
# 强制重启，确保运行端口与配置一致地固定在 $PORT（会先释放本站旧实例占用的端口）
sudo systemctl restart luren-web.service

# 若开了 ufw 防火墙，放行该端口
if command -v ufw >/dev/null 2>&1 && sudo ufw status | grep -q "Status: active"; then
  sudo ufw allow "$PORT"/tcp || true
fi

sleep 1
echo "----------------------------------------"
sudo systemctl --no-pager --lines=0 status luren-web.service | head -4
echo ">> 站点已启动，端口: $PORT"
echo ">> 访问地址: http://43.143.122.43:$PORT"
echo ">> 注意：如果是腾讯云/云服务器，请到控制台【安全组】放行入站 TCP 端口 $PORT，外网才能访问。"
echo "----------------------------------------"
REMOTE

echo "[3/3] 完成。若上面显示了访问地址即部署成功。"
echo "以后更新内容：重新生成 luren-site.tar.gz 后再次运行 bash deploy.sh 即可（会覆盖并自动重启）。"
