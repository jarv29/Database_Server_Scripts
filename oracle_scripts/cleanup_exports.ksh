#!/bin/ksh
#
# Cleanup exports area (/u03/expdp/$SID)
# On CYGWIN or Linux, use "find ./" instead of "find ."
#
# Output file (from crontab listing) is defined in $OUTPUTFILE below 
# This is the file that should be sent in the email.
#
# AUthor       Created          Comments
# J. CHing     08/28/08         Initial Release
# J. CHing     01/03/11         Modified for RH Linux 
##################################################################
#
#if [ $# -lt 1 ]; then
#      echo "Usage: $0 <SID> "
#	echo "Eg.  $0  <SID>"
#fi

TODAY=`date '+%Y-%m-%d'`; export TODAY

HOSTNAME=`hostname`; export HOSTNAME
#SID="$1"; export SID
DBA="email@address"; export DBA
OUTPUTFILE="/tmp/cleanup_expdp_$TODAY.out"; export OUTPUTFILE
NUM_FILES=0; export NUM_FILES

echo `date`                       > $OUTPUTFILE
echo $HOSTNAME                   >> $OUTPUTFILE
echo "-------------------------" >> $OUTPUTFILE
echo "Host is: $HOSTNAME"        >> $OUTPUTFILE
echo "-------------------------" >> $OUTPUTFILE
/bin/df -h >> $OUTPUTFILE
echo " "   >> $OUTPUTFILE
echo " " 
echo " " 
echo "--- Dir/Files to remove in $HOSTNAME are listed" 
echo "--- in $OUTPUTFILE"
NUM_FILES=`/usr/bin/find /u03/expdp -name "full_expdp_*.dmp" -mtime +1 | wc -l`

/usr/bin/find /u03/expdp -name "full_expdp_*.dmp" -mtime +1 -exec ls -al {} \; >> $OUTPUTFILE
echo " " 

/usr/bin/find /u03/expdp -name "full_expdp_*.dmp" -mtime +1 -exec rm -rf {} \;
/usr/bin/find /u03/expdp -name "full_expdp_log_*.log" -mtime +1 -exec rm -rf {} \;


# Remove backup logs, weekly
/usr/bin/find /usr/local/sbin/oracle_scripts/backup/logs -name "*.log" -mtime +7 -exec rm -f {} \;
/usr/bin/find /tmp -name "cleanup_expdp*" -mtime +7 -exec rm -f {} \;
 
echo " " 
echo "--- Deletion completed.  " 

