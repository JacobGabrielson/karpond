# SLR issue

if you get service-linked role error, may be due to missing

aws iam create-service-linked-role --aws-service-name spot.amazonaws.com

# Debugging cni startup


useful:

```
 <command> | curl -F 'sprunge=<-' http://sprunge.us
 ```

ipamd logs here on a worker node:

/var/log/aws-routed-eni/*.log

also check kube-proxy (Pod) and aws-node (Pod)

```
{"level":"info","ts":"2021-09-22T04:00:52.847Z","caller":"entrypoint.sh","msg":"Successfully copied CNI plugin binary and config file."}
```

above line, in aws node, indicates network ready

test3:

- ec2 launch time (pst) Tue Sep 21 2021 20:58:55 GMT-0700 (Pacific Daylight Time) (37 minutes)
  i.e.                                               03:58:55
- messages: http://sprunge.us/GQxAvS - starts (?) at 03:59:18
- ipamd.log: http://sprunge.us/k0tXnm - starts at    04:00:48
- plugin.log: http://sprunge.us/k0tXnm - same ^^
- cni ready at?                                      04:00:52

- aws-node 
```
{"level":"info","ts":"2021-09-22T04:00:48.805Z","caller":"entrypoint.sh","msg":"Install CNI binary.."}
{"level":"info","ts":"2021-09-22T04:00:48.817Z","caller":"entrypoint.sh","msg":"Starting IPAM daemon in the background ... "}
{"level":"info","ts":"2021-09-22T04:00:48.818Z","caller":"entrypoint.sh","msg":"Checking for IPAM connectivity ... "}
{"level":"info","ts":"2021-09-22T04:00:52.844Z","caller":"entrypoint.sh","msg":"Copying config file ... "}
{"level":"info","ts":"2021-09-22T04:00:52.847Z","caller":"entrypoint.sh","msg":"Successfully copied CNI plugin binary and config file."}
{"level":"info","ts":"2021-09-22T04:00:52.848Z","caller":"entrypoint.sh","msg":"Foregrounding IPAM daemon ..."}
```


# Demo

Use?

https://codeberg.org/hjacobs/kube-ops-view

  docker run -it --net=host hjacobs/kube-ops-view
  
  (then open localhost 8080)!!!

https://github.com/derailed/k9s


# Muliple Provisioner Investigation

https://github.com/awslabs/karpenter/issues/783


CriticalAddonsOnly - unused now?

https://github.com/kubernetes/kubernetes/pull/101966#issuecomment-840788605

looks that way.... also it was only used as a temporary taint anyway
(by the "rescheduler")

NewConstraints, however, is called by:

```
func (s *Scheduler) getSchedules
```

use?

```
	if err := f.KubeClient.List(ctx, pods, client.MatchingFields{"spec.nodeName": ""}); err != nil {
```

What would query look like (roughly?)

`PodSpec` has:

```
	Volumes []Volume
```

and `Volume` is:

```
type Volume struct {
	Name string
	VolumeSource
}
```

which includes:

```
type VolumeSource struct {
	// ... other things ...

	// PersistentVolumeClaimVolumeSource represents a reference to a PersistentVolumeClaim in the same namespace
	// +optional
	PersistentVolumeClaim *PersistentVolumeClaimVolumeSource

	// ... other things ...
```

