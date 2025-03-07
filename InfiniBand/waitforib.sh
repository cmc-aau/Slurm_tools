#!/bin/bash

# Search for infiniband devices and check waits until
# at least one reports that it is ACTIVE
# Potential InfiniBand ports: /sys/class/infiniband/*/ports/*

maxcount=180
basedir=/sys/class/infiniband
if [[ ! -d $basedir ]]; then
    logger "$0: No InfiniBand ports found"
    exit 0
fi

# Loop over all InfiniBand $basedir/*/ports/ directories until ALL have come to exist
for (( count = 0; count < $maxcount; count++ ))
do
    for nic in $basedir/*; do
        if [[ ! -d $nic/ports ]]; then
            sleep 1
        fi
    done
done

# Identify any InfiniBand link_layer ports.
# The port might be an iRDMA Ethernet port, check it with "rdma link show".
# Alternative for explicitly skipping Ethernet iRDMA ports: grep -vqc "Ethernet" ...
for nic in $basedir/*; do
    for port in $nic/ports/*; do
        if grep -qc "InfiniBand" "$port/link_layer"; then
            ib_ports+=( "$port" )
        fi
    done
done

if [[ ${#ib_ports[@]} -gt 0 ]]; then
    logger "$0: Found ${#ib_ports[@]} InfiniBand link_layer ports: ${ib_ports[*]}"
else
    logger "$0: No InfiniBand link_layer ports found"
    exit 0
fi

# Loop over InfiniBand link_layer ports until one becomes ACTIVE
for (( count = 0; count < $maxcount; count++ ))
do
    for port in ${ib_ports[*]}; do
        if grep -qc "ACTIVE" "$port/state"; then
            logger "$0: InfiniBand online at $port"
            exit 0    # Exit when the first InfiniBand becomes active
        else
            sleep 1    # Sleep 1 second
        fi
    done
done

logger "$0: Failed to find an ACTIVE InfiniBand link_layer port in $maxcount seconds"
exit 1
