# Oracle Linux 7.9 安装 12c

# 1.硬件配置

|CPU|内存|磁盘|操作系统版本|
| -------| ------| --------------------| ------------------|
|2 CPU|8GB|sda:20GB<br />sdb:50GB|Oracle Linux 7.9|

‍

# 2.系统配置

### 2.1 确认磁盘目录

```cmd
[root@ORCLTEST ~]# lsblk 
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sdb      8:16   0   50G  0 disk 
└─sdb1   8:17   0   50G  0 part /u01
sr0     11:0    1  4.5G  0 rom  /media/cdrom
sda      8:0    0   20G  0 disk 
├─sda2   8:2    0   17G  0 part /
├─sda3   8:3    0    2G  0 part [SWAP]
└─sda1   8:1    0    1G  0 part /boot
```

‍

## 2.2 修改主机名和Hosts

1. 修改主机名

    可以安装系统时修改，或根据此方法进行修改（修改机器名）。
2. 修改hosts文件

    ```cmd
    [root@ORCLTEST ~]# cat /etc/hosts
    127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
    ::1         localhost localhost.localdomain localhost6 localhost6.localdomain6


    192.168.109.107         ORCLTEST.local
    192.168.109.107         ORCLTEST
    ```

‍

## 2.3 关闭防火墙

```powershell
#查看防火墙状态
[root@ORCLTEST ~]# systemctl status firewalld
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
   Active: active (running) since Mon 2024-04-15 21:20:21 CST; 1h 8min ago
     Docs: man:firewalld(1)
 Main PID: 641 (firewalld)
   CGroup: /system.slice/firewalld.service
           └─641 /usr/bin/python2 -Es /usr/sbin/firewalld --nofork --nopid

Apr 15 21:20:15 ORCLTEST.local systemd[1]: Starting firewalld - dynamic fi....
Apr 15 21:20:21 ORCLTEST.local systemd[1]: Started firewalld - dynamic fir....
Apr 15 21:20:22 ORCLTEST.local firewalld[641]: WARNING: AllowZoneDrifting ....
Hint: Some lines were ellipsized, use -l to show in full.
[root@ORCLTEST ~]# 

#关闭防火墙
[root@ORCLTEST ~]# systemctl stop firewalld
[root@ORCLTEST ~]# 

#禁用防火墙
[root@ORCLTEST ~]# systemctl disable firewalld
Removed symlink /etc/systemd/system/multi-user.target.wants/firewalld.service.
Removed symlink /etc/systemd/system/dbus-org.fedoraproject.FirewallD1.service.
[root@ORCLTEST ~]# 

#再次查看防火墙状态
[root@ORCLTEST ~]# systemctl status firewalld
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; disabled; vendor preset: enabled)
   Active: inactive (dead)
     Docs: man:firewalld(1)

Apr 15 21:20:15 ORCLTEST.local systemd[1]: Starting firewalld - dynamic fi....
Apr 15 21:20:21 ORCLTEST.local systemd[1]: Started firewalld - dynamic fir....
Apr 15 21:20:22 ORCLTEST.local firewalld[641]: WARNING: AllowZoneDrifting ....
Apr 15 22:29:04 ORCLTEST.local systemd[1]: Stopping firewalld - dynamic fi....
Apr 15 22:29:06 ORCLTEST.local systemd[1]: Stopped firewalld - dynamic fir....
Hint: Some lines were ellipsized, use -l to show in full.
[root@ORCLTEST ~]# 
```

## 2.4 关闭selinux

设置`SELINUX=disabled`​

```powershell
[root@ORCLTEST ~]# vim /etc/selinux/config
[root@ORCLTEST ~]# cat /etc/selinux/config

# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
SELINUX=disabled
# SELINUXTYPE= can take one of three values:
#     targeted - Targeted processes are protected,
#     minimum - Modification of targeted policy. Only selected processes are protected. 
#     mls - Multi Level Security protection.
SELINUXTYPE=targeted 
[root@ORCLTEST ~]# 
[root@ORCLTEST ~]# 
[root@ORCLTEST ~]# setenforce 0
[root@ORCLTEST ~]# 
```

‍

## 2.5 关闭透明大页

```powershell
[root@ORCLTEST ~]# cat /sys/kernel/mm/transparent_hugepage/enabled 
[always] madvise never
```

‍

## 2.6 检查与配置分区大小

* RAM为1-2GB时，SWAP大小建议为RAM大小的 1.5 倍
* RAM为2-16GB时，SWAP大小建议与RAM大小相等
* RAM大于16GB时，SWAP大小建议为 16GB

检查分配大小：

```powershell
[root@ORCLTEST ~]# free -m
              total        used        free      shared  buff/cache   available
Mem:           7672         111        7330           8         230        7327
Swap:          2047           0        2047
```

由于测试环境内存为8GB，建议SWAP为8GB，swap分区添加6GB（6144）。

```powershell
mkdir /swapvol
dd if=/dev/zero of=/swapvol/swapfile bs=1M count=6144
mkswap /swapvol/swapfile
swapon /swapvol/swapfile
vi /etc/fstab
#文件末尾添加此行
/swapvol/swapfile swap swap defaults 0 0
```

执行过程：

