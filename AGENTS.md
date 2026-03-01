# AI Agent Guidelines

Guidelines for AI agents working on this IaC repository
(`ruzickap/k8s-multicluster-gitops`). The project manages multiple
Kubernetes clusters (Kind, K3d, EKS) across cloud providers using
GitOps with ArgoCD. The task runner is **mise**.

## Build, Lint, and Test Commands

### Task Runner (mise)

```bash
mise tasks                                    # List all tasks
mise run create:kind:kind01-internal          # Create single cluster
mise run delete:kind:kind01-internal          # Delete single cluster
mise run create-kind-all                      # Create all Kind clusters
mise run create-k3d-all                       # Create all K3d clusters
mise run "create-kind-all" ::: "create-k3d-all"  # Parallel
```

### Testing

No unit test frameworks. Tests are integration tests that create
and delete clusters. Single cluster test:

```bash
mise run create:kind:kind01-internal
mise run delete:kind:kind01-internal
```

Full test in Docker (matches CI):

```bash
docker run --rm -it -v "$PWD:/mnt" \
  -v "/var/run/docker.sock:/var/run/docker.sock" \
  --workdir /mnt bash bash -c \
  'apk add docker && wget -q https://mise.run -O - | sh && \
   eval "$(~/.local/bin/mise activate bash)" && \
   mise run "create-kind-all" && mise run "delete-kind-all"'
```

### Linting (CI runs MegaLinter cupcake flavor)

```bash
rumdl <file.md>                               # Markdown
shellcheck scripts/*.sh                       # Shell lint
shfmt --case-indent --indent 2 --space-redirects -d scripts/*.sh
lychee --config lychee.toml .                 # Link check
actionlint                                    # GH Actions
jsonlint --comments <file.json>               # JSON
```

## Shell Script Style

All scripts live in `scripts/` and follow these conventions:

- **Shebang**: `#!/usr/bin/env bash`
- **Indentation**: 2 spaces (no tabs)
- **Variables**: UPPERCASE with braces (`${CLUSTER_FQDN}`)
- **Required vars**: Validate with `${VAR:?Error: message}`
- **Error handling**: Use `set -euo pipefail` (or `set -eux`)
- **Structure**: `create()`, `delete()`, `usage()` functions
  with a `case` statement for command dispatch
- **Idempotency**: Check if resource exists before creating
- **Formatting**: Must pass `shfmt --case-indent --indent 2
  --space-redirects`
- **Linting**: Must pass `shellcheck` (SC2317 excluded)
- **Quoting**: Always quote variable expansions

## Markdown Style

- Must pass `rumdl` checks (config: `.rumdl.toml`)
- Wrap lines at 72 characters
- Use proper heading hierarchy (no skipped levels)
- Include language identifiers in code fences
- Shell code blocks are extracted and validated by CI
  (`shellcheck` + `shfmt`)
- Prefer code fences over inline code for multi-line examples

## YAML and TOML Conventions

- **Sorted blocks**: Use `# keep-sorted start` / `# keep-sorted end`
  comment directives to maintain alphabetical ordering
- **CloudFormation**: Standard AWS template structure with
  Parameters, Resources, Outputs
- **mise configs**: Per-cluster configs in `mise/` directory;
  cluster-specific env vars (`CLUSTER_FQDN`, `CLUSTER_NAME`)

## JSON Files

- Must pass `jsonlint --comments` validation
- Comments are permitted (JSON5 style in Renovate config)

## GitHub Actions Workflows

- **Pin actions to full SHA** (never use tags)
- **Permissions**: Always set `permissions: read-all` at top level
- **Timeout**: Always set `timeout-minutes` on jobs
- **Validate**: Run `actionlint` after modifying any workflow
- **Skip branches**: CI skips `chore/renovate/` and
  `release-please--` branches

## Security Scanning (CI)

- **Checkov**: IaC scanner (skip `CKV_GHA_7`)
- **DevSkim**: Pattern scanner (ignore DS162092, DS137138)
- **KICS**: Fails on HIGH severity only
- **Trivy**: Fails on HIGH/CRITICAL, ignores unfixed
- **CodeQL**: GitHub Actions analysis
- **OSSF Scorecard**: Supply chain security

## Version Control

### Commit Messages

Format: `<type>: <description>` (conventional commits)

- Types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`,
  `style`, `perf`, `ci`, `build`, `revert`
- Subject: imperative mood, lowercase, no period, max 72 chars
- Body: wrap at 72 chars, explain what and why
- Reference issues: `Fixes #123`, `Closes #456`

```text
feat: add automated dependency updates

- Implement Dependabot configuration
- Configure weekly security updates

Resolves: #123
```

### Branching

Conventional branch format: `<type>/<description>`

- `feature/` or `feat/`: new features
- `bugfix/` or `fix/`: bug fixes
- `hotfix/`: urgent fixes
- `release/`: releases (e.g., `release/v1.2.0`)
- `chore/`: non-code tasks

Use lowercase, hyphens, and optional issue numbers
(`feature/issue-123-add-login-page`).

### Pull Requests

- Always create as **draft** initially
- Title must follow conventional commit format
- Include clear description and link related issues

## Quality Checklist

- Pass all pre-commit hooks and CI checks
- Two spaces for indentation everywhere (no tabs)
- Atomic, focused commits with clear reasoning
- Update documentation for user-facing changes
- Consistent formatting across all file types
- No secrets or credentials in committed files
