#!/bin/bash

set -euo pipefail

source .github/scripts/versions/lib.sh

ROOT="$(pwd)"

files="$(resolve_version_files "$ROOT" "6" "1.34")"
count="$(printf '%s\n' "$files" | wc -l | tr -d ' ')"
first_file="$(printf '%s\n' "$files" | head -n 1)"

[[ "$count" -eq 1 ]]
[[ "${first_file##*/}" == "CHANGELOG-1.34.md" ]]
