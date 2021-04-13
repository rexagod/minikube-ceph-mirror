#!/bin/bash

SECONDARY_CLUSTER_PEER_TOKEN_SECRET_NAME=$(kubectl get cephblockpools.ceph.rook.io replicapool --context="${SECONDARY_CLUSTER}" -n rook-ceph -o jsonpath='{.status.info.rbdMirrorBootstrapPeerSecretName}')
SECONDARY_CLUSTER_SECRET=$(kubectl get secret -n rook-ceph "${SECONDARY_CLUSTER_PEER_TOKEN_SECRET_NAME}" --context=${SECONDARY_CLUSTER} -o jsonpath='{.data.token}'| base64 -d)
SECONDARY_CLUSTER_SITE_NAME_UNSANITIZED=$(kubectl get cephblockpools.ceph.rook.io replicapool --context=${SECONDARY_CLUSTER} -n rook-ceph -o jsonpath='{.status.mirroringInfo.site_name}')
SECONDARY_CLUSTER_SITE_NAME=${SECONDARY_CLUSTER_SITE_NAME_UNSANITIZED::-1}

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