```powershell
[root@ORCLTEST ~]# mkdir /swapvol
[root@ORCLTEST ~]# 
[root@ORCLTEST ~]# dd if=/dev/zero of=/swapvol/swapfile bs=1M count=6144
6144+0 records in
6144+0 records out
6442450944 bytes (6.4 GB) copied, 44.8741 s, 144 MB/s
[root@ORCLTEST ~]# 
[root@ORCLTEST ~]# mkswap /swapvol/swapfile
Setting up swapspace version 1, size = 6291452 KiB
no label, UUID=e65bc2b7-3067-4ef0-984a-62368cf8fadc
[root@ORCLTEST ~]# 
[root@ORCLTEST ~]# swapon /swapvol/swapfile
swapon: /swapvol/swapfile: insecure permissions 0644, 0600 suggested.
[root@ORCLTEST ~]# 
[root@ORCLTEST ~]# 
[root@ORCLTEST ~]# free -h
              total        used        free      shared  buff/cache   available
Mem:           7.5G        116M        1.1G        8.4M        6.3G        7.1G
Swap:          8.0G          0B        8.0G
[root@ORCLTEST ~]# 
[root@ORCLTEST ~]# 
[root@ORCLTEST ~]# swapon -s
Filename                                Type            Size    Used    Priority
/dev/sda3                               partition       2097148 0       -2
/swapvol/swapfile                       file    6291452 0       -3
[root@ORCLTEST ~]# 
[root@ORCLTEST ~]# vim /etc/fstab
[root@ORCLTEST ~]# cat /etc/fstab

#
# /etc/fstab
# Created by anaconda on Fri Apr 12 23:42:30 2024
#
# Accessible filesystems, by reference, are maintained under '/dev/disk'
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
#
UUID=273c9b0a-034c-4960-839f-0cfd47ecf2e8 /                       ext4    defaults        1 1
UUID=2424e0da-601b-4b3e-a498-a76bba7dd555 /boot                   ext4    defaults        1 2
UUID=57f4c206-d201-4a3f-aab2-d452c04d134f swap                    swap    defaults        0 0
UUID=1f0c46b7-727d-4eb4-8b5a-521661f7c8b7 /u01                    ext4    defaults        0 0
/swapvol/swapfile                         swap                    swap    defaults        0 0
[root@ORCLTEST ~]# 
[root@ORCLTEST ~]# 
[root@ORCLTEST ~]# mount -a
[root@ORCLTEST ~]# 
```

## 2.7 配置yum源

‍

## 2.8 安装依赖包

1. 安装官方预安装包

    ```powershell
    [root@ORCLTEST home]# yum install oracle-rdbms-server-12cR1-preinstall-1.0-6.el7.x86_64.rpm -y
    Loaded plugins: ulninfo
    Examining oracle-rdbms-server-12cR1-preinstall-1.0-6.el7.x86_64.rpm: oracle-rdbms-server-12cR1-preinstall-1.0-6.el7.x86_64
    Marking oracle-rdbms-server-12cR1-preinstall-1.0-6.el7.x86_64.rpm to be installed
    Resolving Dependencies
    --> Running transaction check
    ---> Package oracle-rdbms-server-12cR1-preinstall.x86_64 0:1.0-6.el7 will be installed
    --> Processing Dependency: bind-utils for package: oracle-rdbms-server-12cR1-preinstall-1.0-6.el7.x86_64
    ORCL                                                                                                                | 3.6 kB  00:00:00   
    --> Processing Dependency: compat-libcap1 for package: oracle-rdbms-server-12cR1-preinstall-1.0-6.el7.x86_64
    --> Processing Dependency: compat-libstdc++-33 for package: oracle-rdbms-server-12cR1-preinstall-1.0-6.el7.x86_64
    --> Processing Dependency: gcc for package: oracle-rdbms-server-12cR1-preinstall-1.0-6.el7.x86_64
    --> Processing Dependency: gcc-c++ for package: oracle-rdbms-server-12cR1-preinstall-1.0-6.el7.x86_64

    ......

    Installed:
      oracle-rdbms-server-12cR1-preinstall.x86_64 0:1.0-6.el7                                                                                

    Dependency Installed:
      GeoIP.x86_64 0:1.5.0-14.el7                                   bind-libs.x86_64 32:9.11.4-26.P2.el7                                     
      bind-libs-lite.x86_64 32:9.11.4-26.P2.el7                     bind-license.noarch 32:9.11.4-26.P2.el7                                  
      bind-utils.x86_64 32:9.11.4-26.P2.el7                         compat-libcap1.x86_64 0:1.10-7.el7                                       
      compat-libstdc++-33.x86_64 0:3.2.3-72.el7                     cpp.x86_64 0:4.8.5-44.0.3.el7                                            
      gcc.x86_64 0:4.8.5-44.0.3.el7                                 gcc-c++.x86_64 0:4.8.5-44.0.3.el7                                        
      geoipupdate.x86_64 0:2.5.0-1.el7                              glibc-devel.x86_64 0:2.17-317.0.1.el7                                    
      glibc-headers.x86_64 0:2.17-317.0.1.el7                       gssproxy.x86_64 0:0.7.0-29.el7                                           
      kernel-headers.x86_64 0:3.10.0-1160.el7                       keyutils.x86_64 0:1.5.8-3.el7                                            
      ksh.x86_64 0:20120801-142.0.1.el7                             libICE.x86_64 0:1.0.9-9.el7                                              
      libSM.x86_64 0:1.2.2-2.el7                                    libX11.x86_64 0:1.6.7-2.el7                                              
      libX11-common.noarch 0:1.6.7-2.el7                            libXau.x86_64 0:1.0.8-2.1.el7                                            
      libXext.x86_64 0:1.3.3-3.el7                                  libXi.x86_64 0:1.7.9-1.el7                                               
      libXinerama.x86_64 0:1.1.3-2.1.el7                            libXmu.x86_64 0:1.1.2-2.el7                                              
      libXrandr.x86_64 0:1.5.1-2.el7                                libXrender.x86_64 0:0.9.10-1.el7                                         
      libXt.x86_64 0:1.1.5-3.el7                                    libXtst.x86_64 0:1.2.3-1.el7                                             
      libXv.x86_64 0:1.0.11-1.el7                                   libXxf86dga.x86_64 0:1.1.4-2.1.el7                                       
      libXxf86misc.x86_64 0:1.0.3-7.1.el7                           libXxf86vm.x86_64 0:1.1.4-1.el7                                          
      libaio.x86_64 0:0.3.109-13.el7                                libaio-devel.x86_64 0:0.3.109-13.el7                                     
      libbasicobjects.x86_64 0:0.1.1-32.el7                         libcollection.x86_64 0:0.7.0-32.el7                                      
      libdmx.x86_64 0:1.1.3-3.el7                                   libevent.x86_64 0:2.0.21-4.el7                                           
      libini_config.x86_64 0:1.3.1-32.el7                           libmpc.x86_64 0:1.0.1-3.el7                                              
      libnfsidmap.x86_64 0:0.25-19.el7                              libpath_utils.x86_64 0:0.2.1-32.el7                                      
      libref_array.x86_64 0:0.1.5-32.el7                            libstdc++-devel.x86_64 0:4.8.5-44.0.3.el7                                
      libtirpc.x86_64 0:0.2.4-0.16.el7                              libverto-libevent.x86_64 0:0.2.5-4.el7                                   
      libxcb.x86_64 0:1.13-1.el7                                    lm_sensors-libs.x86_64 0:3.4.0-8.20160601gitf9185e5.el7                  
      mailx.x86_64 0:12.5-19.el7                                    mpfr.x86_64 0:3.1.1-4.el7                                                
      nfs-utils.x86_64 1:1.3.0-0.68.0.1.el7                         psmisc.x86_64 0:22.20-17.el7                                             
      quota.x86_64 1:4.01-19.el7                                    quota-nls.noarch 1:4.01-19.el7                                           
      rpcbind.x86_64 0:0.2.0-49.el7                                 smartmontools.x86_64 1:7.0-2.el7                                         
      sysstat.x86_64 0:10.1.5-19.el7                                tcp_wrappers.x86_64 0:7.6-77.el7                                         
      unzip.x86_64 0:6.0-21.el7                                     xorg-x11-utils.x86_64 0:7.5-23.el7                                       
      xorg-x11-xauth.x86_64 1:1.0.9-1.el7                        

    Complete!
    [root@ORCLTEST home]# 

    ```
