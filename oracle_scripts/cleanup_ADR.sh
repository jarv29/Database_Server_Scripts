#!/bin/bash
##################################################################################################################
# Script source: mudasblog.wordpress.com/2011/04/05/oracle-11g-r2-11-2-0-2-housekeeping-adr-and-listener-logfiles/
##################################################################################################################
# Script settings
ORACLE_USER="oracle"
LOCK_FILE="/tmp/adr_purge.lck"
PURGE_AGE=14400  # in min, 1 day=60min/hr x 24hrs 
#PURGE_AGE=43200 # 30 days

# Check user id
USER="$(/usr/bin/id -u -nr)"

if [ "$USER" != "$ORACLE_USER" ]
then
echo "ERR: Script must be run as $ORACLE_USER user."
exit 99
fi

# Check if ORACLE_HOME is set
if [ -z ${ORACLE_HOME} ]
then
echo "ERR: ORACLE_HOME must be set."
exit 98
fi

# Check if lock file exists
if [ -e "$LOCK_FILE" ]
then
echo "ERR: Script currently running or aborted uncleanly."
echo "If the script isn't active, delete $LOCK_FILE and rerun it."
exit 97
fi

# Create lock file
/bin/touch $LOCK_FILE 2>/dev/null
if [ $? -ne 0 ]
then
echo "ERR: Can not create lock file $LOCK_FILE"
exit 96
fi

# Starting purge operation
START_DATE="$(/bin/date)"
echo "INF: Starting purge operations at $START_DATE"
echo ""

# Purging...
$ORACLE_HOME/bin/adrci exec="show homes" | grep -v : | while read LINE
do
echo "INF: purging home $LINE"
echo " purging ALERT"
$ORACLE_HOME/bin/adrci exec="set homepath $LINE;purge -age $PURGE_AGE -type ALERT"
echo " purging INCIDENT"
$ORACLE_HOME/bin/adrci exec="set homepath $LINE;purge -age $PURGE_AGE -type INCIDENT"
echo " purging TRACE"
$ORACLE_HOME/bin/adrci exec="set homepath $LINE;purge -age $PURGE_AGE -type TRACE"
echo " purging CDUMP"
$ORACLE_HOME/bin/adrci exec="set homepath $LINE;purge -age $PURGE_AGE -type CDUMP"
echo " purging HM"
$ORACLE_HOME/bin/adrci exec="set homepath $LINE;purge -age $PURGE_AGE -type HM"
echo ""
done

# Remove lock file
rm -f $LOCK_FILE

# Finish purge operation
END_DATE="$(/bin/date)"
echo "INF: Purge operations ended at $END_DATE"
