#!/bin/bash

function destroy {
  minikube --profile="${PROFILE}" stop
  minikube --profile="${PROFILE}" delete
  sudo rm -f /var/lib/libvirt/images/minikube-box2-vm-disk-"${PROFILE}"-50G
  virsh pool-refresh default
}

if [[ $1 == "destroy" ]]
then
  PROFILE=profile1 destroy
  PROFILE=profile2 destroy
  exit 0
fi

PROFILE=profile1 ./script/minikube-cluster.sh
PROFILE=profile2 ./script/minikube-cluster.sh

PRIMARY_CLUSTER=profile1 SECONDARY_CLUSTER=profile2 ./script/minikube-mirroring.sh
PRIMARY_CLUSTER=profile2 SECONDARY_CLUSTER=profile1 ./script/minikube-mirroring.sh

PRIMARY_CLUSTER=profile1 SECONDARY_CLUSTER=profile2 ./script/minikube-rbd-image.sh
PRIMARY_CLUSTER=profile2 SECONDARY_CLUSTER=profile1 ./script/minikube-rbd-image.sh
