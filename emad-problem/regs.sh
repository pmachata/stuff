prevct=0

decode() {
    local v=$1; shift
    local c
    local -a cs

    while ((v > 0)); do
        c=$((v & 0xff))
        v=$((v >> 8))
        cs+=($c)
    done

    printf "%b" $(printf '\\%03o' ${cs[@]}) | rev
    echo
}

while sleep 0.1; do
    out=$(ethtool -S swp1)
    regct=$(echo "$out" | grep ' regct:' | cut -d ':' -f 2)
    want=$((regct - prevct))
    if ((want == 0)); then
        continue
    fi
    if ((want > 64)); then
        echo "$((want - 64)) missed"
        want=64
    fi

    echo "---"
    date +%T.%N
    regidx=$(echo "$out" | grep ' regidx:' | cut -d ':' -f 2)
    regs=($(echo "$out" | grep ' reg[0-9][0-9]:' | cut -d ':' -f 2))
    for ((i = 64 - want; i < 64; i++)); do
        j=$(((regidx + i + 1) % 64))
        decode ${regs[j]}
    done

    prevct=$((regct))
done
