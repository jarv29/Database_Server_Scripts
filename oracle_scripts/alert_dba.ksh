#!/bin/ksh
###
## alert_dba.ksh
###
C_DATE=`date +"%a %b %d %H"`
echo "-----------"
echo $C_DATE
echo "-----------"

DOW=`date '+%a'`; export DOW
export HOSTNM=`hostname`
export LOGDIR="/usr/local/sbin/oracle_scripts/logs"
export ALERT_FINDS=$LOGDIR/alert_rpt_$DOW
export ORA_ERR=$LOGDIR/alert_rpt_error_$DOW
export DBA="email@address"
export ORACLE_BASE="/u01/app/oracle"
touch $ALERT_FINDS
ls -al $ALERT_FINDS

echo "******************************"
echo "Today is `date`"
echo "******************************"
#
# Search through oratab for instance names
#
export ORATAB=/etc/oratab
cat $ORATAB | while read LINE
do
	case $LINE in
	\#*)	;;
	*)	SID=`echo $LINE|awk -F: '{print $1}' -`
		lcSID=`echo $SID | awk '{print tolower($0)}'`
		echo "SID is ...$SID, lowercase is $lcSID" | tee $ALERT_FINDS
		ORACLE_HOME=`echo $LINE | awk -F: '{print $2}' -`
		echo "       ORACLE_HOME is $ORACLE_HOME"
		UPORDOWN=`echo $LINE | awk -F: '{print $3}' -`
		if [[ $UPORDOWN = Y ]]; then
			LOGFILE="alert_${SID}.log"
			DIAG_LOC="$ORACLE_BASE/diag/rdbms/$lcSID/$SID/trace"
			cd $DIAG_LOC
			if [[ ! -r $LOGFILE ]]; then
				echo "$LOGFILE does not exist, probable cause is log rotation."
			else
				echo "   "
				echo "$LOGFILE exists, checking contents...."
sed -n "/^$C_DATE/,$ p" $LOGFILE >> $ALERT_FINDS
#
echo "---------- Begin extracting error... at $C_DATE "
cat $ALERT_FINDS
echo   "---------- End extracting error"
echo   "     "
sed -n "/^ORA-/ p" $ALERT_FINDS >  $ORA_ERR
#
# Variable LN_CNT initialized to the number of lines in the ora_errors file
#
LC_CNT=`wc -l < $ORA_ERR`
#
if [[ $LN_CNT -ge 1 ]]
then
     echo ">>>> ORA- Errors in $SID <<<<<"
     echo " ORA- Error exists"
     echo " Error log is $ORA_ERR"
     /bin/ls -al $ORA_ERR
     echo "    "
     /bin/mail -s "${SID}: ALERT LOG has Errors" $DBA < $ALERT_FINDS
else
     /bin/rm $ORA_ERR
fi
			fi 
		fi
	esac
done
