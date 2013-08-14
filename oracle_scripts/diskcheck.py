#!/usr/bin/python
#######################################################################
## File: diskcheck.py
##
## python version tested: 2.4.3 on RHEL 5
## Usage: /usr/bin/python diskcheck.py
##
## J. CHING  4/10/13
#######################################################################
# if python3 use this --> 
# import os, socket, datetime, re, sys, subprocess, pickle

import os, socket, datetime, re, sys, commands, pickle

###########################
# Set (global?) variables
check_root = "df /"
check_u02 = "df /u02"
check_u03 = "df /u03"
critical = 95.0
warning = 80.0
fullsubjectline = ""
subjectline = ""
###########################

SCRIPTDIR='/usr/local/sbin/oracle_scripts'
LOGDIR='/usr/local/sbin/oracle_scripts/logs'
MYHOST=socket.gethostname()
NOW=str(datetime.datetime.now())
log_file=LOGDIR+'/diskcheck.log'
DBA='email@address'


print("---------------------------------------")
print(MYHOST)
print(NOW)
print("---------------------------------------")


# remove old file, if exists
#if os.path.isfile(log_file):
#    os.remove(log_file)

# Construct log file header, and start writing
# Open file for apending and reading in binary mode
#
if os.path.isfile(log_file):
   f=open(log_file,"ab+")
else:
   f=open(log_file,"w")
#print(f)
f.write("--------------------------------------------\n")
f.write(MYHOST)
f.write('\n')
f.write(NOW)
f.write('\n')
f.write(sys.argv[0])
f.write('\n')
f.write("status:\n")
#pickle.dump(str(socket.gethostname()), f)
#pickle.dump(str(datetime.datetime.now()), f)

# build regex
dfPattern = re.compile('[0-9]+')


# determine to send mail or not
domail1=0
domail2=0
domail3=0


##################################
# Check if directory exists/ get % utilization / construct subjectline
#
# Note:
# if python3 use this instead of below --> diskUtil = subprocess.getstatusoutput(check_u03)
#
if os.path.exists("/"):
    #print(check_root, " exists")
    diskUtilPct_root = commands.getstatusoutput(check_root)   #get disk utilization
    diskUtilPct_root = diskUtilPct_root[1].split()[11]        # split out the util %, include % char
    diskUtilInt_root = re.sub('[%]', '', diskUtilPct_root)    # replace % with a blank
    #print("/ usage is " + diskUtilInt_root)
    #
    # Integers have to be converted to floating point before comparsion
    if float(diskUtilInt_root) >= float(critical):
        print("Critical space usage: '/' is %.2f%% full" % (float(diskUtilInt_root)))
        f.write("Critical space usage: '/' is %.2f%% full\n" % (float(diskUtilInt_root)))
        subjectline = '/ CRITICAL ' + str(diskUtilPct_root)
    elif float(diskUtilInt_root) >= float(warning):
        print("Warning space usage: '/' is %.2f%% full" % (float(diskUtilInt_root)))
        f.write("Warning space usage: '/' is %.2f%% full\n" % (float(diskUtilInt_root)))
        subjectline = '/ WARNING ' + str(diskUtilPct_root)
    else:
        print("Free space OK: '/' is %.2f%% full" % (float(diskUtilInt_root)))
        f.write("Free space OK: '/' is %.2f%% full\n" % (float(diskUtilInt_root)))
        subjectline = '/ normal ' + str(diskUtilPct_root)

fullsubjectline=subjectline 
domail1=fullsubjectline.find('CRITICAL')
if (domail1 == -1):
   print(" - There is no CRITICAL usage in / ")


