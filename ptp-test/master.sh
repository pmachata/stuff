#!/bin/bash
IPV4=192.0.2.1/28
IPV6=2001:db8:1::1/64

extra_config()
{
    crudini --set $INICONF global masterOnly 1
    # crudini --set $INICONF "$1" udp6_scope 0x08
    crudini --set $INICONF global userDescription "master clock;$1"

    if [ ${TRANSPORT^^} = RAWUDPV4 ]; then
        crudini --set $INICONF $1 src_ip ${IPV4/\/*}
    elif [ ${TRANSPORT^^} = RAWUDPV6 ]; then
        crudini --set $INICONF $1 src_ip ${IPV6/\/*}
    fi
}

source ms.sh
