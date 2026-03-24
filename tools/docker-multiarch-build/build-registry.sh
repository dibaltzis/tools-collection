#!/bin/bash
set -euo pipefail

IMAGE="${IMAGE:-project-name-placeholder}"
REGISTRY="${REGISTRY:-192.168.31.229:5444}"
VERSION="${VERSION:-$(git rev-parse --short=6 HEAD 2>/dev/null || echo "dev")}"
PLATFORMS="linux/amd64,linux/arm64"

FULL_IMAGE="${REGISTRY}/${IMAGE}"

echo "Building multi-arch image for: ${PLATFORMS}"
echo "Registry: ${REGISTRY}"
echo "Image: ${FULL_IMAGE}"
echo "Version: ${VERSION}"
echo "-------------------------------------------"

# Create builder if needed
if ! docker buildx inspect multiarch-builder >/dev/null 2>&1; then
    echo "Creating multiarch builder..."
    docker buildx create --name multiarch-builder --driver docker-container --use
fi

# Use the multiarch builder
docker buildx use multiarch-builder
docker buildx inspect --bootstrap

# Build + push multi-arch image
docker buildx build \
  --platform "${PLATFORMS}" \
  --build-arg VERSION="${VERSION}" \
  -t "${FULL_IMAGE}:${VERSION}" \
  -t "${FULL_IMAGE}:latest" \
  --push .

echo "✅ Multi-arch image pushed successfully"

digest=$(docker buildx imagetools inspect "${FULL_IMAGE}:${VERSION}" 2>/dev/null \
  | awk '/Digest:/ {print $2; exit}')
digest=${digest:-unknown}
printf "| %-17s %-30s |\n" "Digest:" "$digest"

echo "Cleaning up dangling images..."
#docker builder prune -f
docker buildx prune --builder multiarch-builder -f

echo "===================================================="
echo "|           ✅ Docker Build Summary                |"
echo "===================================================="
printf "| %-17s %-30s |\n" "Image Name:"     "$IMAGE"
printf "| %-17s %-30s |\n" "Registry:"       "$REGISTRY"
printf "| %-17s %-30s |\n" "Version Tag:"    "$VERSION"
printf "| %-17s %-30s |\n" "Latest Tag:"     "latest"
printf "| %-17s %-30s |\n" "Repository:"     "$FULL_IMAGE"
echo "===================================================="