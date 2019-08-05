#!/bin/bash
source lib.sh

declare -a SlaveDevs
declare -a SlaveIds
declare -a UniqueSlaveDevs

while (($# > 1)); do
    __check_args SlaveDev SlaveId -- "$@"; shift 2
    echo Slave=$SlaveDev Id:$SlaveId
    SlaveDevs+=("$SlaveDev")
    SlaveIds+=("$SlaveId")
done

declare -a UniqueSlaveDevs=($(list_uniq ${SlaveDevs[@]}))

for ((i = 0; ; i++)); do
    SlaveDev=${SlaveDevs[$i]}
    SlaveId=${SlaveIds[$i]}

    if ((i < ${#SlaveDevs[@]} - 1)); then
        bash vlan-slave.sh $SlaveDev $SlaveId &
        sleep 0.5
    else
        bash vlan-slave.sh $SlaveDev $SlaveId
        break
    fi
done
