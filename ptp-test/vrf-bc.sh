#!/bin/bash
source lib.sh

check_args M1 S1 S2 -- "$@"
echo M1=$M1
echo S1=$S1
echo S2=$S2

common_config
crudini --set $INICONF global tx_timestamp_timeout 10
crudini --set $INICONF global masterOnly 0
crudini --set $INICONF global userDescription "physical boundary clock"

use_vrf vrf1 1000
use_slave vrf1 $M1
use_slave vrf1 $S1
use_slave vrf1 $S2
use_if $M1 192.0.2.2/28  2001:db8:1::2/64
use_if $S1 192.0.2.17/28 2001:db8:2::1/64
use_if $S2 192.0.2.33/28 2001:db8:3::1/64

runptp $M1 $S1 $S2
