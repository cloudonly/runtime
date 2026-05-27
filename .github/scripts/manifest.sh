#!/bin/bash

set -eu

readonly ERR_CODE=127

readonly CRI_TYPE=${criType?}
readonly KUBE_TYPE=${kubeType:-k8s}

readonly IMAGE_HUB_REGISTRY=${registry?}
readonly IMAGE_HUB_REPO=${repo?}
readonly IMAGE_HUB_USERNAME=${username?}
readonly IMAGE_HUB_PASSWORD=${password?}

readonly IMAGE_TAG=${version?}
readonly KUBE_RAW="${IMAGE_TAG%%-*}"
readonly KUBE="${KUBE_RAW#v}"
readonly KUBE_XY="${KUBE%.*}"
if [[ "${sealoslatest:-}" == latest ]]; then
  export sealosPatch="ghcr.io/labring/sealos-patch:latest"
  sealoslatest=$(until curl -sL "https://api.github.com/repos/labring/sealos/releases/latest" | grep tarball_url; do sleep 3; done | awk -F\" '{print $(NF-1)}' | awk -F/ '{print $NF}' | cut -dv -f2)
fi
readonly sealoslatest="${sealoslatest:-${IMAGE_TAG#*-}}"
readonly SEALOS=${sealoslatest?}
readonly SEALOS_PATCH="${sealosPatch:-}"
case $CRI_TYPE in
containerd)
  IMAGE_KUBE=kubernetes
  ;;
cri-o)
  IMAGE_KUBE=kubernetes-crio
  ;;
docker)
  IMAGE_KUBE=kubernetes-docker
  ;;
esac
if grep k3s <<<"$KUBE"; then
  IMAGE_KUBE=k3s
fi

if ! [[ "$SEALOS" =~ ^[0-9\.]+[0-9]$ ]] || [[ -n "$SEALOS_PATCH" ]]; then
  IMAGE_TAGS="v${KUBE%.*}-amd64,v${KUBE%.*}-arm64"
  IMAGE_PUSH_NAME=(
    "$IMAGE_HUB_REGISTRY/$IMAGE_HUB_REPO/$IMAGE_KUBE:v${KUBE%.*}-latest"
  )
else
  IMAGE_TAGS="v${KUBE%+*}-$SEALOS-amd64,v${KUBE%+*}-$SEALOS-arm64"
  if [[ "$SEALOS" == "$(
    until curl -sL "https://api.github.com/repos/labring/sealos/releases/latest"; do sleep 3; done | grep tarball_url | awk -F\" '{print $(NF-1)}' | awk -F/ '{print $NF}' | cut -dv -f2
  )" ]]; then
    IMAGE_PUSH_NAME=(
      "$IMAGE_HUB_REGISTRY/$IMAGE_HUB_REPO/$IMAGE_KUBE:v${KUBE%+*}"
      "$IMAGE_HUB_REGISTRY/$IMAGE_HUB_REPO/$IMAGE_KUBE:v${KUBE%+*}-$SEALOS"
    )
  else
    IMAGE_PUSH_NAME=(
      "$IMAGE_HUB_REGISTRY/$IMAGE_HUB_REPO/$IMAGE_KUBE:v${KUBE%+*}-$SEALOS"
    )
  fi
fi

sudo buildah login -u "$IMAGE_HUB_USERNAME" -p "$IMAGE_HUB_PASSWORD" "$IMAGE_HUB_REGISTRY"
for IMAGE_NAME in "${IMAGE_PUSH_NAME[@]}"; do
  manifest_name="mf:${KUBE%+*}-${SEALOS}-${IMAGE_NAME##*:}"
  echo "$IMAGE_TAGS" | sed "s~,~\n~g" | while read -r tag; do
    echo "${IMAGE_NAME%:*}:$tag"
  done | xargs sudo buildah manifest create --all "$manifest_name" || exit $ERR_CODE
  if [[ $(sudo buildah inspect "$manifest_name" | yq .manifests[].platform.architecture | uniq | grep 64 -c) -eq 2 ]]; then
    sudo buildah manifest push --all "$manifest_name" "docker://$IMAGE_NAME" && echo "$IMAGE_NAME push success"
    if sudo buildah login -u labring -p "$1" docker.io; then
      docker_image_name="docker.io/labring/${IMAGE_NAME##*/}"
      sudo buildah manifest push --rm --all "$manifest_name" "docker://$docker_image_name" && echo "$docker_image_name push success"
    else
      echo "warning: Please input REGISTRY_TOKEN for docker.io"
      sudo buildah manifest rm "$manifest_name" >/dev/null 2>&1 || true
    fi
  else
    sudo buildah manifest inspect "$manifest_name" | yq -CP
    echo "ERROR::TARGETARCH for sealos build"
    sudo buildah images
    exit $ERR_CODE
  fi
done

sudo buildah images
