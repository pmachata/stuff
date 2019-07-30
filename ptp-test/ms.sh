#!/bin/bash
source lib.sh

check_args S1 -- "$@"
echo S1=$S1

common_config
extra_config $S1

use_if $S1 $IPV4 $IPV6
runptp $S1
