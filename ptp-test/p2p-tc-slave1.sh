#!/bin/bash
IPV4=192.0.2.18/28
IPV6=2001:db8:2::2/64

extra_config()
{
    crudini --set $INICONF global slaveOnly 1
    crudini --set $INICONF global userDescription "first TC slave clock;$1"
    crudini --set $INICONF global delay_mechanism p2p
}

source ms.sh
