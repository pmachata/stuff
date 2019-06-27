: ${TEAMD:=teamd}

require_command()
{
	local cmd=$1; shift

	if [[ ! -x "$(command -v "$cmd")" ]]; then
		echo "SKIP: $cmd not installed"
		exit 1
	fi
}

declare -a CLEANUPS

on_exit()
{
    local i

    for ((i=${#CLEANUPS[@]}; i > 0; i--)); do
        ${CLEANUPS[$((i - 1))]}
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

team_create()
{
	local if_name=$1; shift
	local mode=$1; shift

	require_command $TEAMD
	$TEAMD -t $if_name -d -c '{"runner": {"name": "'$mode'"}}'
	for slave in "$@"; do
		ip link set dev $slave down
		ip link set dev $slave master $if_name
		ip link set dev $slave up
	done
	ip link set dev $if_name up
}

team_destroy()
{
	local if_name=$1; shift

	$TEAMD -t $if_name -k
}

use_team()
{
    local if_name=$1; shift
    local mode=$1; shift

    team_create "$if_name" "$mode" "$@"
    push_cleanup team_destroy "$if_name"
}

__addr_add_del()
{
	local if_name=$1
	local add_del=$2
	local array

	shift
	shift
	array=("${@}")

	for addrstr in "${array[@]}"; do
		ip address $add_del $addrstr dev $if_name
	done
}

use_addr()
{
    local if_name=$1; shift

    __addr_add_del "$if_name" add "$@"
    push_cleanup __addr_add_del "$if_name" del "$@"
}

common_config()
{
    INICONF=$(mktemp)
    push_cleanup rm -v $INICONF

    crudini --set $INICONF global logSyncInterval 0
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
    cat $conf

    $PTP4L -f $conf -H -m
}
