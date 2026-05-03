# Releasing New Chart Versions

This document explains how to release new versions of the Password Pusher Pro Helm chart.

## How Releases Work

Releases are automated via the [chart-releaser GitHub Action](.github/workflows/release.yml). When changes are pushed to `main`, the workflow:

1. Detects charts with version changes in `Chart.yaml`
2. Packages the chart into a `.tgz` archive
3. Creates a GitHub Release with the packaged chart
4. Updates the `index.yaml` on the `gh-pages` branch

Customers consume the chart via:

```bash
helm repo add pwpush-pro https://apnotic.github.io/pwpush-pro-helm
```

## Release Process

### 1. Update the chart version

Edit `charts/pwpush-pro/Chart.yaml` and bump the `version` field following [Semantic Versioning](https://semver.org/):

- **Patch** (0.1.0 -> 0.1.1): Bug fixes, documentation updates, dependency bumps
- **Minor** (0.1.0 -> 0.2.0): New features, new values, non-breaking template changes
- **Major** (0.1.0 -> 1.0.0): Breaking changes to values schema or template behavior

```yaml
version: 0.2.0      # Chart version (bump this)
appVersion: "latest" # Update if tied to a specific app release
```

### 2. Update appVersion (if applicable)

If the release corresponds to a specific Password Pusher Pro container image tag, update `appVersion`:

```yaml
appVersion: "2.5.0"
```

### 3. Update dependencies (if needed)

If the Bitnami PostgreSQL subchart version changed:

```bash
helm dependency update charts/pwpush-pro
```

This updates `Chart.lock` and downloads the new subchart `.tgz`.

### 4. Validate locally

```bash
make lint      # Lint all three tiers
make template  # Dry-run template rendering for all tiers
```

### 5. Commit and push

```bash
git add -A
git commit -m "Release chart version 0.2.0"
git push
```

### 6. Verify the release

- Check [GitHub Actions](https://github.com/apnotic/pwpush-pro-helm/actions) for a successful "Release Charts" run
- Verify the new [GitHub Release](https://github.com/apnotic/pwpush-pro-helm/releases) was created
- Confirm customers can pull the new version:

```bash
helm repo update
helm search repo pwpush-pro
```

## Updating the Container Image Tag

When a new Password Pusher Pro container image is published to `registry.apnotic.com`:

1. Update `appVersion` in `Chart.yaml` to match the new image tag
2. Bump the chart `version` (at minimum a patch bump)
3. Follow the release process above

## Rollback

If a release has issues:

- The previous chart version remains available in the Helm repo
- Customers can pin to a specific version: `helm install ... --version 0.1.0`
- To remove a broken release, delete the GitHub Release and re-run the workflow

## Notes

- The `gh-pages` branch is managed automatically by chart-releaser. Do not edit it manually.
- Chart releases are immutable. To fix a released version, bump the version number and release again.
- The `skip_existing: true` flag in the release workflow prevents failures when re-pushing the same version.