2. 安装官方依赖包

    检查依赖包

    ```powershell
    [root@ORCLTEST home]# rpm -q bc binutils compat-openssl10 elfutils-libelf glibc glibc-devel ksh libaio libXrender libX11 libXau libXi libXtst libgcc libnsl libstdc++ libxcb libibverbs make smartmontools  sysstat compat-libstdc++ compat-libstdc++-33 gcc gcc-c++ glibc-headers libaio-deve libstdc++-devel libstdc++-devel unixODBC-devel binutils-* compat-libstdc++* elfutils-libelf* glibc* gcc-* libaio* libgcc* libstdc++* make* sysstat* unixODBC* unzip compat-libcap1
    bc-1.06.95-13.el7.x86_64
    binutils-2.27-44.base.0.1.el7.x86_64
    package compat-openssl10 is not installed
    elfutils-libelf-0.176-5.el7.x86_64
    glibc-2.17-317.0.1.el7.x86_64
    glibc-devel-2.17-317.0.1.el7.x86_64
    ksh-20120801-142.0.1.el7.x86_64
    libaio-0.3.109-13.el7.x86_64
    libXrender-0.9.10-1.el7.x86_64
    libX11-1.6.7-2.el7.x86_64
    libXau-1.0.8-2.1.el7.x86_64
    libXi-1.7.9-1.el7.x86_64
    libXtst-1.2.3-1.el7.x86_64
    libgcc-4.8.5-44.0.3.el7.x86_64
    package libnsl is not installed
    libstdc++-4.8.5-44.0.3.el7.x86_64
    libxcb-1.13-1.el7.x86_64
    package libibverbs is not installed
    make-3.82-24.el7.x86_64
    smartmontools-7.0-2.el7.x86_64
    sysstat-10.1.5-19.el7.x86_64
    package compat-libstdc++ is not installed
    compat-libstdc++-33-3.2.3-72.el7.x86_64
    gcc-4.8.5-44.0.3.el7.x86_64
    gcc-c++-4.8.5-44.0.3.el7.x86_64
    glibc-headers-2.17-317.0.1.el7.x86_64
    package libaio-deve is not installed
    libstdc++-devel-4.8.5-44.0.3.el7.x86_64
    libstdc++-devel-4.8.5-44.0.3.el7.x86_64
    package unixODBC-devel is not installed
    binutils-2.27-44.base.0.1.el7.x86_64
    package compat-libstdc++* is not installed
    package elfutils-libelf* is not installed
    package glibc* is not installed
    gcc-4.8.5-44.0.3.el7.x86_64
    package libaio* is not installed
    package libgcc* is not installed
    package libstdc++* is not installed
    package make* is not installed
    package sysstat* is not installed
    package unixODBC* is not installed
    unzip-6.0-21.el7.x86_64
    compat-libcap1-1.10-7.el7.x86_64
    ```

    安装依赖包

    ```powershell
    yum -y install compat-openssl10  ksh libXrender libX11 libXau libXi libXtst libnsl libxcb libibverbs smartmontools  sysstat compat-libstdc++ compat-libstdc++-33  gcc-c++ libaio-deve libstdc++-devel libstdc++-devel unixODBC-devel compat-libstdc++* elfutils-libelf* glibc* libaio* libgcc* libstdc++* make* sysstat* unixODBC* unzip compat-libcap1
    ```

‍

## 2.9 创建用户及用户组

1. 若已执行预安装包，则检查用户及用户组是否已经创建

    ```powershell
    #检查用户组
    [root@ORCLTEST home]# cat /etc/group
    ......
    ......
    oinstall:x:54321:
    dba:x:54322:oracle

    #检查用户
    [root@ORCLTEST home]# cat /etc/passwd
    ......
    ......
    oracle:x:54321:54321::/home/oracle:/bin/bash
    ```
2. 若未执行预安装包，则手动执行创建用于及用户组

    ```powershell
    groupadd oinstall
    groupadd dba
    useradd -u 502 -g oinstall -G dba oracle

    ---查看Oracle用户在哪些组内
    [root@ORCLTEST home]# groups oracle
    oracle : oinstall dba oper backupdba dgdba kmdba racdba
    ```
3. 修改oracle用户密码

    ```powershell
    echo "n@bAsik9" | passwd oracle --stdin
    ```

‍

## 2.10 创建文件目录

```powershell
mkdir /u01
mkdir -p /u01/app/oracle
chmod -R 775 /u01
chown -R oracle:oinstall /u01
chmod -R 775 /u01
chmod g+s /u01

mkdir -p /u01/app/oraInventory
mkdir -p /u01/app/oracle/product/12.1.0/db_1
chown -R oracle:oinstall /u01/app/oraInventory
chown -R oracle:oinstall /u01/app/oracle
```

‍

## 2.11 修改Linux内核参数

