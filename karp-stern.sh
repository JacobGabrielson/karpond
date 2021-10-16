#!/bin/bash

pidfile=$(mktemp)
trap "exit" INT TERM
trap "rm -f $pidfile; kill 0" EXIT

run_stern() {
    stern -n karpenter -l 'karpenter in (controller,webhook)' &
    sternpid=$!
    echo $sternpid > $pidfile
    wait $sternpid
}

lastSum=""

watch_for_restart() {
    nextSum=$(kubectl get --no-headers pods -l karpenter -n karpenter -o name | md5sum)
    if [[ $nextSum != $lastSum ]]; then
	if [[ ! -z $lastSum ]]; then
	    echo "Detected karpenter update, killing stern" 1>&2
	    kill $(cat $pidfile)
	fi
	lastSum=$nextSum
    fi
}

while true; do
    run_stern
    sleep 1
done &

while true; do
    watch_for_restart
    sleep 5
done &

wait
