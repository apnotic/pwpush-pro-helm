# pwpush-pro

Password Pusher Pro Helm chart for Kubernetes.

See the [repository README](../../README.md) for full documentation, quick start guides, and configuration reference.

## Installing the Chart

```bash
helm install my-push pwpush-pro/pwpush-pro --set license.key=YOUR_KEY --set imagePullSecrets[0].name=regcred
```

## Values Files

- `values.yaml` -- Starter Edition defaults
- `values-advanced.yaml` -- Advanced Edition overrides
- `values-enterprise.yaml` -- Enterprise Edition overrides (PostgreSQL, HA)
