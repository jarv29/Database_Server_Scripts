#!/bin/sh
#
#  RMAN Level 0 backup (Full)
#   -  RMAN level is governed by the Day of the Week or an Override
#
#  Level 0 - FRIDAY
#  Level 1 - All other days
#
#  If OVERRIDE_DOW_LEVEL = 'YES' then the next input variable will specify the level
#
#  Host: sis-dev-db-2
# -------------------------------------------------------------------------
#
# Must have at least two input parameters: BACKUP_SID and OVERRIDE_YESNO
#
if [ $# -lt 2 ]; then
        echo "Usage: $0 <BACKUP_SID> <OVERRIDE_YESNO> <OVERRIDE_DOW_LEVEL>  <opt: test>"
        exit 1
fi
# Input variables
BACKUP_SID="$1";                    export BACKUP_SID
OVERRIDE_YESNO="$2";		    export OVERRIDE_YESNO
OVERRIDE_DOW_LEVEL="$3";            export OVERRIDE_DOW_LEVEL
TESTFLAG="$4";                      export TESTFLAG
#
#  Set up logistics
#
ORACLE_SID=${BACKUP_SID}; export ORACLE_SID
BACKUPDIR="/usr/local/sbin/oracle_scripts/backup"; export BACKUPDIR
LOGDIR="/usr/local/sbin/oracle_scripts/backup/logs"; export LOGDIR
MAILTO="email@address";            	export MAILTO
FIRSTRUN=`date '+%Y%m%d'`;		export FIRSTRUN
RUNDATE=`date '+%d-%m-%Y'`;		export RUNDATE
DOW=`date '+%a'`; 			export DOW
HOSTNAME=`cat /proc/sys/kernel/hostname | awk -F . '{print $1}'`
echo "Hostname is $HOSTNAME"
ls -al /etc/oratab
#
ORACLE_HOME=`grep "^$ORACLE_SID" /etc/oratab | awk -F : '{print $2}'`; export ORACLE_HOME
echo "ORACLE_HOME is $ORACLE_HOME"
#
RCVFILEL0=$BACKUPDIR/rman_run_level0.rcv;       export RCVFILEL0
RCVFILEL1=$BACKUPDIR/rman_run_level1.rcv;       export RCVFILEL1
LEVEL=1; export LEVEL
LABEL="REG"; export LABEL
RMAN_TIMES="$LOGDIR/rman_times_${BACKUP_SID}_$FIRSTRUN"; export RMAN_TIMES
#
echo "RMAN begins at" > $RMAN_TIMES
echo `date` >> $RMAN_TIMES
#
#
# Normal settings (without override settings)
#
if [ $DOW = "Mon" ]; then
  LEVEL=1
  echo "Hello Monday"
elif [ $DOW = "Tue" ]; then
  LEVEL=1
  echo "It is Tuesday"
elif [ $DOW = "Wed" ]; then
  LEVEL=1
   echo "Today is Wednesday"
elif [ $DOW = "Thu" ]; then
  LEVEL=1
   echo "Thursday today"
elif [ $DOW = "Fri" ]; then
  LEVEL=0
   echo "Oh Friday is here"
elif [ $DOW = "Sat" ]; then
  LEVEL=1
   echo "Weekend Saturday now"
elif [ $DOW = "Sun" ]; then
  LEVEL=1
   echo "Go to church"
fi
#
# Check input flag for uppercase or lowercase or mixedcase
#
OVERRIDE_YESNO=`echo "${OVERRIDE_YESNO}" | tr a-z A-Z`
echo $OVERRIDE_YESNO
#
#  If OVERRIDE_YESNO is 'YES' then must specify OVERRIDE_DOW_LEVEL
#
if [ "$OVERRIDE_YESNO" = "YES" ]; then
    if [ "$OVERRIDE_DOW_LEVEL" = "" ]; then
        echo "Must specify rman backup level if OVERRIDE_YESNO flag is YES. Try again. Exiting."
        exit 1
    fi 
    LEVEL=${OVERRIDE_DOW_LEVEL}
    LABEL="OVR";  export LABEL
    echo "========================="
    echo "New Override level is $LEVEL"
    echo "========================="
else
    # OVERRIDE_YESNO = 'No'
    echo "========================="
    echo "No Override for designated level"
    echo "========================="
fi
#
# Remove old files
#
if [ -f $RCVFILEL0 ]; then
	rm $RCVFILEL0;
fi
if [ -f $RCVFILEL1 ]; then
        rm $RCVFILEL1;
fi

#-----------------
# Determine output filename based on backup level
#
if [ $LEVEL = 0 ]; then
   echo "----->LEVEL 0";
   OUTPUT=$RCVFILEL0; export OUTPUT
else
   echo "----->LEVEL 1";
   OUTPUT=$RCVFILEL1; export OUTPUT
fi


echo "run { "                                                                   > $OUTPUT
echo "set command id to 'backup_level_${LEVEL}_${DOW}_${LABEL}';"              >> $OUTPUT 
echo "allocate channel d1 type disk;"                                          >> $OUTPUT 
echo "allocate channel d2 type disk;"                                          >> $OUTPUT 
echo "allocate channel d3 type disk;"                                          >> $OUTPUT 
echo "set maxcorrupt for datafile 1 to 0;"                                     >> $OUTPUT 
echo "sql 'alter system archive log current';"                                 >> $OUTPUT
echo "backup"                                                                  >> $OUTPUT 
echo "incremental level ${LEVEL}"                                              >> $OUTPUT 
echo "tag tag_level_${LEVEL}_${DOW}_${LABEL}"                                  >> $OUTPUT 
echo "database include current controlfile plus archivelog skip inaccessible;" >> $OUTPUT 
echo "sql 'alter system archive log current'"                                  >> $OUTPUT 
echo ";"                                                                       >> $OUTPUT 
echo "release channel d1;"                                                     >> $OUTPUT 
echo "release channel d2;"                                                     >> $OUTPUT 
echo "release channel d3;"                                                     >> $OUTPUT 
echo "}"								       >> $OUTPUT 


echo "The rcv file generated is $OUTPUT"

#
#  Run rman
#
$ORACLE_HOME/bin/rman target sys/orac13\$apu08\$sys CMDFILE $OUTPUT LOG=$LOGDIR/rman_run_${BACKUP_SID}_${FIRSTRUN}_${DOW}.log
#
#
echo " Rman backup done at " >> $RMAN_TIMES
echo `date`	>> $RMAN_TIMES

