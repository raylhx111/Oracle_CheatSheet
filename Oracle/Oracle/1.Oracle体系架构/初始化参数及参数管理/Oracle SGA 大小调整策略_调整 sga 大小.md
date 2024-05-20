---
share: "true"
---

# Oracle SGA 大小调整策略_调整 sga 大小

查看SGA信息

```sql
SQL> show parameter SGA

NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
allow_group_access_to_sga            boolean     FALSE
lock_sga                             boolean     FALSE
pre_page_sga                         boolean     TRUE
sga_max_size                         big integer 1488M
sga_min_size                         big integer 0
sga_target                           big integer 0
unified_audit_sga_queue_size         integer     1048576
SQL>
```

修改 SGA 必须保持的原则：
1).sga_target 不能大于 sga_max_size，可以设置为相等。
2).SGA 加上 PGA 等其他进程占用的内存总数必须小于操作系统的物理内存。

确定启动是用哪个参数文件

```sql
SQL> show parameter spfile;

NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
spfile                               string      /opt/oracle/product/19c/dbhome
                                                 _1/dbs/spfileORCLADGPRIM.ora
```

调整原理
1.SGA_MAX_SIZE 是静态参数，而 SGA_TARGET 可以动态修改，当要改的 SGA_TARGET 值超过 SGA_MAX_SIZE 的值时，
必须指定 scope=spfile, 重启后才能修改成功。
如果此时没有设置过 SGA_MAX_SIZE 得值，那么无论是改大还是改小，重启数据库后，SGA_MAX_SIZE 都回跟着 SGA_TARGET 做调整。
2. 当 SGA_TARGET 设置为零时，表示禁用内存组件由 SGA 自动管理。
3. 当给 SGA_TARGET 设置非零值时，表示采用内存组件内存由 oracle 动态调整，如 shared pool,db buffer cache 等，
这些内存组件只会跟着 SGA 的大小动态进行调整（增大或减小），与其他值无关
4. 如果是先设置了 SGA_MAX_SIZE 的值，再设置了 SGA_TARGET，那么只有当 SGA_TARGET 设置的值超过 SGA_MAX_SIZE 的值时，
SGA_MAX_SIZE 才会在重启生效后，调整到与 SGA_TARGET 的值一致，反之则不会改变。

总结：SGA_TARGET 一定要小于等于 SGA_MAX_SIZE，负责重启报错
【调整过程】

1. 确认是否可以修改

    ```sql
    SQL> select name,bytes/1024/1024 "size(MB)",resizeable from v$sgainfo;

    NAME                               size(MB) RES
    -------------------------------- ---------- ---
    Fixed SGA Size                   8.48477173 No
    Redo Buffers                     7.51171875 No
    Buffer Cache Size                       592 Yes
    In-Memory Area Size                       0 No
    Shared Pool Size                        240 Yes
    Large Pool Size                          16 Yes
    Java Pool Size                           16 Yes
    Streams Pool Size                         0 Yes
    Shared IO Pool Size                      48 Yes
    Data Transfer Cache Size                  0 Yes
    Granule Size                             16 No
    Maximum SGA Size                 1487.99649 No
    Startup overhead in Shared Pool  172.698494 No
    Free SGA Memory Available               608

    14 rows selected.
    ```
    因为 SGA_TARGET 设置为零时，表示禁用内存组件由 SGA 自动管理，从上面可以看出 Maximum SGA Size 不可以调整。
2. 修改 sga_target

    ```sql
    SQL> alter system set sga_target=1312m scope=spfile;

    System altered.
    ```
3. 重启数据库
    `SYS@PROD> startup force`​
4. 查看修改后的sga_target已修改未1312M。

    ```sql
    SQL> show parameter SGA

    NAME                                 TYPE        VALUE
    ------------------------------------ ----------- ------------------------------
    allow_group_access_to_sga            boolean     FALSE
    lock_sga                             boolean     FALSE
    pre_page_sga                         boolean     TRUE
    sga_max_size                         big integer 1488M
    sga_min_size                         big integer 0
    sga_target                           big integer 1312M		---已修改为1312M
    unified_audit_sga_queue_size         integer     1048576
    ```
5. 调整 sga_max
    SYS@PROD>alter system set sga_max_size=1600m scope=spfile;
    SYS@PROD> show parameter sga

    补充：若启动有报错，用以下方法修改参数重启即可
    SYS@PROD> create pfile=’/home/oracle/init1.ora’ from spfile;
    SYS@PROD> create spfile from pfile=’/home/oracle/init1.ora’;
