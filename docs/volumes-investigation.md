# Volumes Investigation

## Useful links

https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims

https://github.com/openebs/openebs/issues/2915#issuecomment-623135043
indicates that the kube-scheduler has special logic to know how to
wait for pods to get pv binding before scheduling - if
WaitForFirstConsumer is set

https://github.com/kubernetes/kubernetes/search?q=FindMatchingVolume
looks like both the kube-scheduler and the volume-controller call this
same function to determine which PV will be attached to the PVC
(in case there's one lying around and a PV doesn't need to be created
dynamically). I think this only happens in WaitForFirstConsumer mode?

## StatefulSet behavior

### preserve ebs volumes?

before/after diff of pod

```bash
k get pod inflate-sc-0 -o yaml > /tmp/inflate-sc-0-v1.yaml
k delete pod inflate-sc-0
k get pod inflate-sc-0 -o yaml > /tmp/inflate-sc-0-v2.yaml
```

```
--- /tmp/inflate-sc-0-v1.yaml	2021-10-21 18:15:41.959897090 -0700
+++ /tmp/inflate-sc-0-v2.yaml	2021-10-21 18:16:36.475931887 -0700
@@ -3,7 +3,7 @@
 metadata:
   annotations:
     kubernetes.io/psp: eks.privileged
-  creationTimestamp: "2021-10-19T18:08:09Z"
+  creationTimestamp: "2021-10-22T01:16:04Z"
   generateName: inflate-sc-
   labels:
     app: inflate-sc
@@ -18,8 +18,8 @@
     kind: StatefulSet
     name: inflate-sc
     uid: f4436af3-d3d0-4c45-9d7e-47546819966b
-  resourceVersion: "32462833"
-  uid: ca607ea7-975e-42d9-add3-e6365663cbfe
+  resourceVersion: "33547871"
+  uid: c4509808-1710-4fb4-b363-bb93b0662131
 spec:
   affinity:
     nodeAffinity:
@@ -43,7 +43,7 @@
     - mountPath: /data
       name: inflate-sc-vol
     - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
-      name: kube-api-access-24dbk
+      name: kube-api-access-77cf5
       readOnly: true
   dnsPolicy: ClusterFirst
   enableServiceLinks: true
@@ -71,7 +71,7 @@
   - name: inflate-sc-vol
     persistentVolumeClaim:
       claimName: inflate-sc-vol-inflate-sc-0
-  - name: kube-api-access-24dbk
+  - name: kube-api-access-77cf5
     projected:
       defaultMode: 420
       sources:
@@ -92,23 +92,23 @@
 status:
   conditions:
   - lastProbeTime: null
-    lastTransitionTime: "2021-10-19T18:09:05Z"
+    lastTransitionTime: "2021-10-22T01:16:04Z"
     status: "True"
     type: Initialized
   - lastProbeTime: null
-    lastTransitionTime: "2021-10-19T18:09:32Z"
+    lastTransitionTime: "2021-10-22T01:16:14Z"
     status: "True"
     type: Ready
   - lastProbeTime: null
-    lastTransitionTime: "2021-10-19T18:09:32Z"
+    lastTransitionTime: "2021-10-22T01:16:14Z"
     status: "True"
     type: ContainersReady
   - lastProbeTime: null
-    lastTransitionTime: "2021-10-19T18:08:14Z"
+    lastTransitionTime: "2021-10-22T01:16:04Z"
     status: "True"
     type: PodScheduled
   containerStatuses:
-  - containerID: containerd://225d7883c203929cd1ffca40bfc2a9ae1a68862cf582060684ca010ecd0eba2b
+  - containerID: containerd://dea8915f242a0a88ab6f14b70c2275f905d292ebe483434782e7768abb42012d
     image: public.ecr.aws/eks-distro/kubernetes/pause:3.2
     imageID: public.ecr.aws/eks-distro/kubernetes/pause@sha256:cc3d348dc60bf02db0a1e39d7fe69f28a2ca54770fcdcc1c3e9baa6603b648de
     lastState: {}
@@ -118,11 +118,11 @@
     started: true
     state:
       running:
-        startedAt: "2021-10-19T18:09:31Z"
+        startedAt: "2021-10-22T01:16:13Z"
   hostIP: 192.168.141.238
   phase: Running
-  podIP: 192.168.130.132
+  podIP: 192.168.158.83
   podIPs:
-  - ip: 192.168.130.132
+  - ip: 192.168.158.83
   qosClass: Burstable
-  startTime: "2021-10-19T18:09:05Z"
+  startTime: "2021-10-22T01:16:04Z"
```

answer: yes it preserves existing volumes

f/u: what about if you scale `replicas` up and down?

## how does scheduler handle WaitForFirstConsumer

https://github.com/kubernetes/kubernetes/blob/16fdb2f39148e8843e999780fc7bd3ee161349fb/pkg/scheduler/framework/plugins/volumebinding/binder.go#L124 may have
explanation?


