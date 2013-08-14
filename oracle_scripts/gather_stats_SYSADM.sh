#!/bin/sh
export ORACLE_HOME=/u01/app/oracle/product/11.2.0.3/dbhome_1
export MAILTO="email@address"
export OUTFILE="/usr/local/sbin/oracle_scripts/gather_stats_output.log"
export ORATAB="/etc/oratab"

cat $ORATAB | while read LINE
do
	case $LINE in
	\#*)	;;
	*)	SID=`echo $LINE|awk -F: '{print $1}' -`
		lcSID=`echo $SID | awk '{print tolower($0)}'`
		echo "SID is ...$SID, lowercase is $lcSID" | tee $ALERT_SECT
		ORACLE_HOME=`echo $LINE | awk -F: '{print $2}' -`
		echo "ORACLE_HOME is $ORACLE_HOME"
		UPORDOWN=`echo $LINE | awk -F: '{print $3}' -`
		if [ "$UPORDOWN" = "Y" ]; then
export ORACLE_SID=$SID
$ORACLE_HOME/bin/sqlplus "/ as sysdba" <<EOF
spool /usr/local/sbin/oracle_scripts/gather_stats_${lcSID}_output.log
select name from v\$database;
select to_char(sysdate,'MM-DD-YYYY HH24:MI:SS') start-time from dual;
exec dbms_stats.gather_schema_stats(ownname=>'SYSADM', degree=>DBMS_STATS.AUTO_DEGREE, cascade=>TRUE, method_opt=>'FOR ALL COLUMNS SIZE AUTO');
select to_char(sysdate,'MM-DD-YYYY HH24:MI:SS') end-time from dual;
spool off;
EOF
		fi
	esac
done

