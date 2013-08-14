#!/bin/sh
# File name:  oraexpdp.sh
#
# Input parameters needed: (1) A log directory holding export logs.
#                          (2) The backup directory where the .dmp file will go.
# 
#
#  Name		Created		 Description
# J. Ching      Feb   15, 2009   APU: Run under cygwin 
# J. Ching      Mar    1, 2009   Clarify with timestamps
# J. Ching      May   08, 2009   Change email subject line
# J. Ching      June  12, 2009   Put summary of export times in subject of email
# J. Ching      Jan   20, 2010   Dont' send email after each instance
# J. Ching      Jan   25, 2010   Change the way email is sent 
# J. Ching      Jun   21, 2010   New cygwin does not like DOS style direcotry naming
# J. Ching      Nov   5,  2010   Converting to Linu, new beta host is running RHEL 5 
# J. Ching      Jan  18,  2012   Adjust for RACOne with ASM storage
# J. Ching      March 12, 2012   Removed RACOne, use Single Instance database with ASM on sis-dev-db-2
# J. Ching      Aug   24, 2012   Table update on imtadmin.imt_db_backup
#
# Output that will be read by the mail script: 
#     MAILFILE=$SCRIPTDIR/rpt_filename.txt
#
# Example of $PARFILE (<$SID>_export.dat)
#
# - Export dumps go to /u03/expdp (the directory location pre-defined)
# - Cron entry:
#   /usr/local/sbin/oracle_scripts/backup/oraexpdp.sh PRODSTU <expdp-label> <opt:test> > /tmp/oraexport_$$
#
#============================================================================== 
#
# Check number of parameters requirements
#
if [ $# -lt 2 ]; then
        echo "Usage: $0 <SID> <expdp_backup_label> <opt: test>"
        exit 1
fi
#
BACKUP_SID="$1";                    export BACKUP_SID
BACKUPLABEL="$2";                   export BACKUPLABEL
TESTFLAG="$3";                      export TESTFLAG
#
#  Set up logistics
#
MAILTO="email@address";            export MAILTO
GZIP="/usr/bin/gzip";               export GZIP
SCRIPTDIR="/usr/local/sbin/oracle_scripts/backup";         export SCRIPTDIR
MAILFILE=$SCRIPTDIR/expdp_mailtxt.txt export MAILFILE
ORATAB="/etc/oratab";			export ORATAB
SEND="FALSE";				export SEND
FIRSTRUN=`date '+%Y%m%d'`;		export FIRSTRUN
RUNDATE=`date '+%d-%m-%Y'`;		export RUNDATE
TO_REPOS=0;				export TO_REPOS
DUMPSIZE=0;				export DUMPSIZE
COMPSIZE=0;				export COMPSIZE
#
HOSTNAME=`cat /proc/sys/kernel/hostname | awk -F . '{print $1}'`
#
#HOSTNM=`hostname -s | cut -d"-" -f2`;  export HOSTNM
#HOSTNUM=`hostname -s | cut -d"-" -f4`; export HOSTNUM
#HOSTABBREV="${HOSTNM}${HOSTNUM}";   export HOSTABBREV
#HOSTNAM=`hostname`;			export HOSTNAM
#
TIME_RPT="$SCRIPTDIR/${HOSTNAME}_expdp_report.out";           export TIME_RPT
ORAEXP_REPORT="$SCRIPTDIR/logs/exp_full_${BACKUP_SID}_$FIRSTRUN"; export ORAEXP_REPORT
RUNERROR="$SCRIPTDIR/exp_runtime_error";                          export RUNERROR
FILESIZEFILE="$SCRIPTDIR/logs/${BACKUP_SID}_expdp_filesize";        export FILESIZEFILE
FIRSTRUNDATEFIL="/usr/local/sbin/oracle_scripts/backup/firstrundate.txt";            export FIRSTRUNDATEFIL
STIMEFILE="$SCRIPTDIR/logs/${BACKUP_SID}_expdp_start_time"; export STIMEFILE
FTIMEFILE="$SCRIPTDIR/logs/${BACKUP_SID}_expdp_finish_time"; export FTIMEFILE
DIRECTORY="NULL"; export DIRECTORY
#
#
#  Checks....
#
echo [firstrun-----] Firstrun date is $FIRSTRUN
echo [hostname-----] $HOSTNAME
echo [time_rpt-----] $TIME_RPT
#
# Obtain backup dir
#
############ Log in to the db and find EXPDP dir ################## =============>>
#
# Prepare the reports
#
if [ ! -d $SCRIPTDIR/logs ]; then
   /bin/mkdir $SCRIPTDIR/logs
   echo "$SCRIPTDIR/logs directory created because it did not already exist."
fi
#
if [ -f $ORAEXP_REPORT ]; then
   /bin/rm -f $ORAEXP_REPORT
fi
#
if [ -f "$FIRSTRUNDATEFIL" ]; then
   FILEDATE=`head -1 $FIRSTRUNDATEFIL`;
   if [ "$FILEDATE" = "$FIRSTRUN" ]; then
	echo [-------------] today is the same day as in $FIRSTRUNDATEFIL
    else
	echo [--------- rm ] Remove old first_run_file $FIRSTRUNFILE
	/bin/rm $FIRSTRUNDATEFIL
	echo $FIRSTRUN > $FIRSTRUNDATEFIL
   fi
else
   echo [-------------] first_run_date file did not exists, so create it.
   echo $FIRSTRUN > $FIRSTRUNDATEFIL
fi
#
echo `date` > $ORAEXP_REPORT
echo "  "  >> $ORAEXP_REPORT
#
touch $RUNERROR
#
#
# Trap signals
#
# We will trap signals and clean up 
#trap 'rm -f $SCRIPTDIR/*_expdp.dat; exit 1'  1 2 15
#
ORACLE_SID="$1"; export ORACLE_SID
#
# Need the $ORACLE_HOME value before running SQL*PLUS. 
#
ORACLE_HOME=`grep "$ORACLE_SID" /etc/oratab | awk -F: '{print $2}'`; export ORACLE_HOME
echo "ORACLE_HOME is $ORACLE_HOME"
echo "ORACLE_SID is $ORACLE_SID"
#
#
# Strip off blank lines and lines beginning with "SQL>"
#sed '/^$/d' < $SCRIPTDIR/hostid.txt > $SCRIPTDIR/temp_hostid.txt
#grep -v SQL $SCRIPTDIR/temp_hostid.txt > $SCRIPTDIR/hostid.txt
#HOSTID=`cat $SCRIPTDIR/hostid.txt | awk '{print $1}'`
#export HOSTID


#echo "==================================================="
#echo "Host ID is $HOSTID"
echo "==================================================="
#
$ORACLE_HOME/bin/sqlplus / as sysdba <<EOF
set heading off
set feedback off
set echo off
set termout off
set verify off
spool $SCRIPTDIR/directory_path.txt
select directory_path from dba_directories where directory_name='$BACKUPLABEL';
spool off;
EOF

#
# (Note 1: Using awk doesn't work because the SQL output still echos SQL statement)
# (Note 2: the output file directory_path.txt contains trailing blanks at the end string)
#
DIRECTORY=`sed -n '3p' $SCRIPTDIR/directory_path.txt | sed 's/[ \t]*$//'`; export DIRECTORY
echo "-----------------------------------------"
echo "Backup Location (directory) is $DIRECTORY"
echo "-----------------------------------------"

#
#BACKUPDIR=`cat $SCRIPTDIR/directory_path.txt | awk '{print $1}'`
#export BACKUPDIR

# If path is an ASM location, we can't cd into it to clean up.
#
#
#
if [ -f $ORATAB ]; then
	ls -al $ORATAB
else
	echo [!!!!---------] UNABLE TO LOCATE oratab.  Exit with error.
	echo "!!!! No oratab found.  Abandoning script." >> $ORAEXP_REPORT
	exit 1
fi
#
# Remove old PARFILE
#
if [ -f $PARFILE ]; then
	/bin/rm -f $PARFILE
fi
#
# $BACKUP_SID is given from the argument
#
cat $ORATAB | while read LINE
do
	case $LINE in
	\#*)	;;
	*)	SID=`echo $LINE | awk -F: '{print $1}' -`; export SID
		ORACLE_HOME=`echo $LINE | awk -F: '{print $2}' -`; export ORACLE_HOME
