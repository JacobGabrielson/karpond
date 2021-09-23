
# Debugging cni startup

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

# real-ish testing of nvidia

try out this 

https://www.tensorflow.org/tfx/serving/docker#serving_with_docker_using_your_gpu
