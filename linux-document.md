# ubuntu install command
## apt proxy command
```
sudo apt -o Acquire::http::proxy="http://127.0.0.1:7890"   -o Acquire::https::proxy="https://127.0.0.1:7890"   install curl
sudo apt -o Acquire::http::proxy="http://127.0.0.1:7890"   -o Acquire::https::proxy="https://127.0.0.1:7890"   install git
sudo apt -o Acquire::http::proxy="http://127.0.0.1:7890"   -o Acquire::https::proxy="https://127.0.0.1:7890"   install nx
sudo apt -o Acquire::http::proxy="http://127.0.0.1:7890"   -o Acquire::https::proxy="https://127.0.0.1:7890"   update
sudo apt -o Acquire::http::proxy="http://127.0.0.1:7890"   -o Acquire::https::proxy="https://127.0.0.1:7890"   net-tools
sudo apt -o Acquire::ForceIPv4=true -o Acquire::http::proxy="http://127.0.0.1:7890" update
sudo apt -o Acquire::ForceIPv4=true -o Acquire::http::proxy="http://127.0.0.1:7890" install mesa-utils
glxinfo | grep "OpenGL renderer"
sudo snap remove curl
sudo apt install curl
lspci | grep -i vga # 查看当前使用的显卡
lspci | grep -i nvidia # 查看nvidia显卡
sudo prime-select nvidia  # 切换到 NVIDIA 显卡
sudo apt install nvidia-driver-535 -o Acquire::http::proxy="http://127.0.0.1:7890"   -o Acquire::https::proxy="https://127.0.0.1:7890" # 安装nvidia显卡驱动
sudo apt -o Acquire::ForceIPv4=true -o Acquire::http::proxy="http://127.0.0.1:7890" install nvidia-driver-535
nvidia-smi  # 如果显示 GPU 信息，则驱动正常
sudo prime-select intel
sudo reboot  # 重启生效
```

## dpkg install command
```
sudo dpkg -i code_1.101.2-1750797935_amd64.deb --vs code
```

## nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
nvm install node

## uv
curl -LsSf https://astral.sh/uv/install.sh | sh