echo "ORACLE_SID is $SID"
echo "ORACLE_HOME is $ORACLE_HOME"
		UPORDOWN=`echo $LINE | awk -F: '{print $3}' -`; export UPORDOWN
echo "UPORDOWN is $UPORDOWN"
		#echo "<<BeginCase>>"
		if [ "$UPORDOWN" = 'Y' ]; then
echo "*** " $SID " | " $ORACLE_HOME " | " $UPORDOWN " *** " >> $ORAEXP_REPORT
echo ">>>>>>>>>>>>>>>"
echo "$SID is up; We are asked to backup $BACKUP_SID"
echo "<<<<<<<<<<<<<<<"
# 
# For the sake of comparsion, strip the _1 at the end of the SID in $BACKUP_SID
#
#BACKUPSIDSTRIPPED=`echo $BACKUP_SID | awk -F _ '{print $1}'`
		    if [ $SID = "$BACKUP_SID" ]; then
			echo "---ORACLE_SID matched!  " >> $ORAEXP_REPORT
		        echo "[$SID] Backing up $BACKUP_SID on `hostname`..." >> $ORAEXP_REPORT
		# Check if INSTANCE Is running, if it is 2 lines result
			ISRUNNING=`ps -ef | grep ora_smon_${BACKUP_SID} | egrep -v grep`; export ISRUNNING
			if [ "$ISRUNNING" = "" ]; then
				echo "**************************"
				echo "  INSTANCE IS NOT RUNNING"
				echo "**************************"
				exit 1
			fi
			# Make sure we have the correct SID name for backup in a RAC One environment
			ORACLE_SID=$BACKUP_SID; export ORACLE_SID
			STARTTIME=`date '+%Y/%m/%d_%H:%M:%S'`; export STARTTIME
			echo ":: $STARTTIME :: Dump of $SID started." >> $ORAEXP_REPORT
			echo $STARTTIME > $STIMEFILE
			PARFILE=$SCRIPTDIR/${SID}_expdp.dat; export PARFILE
