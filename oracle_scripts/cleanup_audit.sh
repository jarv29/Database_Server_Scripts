#!/bin/ksh
#
# Cleanup audit area ($ORACLE_BASE/admin/<SID>/adump)
#
# Output file (from crontab listing) is defined in $OUTPUTFILE below 
# This is the file that should be sent in the email.
#
# AUthor       Created          Comments
# J. CHing     08/28/08         Initial Release
# J. CHing     01/03/11         Modified for RH Linux 
##################################################################
#
if [ $# -lt 2 ]; then
    echo "Usage: $0 <SID> <ORACLE_BASE>"
    echo "Eg.  $0 DEVIMG </opt/oracle>"
    exit 1
fi

TODAY=`date '+%Y-%m-%d'`; export TODAY

HOSTNAME=`hostname`; export HOSTNAME
SID="$1"; export SID
ORACLE_BASE="$2"; export ORACLE_BASE
DBA="email@address"; export DBA
OUTPUTFILE="/tmp/cleanup_audit_$SID_$TODAY.out"; export OUTPUTFILE

echo `date`                       > $OUTPUTFILE
echo "---------------------------------" >> $OUTPUTFILE
echo "Host/SID: $HOSTNAME, $SID"         >> $OUTPUTFILE
echo "---------------------------------" >> $OUTPUTFILE
echo " " 
/usr/bin/find $ORACLE_BASE/admin/${SID}/adump/ -iname "*\.aud" -daystart -mtime +2 -exec rm {} \;
echo " " 
echo "--- Deletion of audit files completed.  " 

#
# Cleanup
/usr/bin/find /tmp -name "cleanup_audit*" -mtime +7 -exec rm {} \;
