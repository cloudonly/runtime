#!/bin/bash

set -euo pipefail

resolve_version_files() {
  local root=${1?}
  local part=${2-}
  local kube_minor=${3-}

  if [[ -n "$kube_minor" ]]; then
    find "$root/.github/versions" -maxdepth 2 -type f -name "CHANGELOG-$kube_minor.md" | sort
    return
  fi

  find "$root/.github/versions/${part:-*}" -maxdepth 1 -type f -name 'CHANGELOG*' | sort
}

emit_kube_versions() {
  local cached_file=${1?}
  local kube_minor=${2-}

  if [[ -n "$kube_minor" ]]; then
    head -n 1 "$cached_file"
    return
  fi

  cat "$cached_file"
}
