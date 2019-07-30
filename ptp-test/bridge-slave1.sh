#!/bin/bash
source lib.sh

IPV4=192.0.2.18/28
IPV6=2001:db8:2::2/64

check_args S1 -- "$@"
echo S1=$S1

common_config
crudini --set $INICONF global tx_timestamp_timeout 10
crudini --set $INICONF global slaveOnly 1

if [ ${TRANSPORT^^} = RAWUDPV4 ]; then
    crudini --set $INICONF $S1 src_ip ${IPV4/\/*}
elif [ ${TRANSPORT^^} = RAWUDPV6 ]; then
    crudini --set $INICONF $S2 src_ip ${IPV6/\/*}
fi

use_if $S1
use_vlan $S1 111
use_addr $S1.111 $IPV4 $IPV6

runptp $S1.111
