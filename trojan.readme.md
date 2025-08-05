yay -S trojan-go

curl -s "https://..." \
  | base64 -d \
  | grep ^trojan:// > nodes.txt

将脚本保存为 batch-trojan-go.sh，并赋予可执行权限：
chmod +x batch-trojan-go.sh

运行脚本：
./batch-trojan-go.sh xxxx.txt

在 ~/.config/trojan-go/ 下会生成 config-1.json、config-2.json……

分别启动对应的 trojan-go，监听 127.0.0.1:1081、127.0.0.1:1082……

你可以在浏览器、终端、系统网络代理中，按需填入不同的本地端口来切换节点。

手动启动 trojan-go 客户端：
trojan-go -config ~/.config/trojan-go/config.json

在浏览器或系统代理设置中配置 SOCKS5：

地址：127.0.0.1

端口：xxxx

打开 https://ipinfo.io 或类似网站，确认出口 IP 已切换，表示代理已生效。

创建用户级 systemd 服务文件 ~/.config/systemd/user/trojan-go.service：

[Unit]
Description=trojan-go client
After=network.target

[Service]
ExecStart=/usr/bin/trojan-go -config /home/$(whoami)/.config/trojan-go/config.json
Restart=on-failure

[Install]
WantedBy=default.target

重新加载并启用服务：

systemctl --user daemon-reload
systemctl --user enable --now trojan-go


查看服务状态与日志：

systemctl --user status trojan-go
journalctl --user -u trojan-go -f
