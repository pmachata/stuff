declare -a CLEANUPS

on_exit()
{
    for c in "${CLEANUPS[@]}"; do
        eval "$c"
    done
}

push_cleanup()
{
    CLEANUPS[${#CLEANUPS[@]}]="$@"
}

trap on_exit EXIT

help()
{
    echo -n "usage: $0 "
    for var in "$@"; do
        echo -n " <$var>"
    done
    echo
    echo "environment variables:"
    echo "   PTP4L points at path to ptp4l binary"
    echo "   TRANSPORT sets the transport mode"
}

check_args()
{
    local -a vars

    while [[ $1 != -- ]]; do
        vars+=("$1")
        shift
    done

    shift # eat the "--". Now $@ contains shell script argv.

    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        help ${vars[@]}
        exit 0
    fi

    for var in "${vars[@]}"; do
        if [[ -z "$1" ]]; then
            help ${vars[@]}
            exit 1
        fi

        printf -v $var "%s" "$1"
        shift
    done

    echo TRANSPORT=${TRANSPORT:=UDPv4}
    echo PTP4L=${PTP4L:=ptp4l}
}

inify()
{
    awk '/^[#[]/{print;next} {print $1" = "$2}'
}

ptpify()
{
    awk '/^[#[]/{print;next} {print $1" "$3}'
}

set_config()
{
    local conf=$1; shift
    local section=$1; shift
    local option=$1; shift
    local value=$1; shift

    local tmp=$(mktemp)

    cat $conf | inify > $tmp
    crudini --set $tmp "$section" "$option" "$value"
    ptpify <$tmp >$conf

    rm $tmp
}

init_if()
{
    local ifname=$1; shift
    local addr;

    ip link set dev $ifname up
    for addr in "$@"; do
        ip addr add dev $ifname $addr
    done
}

fini_if()
{
    local ifname=$1; shift
    local addr;

    for addr in "$@"; do
        ip addr del dev $ifname $addr
    done
    ip link set dev $ifname down
}

use_if()
{
    init_if "$@"
    push_cleanup fini_if "$@"
}

if_set_speed()
{
    local ifname=$1; shift
    local speed=$1; shift

    ethtool -s "$ifname" speed $speed autoneg off
    push_cleanup ethtool -s "$ifname" autoneg on
}

common_config()
{
    INICONF=$(mktemp)
    push_cleanup rm -v $INICONF

    crudini --set $INICONF global logSyncInterval -11
    crudini --set $INICONF global step_threshold 1.0
    crudini --set $INICONF global network_transport $TRANSPORT
    crudini --set $INICONF global tx_timestamp_timeout 10
    crudini --set $INICONF global summary_interval 2
}

runptp()
{
    local iface
    local conf=$(mktemp)
    push_cleanup rm -v $conf

    for iface in "$@"; do
        crudini --set $INICONF "$iface"
    done

    ptpify <$INICONF >$conf
    #cat $conf

    $PTP4L -f $conf -H -m
}
