# Password Pusher Pro - Helm Charts

Official Helm charts for deploying [Password Pusher Pro](https://pwpush.com) on Kubernetes.

## Prerequisites

- Kubernetes 1.24+
- Helm 3.x
- Access to `registry.apnotic.com` (requires a Password Pusher Pro license)

## Quick Start

### 1. Add the Helm Repository

```bash
helm repo add pwpush-pro https://apnotic.github.io/pwpush-pro-helm
helm repo update
```

### 2. Create Image Pull Secret

Password Pusher Pro images are hosted on a private registry. Create a pull secret in your namespace:

```bash
kubectl create secret docker-registry regcred \
  --docker-server=registry.apnotic.com \
  --docker-username=YOUR_USERNAME \
  --docker-password=YOUR_PASSWORD
```

### 3. Install

**Starter Edition:**

```bash
helm install my-push pwpush-pro/pwpush-pro \
  --set license.key=YOUR_LICENSE_KEY \
  --set imagePullSecrets[0].name=regcred
```

**Advanced Edition:**

```bash
helm install my-push pwpush-pro/pwpush-pro \
  -f charts/pwpush-pro/values-advanced.yaml \
  --set license.key=YOUR_LICENSE_KEY \
  --set imagePullSecrets[0].name=regcred
```

**Enterprise Edition:**

```bash
helm install my-push pwpush-pro/pwpush-pro \
  -f charts/pwpush-pro/values-enterprise.yaml \
  --set license.key=YOUR_LICENSE_KEY \
  --set imagePullSecrets[0].name=regcred
```

## Editions

| Feature | Starter | Advanced | Enterprise |
|---------|---------|----------|------------|
| Database | SQLite | SQLite | PostgreSQL |
| SSO | - | Google, Microsoft | Google, Microsoft, Okta, Auth0, NetScaler |
| Storage | Disk | Disk, S3, GCS, Azure | Disk, S3, GCS, Azure, MinIO, R2, and more |
| Scaling | Single replica | Single replica | Multi-replica with HPA |

## Configuration

### Common Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `license.key` | Password Pusher Pro license key (required) | `""` |
| `license.region` | License region | `""` |
| `image.repository` | Container image repository | `registry.apnotic.com/pwpush-pro` |
| `image.tag` | Container image tag | `latest` |
| `imagePullSecrets` | Image pull secrets for private registry | `[]` |
| `replicaCount` | Number of pod replicas | `1` |
| `resources` | CPU/memory resource requests and limits | `{}` |

### Storage

| Parameter | Description | Default |
|-----------|-------------|---------|
| `storage.size` | Persistent volume size | `5Gi` |
| `storage.storageClassName` | Storage class name | `""` |
| `storage.accessModes` | PVC access modes | `[ReadWriteOnce]` |

### Ingress

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable Ingress | `false` |
| `ingress.className` | Ingress class name | `""` |
| `ingress.annotations` | Ingress annotations | `{}` |
| `ingress.hosts` | Ingress host rules | `[]` |
| `ingress.tls` | Ingress TLS configuration | `[]` |

### Database (Enterprise)

| Parameter | Description | Default |
|-----------|-------------|---------|
| `database.type` | Database type (`sqlite` or `postgresql`) | `sqlite` |
| `database.host` | External PostgreSQL host | `""` |
| `database.port` | PostgreSQL port | `5432` |
| `database.name` | Database name | `pwpush-pro` |
| `database.user` | Database user | `pwpush-pro` |
| `database.password` | Database password (auto-generated if empty) | `""` |
| `postgresql.enabled` | Deploy bundled PostgreSQL subchart | `false` |

### Secrets

| Parameter | Description | Default |
|-----------|-------------|---------|
| `secrets.autoGenerate` | Auto-generate encryption keys on first install | `true` |
| `secrets.existingSecretName` | Use an existing Kubernetes Secret | `""` |

### Autoscaling

| Parameter | Description | Default |
|-----------|-------------|---------|
| `autoscaling.enabled` | Enable Horizontal Pod Autoscaler | `false` |
| `autoscaling.minReplicas` | Minimum replicas | `1` |
| `autoscaling.maxReplicas` | Maximum replicas | `5` |
| `autoscaling.targetCPUUtilizationPercentage` | Target CPU utilization | `70` |

### Extra Environment Variables

| Parameter | Description | Default |
|-----------|-------------|---------|
| `extraEnv` | Additional environment variables (key-value map) | `{}` |

## TLS / HTTPS

TLS is handled by the Kubernetes Ingress controller, not the application container. When Ingress TLS is configured, the Ingress terminates HTTPS and forwards requests to the app over HTTP on port 80. Rails detects the original protocol via `X-Forwarded-Proto` headers from the Ingress.

For most deployments, configure TLS via Ingress with cert-manager:

```yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: push.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: push-tls
      hosts:
        - push.example.com
```

## Backup & Recovery

### Encryption Secrets

After installation, immediately back up your encryption secrets:

```bash
kubectl get secret <release-name>-pwpush-pro -n <namespace> -o yaml > pwpush-pro-secrets-backup.yaml
```

**Store this file securely.** If you lose these keys, all encrypted data becomes permanently inaccessible.

Secrets are annotated with `helm.sh/resource-policy: keep` -- they are preserved across `helm upgrade` and are not deleted by `helm uninstall`.

### Database

- **Starter/Advanced (SQLite):** The SQLite database files are stored on the PVC mounted at `/opt/PasswordPusher/storage`. Back up the PVC contents regularly.
- **Enterprise (PostgreSQL):** Use standard PostgreSQL backup tools (`pg_dump`) or your cloud provider's managed backup features.

## Upgrading

```bash
helm repo update
helm upgrade my-push pwpush-pro/pwpush-pro
```

Encryption keys and database data are preserved automatically across upgrades.

## Uninstalling

```bash
helm uninstall my-push
```

The Secret and PVC are retained (via `helm.sh/resource-policy: keep`). To fully remove:

```bash
kubectl delete secret <release-name>-pwpush-pro
kubectl delete pvc <release-name>-pwpush-pro-storage
```

## Examples

See the [examples/](examples/) directory for ready-to-use values files:

- `starter-minimal.yaml` -- Starter with Ingress
- `advanced-external-storage.yaml` -- Advanced with S3 storage
- `enterprise-ha.yaml` -- Enterprise HA with bundled PostgreSQL
- `enterprise-external-db.yaml` -- Enterprise with external PostgreSQL (RDS, Cloud SQL, etc.)

## Support

- Documentation: https://docs.pwpush.com
- Support: https://docs.pwpush.com/docs/support/
- FAQ: https://docs.pwpush.com/docs/faq/
