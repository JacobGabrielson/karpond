
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

# Nvidia device plugin ds

https://github.com/NVIDIA/k8s-device-plugin

# Nvidia gpu feature discovery ds

https://github.com/NVIDIA/gpu-feature-discovery#deploy-nvidia-gpu-feature-discovery-gfd

Note this only works on nodes with this label (note: later learned that NFD seems to add
this? Maybe NFD has to run first?):

```
k label node ip-192-168-123-212.us-west-2.compute.internal feature.node.kubernetes.io/pci-10de.present=true
node/ip-192-168-123-212.us-west-2.compute.internal labeled
```

and it just writes to a file:

also need NFD:

https://github.com/kubernetes-sigs/node-feature-discovery

Ok, so GFD outputs:

```
[root@ip-192-168-123-212 features.d]# pwd
/etc/kubernetes/node-feature-discovery/features.d
[root@ip-192-168-123-212 features.d]# cat gfd
nvidia.com/gfd.timestamp=1633385165
nvidia.com/cuda.driver.minor=73
nvidia.com/gpu.machine=HVM-domU
nvidia.com/gpu.product=Tesla-K80
nvidia.com/gpu.count=16
nvidia.com/cuda.runtime.major=11
nvidia.com/cuda.driver.major=460
nvidia.com/cuda.runtime.minor=2
nvidia.com/gpu.family=kepler
nvidia.com/gpu.compute.minor=7
nvidia.com/gpu.memory=11441
nvidia.com/cuda.driver.rev=01
nvidia.com/gpu.compute.major=3
```

But NFD isn't picking it up.

# p4 instance type info

```
  InstanceTypes:
- AutoRecoverySupported: false
  BareMetal: false
  BurstablePerformanceSupported: false
  CurrentGeneration: true
  DedicatedHostsSupported: false
  EbsInfo:
    EbsOptimizedInfo:
      BaselineBandwidthInMbps: 19000
      BaselineIops: 80000
      BaselineThroughputInMBps: 2375.0
      MaximumBandwidthInMbps: 19000
      MaximumIops: 80000
      MaximumThroughputInMBps: 2375.0
    EbsOptimizedSupport: default
    EncryptionSupport: supported
    NvmeSupport: required
  FreeTierEligible: false
  GpuInfo:
    Gpus:
    - Count: 8
      Manufacturer: NVIDIA
      MemoryInfo:
        SizeInMiB: 32768
      Name: V100
    TotalGpuMemoryInMiB: 262144
  HibernationSupported: false
  Hypervisor: nitro
  InstanceStorageInfo:
    Disks:
    - Count: 2
      SizeInGB: 900
      Type: ssd
    NvmeSupport: required
    TotalSizeInGB: 1800
  InstanceStorageSupported: true
  InstanceType: p3dn.24xlarge
  MemoryInfo:
    SizeInMiB: 786432
  NetworkInfo:
    DefaultNetworkCardIndex: 0
    EfaInfo:
      MaximumEfaInterfaces: 1
    EfaSupported: true
    EnaSupport: required
    Ipv4AddressesPerInterface: 50
    Ipv6AddressesPerInterface: 50
    Ipv6Supported: true
    MaximumNetworkCards: 1
    MaximumNetworkInterfaces: 15
    NetworkCards:
    - MaximumNetworkInterfaces: 15
      NetworkCardIndex: 0
      NetworkPerformance: 100 Gigabit
    NetworkPerformance: 100 Gigabit
  PlacementGroupInfo:
    SupportedStrategies:
    - cluster
    - partition
    - spread
  ProcessorInfo:
    SupportedArchitectures:
    - x86_64
    SustainedClockSpeedInGhz: 2.5
  SupportedBootModes:
  - legacy-bios
  SupportedRootDeviceTypes:
  - ebs
  SupportedUsageClasses:
  - on-demand
  - spot
  SupportedVirtualizationTypes:
  - hvm
  VCpuInfo:
    DefaultCores: 48
    DefaultThreadsPerCore: 2
    DefaultVCpus: 96
    ValidCores:
    - 4
    - 6
    - 8
    - 10
    - 12
    - 14
    - 16
    - 18
    - 20
    - 22
    - 24
    - 26
    - 28
    - 30
    - 32
    - 34
    - 36
    - 38
    - 40
    - 42
    - 44
    - 46
    - 48
    ValidThreadsPerCore:
    - 1
    - 2
```


failure launching kubelet on a g4:

