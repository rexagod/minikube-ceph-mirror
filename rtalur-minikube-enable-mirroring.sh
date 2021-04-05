#!/bin/bash

PRIMARY_CLUSTER="${PRIMARY_CLUSTER:-minicluster1}"
SECONDARY_CLUSTER="${SECONDARY_CLUSTER:-minicluster2}"

SECONDARY_CLUSTER_PEER_TOKEN_SECRET_NAME=$(kubectl get cephblockpools.ceph.rook.io replicapool --context="${SECONDARY_CLUSTER}" -nrook-ceph -o jsonpath='{.status.info.rbdMirrorBootstrapPeerSecretName}')

SECONDARY_CLUSTER_SECRET=$(kubectl get secret -n rook-ceph "${SECONDARY_CLUSTER_PEER_TOKEN_SECRET_NAME}" --context=${SECONDARY_CLUSTER} -o jsonpath='{.data.token}'| base64 -d)

SECONDARY_CLUSTER_SITE_NAME_UNSANITIZED=$(kubectl get cephblockpools.ceph.rook.io replicapool --context=${SECONDARY_CLUSTER} -nrook-ceph -o jsonpath='{.status.mirroringInfo.site_name}')
SECONDARY_CLUSTER_SITE_NAME=${SECONDARY_CLUSTER_SITE_NAME_UNSANITIZED::-1}

echo SECONDARY_CLUSTER_PEER_TOKEN_SECRET_NAME is $SECONDARY_CLUSTER_PEER_TOKEN_SECRET_NAME
echo Token for the secondary cluster is $SECONDARY_CLUSTER_SECRET
echo SECONDARY_CLUSTER_SITE_NAME is ${SECONDARY_CLUSTER_SITE_NAME}

kubectl -n rook-ceph create secret generic --context="${PRIMARY_CLUSTER}" "${SECONDARY_CLUSTER_SITE_NAME}" --from-literal=token=${SECONDARY_CLUSTER_SECRET} --from-literal=pool=replicapool

cat <<EOF | kubectl --context="${PRIMARY_CLUSTER}" apply -f -
apiVersion: ceph.rook.io/v1
kind: CephRBDMirror
metadata:
  name: my-rbd-mirror
  namespace: rook-ceph
spec:
  count: 1
  peers:
    secretNames:
      - "${SECONDARY_CLUSTER_SITE_NAME}"
EOF

if kubectl --context="${PRIMARY_CLUSTER}" -n rook-ceph get pods | grep -q rbd-mirror
then
        echo "Found rbd mirror pod."
else
        echo "Did not find rbd mirror pod."
fi

if [[ $(kubectl get cephblockpools.ceph.rook.io replicapool --context="${PRIMARY_CLUSTER}" -nrook-ceph -o jsonpath='{.status.mirroringStatus.summary.daemon_health}') != "OK" ]]
then 
        echo "daemon health not OK"
fi

if [[ $(kubectl get cephblockpools.ceph.rook.io replicapool --context="${PRIMARY_CLUSTER}" -nrook-ceph -o jsonpath='{.status.mirroringStatus.summary.health}') != "OK" ]]
then 
        echo "health not OK"
fi

if [[ $(kubectl get cephblockpools.ceph.rook.io replicapool --context="${PRIMARY_CLUSTER}" -nrook-ceph -o jsonpath='{.status.mirroringStatus.summary.image_health}') != "OK" ]]
then 
        echo "image health not OK"
fi


exit 0
