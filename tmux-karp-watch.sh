#!/bin/bash



twatch() {
    if [[ $1 = '-d' ]]; then
	local dflag="-d"
	shift
    else
	local dflag=""
    fi
    if [[ -z $TMUX ]]; then
	watch $dflag "$1"
    else
	tmux split-window -d -p 10 "watch -n 1 $dflag \"$1\""
	tmux select-layout tiled
    fi
}

podWatch() {
    kubectl get pods --all-namespaces -o json | jq -r '.items[] | [.metadata.ownerReferences[].kind,.spec.nodeName] | @tsv' | sort | uniq -c | sort -k 3
}

if [[ $1 == "podWatch" ]]; then
    podWatch
    exit 0
fi


twatch -d "kubectl get nodes"
tmux split-window -l 50% -h -d -p 10 "stern ^karpenter --all-namespaces"
tmux split-window -l 50% -v -d -p 10 "watch -n 5 $0 podWatch"
