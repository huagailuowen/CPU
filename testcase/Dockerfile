FROM archlinux:latest

# 设置镜像源
RUN echo 'Server = https://mirror.sjtu.edu.cn/archlinux/$repo/os/$arch' > /etc/pacman.d/mirrorlist

# 更新系统并安装基本工具
RUN pacman -Syyu --noconfirm && \
    pacman -S --noconfirm base-devel git

# 创建一个非root用户
RUN useradd -m builder && echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# 切换到非root用户并安装yay
USER builder
WORKDIR /home/builder
RUN git clone https://aur.archlinux.org/yay.git /home/builder/yay && \
    cd /home/builder/yay && \
    makepkg -si --noconfirm && \
    rm -rf /home/builder/yay

# 使用yay安装serial
RUN yay -S --noconfirm serial

# 切换回root用户并安装其他需要的包
USER root
RUN pacman -S --noconfirm make riscv64-elf-gcc riscv64-elf-newlib
RUN pacman -S --noconfirm usbutils usbip iverilog

# 设置工作目录
WORKDIR /app

# 默认命令
CMD ["bash"]
# docker run -it --rm --privileged -v $(pwd):/app -w /app my-archlinux-image