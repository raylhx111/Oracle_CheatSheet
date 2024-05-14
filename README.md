# Oracle_CheatSheet
Oracle Cheat Sheet

# Check database usage (检查表空间)

### 英文版
```
SELECT d.tablespace_name "Name", d.status "Status", 
       TO_CHAR (NVL (a.BYTES / 1024 / 1024, 0), '99,999,990.90') "Size (M)",
          TO_CHAR (NVL (a.BYTES - NVL (f.BYTES, 0), 0) / 1024 / 1024,
                   '99999999.99'
                  ) USE,
       TO_CHAR (NVL ((a.BYTES - NVL (f.BYTES, 0)) / a.BYTES * 100, 0),
                '990.00'
               ) "Used %"
  FROM SYS.dba_tablespaces d,
       (SELECT   tablespace_name, SUM (BYTES) BYTES
            FROM dba_data_files
        GROUP BY tablespace_name) a,
       (SELECT   tablespace_name, SUM (BYTES) BYTES
            FROM dba_free_space
        GROUP BY tablespace_name) f
 WHERE d.tablespace_name = a.tablespace_name(+)
   AND d.tablespace_name = f.tablespace_name(+)
   AND NOT (d.extent_management LIKE 'LOCAL' AND d.CONTENTS LIKE 'TEMPORARY')
UNION ALL
SELECT d.tablespace_name "Name", d.status "Status", 
       TO_CHAR (NVL (a.BYTES / 1024 / 1024, 0), '99,999,990.90') "Size (M)",
          TO_CHAR (NVL (t.BYTES, 0) / 1024 / 1024, '99999999.99') USE,
       TO_CHAR (NVL (t.BYTES / a.BYTES * 100, 0), '990.00') "Used %"
  FROM SYS.dba_tablespaces d,
       (SELECT   tablespace_name, SUM (BYTES) BYTES
            FROM dba_temp_files
        GROUP BY tablespace_name) a,
       (SELECT   tablespace_name, SUM (bytes_cached) BYTES
            FROM v$temp_extent_pool
        GROUP BY tablespace_name) t
 WHERE d.tablespace_name = a.tablespace_name(+)
   AND d.tablespace_name = t.tablespace_name(+)
   AND d.extent_management LIKE 'LOCAL'
   AND d.CONTENTS LIKE 'TEMPORARY'
order by 5 desc;
```

### 中文版
```
SELECT UPPER(F.TABLESPACE_NAME) "表空间名", 
D.TOT_GROOTTE_MB "表空间大小(M)", 
D.TOT_GROOTTE_MB - F.TOTAL_BYTES "已使用空间(M)", 
TO_CHAR(ROUND((D.TOT_GROOTTE_MB - F.TOTAL_BYTES) / D.TOT_GROOTTE_MB * 100,2),'990.99') "使用比", 
F.TOTAL_BYTES "空闲空间(M)", 
F.MAX_BYTES "最大块(M)" 
FROM (SELECT TABLESPACE_NAME, 
ROUND(SUM(BYTES) / (1024 * 1024), 2) TOTAL_BYTES, 
ROUND(MAX(BYTES) / (1024 * 1024), 2) MAX_BYTES 
FROM SYS.DBA_FREE_SPACE 
GROUP BY TABLESPACE_NAME) F, 
(SELECT DD.TABLESPACE_NAME, 
ROUND(SUM(DD.BYTES) / (1024 * 1024), 2) TOT_GROOTTE_MB 
FROM SYS.DBA_DATA_FILES DD 
GROUP BY DD.TABLESPACE_NAME) D 
WHERE D.TABLESPACE_NAME = F.TABLESPACE_NAME 
ORDER BY 4 DESC;
```

