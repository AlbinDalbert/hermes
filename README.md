# Hermes Image

This repo builds a thin custom image on top of `nousresearch/hermes-agent`
and adds a pinned `kubectl` binary.

The Dockerfile handles both `amd64` and `arm64`. If `TARGETARCH` is not provided
by the builder, it falls back to the host architecture, which makes native builds
on an ARM device work without extra flags.

## Docker Build

```bash
docker build -t your-registry/hermes:latest .
```

For a specific platform:

```bash
docker buildx build --platform linux/arm64 -t your-registry/hermes:latest .
```

## nerdctl Deploy

Use [deploy.sh](/home/chell/repos/hermes/deploy.sh:1) to build directly into the
`k8s.io` containerd namespace on a Kubernetes node.

Example:

```bash
IMAGE_REPO=ghcr.io/albindalbert/hermes \
K8S_NAMESPACE=hermes \
./deploy.sh latest
```

## Configuration

`deploy.sh` supports these environment variables:

- `IMAGE_REPO`: target image repository to build, default `ghcr.io/albindalbert/hermes`
- `HERMES_BASE_IMAGE`: upstream base image, default `nousresearch/hermes-agent:latest`
- `K8S_NAMESPACE`: Kubernetes namespace, default `hermes`
- `K8S_DEPLOYMENT`: Kubernetes Deployment to restart, default `hermes`
- `NERDCTL_NAMESPACE`: containerd namespace for nerdctl, default `k8s.io`
- `NO_CACHE`: set to `1` to build with `--no-cache`

## GitHub Access

This image includes a Git credential helper for `https://github.com` that reads
a token from `GITHUB_TOKEN_FILE` first, then `GITHUB_TOKEN`. The preferred
runtime setup is a Kubernetes Secret mounted as a file, so the token is not
present in normal environment dumps.

An administrator with permission to create Secrets and patch the Hermes
Deployment can run:

```bash
GITHUB_TOKEN=ghp_or_github_pat_here ./scripts/setup-github-access.sh
```

Or, to avoid putting the token in shell history:

```bash
./scripts/setup-github-access.sh --from-file /path/to/github-token
```

By default this creates or updates `secret/hermes-github` in namespace `hermes`,
sets `GITHUB_TOKEN` from that Secret, mounts the same Secret at
`/var/run/secrets/hermes-github`, sets `GITHUB_TOKEN_FILE`, and restarts
`deployment/hermes`.

If the Kubernetes container name differs from the Deployment name, set
`CONTAINER_NAME` when running the script.

After the rollout, private HTTPS clones from GitHub should work normally:

```bash
git clone https://github.com/owner/repo.git
```

For direct API calls, read the token explicitly:

```bash
curl -H "Authorization: Bearer $(cat "$GITHUB_TOKEN_FILE")" https://api.github.com/user
```

The Hermes ServiceAccount does not need Kubernetes `get` or `list` permissions
on Secrets for this setup. It only needs the pod spec to reference the Secret.

To verify the Deployment wiring without printing the token:

```bash
kubectl get deploy hermes -n hermes -o yaml | grep -A20 -E 'GITHUB_TOKEN|github-token|hermes-github'
```
