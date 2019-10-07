#!/bin/bash
IPV4=192.0.2.34/28
IPV6=2001:db8:3::2/64

extra_config()
{
    crudini --set $INICONF global slaveOnly 1
    # crudini --set $INICONF "$1" udp6_scope 0x02
    crudini --set $INICONF global userDescription "second slave clock;$1"
    crudini --set $INICONF global uds_address /var/run/ptp4l-slave2
}

source ms.sh
