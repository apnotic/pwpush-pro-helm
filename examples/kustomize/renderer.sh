#!/bin/bash
# Helm Post-Renderer Script for Kustomize
#
# This script is used as a Helm post-renderer to allow Kustomize to patch
# Helm-generated manifests. It captures Helm's output and runs Kustomize build.
#
# Usage with Helm:
#   helm install pwpush-pro pwpush-pro/pwpush-pro \
#     --values values.yaml \
#     --post-renderer ./renderer.sh
#
# Usage with Argo CD:
#   Configure as a ConfigManagementPlugin (see KUSTOMIZE.md)

set -e

KUSTOMIZATION_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$KUSTOMIZATION_DIR"

# Create a unique temp file in the current directory to avoid race conditions
HELM_OUTPUT=$(mktemp ./helm-output.XXXXXX.yaml)
HELM_OUTPUT_NAME=$(basename "$HELM_OUTPUT")

# Cleanup function to remove temp file and restore original kustomization.yaml
cleanup() {
    rm -f "$HELM_OUTPUT"
    # Restore original kustomization.yaml if backup exists
    if [ -f kustomization.yaml.bak ]; then
        mv kustomization.yaml.bak kustomization.yaml
    fi
}
trap cleanup EXIT

# Read Helm output from stdin and save to the unique temp file
cat - > "$HELM_OUTPUT"

# Temporarily modify kustomization.yaml to use the unique filename
sed -i.bak "s/helm-output.yaml/$HELM_OUTPUT_NAME/" kustomization.yaml

# Run Kustomize build
kustomize build .
