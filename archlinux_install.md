# Archlinux

## 1. 环境准备

- 引导到Arch Linux 安装ISO

## 2. 安装

1. 查看网卡状态:

    ```.sh
    ip a  # 查看网卡状态
    iwctl # 检查无线
    station wlan0 connect <wifiname> # 连接无线
    timedatectl set-ntp true # 同步时间
    ```

2. 硬盘分区:

    ```sh
    lsblk -pf           # 查看当前分区情况
    fdisk -l            # /dev/想要查询详细情况的硬盘  小写字母l，查看详细分区信息
    cfdisk /dev/nvme0n1 # 选择自己要使用的硬盘进行分区

    mkfs.fat -F32 /dev/EFI分区  # 格式化fat 
    mkfs.btrfs -f /dev/根分区   # 格式化btrfs 

    mount -t btrfs -o compress=zstd /dev/root_partition /mnt

    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@swap

    btrfs subvolume list -p /mnt # 检查挂载

    umount /mnt

    mount -t btrfs -o subvol=/@,compress=zstd /dev/root_partition /mnt #根目录
    mount --mkdir -t btrfs -o subvol=/@home,compress=zstd /dev/root_partition /mnt/home #/home目录
    mount --mkdir -t btrfs -o subvol=/@swap,compress=zstd /dev/root_partition /mnt/swap #/swap目录
    mount --mkdir /dev/efi_partition /mnt/boot #/boot目录
    mount --mkdir /dev/winefi_partition /mnt/winboot #windows的启动分区，为双系统引导做准备
    ```

3. 安装基础系统

    ```.vim
    pacman -Sy archlinux-keyring --noconfirm
    
    # 优化镜像源
    pacman -S reflector --noconfirm reflector --country China --protocol https --sort rate --save /etc/pacman.d/mirrorlist

    vim /etc/pacman.d/mirrorlist # 拿出手机，浏览器搜索 archlinux中国镜像源，找一个镜像源添加
    
    ## China
    #Server = https://mirrors.aliyun.com/archlinux/$repo/os/$arch
    #Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch
    #Server = https://mirrors.ustc.edu.cn/archlinux/$repo/os/$arch

    # AMD
    pacstrap -K /mnt base base-devel linux linux-firmware btrfs-progs \
        networkmanager vim sudo amd-ucode git openssl

    # Intel
    pacstrap -K /mnt base base-devel linux linux-firmware btrfs-progs \
        networkmanager vim sudo intel-ucode git openssl

    # -K 复制密钥
    # base-devel是编译其他软件的时候用的
    # linux是内核，可以更换
    # linux-firmware是固件
    # btrfs-progs是btrfs文件系统的管理工具
    # networkmanager 是联网用的，和kde和gnome深度集成，也可以换成别的
    # vim 是文本编辑器，也可以换成别的，比如nano
    # sudo 和权限管理有关
    # amd-ucode 是微码，用来修复和优化cpu，intel用户安装intel-ucode
    ```

4. 创建swap文件和引导程序与双启动

    ```.sh
    btrfs filesystem mkswapfile --size 24g --uuid clear /mnt/swap/swapfile
    or
    btrfs filesystem mkswapfile --size 64g --uuid clear /mnt/swap/swapfile

    #启动swap
    swapon /mnt/swap/swapfile

    genfstab -U /mnt > /mnt/etc/fstab # 生成fstab文件

    cat /mnt/etc/fstab

    # 切换根
    arch-chroot /mnt

    # 设置主机名
    exho "Eris-Archlinux" /etc/hostname
    
    # 配置时区与硬件时钟
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    hwclock --systohc
    
    # 本地化设置
    sed -i 's/^#en_US.UTF-8/en_US.UTF-8/;s/^#zh_CN.UTF-8/zh_CN.UTF-8/' /etc/locale.gen
    locale-gen
    echo "LANG=en_US.UTF-8" > /etc/locale.conf

    # 设置 root 密码:
    passwd
    ```

5. 引导程序与双启动

    ```.sh
    # 安装引导相关包
    pacman -S grub efibootmgr os-prober --noconfirm
    # efibootmgr 管理uefi启动项
    # os-prober 用来搜索win11

    # 安装 GRUB
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=ARCH

    # 调整内核参数：编辑 /etc/default/grub
    # AMD
    GRUB_CMDLINE_LINUX_DEFAULT="loglevel=5 nowatchdog modprobe.blacklist=sp5100_tco"
    # INTEL
    GRUB_CMDLINE_LINUX_DEFAULT="loglevel=5 nowatchdog modprobe.blacklist=iTCO_wdt"

    # 生成配置并退出
    grub-mkconfig -o /boot/grub/grub.cfg
    exit
    reboot
    ```

