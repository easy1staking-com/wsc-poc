#!/usr/bin/env bash

set -e

# Usage: ./build.sh
#
# Builds a single Docker image that works for all environments.
# Environment variables (API URL, keys, etc.) are set at RUNTIME
# via Kubernetes ConfigMaps/Secrets, not at build time.

# Get version from git
VERSION=$(git describe --tags --always --dirty)
echo "Building version: ${VERSION}"

# Docker image naming
DOCKER_IMAGE_NAME=easy1staking/programmable-tokens-ui
DOCKER_IMAGE="${DOCKER_IMAGE_NAME}:${VERSION}"
DOCKER_IMAGE_LATEST="${DOCKER_IMAGE_NAME}:latest"

echo "Docker images:"
echo "  - ${DOCKER_IMAGE}"
echo "  - ${DOCKER_IMAGE_LATEST}"

# Build and push (no build args needed - everything is runtime now!)
set -x
docker build --progress plain \
  -t "${DOCKER_IMAGE}" \
  -t "${DOCKER_IMAGE_LATEST}" \
  --push \
  .
set +x

echo ""
echo "✅ Build complete!"
echo "Images pushed:"
echo "  - ${DOCKER_IMAGE}"
echo "  - ${DOCKER_IMAGE_LATEST}"
echo ""
echo "💡 Remember to set runtime environment variables in Kubernetes:"
echo "   - API_URL (e.g., http://wsc)"
echo "   - BLOCKFROST_API_KEY (e.g., preview6rf9Lym3f9XQrTDnxSBbAGwvz5mNafdz)"
echo "   - NETWORK (e.g., Preview)"
