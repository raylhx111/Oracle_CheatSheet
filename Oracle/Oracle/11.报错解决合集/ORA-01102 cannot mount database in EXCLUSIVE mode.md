---
share: "true"
---

# ORA-01102: cannot mount database in EXCLUSIVE mode

# 现象：

安装完oracle 数据库后启时，遇到ora-01102错误。

```sql
oracle@r05a11016.yh.com:/home/oracle>sqlplus "/as sysdba"

SQL*Plus: Release 11.2.0.2.0 Production on Fri Apr 15 16:17:39 2011
Copyright (c) 1982, 2010, Oracle.  All rights reserved.
Connected to an idle instance.

SQL> startup
ORACLE instance started.
Total System Global Area 1.7103E+10 bytes
Fixed Size                  2243608 bytes
Variable Size            8455717864 bytes
Database Buffers         8623489024 bytes
Redo Buffers               21712896 bytes

ORA-01102: cannot mount database in EXCLUSIVE mode
```

‍

# 原因：

1. 在ORACLE_HOME/dbs/存在 "sgadef.dbf" 文件或者lk 文件。这两个文件是用来用于锁内存的。
2. oracle的 pmon, smon, lgwr and dbwr等进程未正常关闭。
3. 数据库关闭后，共享内存或者信号量依然被占用。

存在lk文件说明DATABASE 已经是MOUNT状态了,不用再次MOUNT。当 DATABASE 被UNMOUNT 后会被自动删除。如果DATABASE没有MOUNT，却依然存在这个问题，只有手工将其删除。

‍

# 解决方案：

1. 查看lk文件位置。

    ```sql
    oracle@r05a11016.yh.com:~/11.2.0>cd $ORACLE_HOME/dbs
    oracle@r05a11016.yh.com:~/dbs>ll lk*
    -rw-r----- 1 oracle oinstall 24 Apr 15 15:43 lkORCL
    ```
2. 使用fuser -u lkORCL 查看使用 lkORCL 文件的进程和用户。-u 为进程号后圆括号中的本地进程提供登录名。

    ```sql
    oracle@r05a11016.yh.com:~/dbs>/sbin/fuser -u lkORCL
    lkORCL:21007(oracle) 21009(oracle) 21015(oracle) 21019(oracle) 21023(oracle) 21025(oracle) 21027(oracle) 21029(oracle) 21031(oracle) 21033(oracle) 21035(oracle) 21037(oracle) 21039(oracle) 21041(oracle)
    ```
3. 使用 fuser -k  lkORCL  杀死这些正在访问lkORCL的进程   -k 杀死这些正在访问这些文件的进程。

    ```sql
    oracle@r05a11016.yh.com:~/dbs>fuser -k lkORCL
    lkORCL:21007 21009 21015 21019 21023 21025 21027 21029 21031 21033 21035 21037 21039 21041
    ```
4. 确认进程已经终止。

    ```sql
    oracle@r05a11016.yh.com:~/dbs>/sbin/fuser -u lkORCL
    ```
5. 重启数据库。

    ```sql
    oracle@r05a11016.yh.com:~/dbs>sqlplus "/as sysdba" 

    SQL*Plus: Release 11.2.0.2.0 Production on Fri Apr 15 16:30:16 2011
    Copyright (c) 1982, 2010, Oracle.  All rights reserved.
    Connected to an idle instance.

    SQL> startup
    ORACLE instance started.
    Total System Global Area 1.7103E+10 bytes
    Fixed Size                  2243608 bytes
    Variable Size            8455717864 bytes
    Database Buffers         8623489024 bytes
    Redo Buffers               21712896 bytes
    Database mounted.
    Database opened.
    ```

‍