#-- Now check /u02
if os.path.ismount("/u02"):
   if os.path.exists("/u02"):
      #print(check_u02, " exists")
      diskUtilPct_u02 = commands.getstatusoutput(check_u02)
      diskUtilPct_u02 = diskUtilPct_u02[1].split()[11]
      diskUtilInt_u02 = re.sub('[%]', '', diskUtilPct_u02)
      #print("/u02 usage is " + diskUtilInt_u02)
      if float(diskUtilInt_u02) >= float(critical):
         print("Critical space usage: '/u02' is %.2f%% full" % (float(diskUtilInt_u02)))
         f.write("Critical space usage: '/u02' is %.2f%% full\n" % (float(diskUtilInt_u02)))
         subjectline = '/u02 CRITICAL ' + str(diskUtilPct_u02)
      elif float(diskUtilInt_u02) >= float(warning):
         print("Warning space usage: '/u02' is %.2f%% full" % (float(diskUtilInt_u02)))
         f.write("Warning space usage: '/u02' is %.2f%% full\n" % (float(diskUtilInt_u02)))
         subjectline = '/u02 WARNING ' + str(diskUtilPct_u02)
      else:
         print("Free space OK: '/u02' is %.2f%% full" % (float(diskUtilInt_u02)))
         f.write("Free space OK: '/u02' is %.2f%% full\n" % (float(diskUtilInt_u02)))
         subjectline = '/u02 normal ' + str(diskUtilPct_u02)

   fullsubjectline=fullsubjectline + ', ' + subjectline
   domail2 = fullsubjectline.find('CRITICAL')
   if (domail2 == -1):
      print(" - There is no critical usage in /u02")
else:
   print("/u02 is not a mount point, not checking.")
   f.write("/u02 is not a mount point, not checking.\n")

#-- Now check /u03
if os.path.ismount("/u03"):
   if os.path.exists("/u03"):
      #print(check_u03, " exists")
      diskUtilPct_u03 = commands.getstatusoutput(check_u03)
      diskUtilPct_u03 = diskUtilPct_u03[1].split()[11]
      diskUtilInt_u03 = re.sub('[%]', '', diskUtilPct_u03)
      #print("/u03 usage is " + diskUtilInt_u03)
      if float(diskUtilInt_u03) >= float(critical):
         print("Critical space usage: '/u03' is %.2f%% full" % (float(diskUtilInt_u03)))
         f.write("Critical space usage: '/u03' is %.2f%% full\n" % (float(diskUtilInt_u03)))
         subjectline = '/u03 CRITICAL ' + str(diskUtilPct_u03)
      elif float(diskUtilInt_u03) >= float(warning):
         print("Warning space usage: '/u03' is %.2f%% full" % (float(diskUtilInt_u03)))
         f.write("Warning space usage: '/u03' is %.2f%% full\n" % (float(diskUtilInt_u03)))
         subjectline = '/u03 WARNING ' + str(diskUtilPct_u03)
      else:
         print("Free space OK: '/u03' is %.2f%% full" % (float(diskUtilInt_u03)))
         f.write("Free space OK: '/u03' is %.2f%% full\n" % (float(diskUtilInt_u03)))
         subjectline = '/u03 normal ' + str(diskUtilPct_u03)

   fullsubjectline=fullsubjectline + ',' +subjectline
   domail3 = fullsubjectline.find('CRITICAL')
   if (domail3 == -1):
      print(" - There is no critical usage in /u03")
else:
   print("/u03 is not a mount point, not checking.")
   f.write("/u03 is not a mount point, not checking.\n")


# Determine whether to send mail messages

if (domail1==1 or domail2==1 or domail3==1):
   "Check to see if emails should be sent"
   print("One or more partition is at CRITICAL level, email will be sent...")
   f.write("One or more partition is at CRITICAL level, email will be sent...\n")
   # Send mail
   import smtplib
   from email.MIMEText import MIMEText

# Do I need another file handler here?
   fp = open(log_file, 'rb')
   msg = MIMEText(fp.read())
   fp.close()
   msg['Subject'] = "%usage:  " + fullsubjectline
   msg['From'] = MYHOST
   msg['To'] = DBA
   s = smtplib.SMTP('mailrelay.apu.edu')
   s.sendmail(MYHOST, DBA, msg.as_string())
   s.quit()
else:
   print("No email will be sent.")
   f.write("No email will be sent.\n")

f.close()

print('Log file is ' + log_file)

# look for a match,  If no match exit and return an UNKNOWN state
# ???
matchobj = dfPattern.match(diskUtilPct_root)

if (matchobj):
    diskUtilPct_root = eval(matchobj.group(0))
else:
    print("STATE UNKNOWN")
    sys.exit(3)

##########################
