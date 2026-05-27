# Kube Minor Workflow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an optional `kubeMinor` workflow input so the containerd autobuild workflow can build only the latest patch release for a selected Kubernetes minor such as `1.34`.

**Architecture:** Keep the existing `part` sharding logic as the default path and layer a narrow override on top. A shared shell helper resolves the version changelog files so both version scripts use the same selection behavior and one regression test can cover the new branch.

**Tech Stack:** GitHub Actions YAML, Bash, lightweight shell regression test

---

### Task 1: Add a failing regression test for version file selection

**Files:**
- Create: `tests/versions/test_resolve_version_files.sh`

- [ ] **Step 1: Write the failing test**

```bash
#!/bin/bash
set -euo pipefail

source .github/scripts/versions/lib.sh

root="$(pwd)"
mapfile -t files < <(resolve_version_files "$root" "6" "1.34")

[[ "${#files[@]}" -eq 1 ]]
[[ "${files[0]##*/}" == "CHANGELOG-1.34.md" ]]
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/versions/test_resolve_version_files.sh`
Expected: FAIL because `.github/scripts/versions/lib.sh` or `resolve_version_files` does not exist yet.

- [ ] **Step 3: Commit**

```bash
git add tests/versions/test_resolve_version_files.sh
git commit -m "test: cover kube minor version selection"
```

### Task 2: Implement shared version-file resolution

**Files:**
- Create: `.github/scripts/versions/lib.sh`

- [ ] **Step 1: Write minimal implementation**

```bash
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
```

- [ ] **Step 2: Run test to verify it passes**

Run: `bash tests/versions/test_resolve_version_files.sh`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add .github/scripts/versions/lib.sh tests/versions/test_resolve_version_files.sh
git commit -m "feat: add kube minor version file resolver"
```

### Task 3: Wire workflow and version scripts to `kubeMinor`

**Files:**
- Modify: `.github/workflows/autobuild-k8s-containerd.yml`
- Modify: `.github/scripts/versions/versions.sh`
- Modify: `.github/scripts/versions/versions_arch.sh`

- [ ] **Step 1: Pass the new input through the workflow**

```yaml
      kubeMinor:
        description: 'specific kubernetes minor version.eg.1.34'
        required: false
```

```yaml
  kubeMinor: ${{ github.event.inputs.kubeMinor }}
```

- [ ] **Step 2: Source the helper and replace the file loop**

```bash
source .github/scripts/versions/lib.sh
while IFS= read -r file; do
done < <(resolve_version_files "$(pwd)" "${part:-}" "${kubeMinor:-}")
```

- [ ] **Step 3: Run the regression test again**

Run: `bash tests/versions/test_resolve_version_files.sh`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/autobuild-k8s-containerd.yml .github/scripts/versions/versions.sh .github/scripts/versions/versions_arch.sh
git commit -m "feat: allow selecting kube minor in autobuild workflow"
```

### Task 4: Trigger the workflow for Kubernetes 1.34

**Files:**
- No file changes

- [ ] **Step 1: Push the branch**

Run: `git push origin main`
Expected: push succeeds

- [ ] **Step 2: Trigger the workflow**

Run: `gh workflow run .github/workflows/autobuild-k8s-containerd.yml --ref main -f kubeMinor=1.34 -f part=6 -f allbuild=false`
Expected: a new workflow run is created on `main`
