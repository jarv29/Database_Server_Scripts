#!/bin/sh
# The name of this script
SCRIPT_NAME=test_login.sh
###################################################################
#
# Check for Invalid Command Line Arguments
# $1 = ORACLE_SID
#
###################################################################
if [ $# -lt 1 ]
then
  echo "Usage: $SCRIPT_NAME <ORACLE_SID>"
  echo "Example: $SCRIPT_NAME DWHSE "
  exit
fi

###################################################################
#
# Setup Script Variables
#
###################################################################
#This is the oracle_sid of the instance that the oracle environment
#will be setup for.
export ORACLE_SID=$1
export MAILTO="email@address"
#export TODAY=`date '+%Y-%m-%d'`; export TODAY

export SCRIPTDIR=/usr/local/sbin/oracle_scripts
#
# Initially we need some oracle path in the PATH for the dbhome command
# to be found. We reset the PATH variable to the proper oracle_home/bin
# below
#
export ORACLE_HOME=/u01/app/oracle/product/11.2.0.3/dbhome_1
export PATH=$ORACLE_HOME/bin:/usr/local/bin:$PATH

export ORAENV_ASK=NO

. /usr/local/bin/oraenv

export ORAENV_ASK=YES

#echo "Starting Create PIN for ORACLE_SID: $ORACLE_SID"

### ???????
#MYPWD=`eval $MYPWD`

###################################################################
#
# Run our SQL Plus Commands
#
###################################################################
sqlplus dummy/${dummypass} <<ENDOFSQL
whenever sqlerror exit sql.sqlcode;
spool test_login.out
select sysdate from dual;
spool off;
exit;
ENDOFSQL



ERRORCODE=$?

#Check the return code from SQL Plus
if [ $ERRORCODE != 0 ]
then
   echo "********************"
   echo "ERROR: The SQL Plus Command Failed. ErrorCode: $ERRORCODE"
   /bin/mail -s "!****! $ORACLE_SID - Connection FAILED"  $MAILTO < $SCRIPTDIR/test_login_message
else
   echo "********************"
   echo "SQL Plus Successfully Ran. ErrorCode: $ERRORCODE"
#   /bin/mail -s "$ORACLE_SID - Connection successful" $MAILTO < $SCRIPTDIR/test_login_message
fi
#
#
if [ -f $SCRIPTDIR/test_login.out ]; then
   CONTENT=`grep SYSDATE $SCRIPTDIR/test_login.out`
   if [ $CONTENT = "SYSDATE" ]; then
	echo "test_login output exists -- meaning connection is successful!"
   else
	echo "test_login FAILED"
   fi
fi

