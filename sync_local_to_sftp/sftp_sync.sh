#!/bin/bash 
#set -u
#############################################################
#            sync_local_to_sftp
#############################################################
#
# the goal of this script is to copy the content of a local
# folder to a remote SFTP Server without the ability of using
# scp, rsync, lftp or any other little helper - pure sftp. 
# This is needed in a customer environment with restrict rules.
#
# There are no Options need just call the Script and it will 
# do his job - but be aware to insert your variables at in the 
# following lines.
#
#############################################################
# Idea using flock for Lockfile optain from 
# Przemyslaw Pawelczyk <przemoc@gmail.com> and his very nice
# boilerplate for lockable script https://gist.github.com/przemoc/571091
#############################################################



TARGETSRV=safe.jalogisch.tld # including e.g. target.srv
TARGETUSR=jd # username for target.srv
TARGETPORT=22 # SSH Listen Port 
SSHKEYFILE=/home/jd/.ssh/sftp_sync # lockablecate the sshkeyfile to use
TARGETDIR=/var/home/jd/safe # where should the files goto
SOURCEDIR=~/tmp # Where are the Source files to Copy?
ARCHIVDIR=/tmp/archiv/$(date +%Y-%m) # if not present will be created

### HEADER ###
LOCKFILE="/var/lock/$(basename $0)"
LOCKFD=99

# PRIVATE
_lock()             { flock -$1 $LOCKFD; }
_no_more_locking()  { _lock u; _lock xn && rm -f $LOCKFILE; }
_prepare_locking()  { eval "exec $LOCKFD>\"$LOCKFILE\""; trap _no_more_locking EXIT; }
_create_workdir()   { WORKDIR=$( mktemp -d /tmp/$(basename $0).XXXXXXXXX ); }
_delete_workdir()   { if [[ -d $WORKDIR ]];then rm -rf $WORKDIR;fi ;}

# ON START
_prepare_locking

# PUBLIC
exlock_now()        { _lock xn; }  # obtain an exclusive lock immediately or fail
exlock()            { _lock x; }   # obtain an exclusive locku
shlock()            { _lock s; }   # obtain a shared lock
unlock()            { _lock u; }   # drop a lock

# Provide Logging 
wlog()  {
        test -z "$MYNAME" && MYNAME=`basename $0`
        logger -i -t "$MYNAME" -p "user.info" "`date +%Y.%m.%d-%H:%M:%S` $*"
        test -t 1 && echo "`date +%Z-%Y.%m.%d-%H:%M:%S` $*"
        test -z "$LOGFILE" || {
            echo "`date +%Y.%m.%d-%H:%M:%S` [$$] $*" >> $LOGFILE
            }
        }

# Housekeeping
create_workdir()    {
    _create_workdir || { wlog "create of workdir not possible"; exit 1; }
    trap _delete_workdir 0;
}


### BEGIN OF SCRIPT ###
create_workdir || { wlog "create workdir error"; exit 1; }
exlock_now || { wlog "no lock possible"; exit 1; }

# Test some Local 
[[  -d $WORKDIR ]] || { wlog "no workdir present"; exit 1; }
[[  -d $SOURCEDIR ]] || { wlog "no localdir present"; exit 1; }
#[[  -f $SSHKEYFILE ]] || { wlog "no sshkey present"; exit 1; }
[[ -d ${ARCHIVDIR} ]] || mkdir -p ${ARCHIVDIR}

# Build Filelist
# TODO: make this one more pretty maybe to use the same file for backup
for i in $(find ${SOURCEDIR} -maxdepth 1 -type f)
do
         echo "put $i" >> $WORKDIR/files
         echo "$i" >> ${WORKDIR}/cfiles
done

# check if any files are present
[[ -f ${WORKDIR}/files ]] || { wlog "no files found, no more work"; exit 0; }

# Build the Batch/Upload
#echo "mkdir $TARGETDIR" >> $WORKDIR/batchfile # raise error if exists
echo "cd $TARGETDIR" >> $WORKDIR/batchfile
cat $WORKDIR/files >> $WORKDIR/batchfile
echo "exit" >> $WORKDIR/batchfile

# This does the Upload to SFTP Server
# TODO: Test if the Server is available needed?
sftp -q -C -b $WORKDIR/batchfile -o PubkeyAuthentication=yes -o IdentityFile=$SSHKEYFILE -o Port=$TARGETPORT $TARGETUSR@$TARGETSRV > $WORKDIR/sftp_log || { wlog "Error during Upload"; exit 1; }

# copy the files to archive folder that should be transfered
for D in $(cat ${WORKDIR}/cfiles)
    do
        mv ${D} ${ARCHIVDIR} || { wlog "Could not copy ${D} to archive"; exit 1;}
done

# mail output of the logfile 
#cat ${WORKDIR}/sftp_log | mailx -vs "transferlog" jd@jalogisch.de


set +u
exit 0
