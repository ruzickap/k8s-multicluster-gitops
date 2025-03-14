# k8s-multicluster-gitops

Infrastructure as Code for provisioning multiple Kubernetes clusters, managed
using GitOps with ArgoCD

Tests:

```bash
SOPS_AGE_KEY="$(grep -v ^# ~/Documents/secrets/age.txt)"
export SOPS_AGE_KEY
MISE_SOPS_AGE_KEY="$(grep -v ^# ~/Documents/secrets/age.txt)"
export MISE_SOPS_AGE_KEY

docker run --rm -it \
  --env SOPS_AGE_KEY --env MISE_SOPS_AGE_KEY \
  -v "$PWD:/mnt" \
  -v "/var/run/docker.sock:/var/run/docker.sock" \
  --workdir /mnt \
  bash bash -c 'set -euxo pipefail && \
    apk add docker && \
    wget https://mise.run -O - | sh && \
    eval "$(~/.local/bin/mise activate bash)" && \
    mise run "create:*:*" && \
    mise run "delete:*:*" \
  '
```
