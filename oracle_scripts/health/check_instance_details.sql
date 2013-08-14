REM ------------------------------------------------------
REM    Purpose:
REM         Get details from the instance
REM
REM    Dependency:
REM       Called from "check_instance_details.sql"
REM
REM  Author   Date       Comments
REM  JCHING   06/09/08   Initial release
REM  JCHING   11/16/12   Trim
REM ------------------------------------------------------

set linesize 100
set pagesize 60

prompt |==|==|==|==|==|==|==|==|==|==|==|==|==|==|==|==|==|==|==|==|==|==|==|==|==|==|==|==|

REM ---------- Todays date ------------
select to_char(sysdate, 'DD-MON-YYYY HH24:MI:SS') inst_details_rundate  from dual;



REM ---------- Check dbname, mode, flashback -------

col dbname         for a18 
col dbid           for 999999999999
col db_unique_name for a10
col log_mode       for a11
col flashback_on   for a12
col instance_role  for a18
select d.name || ' (' || d.db_unique_name || ')' dbname, d.dbid,  d.created, d.log_mode, d.flashback_on,
       i.instance_name, i.startup_time
from   v$database d, v$instance i;


REM ---------- Check current_SCN, recovery_file_dest and recovery size

col "Current time" for a20
col current_scn    for 9999999999999
col "FRA space limit" for 999,999,999,999,999
col "FRA_PCT_USED"  for 99.999

select to_char(sysdate,'MM-DD-YYYY HH24:MI:SS') "Current time" , d.current_scn 
,      r.space_limit "FRA space limit", (r.space_used/r.space_limit * 100) FRA_PCT_USED
from V$database d, v$recovery_file_dest r
;


REM ---------- Check init parameters -----------------

col name  for a30
col value for a46
select name, value from v$parameter where name in
('db_recovery_file_dest','db_recovery_file_dest_size',
 'shared_pool_size','large_pool_size',
 'sga_target','sga_max_size', 'spfile',
 'db_flashback_retention_target','fast_start_mttr_target',
 'log_archive_format', 'log_archive_dest_1', 'log_archive_dest_10',
 'log_buffer',
 'background_dump_dest','core_dump_dest','user_dump_dest','pga_aggregrate_target');


REM ---------- Check control files -------------------

col control_file_names for a50
select name control_file_names from V$controlfile;
REM ---select name, status from v$datafile;



REM ---------- Check data files ----------------------

col system_tablespace for a12
col datafile for a45
select t.name system_tablespace, f.name datafile
from   v$datafile f, v$tablespace t
where  f.ts# = t.ts# 
and    t.ts# = 0;

select count(*) num_of_datafiles from V$datafile;


REM ---------- Check redo logs -----------------------

col member for a38

select l1.member, l2.bytes, l2.archived, l2.status
from v$logfile l1, v$log l2
where l1.group#=l2.group#


REM ---------- Check locked user accounts -------------

col username for a18
col password for a25
select username as user_is_locked, password from dba_users where lock_date is not null;


REM --------- Check current users whose p/w expires in 3 months ------
REM --------- current users are not locked ---------------------------

col username for a18
col password for a25
col default_tablespace for a22

select username, default_tablespace, expiry_date from dba_users
 where lock_date is null and   expiry_date < add_months(sysdate,3)
order by username;




REM --------- CHeck monitoring users -----------------

select username as monitoring_users from dba_users where username in ('BACKUP','IMTMON');




REM ---------- Check EXPDP directory location ----------------

col owner for a8
col directory_name for a22
col directory_path for a40
select owner, directory_name, directory_path from dba_directories;


REM ---------- Check for stale Table statistics -----------------

prompt Checking for stale [Table] statistics....
select stale_stats stale_table, count(1)
from dba_tab_statistics
group by stale_stats;



REM ---------- Check for stale Index statistics

prompt Checking for stale [Index] statistics...
select stale_stats stale_index, count(1) 
from dba_ind_statistics 
group by stale_stats;

