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
crudini --set $INICONF global userDescription "bridge boundary clock"
#crudini --set $INICONF global dscp_event 8
#crudini --set $INICONF global dscp_general 18

crudini --set $INICONF $M1@333 network_transport RAW$TRANSPORT
crudini --set $INICONF $M1@333 vlan_intf br

crudini --set $INICONF $S1@333 network_transport RAW$TRANSPORT
crudini --set $INICONF $S1@333 vlan 333
crudini --set $INICONF $S1@333 vlan_intf br

crudini --set $INICONF $S2@333 network_transport RAW$TRANSPORT
crudini --set $INICONF $S2@333 vlan_intf br

if [ ${TRANSPORT^^} = UDPV4 ]; then
    crudini --set $INICONF $M1@333 src_ip 192.0.2.2
    crudini --set $INICONF $S1@333 src_ip 192.0.2.17
    crudini --set $INICONF $S2@333 src_ip 192.0.2.33
    ebtables -I FORWARD -d 01:00:5e:00:01:81 -j DROP
    push_cleanup ebtables -D FORWARD -d 01:00:5e:00:01:81 -j DROP
elif [ ${TRANSPORT^^} = UDPV6 ]; then
    crudini --set $INICONF $M1@333 src_ip 2001:db8:1::2
    crudini --set $INICONF $S1@333 src_ip 2001:db8:2::1
    crudini --set $INICONF $S2@333 src_ip 2001:db8:3::1
    ebtables -I FORWARD -d 33:33:00:00:01:81 -j DROP
    push_cleanup ebtables -D FORWARD -d 33:33:00:00:01:81 -j DROP
else
    echo "Invalid transport: $TRANSPORT"
    exit 1
fi

use_if $M1
use_if $S1
use_if $S2

use_bridge br vlan_filtering 1
use_slave br $M1
use_slave br $S1
use_slave br $S2

bridge vlan del dev br vid 1 self
bridge vlan del dev $M1 vid 1
bridge vlan del dev $S1 vid 1
bridge vlan del dev $S2 vid 1

bridge vlan add dev br vid 333 self pvid untagged
bridge vlan add dev $M1 vid 333 pvid untagged
bridge vlan add dev $S1 vid 333
bridge vlan add dev $S2 vid 333 pvid untagged

# use_addr br 192.0.2.2/28  2001:db8:1::2/64
# use_addr br 192.0.2.33/28 2001:db8:3::1/64

runptp
