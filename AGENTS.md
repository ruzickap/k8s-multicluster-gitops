# AGENTS.md

Repo-specific notes for agents. General conventions (Markdown/`rumdl`,
shell/`shellcheck`+`shfmt`, JSON, Terraform, commit/branch/PR rules, security
scanners) live in the global `~/.config/opencode/AGENTS.md` and are not repeated
here. This file only covers what is unique to this repo.

## What this is

`k8s-multicluster-gitops`: IaC to provision Kubernetes clusters across multiple
clouds/accounts (AWS/Azure/GCP) plus local `kind`/`k3d`. There is **no app code
and no package manifest** — the repo is driven entirely by `mise` tasks, Bash
scripts, and CloudFormation. Pinned tool versions live in `mise.toml`
(`[tools]`).

## How the cluster tasks are wired (non-obvious)

Everything runs through `mise`. The task layer uses a deliberate three-hop
indirection — read all three to understand any cluster operation:

1. `mise.toml` defines the entrypoint tasks. Per-cluster tasks re-invoke mise to
   work around mise not passing env into parallel tasks
   (jdx/mise#4593), e.g.:
   `run = 'mise run --env ${MISE_TASK_NAME##*:} create:${MISE_TASK_NAME##*:}'`
   So `create:kind:kind01-internal` becomes
   `mise run --env kind01-internal create:kind01-internal`.
2. `--env <name>` loads the matching `mise/config.<name>.toml`, which sets
   `CLUSTER_FQDN` / `CLUSTER_NAME` and defines the real `create:<name>` /
   `delete:<name>` task.
3. That task calls `scripts/run-<tool>.sh {create|delete}`.

To add a cluster you generally touch all three: a wrapper task in `mise.toml`, a
new `mise/config.<name>.toml`, and (if a new backend) a `scripts/run-*.sh`.

Aggregate tasks use glob expansion: `create-kind-all` runs
`mise run "create:kind:*"`. Run a single cluster directly with e.g.
`mise run create:kind:kind01-internal`.

`scripts/run-*.sh` **must stay idempotent** (create checks if the cluster exists
first) and require `CLUSTER_FQDN` + `CLUSTERS_KUBECONFIG_DIRECTORY` to be set.
Kubeconfigs are written to `clusters/.kubeconfigs/` (gitignored; dir is created
on demand).

## Known gaps — verify before assuming a feature exists

- `mise/config.k01-k8s-aws-mylabs-dev.toml` calls `scripts/run-eksctl.sh`, which
  **does not exist**. The eksctl path is incomplete; only `run-kind.sh` and
  `run-k3d.sh` are implemented.
- `mise.toml` references
  `cloudformation/allow-mgmt-iam-role-to-assume-tenant-iam-role.yml`, but only
  `cloudformation/route53-gh-action-iam-role-oidc.yml` exists.
- `README.md` mentions `mise run create:aws-tenant:cf-iam-role`; the real task
  is `create:aws-tenant:cf-allow-mgmt-iam-role-to-assume-tenant-iam-role`.

## AWS / CloudFormation

`create:aws-*` tasks `aws cloudformation deploy` directly and require AWS creds
in the env (`AWS_ACCESS_KEY_ID`, etc.); they have interactive `confirm` prompts.
They write outputs back into `mise.local.toml` via `sed` (gitignored —
`mise.local.toml`, `mise.*.local.toml`). User-specific values like
`AWS_USER_ARN` / `AWS_MGMT_IAM_ROLE_ARN` belong in `mise.local.toml`, not
`mise.toml`.

## Linting / CI

- CI uses **MegaLinter** (`.mega-linter.yml`), not standalone linters. Notable:
  Markdown uses `rumdl` (markdownlint disabled), links use `lychee`
  (`lychee.toml`), `markdown-link-check` disabled. `CHANGELOG.md` is excluded
  almost everywhere.
- `mega-linter` extracts shell snippets from changed `*.md` files into a script
  and lints them, so **bash blocks in Markdown must be valid shell**.
- Use the `# jscpd:ignore-start/end` markers (see `scripts/run-*.sh`) to
  suppress copy-paste detection on intentionally duplicated boilerplate.
- Cluster tests (`.github/workflows/run-tests.yml`) only run on non-`main`
  branches and only when `**kind**` / `**k3d**` paths change; they create then
  delete every kind/k3d cluster. Reproduce locally with the Docker command in
  `README.md` ("Tests").

## Releases

`main` is release-automated via `release-please` (`release-type: simple`) — do
not hand-edit version/changelog files. Default branch is `main`; releases and
`renovate`/`release-please--*` branches are skipped by most CI jobs.
