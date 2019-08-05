#!/bin/bash
source lib.sh

check_args M1 -- "$@"; shift
echo M1=$M1

declare -a SlaveDevs
declare -a SlaveIds

while (($# > 1)); do
    __check_args SlaveDev SlaveId -- "$@"; shift 2
    echo Slave=$SlaveDev Id:$SlaveId
    SlaveDevs+=("$SlaveDev")
    SlaveIds+=("$SlaveId")
done

declare -a UniqueSlaveDevs=($(list_uniq ${SlaveDevs[@]}))

common_config
crudini --set $INICONF global tx_timestamp_timeout 10
crudini --set $INICONF global masterOnly 0
crudini --set $INICONF global userDescription "VLAN boundary clock"

speed=1000
if_set_speed $M1 $speed
use_if $M1 192.0.2.2/30  2001:db8:1::2/64

for S in ${UniqueSlaveDevs[@]}; do
    if_set_speed $S $speed
    use_if $S
done

for ((i = 0; i < ${#SlaveDevs[@]}; i++)); do
    SlaveDev=${SlaveDevs[$i]}
    SlaveId=${SlaveIds[$i]}
    VLAN=$((SlaveId * 11))
    IPV4=192.0.2.$((SlaveId * 4 + 1))/30
    IPV6=2001:db8:$((SlaveId + 1))::1/64
    use_vlan $SlaveDev $VLAN
    use_addr $SlaveDev.$VLAN $IPV4 $IPV6
done

runptp $M1 $(for ((i = 0; i < ${#SlaveDevs[@]}; i++)); do
                 SlaveDev=${SlaveDevs[$i]}
                 SlaveId=${SlaveIds[$i]}
                 VLAN=$((SlaveId * 11))
                 echo $SlaveDev.$VLAN
             done)
