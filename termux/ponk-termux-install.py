import os
import base64
import argparse

def install_debian():
    osname = 'Debian'
    folder = 'debian-fs'
    shname = 'start-debian.sh'
    imagedir = 'termux-debian'
    tarball = "debian-rootfs-arm64.tar.xz"
    print("\n正在下载 Rootfs 镜像文件，请耐心等待")
    os.system('git clone "https://gitee.com/sqlsec/termux-debian"')
    print('\n下载完成')
    print('\n正在解压镜像 请耐心等待')
    os.system(f'mkdir -p $HOME/Termux-Linux/{osname}/{folder}')
    os.system(f'proot --link2symlink tar -xJf {imagedir}/{tarball} -C $HOME/Termux-Linux/{osname}/{folder} ||:')
    print('\n解压完成 正在删除已下载的镜像')
    os.system(f'rm -rf {imagedir}')
    print('\n正在优化系统设置')
    os.system(f'mkdir -p $HOME/Termux-Linux/{osname}/binds')
    os.system(f'cp debian/{shname} $HOME/Termux-Linux/{osname}/')
    os.system(f'termux-fix-shebang $HOME/Termux-Linux/{osname}/{shname}')
    os.system(f'chmod +x $HOME/Termux-Linux/{osname}/{shname}')
    os.system(f'rm $HOME/Termux-Linux/{osname}/{folder}/etc/apt/sources.list')
    os.system(f'cp debian/sources.list $HOME/Termux-Linux/{osname}/{folder}/etc/apt/')
    os.system('screenfetch -A "Debian" -L')
    print('\n   Debian 安装成功')
    print('\n     祝您使用愉快\n')


if __name__ == "__main__":
    # 如果没有安装 screenfetch 就安装
    result = os.popen('pkg list-installed|grep screenfetch')
    if 'screenfetch' not in result.read():
        print('正在安装相关依赖包: screenfetch')
        os.system('pkg install screenfetch -y')


    file_exits = False
    result = os.popen('ls $HOME')
    for line in result.read().splitlines():
        if line == 'Termux-Linux':
            file_exits = True
    
    linux_dir = []
    if file_exits:
        result = os.popen('ls $HOME/Termux-Linux/')
        for line in result.read().splitlines():
            linux_dir.append(line)
    else:
        os.system('mkdir $HOME/Termux-Linux')
        install_debian()
  