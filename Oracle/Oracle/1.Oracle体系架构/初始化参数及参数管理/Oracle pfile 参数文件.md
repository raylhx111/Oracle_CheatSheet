---
share: "true"
---

# Oracle pfile 参数文件

Oracle 数据库启动时，第一步开启到 nomount 状态，需要使用到参数文件。

pfile 就是参数文件的一种，全称：**初始化参数文件（Initialization Parameters Files）** ！

##### pfile 介绍

**我们常说的 pfile 参数文件也就是 initSID.ora 文件，initSID.ora 是文本文件。**

在 Oracle 9i 以前，Oracle 使用 `pfile` 存储初始化参数设置，参数文件的修改需要手工进行，这些参数在实例启动时被读取，通过 pfile 的修改需要重启实例才能生效。

**以下为 Linux 下单机数据库的示例：**

```shell
[oracle@ORA11 /]$ ls $ORACLE_HOME/dbs
hc_DBUA0.dat  hc_ORA11.dat  init.ora  initORA11.ora  lkORA11  orapwORA11  snapcf_ORA11.f  spfileORA11.ora
```

可以通过 `strings` 命令查看文件内容：

```shell
[oracle@orcl:/u01/app/oracle/product/12.2.0/db/dbs]$ strings initorcl.ora
orcl.__data_transfer_cache_size=0
orcl.__db_cache_size=457179136
orcl.__inmemory_ext_roarea=0
orcl.__inmemory_ext_rwarea=0
orcl.__java_pool_size=4194304
orcl.__large_pool_size=8388608
orcl.__oracle_base='/u01/app/oracle'#ORACLE_BASE set from environment
orcl.__pga_aggregate_target=180355072
orcl.__sga_target=713031680
orcl.__shared_io_pool_size=25165824
orcl.__shared_pool_size=201326592
orcl.__streams_pool_size=0
*._optimizer_cartesian_enabled=FALSE
*.audit_file_dest='/u01/app/oracle/admin/orcl/adump'
*.audit_trail='NONE'
*.compatible='12.2.0'
*.control_files='/oradata/orcl/control01.ctl','/oradata/orcl/control02.ctl'
*.db_block_size=8192
*.db_create_file_dest='/oradata'
*.db_name='orcl'
*.deferred_segment_creation=FALSE
*.diagnostic_dest='/u01/app/oracle'
*.dispatchers='(PROTOCOL=TCP) (SERVICE=orclXDB)'
*.event='10949 trace name context forever:28401 trace name context forever,level 1:10849 trace name context forever, level 1:19823 trace name context forever, level 90'
*.local_listener='LISTENER_ORCL'
*.log_archive_dest_1='LOCATION=/archivelog'
*.log_archive_format='%t_%s_%r.dbf'
*.nls_language='AMERICAN'
*.nls_territory='AMERICA'
*.open_cursors=300
*.pga_aggregate_target=170m
*.processes=200
*.remote_login_passwordfile='EXCLUSIVE'
*.result_cache_max_size=0
*.sga_target=679m
*.undo_tablespace='UNDOTBS1'
```

其内容主要为数据库的 db_name、数据库的版本、控制文件的位置、内存的分配、一些系统文件的路径、字符集、session 的数量等等，一些数据库最基本的信息。

如果需要修改 pfile 文件，因为是文本文件，所以直接打开文件修改即可。

**initSID.ora 文件通常用于数据库rman备份恢复。**

**注意： 使用 pfile 启动的数据库，使用 alter system 和 alter session 在线修改参数后，只会保存到内存中，重启后即失效。如果需要重启依然生效，应该手动修改 pfile 参数文件。** 

参数文件位置  
=========

pfile 参数文件通常存在于以下目录下：

* **Windows：**  $ORACLE_HOME/database
* **Linux：**  $ORACLE_HOME/dbs

* **pfile 文件格式为：**​`initSID.ora`​​

##### 实例讲解

使用 pfile 启动数据库后修改参数，数据库重启后参数失效

如果使用 pfile 文件启动数据库后，通过 alter system 修改参数后，数据库重启之后参数还会生效吗？

**下面依然做个实验吧：**

**1、确认当时数据库环境是 pfile 文件启动：**

```sql
sqlplus / as sysdba
show parameter spfile
```

**2、在线修改参数：**

```sql
sqlplus / as sysdba

SQL>alter system set undo_retention=500;

System altered.

SQL>show parameter undo_retention;

NAME                                 TYPE                              VALUE
------------------------------------ --------------------------------- ---------
undo_retention                       integer                           500
```

**3、重启数据库，查看参数是否生效：**

```sql
sqlplus / as sysdba
shutdown immediate
startup

SQL> show parameter undo_retention;

NAME                                 TYPE                              VALUE
------------------------------------ --------------------------------- ---------
undo_retention                       integer                           900
```

​ 通过上述演示，发现 pfile 启动的数据库，在线修改动态参数只会在内存中生效，一但重启即失效。

**4、可以通过手动修改 initSID.ora 文件：**

```shell
cd $ORACLE_HOME/dbs
vi initorcl.ora

##添加以下参数：
*.undo_retention=500
```

如上图所示，在最后一行添加需要修改的参数即可。

**5、重启数据库生效：**

```sql
sqlplus / as sysdba
shutdown immediate
startup

SQL>show parameter undo_retention;

NAME                                 TYPE                              VALUE
------------------------------------ --------------------------------- ---------
undo_retention                       integer                           500
```

​ 通过 pfile 参数启动数据库，每次修改参数都需要重启数据库才会永久生效，因此极为麻烦，所以不建议使用，除非特殊情况。
