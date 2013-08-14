#!/bin/sh
#
# Output file name matters based on the ORACLE_SID specified.
# sis-prod-db-1
#
# 2012-11-16
#################################################################################################
ORACLE_HOME=/u01/app/oracle/product/11.2.0.3/dbhome_1; export ORACLE_HOME
FIRSTRUN=`date '+%Y%m%d'`;
DBA="email@address"; export DBA

HEALTHDIR="/usr/local/sbin/oracle_scripts/health"; export HEALTHDIR
### /usr/local/sbin/oracle_scripts/health/check_instance_details.sql

# Clean up old logs
cd $HEALTHDIR
find . -name "cf_PRODSTU*.txt" -mtime +10 -exec rm {} \;
find . -name "check_PRODSTU*.lst" -mtime +10 -exec rm {} \;


ORATAB="/etc/oratab";    export ORATAB

cat $ORATAB | while read LINE
do
	case $LINE in
	\#*)	;;
	*)	ORACLE_SID=`echo $LINE | awk -F: '{print $1}' -`; export ORACLE_SID
echo "-------->>>-------->>>----------->>>---------->>> Processing $ORACLE_SID"
		ORACLE_HOME=`echo $LINE | awk -F: '{print $2}' -`; export ORACLE_HOME
		UPORDOWN=`echo $LINE | awk -F: '{print $3}' -`; export UPORDOWN
		if [ "$UPORDOWN" = "Y" ]; then
$ORACLE_HOME/bin/sqlplus / as sysdba <<EOF
spool check_${ORACLE_SID}_${FIRSTRUN}
@$HEALTHDIR/check_instance_details.sql
spool off;

alter database backup controlfile to trace as '/usr/local/sbin/oracle_scripts/health/cf_${ORACLE_SID}_${FIRSTRUN}.txt' reuse;
EOF
		fi
	esac
done
