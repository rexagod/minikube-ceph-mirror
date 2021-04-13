#!/bin/bash

echo "Using PROFILE:${PROFILE}"

function maybe-create-wait {
  URI="${!#}"
  while [[ "$#" -gt 0 ]]
  do
    OPT="$1"
    case "$OPT" in
      -o|--omit)
        kubectl apply -f "$URI" --context=${PROFILE}
        break
        ;;
      -c|--condition)
        kubectl apply -f "$URI" --context=${PROFILE}
        shift
        echo "Waiting for condition $1 to be met."
        kubectl wait --for condition="$1" --timeout=10m -f "$URI" --context=${PROFILE}
        break
        ;;
      *)
        echo "ERR: Ambigous parameters were passed."
        exit 1
        ;;
    esac
  done
}

minikube start -b kubeadm --kubernetes-version="v1.19.2" --feature-gates="BlockVolume=true,CSIBlockVolume=true,VolumeSnapshotDataSource=true,ExpandCSIVolumes=true" --profile="${PROFILE}"
minikube ssh "sudo mkdir -p /mnt/vda1/var/lib/rook" --profile="${PROFILE}"
minikube ssh "sudo ln -s /mnt/vda1/var/lib/rook /var/lib/rook" --profile="${PROFILE}"

sudo qemu-img create -f raw /var/lib/libvirt/images/minikube-box2-vm-disk-"${PROFILE}"-50G 50G
virsh -c qemu:///system attach-disk "${PROFILE}" --source /var/lib/libvirt/images/minikube-box2-vm-disk-"${PROFILE}"-50G --target vdb --cache none --persistent

minikube --profile="${PROFILE}" stop
minikube --profile="${PROFILE}" start

maybe-create-wait -o "https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/ceph/common.yaml"
maybe-create-wait -c "Established" "https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/ceph/crds.yaml"
maybe-create-wait -o "./kind/replicapool.yaml"
maybe-create-wait -o "./kind/rook-ceph-operator-config.yaml"
maybe-create-wait -c "Available" "./kind/rook-ceph-operator.yaml"
maybe-create-wait -o "./kind/rook-config-override.yaml"
maybe-create-wait -o "./kind/my-cluster.yaml"
maybe-create-wait -c "Available" "https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/ceph/toolbox.yaml"
