方法一：添加数据文件。
查询需要添加的表空间的数据文件：
SELECT tablespace_name, file_name  FROM dba_data_files where tablespace_name ='[Table space name]' ORDER BY tablespace_name;

添加表空间：
ALTER TABLESPACE "[Table space name]" ADD DATAFILE '[数据文件路径]' SIZE 4096M ;

RAC :
ALTER TABLESPACE "TEMPSEG" ADD DATAFILE '+DATADG1/oradata/opera/xxxxxxx' SIZE 5M  autoextend on next 100M maxsize 4096M; (自动扩展)

添加临时表空间：
ALTER TABLESPACE "TEMPSEG" ADD TEMPFILE 'I:\oracle\OraData\opera\TEMPSEG02.DBF' SIZE 4096M ;

ALTER TABLESPACE &tablespace_name ADD TEMPFILE '&datafile_name' SIZE 2G;

ALTER TABLESPACE "TEMPSEG" ADD TEMPFILE '+DATADG1/oradata/opera/tempseg02.dbf' SIZE 5M  autoextend on next 100M maxsize 4096M;

SELECT TABLESPACE_NAME, FILE_ID, FILE_NAME, BYTES/1024/1024 AS "SPACE(M)"
  FROM DBA_TEMP_FILES
 WHERE TABLESPACE_NAME = '&tablespace_name';

select file_name,tablespace_name,autoextensible,maxbytes,user_bytes,online_status from DBA_TEMP_FILES order by tablespace_name,file_name;

select file_name , tablespace_name , autoextensible, maxbytes from dba_temp_files;

方法二：扩展数据文件。
查看数据文件是否可扩展，最大扩展容量：
select TABLESPACE_NAME, FILE_NAME,STATUS,ONLINE_STATUS,AUTOEXTENSIBLE,TO_CHAR (NVL (MAXBYTES / 1024 / 1024, 0), '99,999,990.90') "Max Size (M)"  from dba_data_files ;

开启数据文件自动扩展：
alter database datafile '数据文件路径' autoextend off/on;

开启数据文件自动扩展，无最大限制。
alter database datafile '数据文件路径' autoextend on next 10M maxsize unlimited;

开启数据文件自动扩展，有最大限制：
alter database datafile '数据文件路径' autoextend on next 512M MAXSIZE 8192M;
MAXSIZE 值用把GB换算成MB再更新
