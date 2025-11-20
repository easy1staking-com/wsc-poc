#!/usr/bin/env bash

set -e

# Usage: ./build.sh [environment-tag]
# Example: ./build.sh preview  (creates tags: VERSION-preview, preview-latest)
# Example: ./build.sh          (creates tags: VERSION, latest)
#
# Note: Environment variables (API URL, keys, etc.) are now set at RUNTIME
# via Kubernetes ConfigMaps/Secrets, not at build time.

ENVIRONMENT=${1:-""}

# Get version from git
VERSION=$(git describe --tags --always --dirty)
echo "Building version: ${VERSION}"

# Docker image naming
DOCKER_IMAGE_NAME=easy1staking/programmable-tokens-ui

if [ -n "$ENVIRONMENT" ]; then
  # Environment-specific tags (for organization)
  DOCKER_IMAGE="${DOCKER_IMAGE_NAME}:${VERSION}-${ENVIRONMENT}"
  DOCKER_IMAGE_LATEST="${DOCKER_IMAGE_NAME}:${ENVIRONMENT}-latest"
  echo "Building with environment tag: $ENVIRONMENT"
else
  # Generic tags
  DOCKER_IMAGE="${DOCKER_IMAGE_NAME}:${VERSION}"
  DOCKER_IMAGE_LATEST="${DOCKER_IMAGE_NAME}:latest"
  echo "Building without environment tag"
fi

echo "Docker images:"
echo "  - ${DOCKER_IMAGE}"
echo "  - ${DOCKER_IMAGE_LATEST}"

# Build and push (no build args needed - everything is runtime now!)
set -x
docker build -t "${DOCKER_IMAGE}" \
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
echo "💡 Remember to set runtime environment variables:"
echo "   - NEXT_PUBLIC_API_URL"
echo "   - NEXT_PUBLIC_BLOCKFROST_API_KEY"
echo "   - NETWORK"
