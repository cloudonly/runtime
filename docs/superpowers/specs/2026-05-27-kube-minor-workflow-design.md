# Kube Minor Workflow Filter Design

## Goal
Allow `.github/workflows/autobuild-k8s-containerd.yml` to build a specific Kubernetes minor version such as `1.34`, instead of only relying on the existing `part` shard input.

## Design
- Add an optional workflow input `kubeMinor`.
- Pass `kubeMinor` through workflow env into the existing version resolution scripts.
- Introduce a shared helper in `.github/scripts/versions/lib.sh` that resolves the set of `CHANGELOG-*.md` files to scan.
- When `kubeMinor` is set, resolve exactly one matching changelog file from `.github/versions/*/CHANGELOG-<kubeMinor>.md`.
- When `kubeMinor` is empty, preserve the current `part`-based behavior unchanged.

## Constraints
- Keep current manual `part` usage working.
- Limit the change to the containerd workflow requested by the user.
- Add a lightweight shell regression test for the version-file selection helper.

## Verification
- Run the regression test for version-file selection.
- Run the workflow version scripts locally enough to verify they accept `kubeMinor`.
- After commit/push, trigger the workflow with `gh workflow run` using `kubeMinor=1.34`.
