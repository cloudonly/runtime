#!/bin/bash

set -euo pipefail

source .github/scripts/versions/lib.sh

tmp_file="$(mktemp)"
trap 'rm -f "$tmp_file"' EXIT

cat >"$tmp_file" <<'EOF'
v1.34.8
v1.34.0
EOF

latest_only="$(emit_kube_versions "$tmp_file" "1.34")"
all_versions="$(emit_kube_versions "$tmp_file" "")"

[[ "$latest_only" == "v1.34.8" ]]
[[ "$all_versions" == $'v1.34.8\nv1.34.0' ]]