1. 若已执行预安装包，则检查参数是否已经修改

    ```powershell
    [root@ORCLTEST /]# cat /etc/sysctl.conf 
    # sysctl settings are defined through files in
    # /usr/lib/sysctl.d/, /run/sysctl.d/, and /etc/sysctl.d/.
    #
    # Vendors settings live in /usr/lib/sysctl.d/.
    # To override a whole file, create a new file with the same in
    # /etc/sysctl.d/ and put new settings there. To override
    # only specific settings, add a file with a lexically later
    # name in /etc/sysctl.d/ and put new settings there.
    #
    # For more information, see sysctl.conf(5) and sysctl.d(5).

    # oracle-rdbms-server-12cR1-preinstall setting for fs.file-max is 6815744
    fs.file-max = 6815744

    # oracle-rdbms-server-12cR1-preinstall setting for kernel.sem is '250 32000 100 128'
    kernel.sem = 250 32000 100 128

    # oracle-rdbms-server-12cR1-preinstall setting for kernel.shmmni is 4096
    kernel.shmmni = 4096

    # oracle-rdbms-server-12cR1-preinstall setting for kernel.shmall is 1073741824 on x86_64
    kernel.shmall = 1073741824

    # oracle-rdbms-server-12cR1-preinstall setting for kernel.shmmax is 4398046511104 on x86_64
    kernel.shmmax = 4398046511104

    # oracle-rdbms-server-12cR1-preinstall setting for kernel.panic_on_oops is 1 per Orabug 19212317
    kernel.panic_on_oops = 1

    # oracle-rdbms-server-12cR1-preinstall setting for net.core.rmem_default is 262144
    net.core.rmem_default = 262144

    # oracle-rdbms-server-12cR1-preinstall setting for net.core.rmem_max is 4194304
    net.core.rmem_max = 4194304

    # oracle-rdbms-server-12cR1-preinstall setting for net.core.wmem_default is 262144
    net.core.wmem_default = 262144

    # oracle-rdbms-server-12cR1-preinstall setting for net.core.wmem_max is 1048576
    net.core.wmem_max = 1048576

    # oracle-rdbms-server-12cR1-preinstall setting for net.ipv4.conf.all.rp_filter is 2
    net.ipv4.conf.all.rp_filter = 2

    # oracle-rdbms-server-12cR1-preinstall setting for net.ipv4.conf.default.rp_filter is 2
    net.ipv4.conf.default.rp_filter = 2

    # oracle-rdbms-server-12cR1-preinstall setting for fs.aio-max-nr is 1048576
    fs.aio-max-nr = 1048576

    # oracle-rdbms-server-12cR1-preinstall setting for net.ipv4.ip_local_port_range is 9000 65500
    net.ipv4.ip_local_port_range = 9000 65500

    ```
2. 若没有执行预安装包，则设置以下参数

    ```powershell
    vi /etc/sysctl.conf

    fs.file-max = 6815744
    kernel.sem = 250 32000 100 128
    kernel.shmmni = 4096
    kernel.shmall = 1073741824
    kernel.shmmax = 4398046511104
    net.core.rmem_default = 262144
    net.core.rmem_max = 4194304
    net.core.wmem_default = 262144
    net.core.wmem_max = 1048576
    fs.aio-max-nr = 1048576
    net.ipv4.ip_local_port_range = 9000 65500
    ```
3. 重启生效

    ```powershell
    [root@ORCLTEST /]# sysctl -p
    fs.file-max = 6815744
    kernel.sem = 250 32000 100 128
    kernel.shmmni = 4096
    kernel.shmall = 1073741824
    kernel.shmmax = 4398046511104
    kernel.panic_on_oops = 1
    net.core.rmem_default = 262144
    net.core.rmem_max = 4194304
    net.core.wmem_default = 262144
    net.core.wmem_max = 1048576
    net.ipv4.conf.all.rp_filter = 2
    net.ipv4.conf.default.rp_filter = 2
    fs.aio-max-nr = 1048576
    net.ipv4.ip_local_port_range = 9000 65500
    [root@ORCLTEST /]# 
    ```

‍

## 2.12 修改设置限定

```powershell
[root@ORCLTEST /]# vim /etc/security/limits.conf

###添加以下内容
oracle   soft   nofile   1024
oracle   hard   nofile   65536
oracle   soft   nproc    2047
oracle   hard   nproc    16384
oracle   soft   stack    10240
oracle   hard   stack    32768

```

‍

## 2.13 修改oracle用户环境变量

切换到oracle用户，修改home目录下的.bash_profile，添加以下内容：

```powershell
export TMP=/tmp
export TMPDIR=$TMP

export ORACLE_HOSTNAME=ORCLTEST.local
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/12.1.0/db_1
export ORA_INVENTORY=/u01/app/oraInventory
export ORACLE_SID=ORCL12C
export NLS_DATE_FORMAT="YYYY-MM-DD HH24:MI:SS"
export LANG="en_US.UTF-8"
export NLS_LANG="american_AMERICA.UTF8"
export PATH=$ORACLE_HOME/bin:$ORACLE_HOME/OPatch:$ORACLE_HOME/jdk/bin:$PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib64:/usr/lib64:/usr/local/lib64:/usr/X11R6/lib64/
export CLASSPATH=$ORACLE_HOME/JRE:$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib

alias sqlplus='rlwrap sqlplus'
alias rman='rlwrap rman'
alias lsnrctl='rlwrap lsnrctl'

```

使环境变量生效

```powershell
source .bash_profile
```

‍

## 2.14 重启服务器

‍

# 3.数据库软件安装

## 3.1 上传安装包

上传V38501-01_1of2.zip和V38501-01_2of2.zip。

在root用户下，解压两个安装包。

```powershell
unzip V38501-01_1of2.zip && unzip V38501-01_2of2.zip
```

## 3.2 修改rsp文件

在解压的`database/response`​文件夹下，修改db_install.rsp文件，修改内容如下：

```powershell
oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v12.1.0
# 30行 安装类型,只装数据库软件
oracle.install.option=INSTALL_DB_SWONLY
# 35行 用户组
UNIX_GROUP_NAME=oinstall
# 42行 INVENTORY目录（不填就是默认值，不能是Oracle Base内的文件夹）
INVENTORY_LOCATION=/u01/app/oraInventory
# 46行 oracle目录
ORACLE_HOME=/u01/app/oracle/product/12.1.0/db_1
# 51行 oracle基本目录
ORACLE_BASE=/u01/app/oracle
# 63行 oracle版本
oracle.install.db.InstallEdition=EE
# 80行
oracle.install.db.OSDBA_GROUP=dba
# 86行
oracle.install.db.OSOPER_GROUP=dba
# 91行 
oracle.install.db.OSBACKUPDBA_GROUP=dba
# 96行
oracle.install.db.OSDGDBA_GROUP=dba
# 101行
oracle.install.db.OSKMDBA_GROUP=dba
# 106行
oracle.install.db.OSRACDBA_GROUP=dba
# 180行 数据库类型
oracle.install.db.config.starterdb.type=GENERAL_PURPOSE
# 185行
oracle.install.db.config.starterdb.globalDBName=ORCL12C
# 190行
oracle.install.db.config.starterdb.SID=ORCL12C
# 216行
oracle.install.db.config.starterdb.characterSet=AL32UTF8
# 384行
SECURITY_UPDATES_VIA_MYORACLESUPPORT=TRUE
# 398行 设置安全更新（貌似是有bug，这个一定要选true，否则会无限提醒邮件地址有问题，终止安装。PS：不管地址对不对）
DECLINE_SECURITY_UPDATES=true
```

