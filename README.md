# k8s-multicluster-gitops

Infrastructure as Code for provisioning multiple Kubernetes clusters, managed
using GitOps with ArgoCD

Create all "kind" clusters:

```bash
mise task run "create:kind:*"
mise task run "delete:kind:*"
```

Create all "k3d" clusters:

```bash
mise task run "create:k3d:*"
mise task run "delete:k3d:*"
```

> Same for eksctl, az, terraform-aws, terraform-az, ... clusters

---

## Tests

```bash
SOPS_AGE_KEY="$(grep -v ^# ~/Documents/secrets/age.txt)"
export SOPS_AGE_KEY
MISE_SOPS_AGE_KEY="$(grep -v ^# ~/Documents/secrets/age.txt)"
export MISE_SOPS_AGE_KEY

docker run --rm -it \
  --env SOPS_AGE_KEY --env MISE_SOPS_AGE_KEY --env GITHUB_TOKEN \
  -v "$PWD:/mnt" \
  -v "/var/run/docker.sock:/var/run/docker.sock" \
  --workdir /mnt \
  bash bash -c 'set -euo pipefail && \
    apk add docker && \
    wget -q https://mise.run -O - | sh && \
    eval "$(~/.local/bin/mise activate bash)" && \
    mise run "create-kind-all" ::: "create-k3d-all" && \
    mise run "delete-kind-all" ::: "delete-k3d-all" \
  '
```
