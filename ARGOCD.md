# Deploying Password Pusher Pro with Argo CD

This guide explains how to deploy Password Pusher Pro using Argo CD, a declarative GitOps continuous delivery tool for Kubernetes.

## Overview

Argo CD automates the deployment of Kubernetes applications by continuously monitoring Git repositories and syncing the cluster state with the desired state defined in Git. This guide covers the specific considerations for deploying Password Pusher Pro via Argo CD.

## Prerequisites

- A running Argo CD instance with access to your target cluster
- A valid Password Pusher Pro license with registry access
- Kubernetes cluster (1.24+) with appropriate storage classes

## Important: The Helm `lookup` Function

The Password Pusher Pro Helm chart uses the `lookup` function to preserve encryption keys across upgrades. This function queries the live cluster during template rendering to check if secrets already exist.

**Why this matters:** Argo CD runs `helm template` by default without a live cluster connection, so the `lookup` function returns empty. Without proper handling, Argo CD would regenerate random encryption keys on every sync, invalidating all user sessions and making previously encrypted data permanently inaccessible.

## Deployment Options

Choose one of the following approaches based on your organization's GitOps practices:

### Option 1: Pre-create Secrets (Recommended)

This is the most reliable approach for production deployments. You create the secrets once outside of Argo CD, then reference them in your Application manifest.

#### Step 1: Generate and Create Secrets

```bash
# Generate encryption keys (run once and store securely)
export SECRET_KEY_BASE=$(openssl rand -hex 64)$(openssl rand -hex 64)
export PWPUSH_MASTER_KEY=$(openssl rand -hex 32)
export PWPUSH_PRIMARY_KEY=$(openssl rand -hex 16)
export PWPUSH_DETERMINISTIC_KEY=$(openssl rand -hex 16)
export PWPUSH_KEY_DERIVATION_SALT=$(openssl rand -hex 16)

# Create the secret in your target namespace
kubectl create secret generic pwpush-pro-secrets \
  --namespace=pwpush \
  --from-literal=SECRET_KEY_BASE="$SECRET_KEY_BASE" \
  --from-literal=PWPUSH_MASTER_KEY="$PWPUSH_MASTER_KEY" \
  --from-literal=PWPUSH_PRIMARY_KEY="$PWPUSH_PRIMARY_KEY" \
  --from-literal=PWPUSH_DETERMINISTIC_KEY="$PWPUSH_DETERMINISTIC_KEY" \
  --from-literal=PWPUSH_KEY_DERIVATION_SALT="$PWPUSH_KEY_DERIVATION_SALT" \
  --from-literal=LICENSE_KEY="your-license-key" \
  --from-literal=LICENSE_REGION="your-region"

# CRITICAL: Back up this secret securely
kubectl get secret pwpush-pro-secrets -n pwpush -o yaml > pwpush-secrets-backup.yaml
```

**Store `pwpush-secrets-backup.yaml` in your enterprise secret management system. Losing these keys means permanent data loss.**

#### Step 2: Create Argo CD Application

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: pwpush-pro
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    chart: pwpush-pro
    repoURL: https://apnotic.github.io/pwpush-pro-helm
    targetRevision: 0.1.1  # Pin to specific version
    helm:
      valueFiles:
        - values.yaml  # Base configuration
      values: |
        secrets:
          existingSecretName: pwpush-pro-secrets
        license:
          key: "your-license-key"
          region: "your-region"
        ingress:
          enabled: true
          className: nginx
          hosts:
            - host: pwpush.example.com
              paths:
                - path: /
                  pathType: Prefix
          tls:
            - secretName: pwpush-tls
              hosts:
                - pwpush.example.com
  destination:
    server: https://kubernetes.default.svc
    namespace: pwpush
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### Option 2: Enable Server-Side Dry Run

For Argo CD 2.10+, you can enable server-side dry run to support the `lookup` function:

```yaml
spec:
  source:
    helm:
      serverDryRun: true  # Enables lookup function support
```

**Requirements:**
- Argo CD 2.10 or later
- Argo CD controller must have RBAC permissions to read Secrets in the target namespace

### Option 3: External Secrets Operator

For GitOps-native secret management, integrate with External Secrets Operator:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: pwpush-pro-secrets
  namespace: pwpush
spec:
  refreshInterval: 1h
  secretStoreRef:
    kind: ClusterSecretStore
    name: vault-backend
  target:
    name: pwpush-pro-secrets
    creationPolicy: Owner
  data:
    - secretKey: SECRET_KEY_BASE
      remoteRef:
        key: pwpush/production
        property: secret_key_base
    - secretKey: PWPUSH_MASTER_KEY
      remoteRef:
        key: pwpush/production
        property: master_key
    - secretKey: PWPUSH_PRIMARY_KEY
      remoteRef:
        key: pwpush/production
        property: primary_key
    - secretKey: PWPUSH_DETERMINISTIC_KEY
      remoteRef:
        key: pwpush/production
        property: deterministic_key
    - secretKey: PWPUSH_KEY_DERIVATION_SALT
      remoteRef:
        key: pwpush/production
        property: key_derivation_salt
    - secretKey: LICENSE_KEY
      remoteRef:
        key: pwpush/production
        property: license_key
    - secretKey: LICENSE_REGION
      remoteRef:
        key: pwpush/production
        property: license_region