修改后文件如下：

[db_install.rsp](assets/db_install-20240421122411-ihq1me4.rsp)

## 3.3 安装数据库软件

1. 用oracle用户登录。
2. 转跳到解压出来的database文件，执行以下命令（必须修改rsp文件路径）

    ```powershell
    ./runInstaller -force -silent -noconfig -ignorePrereq -ignoreSysPreReqs -responseFile /home/database/response/db_install.rsp 
    ```

    执行过程：

    ```powershell
    [oracle@ORCLTEST database]$ ./runInstaller -force -silent -noconfig -ignorePrereq -ignoreSysPreReqs -responseFile /home/database/response/db_install.rsp 
    Starting Oracle Universal Installer...

    Checking Temp space: must be greater than 500 MB.   Actual 3157 MB    Passed
    Checking swap space: must be greater than 150 MB.   Actual 8191 MB    Passed
    Preparing to launch Oracle Universal Installer from /tmp/OraInstall2024-04-17_10-29-49AM. Please wait ...[oracle@ORCLTEST database]$ You can find the log of this install session at:
     /u01/app/oraInventory/logs/installActions2024-04-17_10-29-49AM.log
    The installation of Oracle Database 12c was successful.
    Please check '/u01/app/oraInventory/logs/silentInstall2024-04-17_10-29-49AM.log' for more details.

    As a root user, execute the following script(s):
            1. /u01/app/oraInventory/orainstRoot.sh
            2. /u01/app/oracle/product/12.1.0/db_1/root.sh


    Successfully Setup Software.
    As install user, execute the following script to complete the configuration.
            1. /u01/app/oracle/product/12.1.0/db_1/cfgtoollogs/configToolAllCommands RESPONSE_FILE=<response_file>

            Note:
            1. This script must be run on the same host from where installer was run. 
            2. This script needs a small password properties file for configuration assistants that require passwords (refer to install guide documentation).


    [oracle@ORCLTEST database]$ 
    ```
3. 根据以上提示，用root用户执行以下两个脚本：

    ```powershell
    /u01/app/oraInventory/orainstRoot.sh
    /u01/app/oracle/product/12.2.0/db_1/root.sh
    ```

    执行过程：

    ```powershell
    [root@ORCLTEST ~]# /u01/app/oraInventory/orainstRoot.sh
    Changing permissions of /u01/app/oraInventory.
    Adding read,write permissions for group.
    Removing read,write,execute permissions for world.

    Changing groupname of /u01/app/oraInventory to oinstall.
    The execution of the script is complete.
    [root@ORCLTEST ~]# 
    [root@ORCLTEST ~]# 
    [root@ORCLTEST ~]# /u01/app/oracle/product/12.1.0/db_1/root.sh
    Check /u01/app/oracle/product/12.1.0/db_1/install/root_ORCLTEST.local_2024-04-17_10-39-31.log for the output of root script
    [root@ORCLTEST ~]# 
    ```
4. 安装过程日志

    [installActions2024-04-20_11-07-40PM.log](assets/installActions2024-04-20_11-07-40PM-20240421121100-u703twh.log)

‍

# 4.监听安装

静默安装配置文件路径为解压的database文件夹下：/home/database/response/netca.rsp

rsp文件无需特殊配置，在Oracle用户下，直接执行安装即可，如下：

```powershell
netca -silent -responsefile /home/database/response/netca.rsp
```

执行过程：

```powershell
[oracle@ORCLTEST /]$ netca -silent -responsefile /home/database/response/netca.rsp

Parsing command line arguments:
    Parameter "silent" = true
    Parameter "responsefile" = /home/database/response/netca.rsp
Done parsing command line arguments.
Oracle Net Services Configuration:
Profile configuration complete.
Oracle Net Listener Startup:
    Running Listener Control: 
      /u01/app/oracle/product/12.1.0/db_1/bin/lsnrctl start LISTENER
    Listener Control complete.
    Listener started successfully.
Listener configuration complete.
Oracle Net Services configuration successful. The exit code is 0
[oracle@ORCLTEST /]$ 
```

检查监听状态，1521端口已被tnslsnr程序占用：

```powershell
[oracle@ORCLTEST /]$ netstat -tlnp
(Not all processes could be identified, non-owned process info
 will not be shown, you would have to be root to see it all.)
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name  
tcp        0      0 0.0.0.0:111             0.0.0.0:*               LISTEN      -                 
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      -                 
tcp        0      0 127.0.0.1:25            0.0.0.0:*               LISTEN      -                 
tcp        0      0 127.0.0.1:6010          0.0.0.0:*               LISTEN      -                 
tcp        0      0 127.0.0.1:6011          0.0.0.0:*               LISTEN      -                 
tcp6       0      0 :::111                  :::*                    LISTEN      -                 
tcp6       0      0 :::1521                 :::*                    LISTEN      12654/tnslsnr     
tcp6       0      0 :::22                   :::*                    LISTEN      -                 
tcp6       0      0 ::1:25                  :::*                    LISTEN      -                 
tcp6       0      0 ::1:6010                :::*                    LISTEN      -                 
tcp6       0      0 ::1:6011                :::*                    LISTEN      -                 
[oracle@ORCLTEST /]$ 
```

‍

# 5.创建数据库

静默安装配置文件路径为解压的database文件夹下：/home/database/response/dbca.rsp

修改dbca.rsp文件如下：（**gdbName, sid,pdbName均建议采用大写**）

