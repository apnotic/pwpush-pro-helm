# Kustomize Examples for Password Pusher Pro

This directory contains example configurations for using Kustomize with the Password Pusher Pro Helm chart.

## Quick Start

### Prerequisites

1. Install Kustomize:
   ```bash
   # macOS
   brew install kustomize

   # Linux
   curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
   ```

2. Pre-create the required secrets (see [ARGOCD.md](../../ARGOCD.md)):
   ```bash
   kubectl create secret generic pwpush-pro-secrets \
     --namespace=pwpush \
     --from-literal=SECRET_KEY_BASE="..." \
     --from-literal=LICENSE_KEY="your-license-key" \
     --from-literal=LICENSE_REGION="your-region"
   ```

3. Update `values.yaml` with:
   - Your license key and region
   - The correct image repository for your edition:
     - Starter: `registry.apnotic.com/pwpush-pro`
     - Advanced: `registry.apnotic.com/pwpush-pro-advanced`
     - Enterprise: `registry.apnotic.com/pwpush-pro-enterprise`

### Method 1: Helm with Post-Renderer (Recommended)

```bash
# Make the renderer executable
chmod +x renderer.sh

# Install with Helm + Kustomize
helm repo add pwpush-pro https://apnotic.github.io/pwpush-pro-helm
helm repo update

helm install pwpush-pro pwpush-pro/pwpush-pro \
  --values values.yaml \
  --post-renderer ./renderer.sh \
  --namespace pwpush \
  --create-namespace
```

### Method 2: Kustomize with Native Helm Support

> **Note:** The example `kustomization.yaml` in this directory uses the post-renderer method (references `helm-output.yaml`).
> To use Method 2, you need a different `kustomization.yaml` with a `helmCharts` section. See the [Kustomize documentation](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/helmcharts/) for details.

```bash
# Example kustomization.yaml for Method 2:
# helmCharts:
#   - name: pwpush-pro
#     repo: https://apnotic.github.io/pwpush-pro-helm
#     version: 0.1.1
#     releaseName: pwpush-pro
#     namespace: pwpush
#     valuesFile: values.yaml
#
# patches:
#   - path: patches/add-labels.yaml

# Build with Kustomize (requires --enable-helm flag)
kustomize build --enable-helm . > rendered.yaml

# Review the output, then apply
kubectl apply -f rendered.yaml --namespace pwpush
```

## Files Overview

| File | Purpose |
|------|---------|
| `renderer.sh` | Post-renderer script for Helm integration |
| `kustomization.yaml` | Main Kustomize configuration |
| `values.yaml` | Helm values for the chart |
| `patches/add-labels.yaml` | Add organizational labels for cost allocation |
| `patches/add-annotations.yaml` | Add annotations for external-dns, monitoring |
| `patches/custom-resource-limits.yaml` | Fine-tune resource allocation |
| `patches/inject-monitoring-sidecar.yaml` | Add monitoring agent sidecars |
| `patches/security-hardening.yaml` | Apply security hardening |
| `resources/network-policy.yaml` | NetworkPolicy for pod-to-pod communication (new resource, not a patch) |

## Customization Guide

### Adding Your Organization's Labels

Edit `patches/add-labels.yaml` and replace the example labels with your organization's:

```yaml
labels:
  cost-center: "your-cost-center"
  department: "your-department"
  environment: "production"
  team: "your-team"
```

Then uncomment the patch in `kustomization.yaml`:

```yaml
patches:
  - path: patches/add-labels.yaml
```

### Enabling Multiple Patches

You can enable multiple patches by uncommenting them in `kustomization.yaml`:

```yaml
patches:
  - path: patches/add-labels.yaml
  - path: patches/custom-resource-limits.yaml
  - path: patches/security-hardening.yaml
```

### Testing Changes Locally

> **Note:** The `kustomize build .` command requires `helm-output.yaml` to exist, which is generated during the Helm post-renderer phase. For local testing, you have two options:
>
> 1. **Use Method 1 (Helm + Post-Renderer):** This is the recommended approach. The `helm-output.yaml` is created automatically during deployment.
> 2. **Generate helm-output.yaml first:** Use `helm template` to generate the file before running Kustomize:
>    ```bash
>    helm template pwpush-pro pwpush-pro/pwpush-pro --values values.yaml > helm-output.yaml
>    kustomize build . | less
>    rm helm-output.yaml  # Clean up
>    ```

Always test your Kustomize build before applying:

```bash
# Build and review (requires helm-output.yaml to exist first)
kustomize build . | less

# Or save to file for detailed review
kustomize build . > output.yaml
```

## Argo CD Integration

For Argo CD, see the [ARGOCD.md](../../ARGOCD.md) guide which covers:
- Using Kustomize with Helm via post-renderer
- Native Kustomize Helm integration
- Configuration Management Plugins

## Advanced Usage

### Creating Environment Overlays

For multiple environments (staging, production), create an overlay structure:

```
overlays/
├── production/
│   ├── kustomization.yaml
│   └── patches/
│       └── production-specific.yaml
└── staging/
    ├── kustomization.yaml
    └── patches/
        └── staging-specific.yaml
```

Example `overlays/production/kustomization.yaml`:

```yaml
resources:
  - ../../base

namespace: pwpush-production

namePrefix: prod-

commonLabels:
  environment: production

patches:
  - path: patches/production-specific.yaml
```

### Using with Private Registries

If using a private registry, add image pull secrets via a patch:

```yaml
# patches/image-pull-secret.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pwpush-pro
spec:
  template:
    spec:
      imagePullSecrets:
        - name: my-registry-secret
```

## Troubleshooting

### "helmCharts is not enabled" error

Kustomize Helm support is disabled by default. Use `--enable-helm` flag:

```bash
kustomize build --enable-helm .
```

### Patches not applying

Ensure the `metadata.name` in your patch matches the resource name exactly:

```bash
# See what resources exist
helm template pwpush-pro pwpush-pro/pwpush-pro | grep -E "^(apiVersion|kind|metadata)"
```

### Kustomize version issues

Check your Kustomize version:

```bash
kustomize version
```

Helm support requires Kustomize v4.1.0 or later.

## References

- [Kustomize Documentation](https://kubectl.docs.kubernetes.io/guides/introduction/kustomize/)
- [Password Pusher Pro Kustomize Guide](../../KUSTOMIZE.md)
- [Password Pusher Pro Argo CD Guide](../../ARGOCD.md)
- [Helm Post-Rendering](https://helm.sh/docs/topics/advanced/#post-rendering)
