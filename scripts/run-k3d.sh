#!/usr/bin/env bash

# The "create" needs to be idempotent !
create() {
  k3d --version
  if k3d cluster list --no-headers | grep -q "^${CLUSTER_FQDN} "; then
    echo "*** Cluster \"${CLUSTER_FQDN}\" already exists...."
  else
    mkdir -p "${CLUSTERS_KUBECONFIG_DIRECTORY}"
    k3d cluster create "${CLUSTER_FQDN}" --kubeconfig-update-default=false \
      --k3s-arg "--disable=traefik@all" \
      --k3s-arg "--disable=local-storage@all" \
      --k3s-arg "--disable=metrics-server@all"
    k3d kubeconfig write "${CLUSTER_FQDN}" --overwrite --output "${CLUSTERS_KUBECONFIG_DIRECTORY}/kubeconfig_${CLUSTER_FQDN}.yml"
  fi
}

delete() {
  if k3d cluster list --no-headers | grep -q "^${CLUSTER_FQDN} "; then
    k3d cluster delete "${CLUSTER_FQDN}"
    if [[ -f "${CLUSTERS_KUBECONFIG_DIRECTORY}/kubeconfig_${CLUSTER_FQDN}.yml" ]]; then
      echo "*** Deleting \"${CLUSTERS_KUBECONFIG_DIRECTORY}/kubeconfig_${CLUSTER_FQDN}.yml\" ..."
      rm "${CLUSTERS_KUBECONFIG_DIRECTORY}/kubeconfig_${CLUSTER_FQDN}.yml"
    fi
    if [[ -d "${CLUSTERS_KUBECONFIG_DIRECTORY}" && -z "$(ls -A "${CLUSTERS_KUBECONFIG_DIRECTORY}")" ]]; then
      echo "*** Deleting empty \"${CLUSTERS_KUBECONFIG_DIRECTORY}\" ..."
      rmdir "${CLUSTERS_KUBECONFIG_DIRECTORY}" || true
    fi
  else
    echo "*** Cluster \"${CLUSTER_FQDN}\" does not exist..."
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
    echo "*** Creating K8s cluster..."
    create
    ;;
  delete)
    echo "*** Deleting K8s cluster..."
    delete
    ;;
  *)
    usage
    ;;
esac