```powershell
PDB# 21行 不可更改
responseFileVersion=/oracle/assistants/rspfmt_dbca_response_schema_v12.1.0
# 32行 全局数据库名
gdbName=ORCL12C
# 42行 系统标识符
sid=ORCL12C
# 52行
databaseConfigType=SI
# 74行
policyManaged=false
# 88行
createServerPool=false
# 127行
force=false
# 163行
createAsContainerDatabase=true
# 172行
numberOfPDBs=1
# 182行
pdbName=ORCL12CPDB
# 192行
useLocalUndoForPDBs=true
# 203行 库密码
pdbAdminPassword=********
# 223行
templateName=/u01/app/oracle/product/12.2.0/db_1/assistants/dbca/templates/General_Purpose.dbc
# 233行 超级管理员密码
sysPassword=********
# 233行 管理员密码
systemPassword=********
# 273行
emExpressPort=5500
# 284行
runCVUChecks=false
# 313行
omsPort=0
# 341行
dvConfiguration=false
# 391行
olsConfiguration=false
# 401行
datafileJarLocation={ORACLE_HOME}/assistants/dbca/templates/
# 411行
datafileDestination={ORACLE_BASE}/oradata/
# 421行
recoveryAreaDestination={ORACLE_BASE}/fast_recovery_area/
# 431行
storageType=FS
# 468行 字符集创建库之后不可更改
characterSet=AL32UTF8
# 478行
nationalCharacterSet=AL16UTF16
# 488行
registerWithDirService=false
# 526行
listeners=LISTENER
# 546行
sampleSchema=false
# 584行
databaseType=MULTIPURPOSE
# 594行
automaticMemoryManagement=false
# 604行
totalMemory=0
```

修改后配置文件如下：

[dbca.rsp](assets/dbca-20240421122713-mojmw1i.rsp)

修改后，在Oracle用户下，使用 dbca 命令创建数据库实例（dbca是oracle命令，如果提示命令找不到，检查环境变量，可能需要几分钟），执行以下语句：

```powershell
dbca -silent -createDatabase -responseFile /home/database/response/dbca.rsp
```

执行过程如下：

```powershell
[oracle@ORCLTEST ~]$ dbca -silent -createDatabase -responseFile /home/database/response/dbca.rsp
Copying database files
1% complete
2% complete
4% complete
37% complete
Creating and starting Oracle instance
38% complete
41% complete
46% complete
47% complete
48% complete
49% complete
50% complete
51% complete
52% complete
53% complete
58% complete
59% complete
62% complete
63% complete
64% complete
67% complete
Completing Database Creation
71% complete
75% complete
79% complete
90% complete
91% complete
92% complete
100% complete
Look at the log file "/u01/app/oracle/cfgtoollogs/dbca/ORCL12C/ORCL12C.log" for further details.
[oracle@ORCLTEST ~]$ 
```

执行日志如下：

```powershell
[root@ORCLTEST ORCL12C]# cat /u01/app/oracle/cfgtoollogs/dbca/ORCL12C/ORCL12C.log

Unique database identifier check passed.

/u01/ has enough space. Required space is 7665 MB , available space is 42293 MB.
File Validations Successful.
Copying database files
DBCA_PROGRESS : 1%
DBCA_PROGRESS : 2%
DBCA_PROGRESS : 27%
Creating and starting Oracle instance
DBCA_PROGRESS : 29%
DBCA_PROGRESS : 32%
DBCA_PROGRESS : 33%
DBCA_PROGRESS : 34%
DBCA_PROGRESS : 38%
DBCA_PROGRESS : 42%
DBCA_PROGRESS : 43%
DBCA_PROGRESS : 45%
Completing Database Creation
DBCA_PROGRESS : 48%
DBCA_PROGRESS : 51%
DBCA_PROGRESS : 53%
DBCA_PROGRESS : 62%
DBCA_PROGRESS : 70%
DBCA_PROGRESS : 72%
Creating Pluggable Databases
ORA-12712: new character set must be a superset of old character set

DBCA_PROGRESS : 78%
DBCA_PROGRESS : 100%
Database creation complete. For details check the logfiles at:
 /u01/app/oracle/cfgtoollogs/dbca/ORCL12C.
Database Information:
Global Database Name:ORCL12C
System Identifier(SID):ORCL12C
[root@ORCLTEST ORCL12C]# 
```

‍

# 6.检查Oracle进程

