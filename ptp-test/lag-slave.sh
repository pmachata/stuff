#!/bin/bash
source lib.sh

check_args S1 S2 -- "$@"
echo S1=$S1
echo S2=$S2

common_config
crudini --set $INICONF global tx_timestamp_timeout 10
crudini --set $INICONF global slaveOnly 1
for S in $S1 $S2; do
    crudini --set $INICONF $S network_transport RAWUDPv4
    crudini --set $INICONF $S lag_intf lag
    crudini --set $INICONF $S src_ip 192.0.2.18
done

use_if $S1
use_if $S2
use_team lag lacp $S1 $S2
use_addr lag 192.0.2.18/28 2001:db8:2::2/64

runptp $S1 $S2
