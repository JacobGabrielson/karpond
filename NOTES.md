
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

## getting ec2 instance into shape for testing

https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/install-nvidia-driver.html#preinstalled-nvidia-driver

on g2 instance, needed https://us.download.nvidia.com/XFree86/Linux-x86_64/470.74/NVIDIA-Linux-x86_64-470.74.run (grid, k520) - but didn't work

actually, needed this AMI https://aws.amazon.com/marketplace/pp/prodview-64e4rx3h733ru?sr=0-3&ref_=beagle&applicationId=AWSMPContessa ?? 

now trying this:

- https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html#installing-on-amazon-linux

None of above worked... trying to use the ami-id from the SSM params on a g2 

```bash
sudo docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi 
```

does work

BUT g2 does NOT work with tensorflow example above, because it needs minimum computeCompatibility score of 3.5, this is only 3.0 (K520)

trying g3 w/ ami-03047fe9510483cce

```

sudo yum update -y
sudo yum install -y git make glibc-devel emacs ncurses-devel
sudo systemctl --now enable docke
sudo docker run --rm hello-world
sudo docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi

```

then follow this: https://www.tensorflow.org/tfx/serving/docker#gpu_serving_example

add via `visudo`:

```
someuser ALL=(ALL) NOPASSWD:ALL
	```