```go
// SchedulerVolumeBinder is used by the scheduler VolumeBinding plugin to
// handle PVC/PV binding and dynamic provisioning. The binding decisions are
// integrated into the pod scheduling workflow so that the PV NodeAffinity is
// also considered along with the pod's other scheduling requirements.
//
// This integrates into the existing scheduler workflow as follows:
// 1. The scheduler takes a Pod off the scheduler queue and processes it serially:
//    a. Invokes all pre-filter plugins for the pod. GetPodVolumes() is invoked
//    here, pod volume information will be saved in current scheduling cycle state for later use.
//    b. Invokes all filter plugins, parallelized across nodes.  FindPodVolumes() is invoked here.
//    c. Invokes all score plugins.  Future/TBD
//    d. Selects the best node for the Pod.
//    e. Invokes all reserve plugins. AssumePodVolumes() is invoked here.
//       i.  If PVC binding is required, cache in-memory only:
//           * For manual binding: update PV objects for prebinding to the corresponding PVCs.
//           * For dynamic provisioning: update PVC object with a selected node from c)
//           * For the pod, which PVCs and PVs need API updates.
//       ii. Afterwards, the main scheduler caches the Pod->Node binding in the scheduler's pod cache,
//           This is handled in the scheduler and not here.
//    f. Asynchronously bind volumes and pod in a separate goroutine
//        i.  BindPodVolumes() is called first in PreBind phase. It makes all the necessary API updates and waits for
//            PV controller to fully bind and provision the PVCs. If binding fails, the Pod is sent
//            back through the scheduler.
//        ii. After BindPodVolumes() is complete, then the scheduler does the final Pod->Node binding.
// 2. Once all the assume operations are done in e), the scheduler processes the next Pod in the scheduler queue
//    while the actual binding operation occurs in the background.
```

### Test

delete provisioner

```
k delete provisioners.karpenter.sh default
```

delete ss

```
k delete statefulsets.apps inflate-sc
```

delete storageclass

```
k delete storageclasses.storage.k8s.io sc-us-west-2b
```

Apply:

```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: sc-us-west-2b
provisioner: kubernetes.io/aws-ebs
parameters:
  type: io1
  iopsPerGB: "10"
  fsType: ext4
  zone: us-west-2b
volumeBindingMode: WaitForFirstConsumer
```

cordon all nodes

```
kubectl cordon $(kubectl get nodes -o name)
```

create ss

```
k apply -f inflate-sc-uswest2b.yaml
```

scale it up

```
k scale statefulset inflate-sc --replicas=1
```


```
k describe pod inflate-sc-0
```

output:

```
Name:           inflate-sc-0
Namespace:      default
Priority:       0
Node:           <none>
Labels:         app=inflate-sc
                controller-revision-hash=inflate-sc-5dd7694cf8
                statefulset.kubernetes.io/pod-name=inflate-sc-0
Annotations:    kubernetes.io/psp: eks.privileged
Status:         Pending
IP:
IPs:            <none>
Controlled By:  StatefulSet/inflate-sc
Containers:
  inflate:
    Image:      public.ecr.aws/eks-distro/kubernetes/pause:3.2
    Port:       <none>
    Host Port:  <none>
    Requests:
      cpu:        1
    Environment:  <none>
    Mounts:
      /data from inflate-sc-vol (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-p9wlk (ro)
Conditions:
  Type           Status
  PodScheduled   False
Volumes:
  inflate-sc-vol:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  inflate-sc-vol-inflate-sc-0
    ReadOnly:   false
  kube-api-access-p9wlk:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   Burstable
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type     Reason            Age                From               Message
  ----     ------            ----               ----               -------
  Warning  FailedScheduling  36s (x2 over 38s)  default-scheduler  0/2 nodes are available: 2 node(s) were unschedulable.

```

```
k describe pvc inflate-sc-vol-inflate-sc-0

```

```
Name:          inflate-sc-vol-inflate-sc-0
Namespace:     default
StorageClass:  sc-us-west-2b
Status:        Pending
Volume:        
Labels:        app=inflate-sc
Annotations:   <none>
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      
Access Modes:  
VolumeMode:    Filesystem
Used By:       inflate-sc-0
Events:
  Type    Reason                Age               From                         Message
  ----    ------                ----              ----                         -------
  Normal  WaitForFirstConsumer  34s               persistentvolume-controller  waiting for first consumer to be created before binding
  Normal  WaitForPodScheduled   5s (x2 over 20s)  persistentvolume-controller  waiting for pod inflate-sc-0 to be scheduled
```

add a node in the web console

label node properly so pod schedules there

```
k label nodes ip-192-168-94-59.us-west-2.compute.internal karpond.example/inflatemeister=quasiquote
```

Note that `volume.kubernetes.io/selected-node: ip-192-168-94-59.us-west-2.compute.internal` was added

```
k describe pvc inflate-sc-vol-inflate-sc-0
Name:          inflate-sc-vol-inflate-sc-0
Namespace:     default
StorageClass:  sc-us-west-2b
Status:        Pending
Volume:
Labels:        app=inflate-sc
Annotations:   volume.beta.kubernetes.io/storage-provisioner: kubernetes.io/aws-ebs
               volume.kubernetes.io/selected-node: ip-192-168-94-59.us-west-2.compute.internal
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:
Access Modes:
VolumeMode:    Filesystem
Used By:       inflate-sc-0
Events:
  Type    Reason                Age                   From                         Message
  ----    ------                ----                  ----                         -------
  Normal  WaitForFirstConsumer  19m                   persistentvolume-controller  waiting for first consumer to be created before binding
  Normal  WaitForPodScheduled   4m12s (x61 over 19m)  persistentvolume-controller  waiting for pod inflate-sc-0 to be scheduled
```

Note that I ran into an issue:

```
  Warning  ProvisioningFailed    7s (x8 over 2m10s)   persistentvolume-controller  Failed to provision volume with StorageClass "sc-us-west-2b": zone[s] cannot be specified in StorageClass if VolumeBindingMode is set to WaitForFirstConsumer. Please specify allowedTopologies in StorageClass for constraining zones
```
  
  
