#!/bin/bash
IPV4=192.0.2.1/28
IPV6=2001:db8:1::2/64

extra_config()
{
    crudini --set $INICONF global masterOnly 1
}

source ms.sh