```powershell
[oracle@ORCLTEST ~]$ ps -ef | grep ora_ | grep -v grep
oracle    6389     1  0 11:43 ?        00:00:01 ora_pmon_ORCL12C
oracle    6391     1  0 11:43 ?        00:00:04 ora_psp0_ORCL12C
oracle    6394     1  2 11:43 ?        00:03:27 ora_vktm_ORCL12C
oracle    6398     1  0 11:43 ?        00:00:01 ora_gen0_ORCL12C
oracle    6400     1  0 11:43 ?        00:00:03 ora_mman_ORCL12C
oracle    6404     1  0 11:43 ?        00:00:00 ora_diag_ORCL12C
oracle    6406     1  0 11:43 ?        00:00:08 ora_dbrm_ORCL12C
oracle    6408     1  0 11:43 ?        00:00:00 ora_vkrm_ORCL12C
oracle    6410     1  0 11:43 ?        00:00:15 ora_dia0_ORCL12C
oracle    6412     1  0 11:43 ?        00:00:04 ora_dbw0_ORCL12C
oracle    6414     1  0 11:43 ?        00:00:02 ora_lgwr_ORCL12C
oracle    6416     1  0 11:43 ?        00:00:06 ora_ckpt_ORCL12C
oracle    6419     1  0 11:43 ?        00:00:01 ora_lg00_ORCL12C
oracle    6421     1  0 11:43 ?        00:00:01 ora_smon_ORCL12C
oracle    6423     1  0 11:43 ?        00:00:00 ora_lg01_ORCL12C
oracle    6425     1  0 11:43 ?        00:00:00 ora_reco_ORCL12C
oracle    6427     1  0 11:43 ?        00:00:00 ora_lreg_ORCL12C
oracle    6429     1  0 11:43 ?        00:00:00 ora_pxmn_ORCL12C
oracle    6431     1  0 11:43 ?        00:00:31 ora_mmon_ORCL12C
oracle    6433     1  0 11:44 ?        00:00:17 ora_mmnl_ORCL12C
oracle    6435     1  0 11:44 ?        00:00:00 ora_d000_ORCL12C
oracle    6437     1  0 11:44 ?        00:00:00 ora_s000_ORCL12C
oracle    6455     1  0 11:44 ?        00:00:00 ora_tmon_ORCL12C
oracle    6457     1  0 11:44 ?        00:00:00 ora_tt00_ORCL12C
oracle    6460     1  0 11:44 ?        00:00:01 ora_smco_ORCL12C
oracle    6462     1  0 11:44 ?        00:00:01 ora_w000_ORCL12C
oracle    6464     1  0 11:44 ?        00:00:01 ora_w001_ORCL12C
oracle    6468     1  0 11:44 ?        00:00:00 ora_aqpc_ORCL12C
oracle    6474     1  0 11:44 ?        00:00:18 ora_p000_ORCL12C
oracle    6476     1  0 11:44 ?        00:00:07 ora_p001_ORCL12C
oracle    6478     1  0 11:44 ?        00:00:05 ora_p002_ORCL12C
oracle    6480     1  0 11:44 ?        00:00:04 ora_p003_ORCL12C
oracle    6482     1  0 11:44 ?        00:00:02 ora_p004_ORCL12C
oracle    6484     1  0 11:44 ?        00:00:03 ora_p005_ORCL12C
oracle    6486     1  0 11:44 ?        00:00:00 ora_p006_ORCL12C
oracle    6488     1  0 11:44 ?        00:00:00 ora_p007_ORCL12C
oracle    6492     1  0 11:44 ?        00:00:16 ora_cjq0_ORCL12C
oracle    6604     1  0 11:44 ?        00:00:00 ora_qm02_ORCL12C
oracle    6610     1  0 11:44 ?        00:00:00 ora_q003_ORCL12C
oracle    6961     1  0 11:49 ?        00:00:02 ora_w002_ORCL12C
oracle    6990     1  0 11:50 ?        00:00:01 ora_q001_ORCL12C
oracle   11358     1  0 13:04 ?        00:00:00 ora_w003_ORCL12C
oracle   11401     1  0 13:05 ?        00:00:00 ora_w004_ORCL12C
oracle   11409     1  0 13:05 ?        00:00:00 ora_w005_ORCL12C
oracle   11413     1  0 13:05 ?        00:00:00 ora_w006_ORCL12C
oracle   11418     1  0 13:05 ?        00:00:00 ora_w007_ORCL12C
oracle   18212     1  0 13:52 ?        00:00:00 ora_p008_ORCL12C
oracle   18214     1  0 13:52 ?        00:00:00 ora_p009_ORCL12C
oracle   18216     1  0 13:52 ?        00:00:00 ora_p00a_ORCL12C
oracle   18218     1  0 13:52 ?        00:00:00 ora_p00b_ORCL12C
oracle   18220     1  0 13:52 ?        00:00:00 ora_p00c_ORCL12C
oracle   18222     1  0 13:52 ?        00:00:00 ora_p00d_ORCL12C
[oracle@ORCLTEST ~]$ 
```

‍

# 7.其他操作

## 7.1 安装rlwrap

1. 安装依赖包

    ```cmd
    [root@node3 ~]# yum install readline-devel* -y
    ```
2. 安装rlwrap工具

    ```cmd
    [root@node3 ~]# tar xvf rlwrap-0.43.tar.gz
    [root@node3 ~]# cd rlwrap-0.43
    [root@node3 rlwrap-0.43]# ./configure
    [root@node3 rlwrap-0.43]# make
    [root@node3 rlwrap-0.43]# make check
    [root@node3 rlwrap-0.43]# make install
    ```
3. 在环境变量添加相应的命令：

    ```cmd
    [root@node3 rlwrap-0.43]# vim /home/oracle/.bash_profile
    alias sqlplus='rlwrap sqlplus'
    alias rman='rlwrap rman'
    alias lsnrctl='rlwrap lsnrctl'
    ```

如果遇到以下报错（rlwrap-0.37版本会遇到）：

```cmd
[oracle@ORCLTEST /]$ lsnrctl status
rlwrap: Cannot execute lsnrctl: No such file or directory
```

则添加以下内容到环境变量中：

```cmd
export PATH=$ORACLE_HOME/bin:$PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
```

‍

## 7.2 添加自动启动服务

1. 编辑/etc/oratab文件

    将每个实例的重新启动标准设置为Y

    ```powershell
    ORCL12C:/u01/app/oracle/product/12.1.0/db_1:Y
    ```
2. 修改/etc/rc.d/rc.local文件

    添加如下内容

    ```powershell
    su - oracle -c "/u01/app/oracle/product/12.1.0/db_1/bin/lsnrctl start"
    su - oracle -c "/u01/app/oracle/product/12.1.0/db_1/bin/dbstart"
    ```
3. 赋权

    因为Oracle linux 7.2默认rc.local是没有执行权限，需执行chmod自己增加。

    dbstart默认将oratab中参数为Y的所有库启动。

    ```powershell
    chmod +x /etc/rc.d/rc.local
    ```
4. 重启服务器检查自启动是否成功。

‍

## 7.3 PDB自启动设置

PDB的启动方式

‍

## 7.4 创建sample schema

示例数据库模板的内容如下：

```sql
Schema HR – Division Human Resources tracks information about the company employees and facilities.
Schema OE – Division Order Entry tracks product inventories and sales of company products through various channels.
Schema PM – Division Product Media maintains descriptions and detailed information about each product sold by the company.
Schema IX – Division Information Exchange manages shipping through B2B applications.
Schema SH – Division Sales tracks business statistics to facilitate business decisions.
```

sample schema 安装包下载路径为：`https://github.com/oracle/db-sample-schemas/releases/latest`​

安装步骤如下：

1. 上传12c sample schema脚本包到服务器

    路径为：$ORACLE_HOME/demo

    ```sql
    [oracle@dave.cndba.cn demo]$ cp /home/oracle/db-sample-schemas-12.2.0.1.zip $ORACLE_HOME/demo
    [oracle@dave.cndba.cn demo]$ ls
    db-sample-schemas-12.2.0.1.zip  schema
    [oracle@dave.cndba.cn demo]$ unzip db-sample-schemas-12.2.0.1.zip
    [oracle@dave.cndba.cn demo]$ mv schema schema.bak
    [oracle@dave.cndba.cn demo]$ mv db-sample-schemas-12.2.0.1 schema
    ```
