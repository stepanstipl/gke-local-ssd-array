# GKE Local SSD Array

__*Combine local SSDs into single volume*__

This little DaemonSet helps to combine multiple local SSDs into a single logical
volume on Google Kubernetes Engine (GKE).

## Deployment

```bash
# Create config map with actual startup script
$ kubectl create configmap ssd-startup-script --from-file ssd-startup-script.sh -n kube-system
# Deploy DaemonSet
$ kubectl apply -f ssd-startup-daemon.yaml
```

The DaemonSet will only run on nodes with local SSDs provisioned, this is
achieved by using the `cloud.google.com/gke-local-ssd: "true"` nodeSelector.


## Usage

The newly created volume will be available under the `/mnt/disks/ssd-array`
path by default and can be consumed either using `hostPath` volumes [[1]], or
local Persistent Volumes provisioned either manually or using the local volume
static provisioner [[2]].

[1]: https://cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/local-ssd#example_hostpath
[2]: https://kubernetes.io/docs/concepts/storage/volumes/#local


### Deploy local volume static provisioner 

You can follow GKE documentation to deploy local volume static provisioner [[3]].
Contrary to the documentation stating creating the `local-scsi` StorageClass is
optional, this step seems to be necessary.

**TL;DR:**

```bash
# This is necessary to allow creation of ClusterRoles
$ kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole cluster-admin \
  --user ${YOUR_GCP_USER_ACCOUNT}
# Deploy the local volume provisioner
$ kubectl apply -f "https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/local-volume/provisioner/deployment/kubernetes/gce/provisioner_generated_gce_ssd_count.yaml" 
# Create StorageClass - seems to be necessary
$ kubectl apply -f storage-class.yaml
```

### Consumption

The provisioned Persisten Volumes can be then consumed by creating
PersistentVolumeClaim, with corresponding `storageClassName`, and pod with
volumes referencing this PVC [[4]].

[4]: https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/#create-a-persistentvolumeclaim

[3]: https://cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/local-ssd#running_the_local_volume_static_provisioner