```

## Edition-Specific Examples

### Starter Edition

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: pwpush-pro-starter
  namespace: argocd
spec:
  project: default
  source:
    chart: pwpush-pro
    repoURL: https://apnotic.github.io/pwpush-pro-helm
    targetRevision: 0.1.1
    helm:
      values: |
        edition: starter
        secrets:
          existingSecretName: pwpush-pro-secrets
        license:
          key: "your-license-key"
          region: "your-region"
        storage:
          size: 10Gi
  destination:
    server: https://kubernetes.default.svc
    namespace: pwpush
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### Advanced Edition

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: pwpush-pro-advanced
  namespace: argocd
spec:
  project: default
  source:
    chart: pwpush-pro
    repoURL: https://apnotic.github.io/pwpush-pro-helm
    targetRevision: 0.1.1
    helm:
      valueFiles:
        - values-advanced.yaml
      values: |
        secrets:
          existingSecretName: pwpush-pro-secrets
        license:
          key: "your-license-key"
          region: "your-region"
        extraSecretEnv:
          AWS_ACCESS_KEY_ID: "your-aws-key"
        extraEnv:
          AWS_REGION: "us-east-1"
          AWS_BUCKET_NAME: "pwpush-uploads"
  destination:
    server: https://kubernetes.default.svc
    namespace: pwpush
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### Enterprise Edition with HA

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: pwpush-pro-enterprise
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    chart: pwpush-pro
    repoURL: https://apnotic.github.io/pwpush-pro-helm
    targetRevision: 0.1.1
    helm:
      valueFiles:
        - values-enterprise.yaml
      values: |
        secrets:
          existingSecretName: pwpush-pro-secrets
        license:
          key: "your-license-key"
          region: "your-region"
        database:
          type: postgresql
          host: "postgres.example.com"
          name: pwpush_pro
          user: pwpush
        postgresql:
          enabled: false  # Using external PostgreSQL
        autoscaling:
          enabled: true
          minReplicas: 3
          maxReplicas: 10
          targetCPUUtilizationPercentage: 70
        ingress:
          enabled: true
          className: nginx
          annotations:
            cert-manager.io/cluster-issuer: letsencrypt-prod
          hosts:
            - host: pwpush.example.com
              paths:
                - path: /
                  pathType: Prefix
          tls:
            - secretName: pwpush-tls
              hosts:
                - pwpush.example.com
  destination:
    server: https://kubernetes.default.svc
    namespace: pwpush
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

## Using ApplicationSet for Multiple Environments

For managing multiple environments with Argo CD:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: pwpush-pro
  namespace: argocd
spec:
  generators:
    - list:
        elements:
          - cluster: staging
            url: https://staging-cluster.example.com
            valuesFile: values-staging.yaml
            namespace: pwpush-staging
          - cluster: production
            url: https://production-cluster.example.com
            valuesFile: values-production.yaml
            namespace: pwpush-prod
  template:
    metadata:
      name: 'pwpush-pro-{{cluster}}'
    spec:
      project: default
      source:
        chart: pwpush-pro
        repoURL: https://apnotic.github.io/pwpush-pro-helm
        targetRevision: 0.1.1
        helm:
          valueFiles:
            - '{{valuesFile}}'
          values: |
            secrets:
              existingSecretName: pwpush-pro-secrets-{{cluster}}
      destination:
        server: '{{url}}'
        namespace: '{{namespace}}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
```

## Best Practices

1. **Pin Chart Versions**: Always use specific chart versions (`targetRevision: 0.1.1`) instead of `latest` for reproducible deployments

2. **Separate Config from Source**: Keep environment-specific values files in a separate GitOps configuration repository

3. **Never Commit Secrets**: Use External Secrets Operator, Vault, or pre-created Kubernetes Secrets. Never commit secrets to Git

4. **Backup Encryption Keys**: Immediately after first deployment, back up your encryption secrets. Store them in your enterprise secret management system

5. **Use Sync Waves**: If deploying with bundled PostgreSQL, add sync wave annotations to ensure proper ordering:
   ```yaml
   metadata:
     annotations:
       argocd.argoproj.io/sync-wave: "1"
   ```

6. **Enable Auto-Sync with Caution**: The encryption keys secret should use `helm.sh/resource-policy: keep` (which the chart already does), preventing accidental deletion during `helm uninstall`

## Troubleshooting

### Issue: Secrets are regenerated on every sync

**Cause**: Argo CD doesn't support the `lookup` function by default.

**Solution**: Use `existingSecretName` to reference pre-created secrets (Option 1 above).

### Issue: Image pull errors

**Cause**: Missing or invalid image pull secret for the private registry.

**Solution**: Create the pull secret:
```bash
kubectl create secret docker-registry regcred \
  --docker-server=registry.apnotic.com \
  --docker-username=YOUR_USERNAME \
  --docker-password=YOUR_PASSWORD \
  --namespace=pwpush
```

Then reference it in values:
```yaml
imagePullSecrets:
  - name: regcred
```

### Issue: Database connection failures

**Cause**: Using SQLite with multiple replicas or incorrect PostgreSQL credentials.

**Solution**: For multi-replica deployments, use PostgreSQL (Enterprise edition) with proper external database configuration.

## Additional Resources

- [Argo CD Documentation](https://argo-cd.readthedocs.io/)
- [Argo CD Helm Guide](https://argo-cd.readthedocs.io/en/latest/user-guide/helm/)
- [Password Pusher Pro Documentation](https://docs.pwpush.com)
- [Helm Chart README](./README.md)