2. 修改脚本

    由于使用原脚本执行会有以下报错：

    ```sql
    SP2-0310: unable to open file "__SUB__CWD__/human_resources/hr_cre.sql"
    SP2-0310: unable to open file "__SUB__CWD__/human_resources/hr_popul.sql"
    SP2-0310: unable to open file "__SUB__CWD__/human_resources/hr_idx.sql"
    SP2-0310: unable to open file "__SUB__CWD__/human_resources/hr_code.sql"
    SP2-0310: unable to open file "__SUB__CWD__/human_resources/hr_comnt.sql"
    SP2-0310: unable to open file "__SUB__CWD__/human_resources/hr_analz.sql"
    not spooling currently 
    ```

    是由于脚本里面的`__SUB__CWD__/`​内容造成无法执行脚本，需要替换成绝对路径：

    ```sql
    ---在schema文件夹下执行，目的是替换schema文件夹中所有脚本文件的内容：
    [oracle@dave.cndba.cn schema]$ sed -i "s#__SUB__CWD__#$(pwd)#g" `grep __SUB__CWD__ -rl --include="*.sql" ./` 
    ```

    替换后效果如下：

    ```shell
    [oracle@dave.cndba.cn schema]$ cat mksample.sql
    …
    @/u01/app/oracle/product/12.1.0/db_1/demo/schema/order_entry/oe_main.sql &&password_oe &&default_ts &&temp_ts &&password_hr &&password_sys /u01/app/oracle/product/12.1.0/db_1/demo/schema/order_entry/ &&logfile_dir &vrs &&connect_string
    ..
    ```
3. 执行安装

    安装语法如下：

    ```sql
    SQL> @?/demo/schema/mksample <SYSTEM_password> <SYS_password>
     		<HR_password> <OE_password> <PM_password> <IX_password> 
    		<SH_password> <BI_password> EXAMPLE TEMP 
    		$ORACLE_HOME/demo/schema/log/ localhost:1521/pdb
    ```

    其中各参数解析如下：

    ```sql
    ----各sample schema的密码
    2.1     Decide on passwords for the Sample Schemas. Here, we are using
            placeholder names inside "<" and ">" brackets:

                    SYSTEM: <SYSTEM_password>
                    SYS:    <SYS_password>
                    HR:     <HR_password>
                    OE:     <OE_password>
                    PM:     <PM_password>
                    IX:     <IX_password>
                    SH:     <SH_password>
                    BI:     <BI_password>

    ---默认表空间名称，默认临时表空间名称，日志存放路径
    2.2     Verify the value for the default tablespace, the temporary
            tablespace, and the log file directory. For illustration purposes,
            the values are:

                    default tablespace: EXAMPLE
                    temporary tablespace: TEMP
                    log file directory: $ORACLE_HOME/demo/schema/log

            NOTE: Use your own passwords.

    ---pdb的连接方法，pdb为该db名称
    2.3     Verify the connect string for the database. For illustration
            purposes, the value of <connect_string> for database pdb is:

                    connect_string: localhost:1521/pdb
    ```

    实际执行命令为：

    ```sql
    @?/demo/schema/mksample oracle oracle oracle oracle oracle oracle oracle oracle EXAMPLE TEMP '/tmp/log' localhost:1521/ORCL12CPDB
    ```
4. 执行过程及结果

    ```sql
    [oracle@ORCLTEST ~]$ sqlplus /nolog
    SQL*Plus: Release 12.1.0.2.0 Production on Wed May 8 21:59:22 2024
    Copyright (c) 1982, 2014, Oracle.  All rights reserved.
    SQL> conn / as sysdba
    Connected.
    SQL> 
    SQL> 
    SQL> @?/demo/schema/mksample oracle oracle oracle oracle oracle oracle oracle oracle EXAMPLE TEMP '/tmp/log' localhost:1521/ORCL12CPDB
    specify password for SYSTEM as parameter 1:
    specify password for SYS as parameter 2:
    specify password for HR as parameter 3:
    specify password for OE as parameter 4:
    specify password for PM as parameter 5:
    specify password for IX as parameter 6:
    specify password for  SH as parameter 7:
    specify password for  BI as parameter 8:
    specify default tablespace as parameter 9:
    specify temporary tablespace as parameter 10:
    specify log file directory (including trailing delimiter) as parameter 11:
    specify connect string as parameter 12:
    Sample Schemas are being created ...
    Connected.

    ......
    Table cardinality relational and object tables

    OWNER  TABLE_NAME                       NUM_ROWS
    ------ ------------------------------ ----------
    HR     COUNTRIES                              25
    HR     DEPARTMENTS                            27
    HR     EMPLOYEES                             107
    HR     JOBS                                   19
    HR     JOB_HISTORY                            10
    HR     LOCATIONS                              23
    HR     REGIONS                                 4
    IX     AQ$_ORDERS_QUEUETABLE_G                 0
    IX     AQ$_ORDERS_QUEUETABLE_H                 2
    IX     AQ$_ORDERS_QUEUETABLE_I                 2
    IX     AQ$_ORDERS_QUEUETABLE_L                 2
    IX     AQ$_ORDERS_QUEUETABLE_S                 4

    .....

    Index cardinality (without  LOB indexes)

    OWNER  INDEX_NAME                DISTINCT_KEYS   NUM_ROWS
    ------ ------------------------- ------------- ----------
    HR     COUNTRY_C_ID_PK                      25         25
    HR     DEPT_ID_PK                           27         27
    HR     DEPT_LOCATION_IX                      7         27
    HR     EMP_DEPARTMENT_IX                    11        106
    HR     EMP_EMAIL_UK                        107        107
    HR     EMP_EMP_ID_PK                       107        107
    HR     EMP_JOB_IX                           19        107
    HR     EMP_MANAGER_IX                       18        106
    HR     EMP_NAME_IX                         107        107
    HR     JHIST_DEPARTMENT_IX                   6         10
    HR     JHIST_EMPLOYEE_IX                     7         10
    HR     JHIST_EMP_ID_ST_DATE_PK              10         10
    HR     JHIST_JOB_IX                          8         10
    HR     JOB_ID_PK                            19         19
    HR     LOC_CITY_IX                          23         23

    ....
    ```

    ```sql
    ---新创建用户
    SQL> select username from dba_users;

    USERNAME
    ------------------------------------------------------------------------------------------
    BI
    PM
    IX
    SH
    OE
    HR
    SCOTT
    ```

‍
