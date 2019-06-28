#!/bin/bash
source lib.sh

check_args S1 -- "$@"
echo S1=$S1

common_config
crudini --set $INICONF global tx_timestamp_timeout 10
crudini --set $INICONF global slaveOnly 1

use_if $S1
use_vlan $S1 111
use_addr $S1.111 192.0.2.18/28 2001:db8:2::2/64

runptp $S1.111
