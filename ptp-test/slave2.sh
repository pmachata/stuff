#!/bin/bash
IPV4=192.0.2.34/28
IPV6=2001:db8:3::2/64

extra_config()
{
    crudini --set $INICONF global slaveOnly 1
    crudini --set $INICONF global userDescription "second slave clock;$1"
}

source ms.sh
