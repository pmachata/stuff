#!/bin/bash
source lib.sh

check_args M1 S1 S2 -- "$@"
echo M1=$M1
echo S1=$S1
echo S2=$S2

if false; then
    speed=1000
    if_set_speed $M1 $speed
    if_set_speed $S1 $speed
    if_set_speed $S2 $speed
fi

common_config
crudini --set $INICONF global tx_timestamp_timeout 10
crudini --set $INICONF global masterOnly 0
crudini --set $INICONF $M1 network_transport UDPv4
for S in $S1 $S2; do
    crudini --set $INICONF $S network_transport RAWUDPv4
    crudini --set $INICONF $S lag_intf lag.1
    crudini --set $INICONF $S src_ip 192.0.2.17
done

use_if $M1 192.0.2.2/28 2001:db8:1::2/64
use_if $S1
use_if $S2
use_team lag.1 lacp $S1 $S2
use_addr lag.1 192.0.2.17/28 2001:db8:2::1/64

runptp $M1 $S1 $S2
