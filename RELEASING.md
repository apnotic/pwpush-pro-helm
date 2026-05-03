# Releasing New Chart Versions

This document explains how to release new versions of the Password Pusher Pro Helm chart.

## How Releases Work

Releases are fully automated via GitHub Actions:

1. **[CI workflow](.github/workflows/ci.yml)** runs on every push and PR -- lints and template-renders all three tiers (Starter, Advanced, Enterprise)
2. **[Release workflow](.github/workflows/release.yml)** runs on push to `main` -- detects version changes in `Chart.yaml`, packages the chart, creates a GitHub Release, and updates `index.yaml` on the `gh-pages` branch

Customers consume the chart via:

```bash
helm repo add pwpush-pro https://apnotic.github.io/pwpush-pro-helm
```

## Release Process

### 1. Bump the chart version

Edit `charts/pwpush-pro/Chart.yaml` and bump the `version` field following [Semantic Versioning](https://semver.org/):

| Bump | When | Example |
|------|------|---------|
| **Patch** | Bug fixes, doc updates, dependency bumps | 0.1.0 -> 0.1.1 |
| **Minor** | New features, new values, non-breaking changes | 0.1.0 -> 0.2.0 |
| **Major** | Breaking changes to values schema or behavior | 0.1.0 -> 1.0.0 |

If the release corresponds to a specific container image tag, also update `appVersion`.

### 2. Update dependencies (if needed)

Only required when changing the Bitnami PostgreSQL subchart version in `Chart.yaml`:

```bash
helm dependency update charts/pwpush-pro
```

### 3. Commit and push

```bash
git add -A
git commit -m "Release chart version X.Y.Z"
git push
```

CI will automatically lint and template-render all three tiers. If CI fails, fix the issue and push again -- the release workflow only runs after CI passes.

### 4. Verify

- Check [GitHub Actions](https://github.com/apnotic/pwpush-pro-helm/actions) for green CI and Release runs
- Confirm the new [GitHub Release](https://github.com/apnotic/pwpush-pro-helm/releases) was created
- Optionally verify from the customer side:

```bash
helm repo update
helm search repo pwpush-pro
```

## Updating the Container Image Tag

When a new Password Pusher Pro container image is published to `registry.apnotic.com`:

1. Update `appVersion` in `Chart.yaml` to match the new image tag
2. Bump the chart `version` (at minimum a patch bump)
3. Commit and push

## Rollback

- Previous chart versions remain available in the Helm repo
- Customers can pin to a specific version: `helm install ... --version 0.1.0`
- To remove a broken release, delete the GitHub Release and re-run the workflow

## Notes

- The `gh-pages` branch is managed automatically by chart-releaser. Do not edit it manually.
- Chart releases are immutable. To fix a released version, bump the version number and release again.
- The `skip_existing: true` flag in the release workflow prevents failures when re-pushing the same version.
