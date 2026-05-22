#!/usr/bin/env bash
set -euo pipefail

TAG="${1:-latest}"
IMAGE_REPO="${IMAGE_REPO:-ghcr.io/albindalbert/hermes}"
IMAGE_TAG="${IMAGE_TAG:-$TAG}"
IMAGE="${IMAGE_REPO}:${IMAGE_TAG}"
HERMES_BASE_IMAGE="${HERMES_BASE_IMAGE:-nousresearch/hermes-agent:latest}"
K8S_NAMESPACE="${K8S_NAMESPACE:-default}"
NERDCTL_NAMESPACE="${NERDCTL_NAMESPACE:-k8s.io}"
NO_CACHE="${NO_CACHE:-1}"
TARGETARCH="${TARGETARCH:-}"

if [ -z "${TARGETARCH}" ]; then
    case "$(uname -m)" in
        aarch64|arm64) TARGETARCH="arm64" ;;
        x86_64|amd64) TARGETARCH="amd64" ;;
        *)
            echo "Unsupported architecture: $(uname -m)" >&2
            exit 1
            ;;
    esac
fi

if ! pgrep -x buildkitd >/dev/null 2>&1; then
    sudo buildkitd >/dev/null 2>&1 &
    sleep 2
fi

echo "Pulling base image: ${HERMES_BASE_IMAGE}"
sudo nerdctl --namespace "${NERDCTL_NAMESPACE}" pull "${HERMES_BASE_IMAGE}"

build_args=(
    --build-arg "HERMES_BASE_IMAGE=${HERMES_BASE_IMAGE}"
    --build-arg "TARGETARCH=${TARGETARCH}"
    -t "${IMAGE}"
    .
)

if [ "${NO_CACHE}" = "1" ]; then
    build_args=(--no-cache "${build_args[@]}")
fi

echo "Building ${IMAGE} for ${TARGETARCH} in namespace ${NERDCTL_NAMESPACE}"
sudo nerdctl --namespace "${NERDCTL_NAMESPACE}" build "${build_args[@]}"

echo "Restarting deploy/hermes in namespace ${K8S_NAMESPACE}"
kubectl rollout restart deploy/hermes -n "${K8S_NAMESPACE}"

echo "Done."
