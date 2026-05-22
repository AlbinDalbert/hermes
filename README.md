# Hermes Image

This repo builds a thin custom image on top of `ghcr.io/nousresearch/hermes-agent`
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
- `HERMES_BASE_IMAGE`: upstream base image, default `ghcr.io/nousresearch/hermes-agent:latest`
- `K8S_NAMESPACE`: Kubernetes namespace, default `default`
- `NERDCTL_NAMESPACE`: containerd namespace for nerdctl, default `k8s.io`
- `NO_CACHE`: set to `1` to build with `--no-cache`
