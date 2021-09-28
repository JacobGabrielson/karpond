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

#tmux split-window -l 50% -h "kubectl logs -f -n karpenter -l 'karpenter in (controller,webhook)'"
tmux split-window -l 50% -h "stern -n karpenter -l 'karpenter in (controller,webhook)'"
#tmux split-window -l 50% -v -d "kubectl -n kube-system logs -f -l name=nvidia-device-plugin-ds"
tmux split-window -l 50% -v -d "stern -n kube-system logs -l name=nvidia-device-plugin-ds"
tmux split-window -t $TMUX_PANE -l 30% -v -d "watch -d -n 1 kubectl get nodes -o wide"
tmux split-window -t $TMUX_PANE -l 30% -v -d "watch -d -n 5 $0 podWatch"
tmux split-window -t $TMUX_PANE -l 7 -v -d "watch -d -n 1 kubectl get pods -n karpenter -o wide"
tmux split-window -t $TMUX_PANE -l 8 -v -d "watch -d -n 1 kubectl get pods --selector=name=nvidia-device-plugin-ds -n kube-system"
