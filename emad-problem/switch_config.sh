#!/bin/bash
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv4.ip_forward_update_priority=0

if true; then
    # r-anaconda-03
    swp1=swp26 #ingress 1
    swp3=swp25 #egress
else
    # spider-97
    swp1=swp51 #ingress 1
    swp3=swp49 #egress
fi

# QoS and lldp setup
systemctl stop lldpad
(
    PATH=$PATH:/mnt/share156/petrm:/images/156/petrm
    PYTHONPATH=.
    mlnx_qos -i $swp1 --dscp2prio set,08,1
    mlnx_qos -i $swp3 --prio_tc 0,1,1,1,1,1,1,1
)

# ingress: 10G
ethtool -s $swp1 autoneg off speed 10000
ip link set dev $swp1 mtu 9216
ip a a 192.0.2.18/28 dev $swp1
ip link set dev $swp1 up

# egress: 1G
ethtool -s $swp3 autoneg off speed 1000
ip link set dev $swp3 mtu 9216
ip a a 192.0.2.65/28 dev $swp3
ip link set dev $swp3 up

ip r add 192.0.2.128/28 via 192.0.2.66

ip n r 192.0.2.129 dev swp25 lladdr 98:03:9b:8f:b5:94
ip n r 192.0.2.66 dev swp25 lladdr 98:03:9b:8f:b5:94
