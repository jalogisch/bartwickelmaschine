#/bin/bash


DOWNURL=http://ham-dmr.de/hdmr/repeater_status_csv.php?rid=2624

GRAYLOGSERVER=192.168.1.50
GRAYLOGINPUTPORT=5555
# This can be nc or netcat depending of the system
NETCATCOMMAND=nc


wget -O- -q ${DOWNURL} | while read LINE
do
    if [[ ${#LINE} -gt 1  ]];then
        echo $LINE | ${NETCATCOMMAND} ${GRAYLOGSERVER} ${GRAYLOGINPUTPORT}
    fi
done