echo "!!!! PARFILE is $PARFILE"
			echo "DIRECTORY=EXPDP_DIR" > $PARFILE
			echo "DUMPFILE=EXPDP_DIR:full_expdp_${SID}_${FIRSTRUN}.dmp" >> $PARFILE
			if [ "$TESTFLAG" = "test" ]; then
			   echo "SCHEMAS=SCOTT" >> $PARFILE
			else
                           echo "FULL=Y" >> $PARFILE
			fi
			echo "LOGFILE=EXPDP_LOG_DIR:full_expdp_log_${SID}_${FIRSTRUN}.log" >> $PARFILE
			echo "COMPRESSION=ALL" >> $PARFILE
			echo "PARALLEL=4" >> $PARFILE
echo "!!!! should be done constructing $PARFILE"
/bin/cat $PARFILE
$ORACLE_HOME/bin/expdp PARFILE=$PARFILE<<END
backup/m9g4gpu2kcab
END
			echo "  " >> $ORAEXP_REPORT
			echo "  " >> $ORAEXP_REPORT
echo "EXPDP finished. Backup_DIR is [$DIRECTORY]"
echo "Dumpfile is $DIRECTORY/full_expdp_${SID}_${FIRSTRUN}.dmp"
DUMPSIZE=`/bin/ls -al $DIRECTORY/full_expdp_${SID}_${FIRSTRUN}.dmp | cut -d" " -f5`; export DUMPSIZE
echo "---------------------"
ENDTIME=`date '+%Y/%m/%d_%H:%M:%S'`; export ENDTIME
			#
			# INSERT INTO ADMIN DATABASE ::::
 			#
echo "DUMPSIZE is $DUMPSIZE"
echo "starts: $STARTTIME"
echo "ends: $ENDTIME"

echo "$ENDTIME" > $FTIMEFILE
echo "$DUMPSIZE" > $FILESIZEFILE

		    fi #if SID
		fi # UPORDOWN
		#echo "<<EndCase>>"
	esac
done
#
#
#
#
# Remove export parameter file, and other output file
#
rm $RUNERROR
#
#
x=`cat $STIMEFILE`; export x
y=`cat $FTIMEFILE`; export y
z=`cat $FILESIZEFILE`; export z
#
#
# FINAL REPORT PER SERVER
echo "$BACKUP_SID    $FIRSTRUN   $z   $x   $y"  >> $TIME_RPT
#
#
/bin/echo -n $TIME_RPT    > $MAILFILE 
/bin/echo "------------" >> $MAILFILE
/bin/df -h |grep u03     >> $MAILFILE
#/bin/mail -s "`hostname` EXPDP report" $MAILTO < $MAILFILE
#
rm -f $STMEFILE
rm -f $FTMEFILE
rm -f $FILESIZEFILE
#
# Exit successfully
exit 0
#
