#!/usr/bin/env bash

set -e

# Usage: ./build.sh <environment>
# Example: ./build.sh preview
# Example: ./build.sh preprod
# Example: ./build.sh mainnet

ENVIRONMENT=${1:-preview}

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(preview|preprod|mainnet)$ ]]; then
  echo "Error: Invalid environment '$ENVIRONMENT'"
  echo "Usage: ./build.sh <environment>"
  echo "Valid environments: preview, preprod, mainnet"
  exit 1
fi

# Load environment-specific configuration
ENV_FILE=".env.${ENVIRONMENT}"
if [ ! -f "$ENV_FILE" ]; then
  echo "Error: Environment file '$ENV_FILE' not found"
  exit 1
fi

echo "Building for environment: $ENVIRONMENT"
echo "Loading configuration from: $ENV_FILE"

# Source the environment file
set -a
source "$ENV_FILE"
set +a

# Get version from git
VERSION=$(git describe --tags --always --dirty)
echo "Building version: ${VERSION}"

# Docker image naming
DOCKER_IMAGE_NAME=easy1staking/programmable-tokens-ui
DOCKER_IMAGE="${DOCKER_IMAGE_NAME}:${VERSION}-${ENVIRONMENT}"
DOCKER_IMAGE_LATEST="${DOCKER_IMAGE_NAME}:${ENVIRONMENT}-latest"

echo "Docker images:"
echo "  - ${DOCKER_IMAGE}"
echo "  - ${DOCKER_IMAGE_LATEST}"

# Build and push
set -x
docker build -t "${DOCKER_IMAGE}" \
  -t "${DOCKER_IMAGE_LATEST}" \
  --build-arg NEXT_PUBLIC_API_URL="${NEXT_PUBLIC_API_URL}" \
  --build-arg NEXT_PUBLIC_BLOCKFROST_API_KEY="${NEXT_PUBLIC_BLOCKFROST_API_KEY}" \
  --build-arg NETWORK="${NETWORK}" \
  --push \
  .
set +x

echo ""
echo "✅ Build complete!"
echo "Images pushed:"
echo "  - ${DOCKER_IMAGE}"
echo "  - ${DOCKER_IMAGE_LATEST}"
