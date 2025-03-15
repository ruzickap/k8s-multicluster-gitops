#!/usr/bin/env bash

# The "create" needs to be idempotent !
create() {
  kind --version
  if kind get clusters 2>&1 | grep -q "^${CLUSTER_FQDN}$"; then
    echo "*** Cluster \"${CLUSTER_FQDN}\" already exists...."
  else
    mkdir -p "${CLUSTERS_KUBECONFIG_DIRECTORY}"
    cat << EOF | kind create cluster --name "${CLUSTER_FQDN}" --kubeconfig "${CLUSTERS_KUBECONFIG_DIRECTORY}/kubeconfig_${CLUSTER_FQDN}.yml" --config -
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
EOF
  fi
}

delete() {
  if kind get clusters | grep -q "^${CLUSTER_FQDN}$"; then
    kind delete cluster --name "${CLUSTER_FQDN}" --kubeconfig "${CLUSTERS_KUBECONFIG_DIRECTORY}/kubeconfig_${CLUSTER_FQDN}.yml"
    if [[ -f "${CLUSTERS_KUBECONFIG_DIRECTORY}/kubeconfig_${CLUSTER_FQDN}.yml" ]]; then
      echo "*** Deleting \"${CLUSTERS_KUBECONFIG_DIRECTORY}/kubeconfig_${CLUSTER_FQDN}.yml\""
      rm "${CLUSTERS_KUBECONFIG_DIRECTORY}/kubeconfig_${CLUSTER_FQDN}.yml"
    fi
    if [[ -d "${CLUSTERS_KUBECONFIG_DIRECTORY}" && -z "$(ls -A "${CLUSTERS_KUBECONFIG_DIRECTORY}")" ]]; then
      echo "*** Deleting empty \"${CLUSTERS_KUBECONFIG_DIRECTORY}\""
      rmdir "${CLUSTERS_KUBECONFIG_DIRECTORY}" || true
    fi
  else
    echo "*** Cluster \"${CLUSTER_FQDN}\" does not exist"
  fi
}

usage() {
  echo "*** Usage: $0 {create|delete}"
  exit 1
}

: "${CLUSTER_FQDN:?Error: CLUSTER_FQDN environment variable is not set!}"
: "${CLUSTERS_KUBECONFIG_DIRECTORY:?Error: CLUSTERS_KUBECONFIG_DIRECTORY environment variable is not set!}"

if [[ $# -ne 1 ]]; then
  usage
fi

case "$1" in
  create)
    echo "*** Creating K8s cluster"
    create
    ;;
  delete)
    echo "*** Deleting K8s cluster"
    delete
    ;;
  *)
    usage
    ;;
esac
