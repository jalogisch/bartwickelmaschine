#!/bin/bash
#
# this script looks into the default user homdir location
# extract the homes that are present and check if this user
# is available in the System authentification (passwd / ldap )
# if not the user homedir is removed from the system

KNOWNHOME=/home/

# NOW is given the current Date and epoch
# in general this should only run once a week
# but if called more often epoch will be the identifier
NOW=$(date +"%Y-%m-%d (%s)" )

# this is the simplest solution that runs on most linux distros
FUSER=$( find ${KNOWNHOME} -maxdepth 1 -type d | grep -o '[^/]*$' )

# every Output is send to syslog 
exec 1> >(logger -s -t $(basename $0)) 2>&1

# runloop for every element
for U in ${FUSER};do
    # test if a user is available
    # if user is not present via passwd
    # we are going to delete the user and
    # write the name to output
    HPRESENT=$(  getent passwd ${U} )
    if [[ ! ${HPRESENT} ]];then
        # check now if the homedir is a directory
        if [[ -d ${KNOWNHOME}${U} ]];then
                echo "${NOW} delete '${U}' homedir in ${KNOWNHOME}${U}"
               # FIXME: maybe a better solution will be found
				rm -rf ${KNOWNHOME}${U}
            else
                echo "${NOW} ${KNOWNHOME}${U} is not a directory - nothing todo"
            fi
    fi
done
