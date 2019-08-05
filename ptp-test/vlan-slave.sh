#!/bin/bash
source lib.sh

check_args S1 SlaveId -- "$@"
echo S1=$S1
echo SlaveId=$SlaveId

if ((SlaveId < 1 || SlaveId > 63)); then
    # VLAN needs to be >0, and IP and IPv6 network address 1 is for master,
    # hence the low limit. IPv4 only has 256 addresses to subnet, hence the high
    # limit.
    echo "SlaveId has to be [1..63]"
fi

IPV4=192.0.2.$((SlaveId * 4 + 2))/30
IPV6=2001:db8:$((SlaveId + 1))::2/64
VLAN=$((SlaveId * 11))

common_config
crudini --set $INICONF global tx_timestamp_timeout 10
#crudini --set $INICONF global slaveOnly 1
crudini --set $INICONF global userDescription "VLAN slave clock #$SlaveId"

use_if $S1
use_vlan $S1 $VLAN
use_addr $S1.$VLAN $IPV4 $IPV6

runptp $S1.$VLAN
