
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

# Nvidia device plugin ds

https://github.com/NVIDIA/k8s-device-plugin

# Nvidia gpu feature discovery ds

https://github.com/NVIDIA/gpu-feature-discovery#deploy-nvidia-gpu-feature-discovery-gfd

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


