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

# Read Helm output from stdin and save to temporary file
cat - > helm-output.yaml

# Run Kustomize build on the current directory (which contains kustomization.yaml)
# The helm-output.yaml is referenced as a resource in kustomization.yaml
kustomize build .

# Clean up the temporary file
rm -f helm-output.yaml
