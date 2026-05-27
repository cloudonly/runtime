#!/bin/bash

set -euo pipefail

workflow_file=".github/workflows/autobuild-k8s-containerd.yml"

grep -q '^permissions:$' "$workflow_file"
grep -q '^  contents: read$' "$workflow_file"
grep -q '^  packages: write$' "$workflow_file"
grep -q '^      contents: read$' "$workflow_file"
grep -q '^      packages: write$' "$workflow_file"
grep -Fq 'password: ${{ secrets.GHCR_TOKEN || secrets.GITHUB_TOKEN }}' "$workflow_file"
