#!/bin/bash
#
# this script get all user ids above uid 500 and
# get the ssh-key (beginn and comment) for this user
#
# 

# this is also a nice test to see if the system is setup proper!
LHOS=$( hostname -s )
# assume that userids not set by the system starts with 500
USERLIST=$(awk -F: '{if(($3 >= 500)&&($3 <65534)) print $1}' /etc/passwd)



# This function does the hole job - it will do all checks for
# each username that is given
function _get_userinfo {
    LUSER=$1
    echo -n "${LHOS}:${LUSER}:"
    # grep homedirectory of the user for later use
    GHOME=$(grep "${LUSER}:" /etc/passwd | cut -d":" -f6)
    # check if the user has a password
    # TODO: add check for *
    # TODO: check if a user is disabled of have in general no login
    if [[ $(grep "${LUSER}:" /etc/shadow | cut -d":" -f2) == "!" ]];then
        echo -n "nologin"
    else
        echo -n "password"
    fi
    # TODO: find a better way to test if someone is able to use sudo
    grep ${LUSER} /etc/sudoers 2>&1> /dev/null
    if [ $? -eq 0 ];then
        echo -n ":sudo"
    fi
    # TODO: check sshd config for authorized_keys file
    #       at the moment i assume that it is default file
    # This block runs if there is a ssh-key file to get information
    if [[ -f ${GHOME}/.ssh/authorized_keys ]];then
        # do a grep ^ssh here to missmatch comments
        # and Keys with environment variable set
        # all other keys should be "normal"
        WOCG=$(grep "^ssh-" ${GHOME}/.ssh/authorized_keys)
            # TODO: find a better way to test if this is empty or not
           if [[ -n "${WOCG}" ]];then
            echo -n ":sshkey ("
            # this while read is the only way to ensure
            # that the lines are printed one by one
            while read LKEYS; do
                # finaly we cut field 1, 3 (and following til the end of the line)
                LUK=$(echo ${LKEYS}|cut -d" " -f1,3-)
                echo -n "${LUK};"
            done < <( grep "^ssh-" ${GHOME}/.ssh/authorized_keys )
            echo ")"
        fi
     else
        echo ""
    fi

}


# we start it all for the useraccounts
for LUSER in $USERLIST
do
    _get_userinfo ${LUSER}
done

# we do want to get the information for the
# root user - any other "system" user can specified here to check
_get_userinfo root


