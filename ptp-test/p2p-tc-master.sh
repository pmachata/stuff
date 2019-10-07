#!/bin/bash
IPV4=192.0.2.1/28
IPV6=2001:db8:1::1/64

extra_config()
{
    crudini --set $INICONF global masterOnly 1
    crudini --set $INICONF global userDescription "TC master;$1"
    crudini --set $INICONF global delay_mechanism p2p
}

source ms.sh
