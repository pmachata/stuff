#!/bin/bash
# SPDX-License-Identifier: GPL-2.0
#
# Script for max single flow performance
#  - If correctly tuned[1], single CPU 10G wirespeed small pkts is possible[2]
#
# Using pktgen "burst" option (use -b $N)
#  - To boost max performance
#  - Avail since: kernel v3.18
#   * commit 38b2cf2982dc73 ("net: pktgen: packet bursting via skb->xmit_more")
#  - This avoids writing the HW tailptr on every driver xmit
#  - The performance boost is impressive, see commit and blog [2]
#
# Notice: On purpose generates a single (UDP) flow towards target,
#   reason behind this is to only overload/activate a single CPU on
#   target host.  And no randomness for pktgen also makes it faster.
#
# Tuning see:
#  [1] http://netoptimizer.blogspot.dk/2014/06/pktgen-for-network-overload-testing.html
#  [2] http://netoptimizer.blogspot.dk/2014/10/unlocked-10gbps-tx-wirespeed-smallest.html
#
basedir=`dirname $0`
source ${basedir}/functions.sh
root_check_run_with_sudo "$@"

# Parameter parsing via include
#source ${basedir}/parameters.sh
# Set some default params, if they didn't get set
if [ -z "$DEST_IP" ]; then
    [ -z "$IP6" ] && DEST_IP="198.18.0.42" || DEST_IP="FD00::1"
fi
[ -z "$DST_MAC" ]   && DST_MAC="90:e2:ba:ff:ff:ff"
[ -z "$BURST" ]     && BURST=32
[ -z "$CLONE_SKB" ] && CLONE_SKB="0" # No need for clones when bursting
[ -z "$COUNT" ]     && COUNT="0" # Zero means indefinitely

# Base Config
DELAY="0"  # Zero means max speed

# General cleanup everything since last run
pg_ctrl "reset"

export PKT_SIZE=9014
if true; then
    # r-anaconda-03
    export DST_MAC1=98:03:9b:94:c7:d5
    export DST_MAC2=98:03:9b:94:c7:cd
    export DEV1=ens8
    export DEV2=ens9
else
    # spider-97
    export DST_MAC1=7c:fe:90:f5:a3:55
    export DST_MAC2=7c:fe:90:f5:a3:57
    export DEV1=ens6
    export DEV2=ens7
fi

export DEBUG=yes

if false; then
    export SRC=src6
    export DST=dst6
    export TOS=traffic_class
    export SRC_IP1=2011::1
    export SRC_IP2=2012::1
    export DEST_IP=2005::1
else
    export SRC=src_min
    export DST=dst
    export TOS=tos
    export SRC_IP1=192.0.2.17
    export SRC_IP2=192.0.2.33
    export DEST_IP=192.0.2.129
fi

# Threads are specified with parameter -t value in $THREADS
for ((thread = 0; thread <= 0; thread++)); do
    dev=${DEV1}@${thread}

    # Add remove all other devices and add_device $dev to thread
    pg_thread $thread "rem_device_all"
    pg_thread $thread "add_device" $dev

    # Base config
    pg_set $dev "flag QUEUE_MAP_CPU"
    pg_set $dev "count $COUNT"
    pg_set $dev "clone_skb $CLONE_SKB"
    pg_set $dev "pkt_size $PKT_SIZE"
    pg_set $dev "delay $DELAY"
    pg_set $dev "flag NO_TIMESTAMP"
    pg_set $dev "flag UDPCSUM"
    #pg_set $dev "$TOS 60"
    pg_set $dev "$TOS 20"

    # Destination
    pg_set $dev "dst_mac $DST_MAC1"
    pg_set $dev "$DST $DEST_IP"
    pg_set $dev "$SRC $SRC_IP1"

    # Setup burst, for easy testing -b 0 disable bursting
    # (internally in pktgen default and minimum burst=1)
    if [[ ${BURST} -ne 0 ]]; then
	pg_set $dev "burst $BURST"
    else
	info "$dev: Not using burst"
    fi
done

if false; then
for ((thread = 1; thread <= 1; thread++)); do
    dev=${DEV2}@${thread}

    # Add remove all other devices and add_device $dev to thread
    pg_thread $thread "rem_device_all"
    pg_thread $thread "add_device" $dev

    # Base config
    pg_set $dev "flag QUEUE_MAP_CPU"
    pg_set $dev "count $COUNT"
    pg_set $dev "clone_skb $CLONE_SKB"
    pg_set $dev "pkt_size $PKT_SIZE"
    pg_set $dev "delay $DELAY"
    pg_set $dev "flag NO_TIMESTAMP"
    pg_set $dev "flag UDPCSUM"
    #pg_set $dev "$TOS 80"
    pg_set $dev "$TOS 20"

    # Destination
    pg_set $dev "dst_mac $DST_MAC2"
    pg_set $dev "$DST $DEST_IP"
    pg_set $dev "$SRC $SRC_IP2"

    # Setup burst, for easy testing -b 0 disable bursting
    # (internally in pktgen default and minimum burst=1)
    if [[ ${BURST} -ne 0 ]]; then
	pg_set $dev "burst $BURST"
    else
	info "$dev: Not using burst"
    fi
done
fi

# Run if user hits control-c
function control_c() {
    # Print results
    for ((thread = 0; thread <= 0; thread++)); do
	dev=${DEV1}@${thread}
	echo "Device: $dev"
	cat /proc/net/pktgen/$dev | grep -A2 "Result:"
    done
    for ((thread = 1; thread <= 1; thread++)); do
	dev=${DEV2}@${thread}
	echo "Device: $dev"
	cat /proc/net/pktgen/$dev | grep -A2 "Result:"
    done
}
# trap keyboard interrupt (Ctrl-C)
trap control_c SIGINT

echo "Running... ctrl^C to stop" >&2
pg_ctrl "start"
