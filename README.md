# k8s-multicluster-gitops

Infrastructure as Code (IaC) for provisioning and managing multiple Kubernetes
clusters across multiple cloud accounts, using GitOps principles with ArgoCD.

## Requirements

Guides on setting up Kubernetes clusters in the cloud are common, but few cover
managing clusters across multiple providers and accounts (a key need for large
enterprises)

This project aims to provide a practical example:

- ✅ Provisioning and managing Kubernetes clusters across multiple cloud
  providers (AWS, Azure, GCP).
- ✅ Deploying and maintaining Kubernetes clusters across multiple accounts and
  regions.

## Architecture

You likely need to deploy multiple Kubernetes clusters across various cloud
providers and accounts.

Each cloud provider has a designated "primary account" where subdomains are hosted:

- `aws.mylabs.dev` - AWS
- `az.mylabs.dev` - Azure
- `gcp.mylabs.dev` - Google Cloud Platform

> The second-level domain `mylabs.dev` is hosted externally (e.g., Cloudflare),
> and it's the user's responsibility to configure DNS delegation properly.

An IAM role (or the equivalent for each cloud provider) will be created in the
primary account. This role will allow GitHub Actions / mise to manage resources
in the primary account and will also be used to access other accounts where
Kubernetes clusters are deployed.

## Cloud Providers - Multi-Account Setup

Let's assume you have 2 AWS accounts, 2 Azure accounts, 2 GCP accounts and you
want to deploy 2 Kubernetes clusters (EKS, AKS, GKE) in each account:

| Cloud Provider                                   | Account 01                                                   | Account 02                                                   |
|--------------------------------------------------|--------------------------------------------------------------|--------------------------------------------------------------|
| **AWS** (`aws.mylabs.dev`, `k8s.aws.mylabs.dev`) | `k01.k8s.aws.mylabs.dev` (US), `k02.k8s.aws.mylabs.dev` (EU) | `k03.k8s.aws.mylabs.dev` (US), `k04.k8s.aws.mylabs.dev` (EU) |
| **Azure** (`az.mylabs.dev`, `k8s.az.mylabs.dev`) | `k01.k8s.az.mylabs.dev` (US), `k02.k8s.az.mylabs.dev` (EU)   | `k03.k8s.az.mylabs.dev` (US), `k04.k8s.az.mylabs.dev` (EU)   |
| **GCP** (`gcp.mylabs.dev`, `k8s.gcp.mylabs.dev`) | `k01.k8s.gcp.mylabs.dev` (US), `k02.k8s.gcp.mylabs.dev` (EU) | `k03.k8s.gcp.mylabs.dev` (US), `k04.k8s.gcp.mylabs.dev` (EU) |

### AWS

#### Primary account

Choose one of your AWS accounts to act as the **primary account** and create a
Route 53 hosted zone for `aws.mylabs.dev`

> Ensure that the necessary environment variables are set for the AWS CLI
> (e.g., `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`).

```bash
mise run create:aws-primary:cf-route53-gh-action-iam-role-oidc
```

> For more details please inspect the [mise.toml](./mise.toml) file.

Next, manually set up the DNS delegation between your second-level domain
`mylabs.dev` and the `aws.mylabs.dev` hosted zone in Route 53.

Example:

![Cloudflare DNS records for mylabs.dev](images/cloudflare-mylabs-dev-dns-records.avif)

#### Tenant Accounts

Create an IAM role in each tenant account that allows the primary account to
assume a role in the tenant account.

> Make sure to use AWS credentials (`AWS_ACCESS_KEY_ID`,
> `AWS_SECRET_ACCESS_KEY`) for the tenant account.

```bash
mise run create:aws-tenant:cf-iam-role
```

### Azure

### GCP

## K8s Clusters

All the "kubeconfig files" will be stored in the `clusters/.kubeconfigs`
directory.

### Kind

