#!/bin/bash

set -euo pipefail

workflow_file=".github/workflows/autobuild-k8s-containerd.yml"
manifest_file=".github/scripts/manifest.sh"

grep -q '^      packages: write$' "$workflow_file"
grep -q '^      contents: read$' "$workflow_file"
grep -Fq 'sudo buildah manifest push --all "$manifest_name" "docker://$IMAGE_NAME"' "$manifest_file"
grep -Fq 'docker_image_name="docker.io/labring/${IMAGE_NAME##*/}"' "$manifest_file"
grep -Fq 'readonly DOCKER_REGISTRY_TOKEN="${1:-}"' "$manifest_file"
