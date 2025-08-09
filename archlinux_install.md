# Archlinux

- 检查网网络
```
ip a
```


- 检查无线
```
iwctl
station wlan0 connect <wifiname>
```

- 同步时间
```
timedatectl set-ntp true 
```

- 硬盘分区
```
lsblk -pf           #查看当前分区情况
fdisk -l            #/dev/想要查询详细情况的硬盘  小写字母l，查看详细分区信息
cfdisk /dev/nvme0n1 #选择自己要使用的硬盘进行分区

mkfs.fat -F 32 /dev/efi_system_partition
mkfs.btrfs -f /dev/root_partition

mount -t btrfs -o compress=zstd /dev/root_partition /mnt

btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@swap

btrfs subvolume list -p /mnt

umount /mnt

mount -t btrfs -o subvol=/@,compress=zstd /dev/root_partition /mnt #根目录
mount --mkdir -t btrfs -o subvol=/@home,compress=zstd /dev/root_partition /mnt/home #/home目录
mount --mkdir -t btrfs -o subvol=/@swap,compress=zstd /dev/root_partition /mnt/swap #/swap目录
mount --mkdir /dev/efi_partition /mnt/boot #/boot目录
mount --mkdir /dev/winefi_partition /mnt/winboot #windows的启动分区，为双系统引导做准备
```

- 更新密钥
```
pacman -Sy archlinux-keyring
```

- 手动设置
```
vim /etc/pacman.d/mirrorlist
拿出手机，浏览器搜索 archlinux中国镜像源，找一个镜像源添加
```

- 安装系统
```
pacstrap -K /mnt base base-devel linux linux-firmware btrfs-progs
-K 复制密钥
base-devel是编译其他软件的时候用的
linux是内核，可以更换
linux-firmware是固件
btrfs-progs是btrfs文件系统的管理工具
```


- 安装必要的功能性软件
```
pacstrap /mnt networkmanager vim sudo amd-ucode git openssl dhcpcd 

networkmanager 是联网用的，和kde和gnome深度集成，也可以换成别的
vim 是文本编辑器，也可以换成别的，比如nano
sudo 和权限管理有关
amd-ucode 是微码，用来修复和优化cpu，intel用户安装intel-ucode
```

- 创建swap文件
```
btrfs filesystem mkswapfile --size 24g --uuid clear /mnt/swap/swapfile
or
btrfs filesystem mkswapfile --size 64g --uuid clear /mnt/swap/swapfile

#启动swap
swapon /mnt/swap/swapfile
```

- 生成fstab文件
```
genfstab -U /mnt > /mnt/etc/fstab

cat /mnt/etc/fstab
```

- 进入系统
```
arch-chroot /mnt
```

- 主机名
```
vim /etc/hostname
```

- 设置时间和时区
```
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
#ln 是link的缩写，-s代表跨文件系统的软链接，-f代表强制执行，所以这条命令的意思是创建一个Shanghai的链接，取名为localtime。zoneinfo里面包含了所有可用时区的文件，localtime是系统确认时间的依据。

hwclock --systohc
```

- 本地化设置
```
vim /etc/locale.gen
#取消en_US.UTF-8 UTF-8和zh_CN.UTF-8的注释

locale-gen

vim /etc/locale.conf
写入 LANG=en_US.UTF-8
```

- 设置root密码
```
passwd 
```

- 安装引导程序
```
pacman -S grub efibootmgr os-prober

efibootmgr 管理uefi启动项
os-prober 用来搜索win11

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=ARCH #此处的id可以自取

vim /etc/default/grub
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=5 nowatchdog modprobe.blacklist=sp5100_tco" #AMD
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=5 nowatchdog modprobe.blacklist=iTCO_wdt"   #INTEL

grub-mkconfig -o /boot/grub/grub.cfg
exit 退出changeroot
reboot 重启，会自动取消所有的挂载
```

- 登录root账号
```
systemctl enable --now NetworkManager #enbale代表开机自启，--now代表现在启动，开启networkmanager服务，注意大小写
nmcli dev wifi connect <wifiname> password <password>
pacman -S fastfetch lolcat cmatrix
```

- 创建普通用户
```
useradd -m -g wheel <username> #不需要输入<>符号
#-m代表创建用户的时候创建home目录，-g代表设置组

passwd <username>

EDITOR=vim visudo
%wheel ALL=（ALL：ALL） ALL
```

- 安装显卡驱动和硬件编解码
```
sudo pacman -S linux-headers
#linux替换为自己的内核，比如zen内核是linux-zen-headers

pacman -S nvidia nvidia-utils nvidia-settings
sudo vim /etc/default/grub
GRUB_CMDLINE_LINUX="nvidia_drm.modeset=1"
#在GRUB_CMDLINE_LINUX中添加nvidia_drm.modeset=1
sudo grub-mkconfig -o /boot/grub/grub.cfg

sudo vim /etc/mkinitcpio.conf
MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)
#在MODULES中加入nvidia nvidia_modeset nvidia_uvm nvidia_drm
#将kms从HOOKS中去掉
sudo mkinitcpio -P
reboot 重启
nvidia-smi 验证是否安装成功

在/etc/pacman.d/hooks/nvidia.hook中写入
[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Package
Target=nvidia
Target=linux
# Change the linux part above if a different kernel is used

[Action]
Description=Update NVIDIA module in initcpio
Depends=mkinitcpio
When=PostTransaction
NeedsTargets
Exec=/bin/sh -c 'while read -r trg; do case $trg in linux*) exit 0; esac; done; /usr/bin/mkinitcpio -P'
```

- 硬件编解码
```
# Nvidia
sudo pacman -S libva-nvidia-driver
# Intel
sudo pacman -S intel-media-driver libva
```

- 安装字体
```
sudo pacman -S wqy-zenhei noto-fonts noto-fonts-emoji
```

- 安装声音固件和声音服务
```
sudo pacman -S sof-firmware alsa-firmware alsa-ucm-conf

sudo pacman -S pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber

systemctl --user enable --now pipewire pipewire-pulse wireplumber

sudo pacman -S pavucontrol 
```

- 安装Hyprland桌面
```
sudo pacman -S hyprland kitty waybar git openssl flatpak
sudo pacman -S sddm
# sudo pacman -S ttf-jetbrains-mono-nerd adobe-source-han-sans-cn-fonts adobe-source-code-pro-fonts
sudo systemctl enable sddm
reboot 重启
```

- 更换flatpak上海交大源
```
sudo flatpak remote-modify flathub --url=https://mirror.sjtu.edu.cn/flathub
```

- 终端代理设置
```
# 在 ~/.bashrc 中加入以下内容（注意不要再有全局的 export http_proxy=… 之类语句
# 打开代理
proxy_on() {
  export http_proxy="http://127.0.0.1:7890"
  export https_proxy="http://127.0.0.1:7890"
  export no_proxy="localhost,127.0.0.1,::1"
  echo "代理已开启"
}

# 关闭代理
proxy_off() {
  unset http_proxy https_proxy no_proxy
  echo "代理已关闭"
}

source ~/.bashrc   # 重载配置
echo $http_proxy   # 不会有输出，说明当前不走代理


proxy_on
echo $http_proxy   # 会输出 http://127.0.0.1:7890

proxy_off
echo $http_proxy   # 再次无输出
```

- Exanple
```
ip a
```






