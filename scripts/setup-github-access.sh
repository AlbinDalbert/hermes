#!/usr/bin/env bash
set -euo pipefail

K8S_NAMESPACE="${K8S_NAMESPACE:-hermes}"
DEPLOYMENT="${DEPLOYMENT:-hermes}"
CONTAINER_NAME="${CONTAINER_NAME:-${DEPLOYMENT}}"
SECRET_NAME="${SECRET_NAME:-hermes-github}"
TOKEN_KEY="${TOKEN_KEY:-GITHUB_TOKEN}"
MOUNT_PATH="${MOUNT_PATH:-/var/run/secrets/hermes-github}"

usage() {
    cat <<EOF
Usage:
  GITHUB_TOKEN=ghp_... $0
  $0 --from-file /path/to/token

Environment:
  K8S_NAMESPACE   Kubernetes namespace, default: hermes
  DEPLOYMENT      Deployment to patch, default: hermes
  CONTAINER_NAME  Container to patch, default: same as DEPLOYMENT
  SECRET_NAME     Secret name, default: hermes-github
EOF
}

token_file=""
if [ "${1:-}" = "--from-file" ]; then
    token_file="${2:-}"
    if [ -z "${token_file}" ] || [ ! -r "${token_file}" ]; then
        echo "Token file is missing or unreadable." >&2
        usage >&2
        exit 2
    fi
elif [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    exit 0
elif [ "${#}" -gt 0 ]; then
    echo "Unknown argument: $1" >&2
    usage >&2
    exit 2
fi

if [ -n "${token_file}" ]; then
    kubectl create secret generic "${SECRET_NAME}" \
        -n "${K8S_NAMESPACE}" \
        "--from-file=${TOKEN_KEY}=${token_file}" \
        --dry-run=client -o yaml | kubectl apply -f -
elif [ -n "${GITHUB_TOKEN:-}" ]; then
    kubectl create secret generic "${SECRET_NAME}" \
        -n "${K8S_NAMESPACE}" \
        "--from-literal=${TOKEN_KEY}=${GITHUB_TOKEN}" \
        --dry-run=client -o yaml | kubectl apply -f -
else
    echo "Set GITHUB_TOKEN or pass --from-file /path/to/token." >&2
    usage >&2
    exit 2
fi

kubectl patch deployment "${DEPLOYMENT}" -n "${K8S_NAMESPACE}" --type='strategic' -p "
spec:
  template:
    spec:
      containers:
      - name: ${CONTAINER_NAME}
        env:
        - name: GITHUB_TOKEN_FILE
          value: ${MOUNT_PATH}/${TOKEN_KEY}
        volumeMounts:
        - name: github-token
          mountPath: ${MOUNT_PATH}
          readOnly: true
      volumes:
      - name: github-token
        secret:
          secretName: ${SECRET_NAME}
"

kubectl rollout restart "deployment/${DEPLOYMENT}" -n "${K8S_NAMESPACE}"
kubectl rollout status "deployment/${DEPLOYMENT}" -n "${K8S_NAMESPACE}"
