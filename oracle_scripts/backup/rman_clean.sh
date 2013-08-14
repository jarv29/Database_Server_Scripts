#!/bin/sh
#
#  RMAN Cleanup 
#
#  Host: dev-s25-1
# -------------------------------------------------------------------------
#
if [ $# -lt 2 ]; then
        echo "Usage: $0 <BACKUP_SID> <No of days to keep backup>"
        exit 1
fi
#
# Input variables
BACKUP_SID="$1";              export BACKUP_SID
KEEPDAYS="$2";                export KEEPDAYS
#
#
#  Set up logistics
#
ORACLE_SID=${BACKUP_SID}; export ORACLE_SID
ORACLE_HOME=`grep "^${BACKUP_SID}" /etc/oratab | awk -F: '{print $2}'`; export ORACLE_HOME
echo "Home is $ORACLE_HOME"
#
BACKUPDIR="/usr/local/sbin/oracle_scripts/backup"; export BACKUPDIR
LOGDIR="/usr/local/sbin/oracle_scripts/backup/logs"; export LOGDIR
RCVFILE="/usr/local/sbin/oracle_scripts/backup/rman_clean.rcv"; export RCVFILE
MAILTO="email@address";            	export MAILTO
FIRSTRUN=`date '+%Y%m%d'`;		export FIRSTRUN
RUNDATE=`date '+%Y-%m-%d'`;		export RUNDATE
DOW=`date '+%a'`; 			export DOW
HOSTNAME=`cat /proc/sys/kernel/hostname | awk -F . '{print $1}'`
echo ">>> $ORACLE_HOME"
#
# Remove old RCV file
#
if [ -f $RCVFILE ]; then
	/bin/rm $RCVFILE
fi
#
#
# Create RCV file
#
echo "show all;"                                                         > $RCVFILE
echo "CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF $KEEPDAYS DAYS;" >> $RCVFILE
echo "CONFIGURE CONTROLFILE AUTOBACKUP ON;"                             >> $RCVFILE
echo "crosscheck backup;"                                               >> $RCVFILE
echo "crosscheck archivelog all;"                                       >> $RCVFILE
echo "delete expired archivelog all;"                                   >> $RCVFILE
echo "delete expired backupset;"                                        >> $RCVFILE
echo "list recoverable backup of database;"                             >> $RCVFILE
echo "delete obsolete;"                                                 >> $RCVFILE

#
#
# 
#
$ORACLE_HOME/bin/rman target sys/orac13\$apu08\$sys CMDFILE $RCVFILE LOG=$LOGDIR/rman_clean_${BACKUP_SID}_$FIRSTRUN.log
#