6. 网络管理与软件安装

    ```.sh
    # 启用 NetworkManager
    systemctl enable --now NetworkManager

    # 连接Wi-Fi
    nmcli dev wifi connect <网络名称> password <密码>

    # 安装常用工具
    pacman -S fastfetch lolcat cmatrix --noconfirm
    ```

7. 普通用户与权限配置

    ```.sh
    useradd -m -g wheel <username> #不需要输入<>符号
    #-m代表创建用户的时候创建home目录，-g代表设置组

    passwd <username>

    EDITOR=vim visudo
    %wheel ALL=（ALL：ALL） ALL
    ```

8. 显卡驱动与硬件编解码

    ```.sh
    # 安装内核头与显卡驱动：
    pacman -S linux-headers nvidia nvidia-utils nvidia-settings --noconfirm

    # 配置 GRUB：在 /etc/default/grub 中添加
    GRUB_CMDLINE_LINUX="nvidia_drm.modeset=1"

    # 更新 initramfs：编辑 /etc/mkinitcpio.conf
    MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)

    # 移除 kms 钩子后
    mkinitcpio -P
    grub-mkconfig -o /boot/grub/grub.cfg
    reboot
    ```

9. 安装硬件编解码

    ```.sh
    # Nvidia 平台
    pacman -S libva-nvidia-driver --noconfirm

    # Intel 平台
    pacman -S intel-media-driver libva --noconfirm
    ```

10. 字体和音频服务

    ```.sh
    # 安装常用字体
    sudo pacman -S wqy-zenhei noto-fonts noto-fonts-emoji
    sudo pacman -S \
          fcitx5-im \
          fcitx5-configtool \
          fcitx5-gtk \
          fcitx5-qt \
          fcitx5-chinese-addons \
          noto-fonts-cjk \
          fcitx5-pinyin-zhwiki \
          fcitx5-rime


    # 安装音频固件与服务
    sudo pacman -S sof-firmware alsa-firmware alsa-ucm-conf \
        pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber

    systemctl --user enable --now pipewire pipewire-pulse wireplumber

    sudo pacman -S pavucontrol


    sudo mkdir -p /etc/pipewire

    sudo cp /usr/share/pipewire/pipewire-pulse.conf /etc/pipewire/pipewire-pulse.conf
    systemctl --user restart pipewire pipewire-pulse wireplumber
    # 在 context.modules 的 libpipewire-module-protocol-pulse 或 libpipewire-module-pulse-volume （若该模块存在）添加：
    {
        name = libpipewire-module-protocol-pulse
        args = {
        +    enable-volume-boost = true
        +    volume-max = 150
        }
    }

    ```

11. Hyprland 桌面环境

    ```.sh
    pacman -S hyprland kitty sddm flatpak --noconfirm
    systemctl enable sddm
    reboot
    ```

12. AUR 源与常用软件

    ```.bash
    sudo vim /etc/pacman.conf

    [archlinuxcn]
    Server = https://mirrors.ustc.edu.cn/archlinuxcn/$arch 
    Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/$arch 
    Server = https://mirrors.hit.edu.cn/archlinuxcn/$arch 
    Server = https://repo.huaweicloud.com/archlinuxcn/$arch

    flatpak remote-modify flathub --url=https://mirrors.ustc.edu.cn/flathub
    flatpak remote-modify flathub --url=https://mirror.sjtu.edu.cn/flathub

    pacman -S paru --noconfirm
    paru -S google-chrome clash-verge --noconfirm

    # install browser 
    paru -S google-chrome
    google-chrome-stable
    clash-verge
    ```

13. 终端代理设置

    ```.sh
    # 在 ~/.bashrc 中加入以下内容（注意不要再有全局的 export http_proxy=… 之类语句
    proxy_on() {
        export http_proxy="socks5h://127.0.0.1:1080"
        export https_proxy="socks5h://127.0.0.1:1080"
        export no_proxy="localhost,127.0.0.1,::1"
        echo "代理已开启"
    }

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
