#!/bin/bash

script_dir=$(dirname $(realpath $0))

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

kubestats() {
    printf "nodes: %s pods: %s spots: %s\n" \
	   $(kubectl get nodes --no-headers | wc -l) \
	   $(kubectl get pods --no-headers 2>/dev/null | wc -l) \
	   $(aws ec2 describe-spot-instance-requests --filters Name=state,Values=active --query "SpotInstanceRequests[*].[InstanceId]" --output text | wc -l)    
}

podWatch() {
    kubectl get pods --all-namespaces -o json | jq -r '.items[] | [.metadata.ownerReferences[].kind,.spec.nodeName]? | @tsv' | sort | uniq -c | sort -k 3
}

if [[ $1 == "podWatch" ]]; then
    podWatch
    exit 0
fi

if [[ $1 == "kubestats" ]]; then
    kubestats
    exit 0
fi

if [[ $1 == "emacs" ]]; then
    tmux split-window -l 50% -h emacsclient -t
    tmux split-window -t $TMUX_PANE -l 3 -v "watch -d -n 5 $0 kubestats"
    tmux split-window -t $TMUX_PANE -l 7 -v -d "watch -d -n 1 kubectl get pods -n karpenter -o wide"
    #tmux split-window -t $TMUX_PANE -l 40% -v -d "stern -n karpenter -l 'karpenter in (controller,webhook)'"
    tmux split-window -t $TMUX_PANE -l 40% -v -d "${script_dir}/karp-stern.sh"
    tmux split-window -t $TMUX_PANE -l 7 -v -d "watch -d -n 1 kubectl get nodes -o wide"
    exit 0
fi


# Demo for kubecon oct 2021
if [[ $1 == "demo" ]]; then
    tmux split-window -l 50% -v "stern -n karpenter -l 'karpenter in (controller,webhook)'"
    tmux split-window -l 3 -v "watch -d -n 5 $0 kubestats"
    #tmux split-window -t $TMUX_PANE -l 35% -v -d "watch -d -n 1 'kubectl get nodes -o wide --no-headers'"
    #tmux split-window -t $TMUX_PANE -l 35% -h -d "watch -d -n 5 $0 podWatch"
    exit
fi


#tmux split-window -l 50% -h "kubectl logs -f -n karpenter -l 'karpenter in (controller,webhook)'"
tmux split-window -l 50% -h "${script_dir}/karp-stern.sh"
tmux split-window -l 50% -v -d 'watch -d -n 10  aws ec2 describe-spot-instance-requests --filters Name=state,Values=active      --query "SpotInstanceRequests[*].[InstanceId]"     --output text'
tmux split-window -l 20% -v -d 'watch -d -n 10  "aws ec2 describe-launch-templates | grep -c Karpenter"'
#tmux split-window -l 50% -v -d "kubectl -n kube-system logs -f -l name=nvidia-device-plugin-ds"
#tmux split-window -l 50% -v -d "stern -n kube-system logs -l name=nvidia-device-plugin-ds"
tmux split-window -t $TMUX_PANE -l 30% -v -d "watch -d -n 10 kubectl get nodes -o wide"
tmux split-window -t $TMUX_PANE -l 30% -v -d "watch -d -n 10 $0 podWatch"
tmux split-window -t $TMUX_PANE -l 7 -v -d "watch -d -n 10 kubectl get pods -n karpenter -o wide"
tmux split-window -t $TMUX_PANE -l 8 -v -d "watch -d -n 10 kubectl get pods --selector=name=nvidia-device-plugin-ds -n kube-system"
