#!/bin/bash
source lib.sh

check_args M1 S1 S2 -- "$@"
echo M1=$M1
echo S1=$S1
echo S2=$S2

speed=10000
if_set_speed $M1 $speed
if_set_speed $S1 $speed
if_set_speed $S2 $speed

common_config
crudini --set $INICONF global tx_timestamp_timeout 10
crudini --set $INICONF global masterOnly 0
crudini --set $INICONF $M1 network_transport $TRANSPORT

crudini --set $INICONF $S1@111 network_transport RAW$TRANSPORT
crudini --set $INICONF $S1@111 vlan 111
crudini --set $INICONF $S1@111 vlan_intf br

crudini --set $INICONF $S2@222 network_transport RAW$TRANSPORT
crudini --set $INICONF $S2@222 vlan_intf br.222

if [ ${TRANSPORT^^} = UDPV4 ]; then
    crudini --set $INICONF $S1@111 src_ip 192.0.2.17
    crudini --set $INICONF $S2@222 src_ip 192.0.2.33
elif [ ${TRANSPORT^^} = UDPV6 ]; then
    crudini --set $INICONF $S1@111 src_ip 2001:db8:2::1
    crudini --set $INICONF $S2@222 src_ip 2001:db8:3::1
else
    echo "Invalid transport: $TRANSPORT"
    exit 1
fi

use_if $M1 192.0.2.2/28 2001:db8:1::2/64
use_if $S1
use_if $S2

use_bridge br vlan_filtering 1
use_addr br 192.0.2.17/28 2001:db8:2::1/64
use_slave br $S1
use_slave br $S2

use_vlan br 222
use_addr br.222 192.0.2.33/28 2001:db8:3::1/64

bridge vlan del dev br vid 1 self
bridge vlan del dev $S1 vid 1
bridge vlan del dev $S2 vid 1
bridge vlan add dev br vid 111 self pvid untagged
bridge vlan add dev br vid 222 self
bridge vlan add dev $S1 vid 111
bridge vlan add dev $S2 vid 222 pvid untagged

runptp $M1