```
Oct  4 16:57:28 ip-192-168-160-221 kubelet: I1004 16:57:28.762315    8031 manager_no_libpfm.go:28] cAdvisor is build without cgo and/or libpfm support. Perf event counters are not available.
Oct  4 16:57:28 ip-192-168-160-221 kubelet: I1004 16:57:28.763108    8031 manager.go:229] Version: {KernelVersion:5.4.144-69.257.amzn2.x86_64 ContainerOsVersion:Amazon Linux 2 DockerVersion:Unknown DockerAPIVersion:Unknown CadvisorVersion: CadvisorRevision:}
Oct  4 16:57:28 ip-192-168-160-221 kubelet: I1004 16:57:28.763615    8031 container_manager_linux.go:278] "Container manager verified user specified cgroup-root exists" cgroupRoot=[]
Oct  4 16:57:28 ip-192-168-160-221 kubelet: I1004 16:57:28.763782    8031 container_manager_linux.go:283] "Creating Container Manager object based on Node Config" nodeConfig={RuntimeCgroupsName: SystemCgroupsName: KubeletCgroupsName: ContainerRuntime:remote CgroupsPerQOS:true CgroupRoot:/ CgroupDriver:cgroupfs KubeletRootDir:/var/lib/kubelet ProtectKernelDefaults:true NodeAllocatableConfig:{KubeReservedCgroupName: SystemReservedCgroupName: ReservedSystemCPUs: EnforceNodeAllocatable:map[pods:{}] KubeReserved:map[cpu:{i:{value:110 scale:-3} d:{Dec:<nil>} s:110m Format:DecimalSI} ephemeral-storage:{i:{value:1073741824 scale:0} d:{Dec:<nil>} s:1Gi Format:BinarySI} memory:{i:{value:2966421504 scale:0} d:{Dec:<nil>} s:2829Mi Format:BinarySI}] SystemReserved:map[] HardEvictionThresholds:[{Signal:nodefs.inodesFree Operator:LessThan Value:{Quantity:<nil> Percentage:0.05} GracePeriod:0s MinReclaim:<nil>} {Signal:memory.available Operator:LessThan Value:{Quantity:100Mi Percentage:0} GracePeriod:0s MinReclaim:<nil>} {Signal:nodefs.available Operator:LessThan Value:{Quantity:<nil> Percentage:0.1} GracePeriod:0s MinReclaim:<nil>}]} QOSReserved:map[] ExperimentalCPUManagerPolicy:none ExperimentalTopologyManagerScope:container ExperimentalCPUManagerReconcilePeriod:10s ExperimentalMemoryManagerPolicy:None ExperimentalMemoryManagerReservedMemory:[] ExperimentalPodPidsLimit:-1 EnforceCPULimits:true CPUCFSQuotaPeriod:100ms ExperimentalTopologyManagerPolicy:none}
Oct  4 16:57:28 ip-192-168-160-221 kubelet: I1004 16:57:28.763953    8031 topology_manager.go:120] "Creating topology manager with policy per scope" topologyPolicyName="none" topologyScopeName="container"
Oct  4 16:57:28 ip-192-168-160-221 kubelet: I1004 16:57:28.763975    8031 container_manager_linux.go:314] "Initializing Topology Manager" policy="none" scope="container"
Oct  4 16:57:28 ip-192-168-160-221 kubelet: I1004 16:57:28.763992    8031 container_manager_linux.go:319] "Creating device plugin manager" devicePluginEnabled=true
Oct  4 16:57:28 ip-192-168-160-221 kubelet: I1004 16:57:28.764037    8031 manager.go:136] "Creating Device Plugin manager" path="/var/lib/kubelet/device-plugins/kubelet.sock"
Oct  4 16:57:28 ip-192-168-160-221 kubelet: I1004 16:57:28.764442    8031 server.go:989] "Cloud provider determined current node" nodeName="ip-192-168-160-221.us-west-2.compute.internal"
Oct  4 16:57:28 ip-192-168-160-221 kubelet: I1004 16:57:28.764467    8031 server.go:1131] "Using root directory" path="/var/lib/kubelet"
Oct  4 16:57:28 ip-192-168-160-221 kubelet: WARNING: 2021/10/04 16:57:28 grpc: addrConn.createTransport failed to connect to {/run/containerd/containerd.sock  <nil> 0 <nil>}. Err :connection error: desc = "transport: Error while dialing dial unix /run/containerd/containerd.sock: connect: no such file or directory". Reconnecting...
Oct  4 16:57:28 ip-192-168-160-221 kubelet: WARNING: 2021/10/04 16:57:28 grpc: addrConn.createTransport failed to connect to {/run/containerd/containerd.sock  <nil> 0 <nil>}. Err :connection error: desc = "transport: Error while dialing dial unix /run/containerd/containerd.sock: connect: no such file or directory". Reconnecting...
Oct  4 16:57:28 ip-192-168-160-221 kubelet: I1004 16:57:28.767066    8031 kubelet.go:404] "Attempting to sync node with API server"
Oct  4 16:57:28 ip-192-168-160-221 kubelet: I1004 16:57:28.767582    8031 kubelet.go:283] "Adding apiserver pod source"
Oct  4 16:57:28 ip-192-168-160-221 kubelet: I1004 16:57:28.767625    8031 apiserver.go:42] "Waiting for node sync before watching apiserver pods"
Oct  4 16:57:28 ip-192-168-160-221 kubelet: E1004 16:57:28.770481    8031 remote_runtime.go:86] "Version from runtime service failed" err="rpc error: code = Unavailable desc = connection error: desc = \"transport: Error while dialing dial unix /run/containerd/containerd.sock: connect: no such file or directory\""
Oct  4 16:57:28 ip-192-168-160-221 kubelet: E1004 16:57:28.770534    8031 kuberuntime_manager.go:208] "Get runtime version failed" err="get remote runtime typed version failed: rpc error: code = Unavailable desc = connection error: desc = \"transport: Error while dialing dial unix /run/containerd/containerd.sock: connect: no such file or directory\""
Oct  4 16:57:28 ip-192-168-160-221 kubelet: E1004 16:57:28.770562    8031 server.go:292] "Failed to run kubelet" err="failed to run Kubelet: failed to create kubelet: get remote runtime typed version failed: rpc error: code = Unavailable desc = connection error: desc = \"transport: Error while dialing dial unix /run/containerd/containerd.sock: connect: no such file or directory\""
Oct  4 16:57:28 ip-192-168-160-221 systemd: kubelet.service: main process exited, code=exited, status=1/FAILURE
Oct  4 16:57:28 ip-192-168-160-221 systemd: Unit kubelet.service entered failed state.
Oct  4 16:57:28 ip-192-168-160-221 systemd: kubelet.service failed.
```

# Demo

Use?

https://codeberg.org/hjacobs/kube-ops-view

