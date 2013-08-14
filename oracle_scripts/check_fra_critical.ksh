#!/bin/ksh
#
# FIlename:  check_fra_critical.ksh
#
# Purpose:
#	Send TXT message to the DBA when FRA usage is > 92%
#
# Dependency:
#
#
# Author       Created         Comments
# J. Ching     11/11/11        Initial Release
#
#
###############################################################
HOSTNAME=`hostname`; export HOSTNAME
CRITICALLIMIT=90

MAILTO="email@address"; 		export MAILTO
TXTTO="text@address"; 	export TXTTO
SCRIPTDIR="/usr/local/sbin/oracle_scripts"; export SCRIPTDIR
ORATAB="/etc/oratab";			export ORATAB
TODAY=`date +"%F %k:%M"`; 		export TODAY
HOUR=`date +"%k"`; 			export HOUR
MIN=`date +"%M"` ; 			export MIN
RPT="$SCRIPTDIR/fra_rpt.txt"; 		export RPT

echo "--------------------------------------------------------------"
echo "      SCRIPT $0 "
echo "--------------------------------------------------------------"

if [ -f $ORATAB ]; then
        ls -al $ORATAB
else
        echo [!!!!---------] UNABLE TO LOCATE oratab.  Exit with error.
        echo "!!!! No oratab found.  Abandoning script." >> $ORAEXP_REPORT
        exit 1
fi

if [ -f "/tmp/fra_usage.txt" ]
then
    /bin/rm /tmp/fra_usage.txt
fi

cat $ORATAB | while read LINE
do
        case $LINE in
        \#*)    ;;
        *)      SID=`echo $LINE | awk -F: '{print $1}' -`; export SID
                ORACLE_HOME=`echo $LINE | awk -F: '{print $2}' -`; export ORACLE_HOME
                UPORDOWN=`echo $LINE | awk -F: '{print $3}' -`; export UPORDOWN
		echo "ORACLE_SID=$SID, ORACLE_HOME=$ORACLE_HOME, UPORDOWN=$UPORDOWN"
		# For each SID in /etc/oratab, we will check FRA usage on all of them
		if [ "$UPORDOWN" = "Y" ]; then
			# Check if instance is running
			ISRUNNING=`ps ax | grep ora_smon_${SID} | egrep -v grep`; export ISRUNNING
			export STATUSF=/tmp/check_fra_instance_running
			echo $ISRUNNING > $STATUSF
			echo "======> $ISRUNNING"
			if [ "$ISRUNNING" = "" ]; then
				echo " Instance $SID is not running, unable to check FRA"
				/bin/mail -s "FRA CHECK: $SID not running on `hostname`" $MAILTO < /tmp/check_fra_instance_running
			fi
export ORACLE_SID=$SID
$ORACLE_HOME/bin/sqlplus "/ as sysdba" << EOF
set linesize 8
set echo off
set verify off
set feedback off
set heading off
set termout off
col percent for 999
spool /tmp/fra_usage.txt
select ROUND((space_used/space_limit)*100) percent
from v\$recovery_file_dest;
spool off;
EOF
#
			SZ=`sed -n 4p /tmp/fra_usage.txt`; export SZ
			echo "$SZ - $ORACLE_SID FRA %usage on $TODAY" > $RPT
echo "--DEBUG: FRA Overall Usage is [$SZ] percent "
#
			if [[ "$SZ" -gt $CRITICALLIMIT ]]
			then
			    /bin/mail -s "$ORACLE_SID FRA report" $TXTTO < $RPT 
			    print "Page sent at ${HOUR} : ${MIN}"
			fi
		fi   #--if UPORDOWN
	esac
done

echo "--------------------------------------------------------------"
