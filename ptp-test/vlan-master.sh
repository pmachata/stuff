#!/bin/bash
source lib.sh

check_args S1 -- "$@"
echo S1=$S1

speed=1000
if_set_speed $S1 $speed

common_config
crudini --set $INICONF global tx_timestamp_timeout 10
crudini --set $INICONF global masterOnly 0

crudini --set $INICONF $S1@111 network_transport RAW$TRANSPORT
crudini --set $INICONF $S1@111 vlan 111
crudini --set $INICONF $S1@111 vlan_intf $S1.111

if [ ${TRANSPORT^^} = UDPV4 ]; then
    crudini --set $INICONF $S1@111 src_ip 192.0.2.1
elif [ ${TRANSPORT^^} = UDPV6 ]; then
    crudini --set $INICONF $S1@111 src_ip 2001:db8:1::1
else
    echo "Invalid transport: $TRANSPORT"
    exit 1
fi

use_if $S1
use_vlan $S1 111
use_addr $S1.111 192.0.2.1/28 2001:db8:1::1/64

runptp
