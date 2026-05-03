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

# Create unique temp files to avoid race conditions
HELM_OUTPUT=$(mktemp ./helm-output.XXXXXX.yaml)
HELM_OUTPUT_NAME=$(basename "$HELM_OUTPUT")
KUSTOMIZATION_BAK=$(mktemp ./kustomization.yaml.XXXXXX.bak)
KUSTOMIZATION_BAK_NAME=$(basename "$KUSTOMIZATION_BAK")

# Cleanup function to remove temp files and restore original kustomization.yaml
cleanup() {
    rm -f "$HELM_OUTPUT"
    rm -f "$KUSTOMIZATION_BAK"
    # Restore original kustomization.yaml if our specific backup exists
    if [ -f "$KUSTOMIZATION_BAK_NAME" ] && [ -f kustomization.yaml ]; then
        mv "$KUSTOMIZATION_BAK_NAME" kustomization.yaml
    fi
}
trap cleanup EXIT

# Read Helm output from stdin and save to the unique temp file
cat - > "$HELM_OUTPUT"

# Temporarily modify kustomization.yaml to use the unique filename
# Use a unique backup file to avoid race conditions with concurrent runs
cp kustomization.yaml "$KUSTOMIZATION_BAK"
sed -i "s/helm-output.yaml/$HELM_OUTPUT_NAME/" kustomization.yaml

# Run Kustomize build
kustomize build .
