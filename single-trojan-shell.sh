#!/usr/bin/env bash

# 用法提示
if [[ -z "$1" ]]; then
  echo "用法: $0 \"trojan://…#备注\""
  exit 1
fi

URI="$1"

# 提取认证信息、主机、端口、Query 与备注
UUID=$(echo "$URI" | sed -nE 's/^trojan:\/\/([^@]+)@.*$/\1/')
HOST=$(echo "$URI" | sed -nE 's/^trojan:\/\/[^@]+@([^:]+):.*$/\1/')
PORT=$(echo "$URI" | sed -nE 's/^.*:([0-9]+)\?.*$/\1/')
QSTR=$(echo "$URI" | sed -nE 's/^.*\?([^#]+)#.*$/\1/')
TAG=$(echo "$URI" | sed -E 's/^.*#(.*)$/\1/')

# 从 Query 中拆出 allowInsecure / sni / peer
ALLOW_INSECURE=$(echo "$QSTR" | tr '&' '\n' | sed -nE 's/allowInsecure=([01])/\1/')
SNI=$(echo "$QSTR" | tr '&' '\n' | sed -nE 's/sni=([^&]+)/\1/')
PEER=$(echo "$QSTR" | tr '&' '\n' | sed -nE 's/peer=([^&]+)/\1/')

# 准备配置目录
CONFIG_DIR="$HOME/.config/trojan-go"
mkdir -p "$CONFIG_DIR"

# 生成 config.json
cat >"$CONFIG_DIR/config.json" <<EOF
{
  "run_type": "client",
  "local_addr": "127.0.0.1",
  "local_port": 1080,
  "remote_addr": "$HOST",
  "remote_port": $PORT,
  "password": ["$UUID"],
  "ssl": {
    "verify": $( [[ "$ALLOW_INSECURE" == "1" ]] && echo false || echo true ),
    "verify_hostname": $( [[ "$ALLOW_INSECURE" == "1" ]] && echo false || echo true ),
    "sni": "${SNI:-$HOST}"
  },
  "mux": {
    "enabled": false
  }
}
EOF

echo "[$TAG] 已生成配置: $CONFIG_DIR/config.json"

# 启动 trojan-go（可自行改用 systemd 管理）
trojan-go -config "$CONFIG_DIR/config.json"