The [kind clusters](https://kind.sigs.k8s.io/) are created using the `kind`
tool, which is a tool for running Kubernetes clusters in Docker containers.

```bash
mise run create:kind:kind01-internal
mise run delete:kind:kind01-internal
mise run create:kind:kind02-internal
mise run delete:kind:kind02-internal
mise run create-kind-all
mise run delete-kind-all
```

### K3d

The [k3d clusters](https://k3d.io/) are created using the `k3d` tool, which
is a lightweight wrapper to run `k3s` in Docker containers.

```bash
mise run create:k3d:k3d01-internal
mise run delete:k3d:k3d01-internal
mise run create:k3d:k3d02-internal
mise run delete:k3d:k3d02-internal
mise run create-k3d-all
mise run delete-k3d-all
```

> You can also create all the clusters at once using the `create-all` and
> `delete-all` commands:
>
> ```bash
> mise run "create-kind-all" ::: "create-k3d-all"
> mise run "delete-kind-all" ::: "delete-k3d-all"
> ```

## Architecture diagrams

### DNS diagram

```mermaid
flowchart TB
  subgraph "Cloudflare"
    mylabs.dev@{ icon: "logos:cloudflare-icon", form: "square", label: "mylabs.dev", pos: "b", h: 60 }
  end

  subgraph "AWS"
    subgraph "AWS Primary Account"
      aws.mylabs.dev@{ icon: "logos:aws-route53", form: "circle", label: "aws.mylabs.dev", pos: "b", h: 60 }
      k8s.aws.mylabs.dev@{ icon: "logos:aws-route53", form: "square", label: "k8s.aws.mylabs.dev", pos: "b", h: 60 }
    end
    subgraph "AWS Account 02"
      k03.k8s.aws.mylabs.dev@{ icon: "logos:aws-route53", form: "square", label: "k03.k8s.aws.mylabs.dev", pos: "b", h: 60 }
      k04.k8s.aws.mylabs.dev@{ icon: "logos:aws-route53", form: "square", label: "k04.k8s.aws.mylabs.dev", pos: "b", h: 60 }
    end
    subgraph "AWS Account 01"
      k01.k8s.aws.mylabs.dev@{ icon: "logos:aws-route53", form: "square", label: "k01.k8s.aws.mylabs.dev", pos: "b", h: 60 }
      k02.k8s.aws.mylabs.dev@{ icon: "logos:aws-route53", form: "square", label: "k02.k8s.aws.mylabs.dev", pos: "b", h: 60 }
    end
  end

  subgraph "Azure"
    subgraph "Azure Primary Account"
      az.mylabs.dev@{ icon: "logos:azure-icon", form: "circle", label: "az.mylabs.dev", pos: "b", h: 60 }
      k8s.az.mylabs.dev@{ icon: "logos:azure-icon", form: "square", label: "k8s.az.mylabs.dev", pos: "b", h: 60 }
    end
    subgraph "Azure Account 02"
      k03.k8s.az.mylabs.dev@{ icon: "logos:azure-icon", form: "square", label: "k03.k8s.az.mylabs.dev", pos: "b", h: 60 }
      k04.k8s.az.mylabs.dev@{ icon: "logos:azure-icon", form: "square", label: "k04.k8s.az.mylabs.dev", pos: "b", h: 60 }
    end
    subgraph "Azure Account 01"
      k01.k8s.az.mylabs.dev@{ icon: "logos:azure-icon", form: "square", label: "k01.k8s.az.mylabs.dev", pos: "b", h: 60 }
      k02.k8s.az.mylabs.dev@{ icon: "logos:azure-icon", form: "square", label: "k02.k8s.az.mylabs.dev", pos: "b", h: 60 }
    end
  end

  subgraph "GCP"
    subgraph "GCP Primary Account"
      gcp.mylabs.dev@{ icon: "logos:google-cloud", form: "circle", label: "gcp.mylabs.dev", pos: "b", h: 60 }
      k8s.gcp.mylabs.dev@{ icon: "logos:google-cloud", form: "square", label: "k8s.gcp.mylabs.dev", pos: "b", h: 60 }
    end
    subgraph "GCP Account 02"
      k03.k8s.gcp.mylabs.dev@{ icon: "logos:google-cloud", form: "square", label: "k03.k8s.gcp.mylabs.dev", pos: "b", h: 60 }
      k04.k8s.gcp.mylabs.dev@{ icon: "logos:google-cloud", form: "square", label: "k04.k8s.gcp.mylabs.dev", pos: "b", h: 60 }
    end
    subgraph "GCP Account 01"
      k01.k8s.gcp.mylabs.dev@{ icon: "logos:google-cloud", form: "square", label: "k01.k8s.gcp.mylabs.dev", pos: "b", h: 60 }
      k02.k8s.gcp.mylabs.dev@{ icon: "logos:google-cloud", form: "square", label: "k02.k8s.gcp.mylabs.dev", pos: "b", h: 60 }
    end
  end

  mylabs.dev --> aws.mylabs.dev
  aws.mylabs.dev --> k8s.aws.mylabs.dev
  k8s.aws.mylabs.dev --> k01.k8s.aws.mylabs.dev
  k8s.aws.mylabs.dev --> k02.k8s.aws.mylabs.dev
  k8s.aws.mylabs.dev --> k03.k8s.aws.mylabs.dev
  k8s.aws.mylabs.dev --> k04.k8s.aws.mylabs.dev
  mylabs.dev --> az.mylabs.dev
  az.mylabs.dev --> k8s.az.mylabs.dev
  k8s.az.mylabs.dev --> k01.k8s.az.mylabs.dev
  k8s.az.mylabs.dev --> k02.k8s.az.mylabs.dev
  k8s.az.mylabs.dev --> k03.k8s.az.mylabs.dev
  k8s.az.mylabs.dev --> k04.k8s.az.mylabs.dev
  mylabs.dev --> gcp.mylabs.dev
  gcp.mylabs.dev --> k8s.gcp.mylabs.dev
  k8s.gcp.mylabs.dev --> k01.k8s.gcp.mylabs.dev
  k8s.gcp.mylabs.dev --> k02.k8s.gcp.mylabs.dev
  k8s.gcp.mylabs.dev --> k03.k8s.gcp.mylabs.dev
  k8s.gcp.mylabs.dev --> k04.k8s.gcp.mylabs.dev
```

## Tests

```bash
docker run --rm -it --env GITHUB_TOKEN \
  -v "$PWD:/mnt" -v "/var/run/docker.sock:/var/run/docker.sock" \
  --workdir /mnt \
  bash bash -c 'set -euo pipefail && \
    apk add docker && \
    wget -q https://mise.run -O - | sh && \
    eval "$(~/.local/bin/mise activate bash)" && \
    mise run "create-kind-all" ::: "create-k3d-all" && \
    mise run "delete-kind-all" ::: "delete-k3d-all" \
  '
```
