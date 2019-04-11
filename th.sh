if [[ $# -lt 2 ]]; then
	echo "Usage: $(basename $0) <if> <counter> <counter> ... <if2> ..."
	echo " counters measures traffic in bytes, use B: to toggle"
	echo " packet counters measures traffic in packets, use P: to toggle"
	echo " us counters measures traffic in microseconds use uS: to toggle"
	echo " gauges measure usage in bytes, use G: to toggle"
	echo " default type is byte counters"
	echo " default sleep between measurements is 1s. Use -s <time> to change"
	echo "e.g.: $(basename $0) sw1p6 rx_octets_prio_1 sw1p7 rx_octets_prio_2 sw1p10 rx_octets_prio_1 rx_octets_prio_2 G: sw1p9 tc_transmit_queue_tc_1 tc_transmit_queue_tc_2"
	exit 1
fi

declare -a COUNTERS

type=B
sleep=1
if=
while [[ $# -gt 0 ]]; do
    arg=$1; shift
    if [[ $arg == "G:" ]]; then
	type=G
	continue
    elif [[ $arg == "B:" ]]; then
	type=B
	continue
    elif [[ $arg == "P:" ]]; then
	type=P
	continue
    elif [[ $arg == "uS:" ]]; then
	type=uS
	continue
    elif [[ $arg == "-s" ]]; then
	sleep=$1; shift
	continue
    elif ip l sh dev $arg &> /dev/null; then
	if=$arg
	continue
    elif [[ -z $if ]]; then
	echo "'$arg' is not an interface, so it must be a counter"
	echo "but no interface has been selected"
	exit 1
    fi

    counter=$arg
    COUNTERS[${#COUNTERS[@]}]="type=$type if=$if counter=$arg"
done

humanize()
{
	local value=$1; shift
	local suffix=$1; shift
	local -a prefix=("$@")

	for unit in "${prefix[@]}" "" K M G; do
		if (($(echo "$value < 1024" | bc))); then
			break
		fi

		value=$(echo "scale=1; $value / 1024" | bc)
	done

	echo "$value${unit}${suffix}"
}

rate()
{
	local t0=$1; shift
	local t1=$1; shift
	local interval=$1; shift

	echo "($t1 - $t0) / $interval" | bc
}

ethtool_stats_get()
{
	local dev=$1; shift
	local stat=$1; shift

	ethtool -S $dev | grep "^ *$stat:" | head -n 1 | cut -d: -f2
}

declare -a VALS
collect()
{
	orig_time=$time
	time=$(date "+%s.%N") # Nanoseconds are reported with leading zeros
	local last_if
	local ethout

	for ((i=0; i< ${#COUNTERS[@]}; ++i)); do
		eval ${COUNTERS[$i]}
		eval ${VALS[$i]}
		if [[ $if != $last_if ]]; then
			ethout=$(ethtool -S $if)
		fi
		orig=$((val))
		val=$(($(echo "$ethout" | grep "^ *$counter" \
			      | head -n 1 | cut -d: -f2)))
		VALS[$i]="orig=$orig val=$val"
	done
}

collect
sleep 0.1
while true; do
	if ((N > 0)); then
		echo -ne "\033[${N}A"
	fi
	collect

	interval=$(echo "$time - $orig_time" | bc)
	echo -e "interval\t\033[K$interval"
	N=1

	for ((i=0; i< ${#COUNTERS[@]}; ++i)); do
	    eval ${COUNTERS[$i]}
	    eval ${VALS[$i]}
	    if [[ $type == B ]]; then
		    val=$((8 * val))
		    orig=$((8 * orig))
		    rate=$(rate $orig $val $interval)
		    echo -e "$if $counter\t\033[K$(humanize $rate bps)"
	    elif [[ $type == P ]]; then
		    rate=$(rate $orig $val $interval)
		    echo -e "$if $counter\t\033[K$(humanize $rate pps)"
	    elif [[ $type == uS ]]; then
		    rate=$(rate $orig $val $interval)
		    echo -e "$if $counter\t\033[K$(humanize $rate s/s u m)"
	    elif [[ $type == G ]]; then
		    echo -e "$if $counter\t\033[K$(humanize $val B)"
	    else
		    echo -e "$if $counter\t\033[Ktype=$type???"
	    fi
	    N=$((N + 1))
	done

	sleep $sleep
done
