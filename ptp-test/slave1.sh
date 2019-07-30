#!/bin/bash
IPV4=192.0.2.18/28
IPV6=2001:db8:2::2/64

extra_config()
{
    crudini --set $INICONF global slaveOnly 1
    # crudini --set $INICONF "$1" udp6_scope 0x04

    if [ ${TRANSPORT^^} = RAWUDPV4 ]; then
        crudini --set $INICONF $1 src_ip ${IPV4/\/*}
    elif [ ${TRANSPORT^^} = RAWUDPV6 ]; then
        crudini --set $INICONF $1 src_ip ${IPV6/\/*}
    fi
}

source ms.sh
