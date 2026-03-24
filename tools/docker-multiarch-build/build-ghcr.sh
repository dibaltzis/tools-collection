#!/bin/bash
set -euo pipefail

GITHUB_USER="${GITHUB_USER:-github-username-placeholder}"

IMAGE="${IMAGE:-project-name-placeholder}"
REGISTRY="${REGISTRY:-ghcr.io}"
VERSION="${VERSION:-$(git rev-parse --short=6 HEAD 2>/dev/null || echo "dev")}"
PLATFORMS="linux/amd64,linux/arm64"

FULL_IMAGE="${REGISTRY}/${GITHUB_USER}/${IMAGE}"

echo "Building multi-arch image for: ${PLATFORMS}"
echo "Registry: ${REGISTRY}"
echo "Image: ${FULL_IMAGE}"
echo "Version: ${VERSION}"
echo "-------------------------------------------"

# ghcr.io part
#------------------------------------------------
echo "Logging into GHCR..."
if [ -z "${GHCR_TOKEN:-}" ]; then
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    GHCR_TOKEN="$(gh auth token)"
  else
    echo "❌ GHCR_TOKEN not set and gh not authenticated"
    echo "   → Run: gh auth login"
    echo "   → Or export GHCR_TOKEN manually"
    exit 1
  fi
fi
echo "${GHCR_TOKEN}" | docker login "${REGISTRY}" -u "${GITHUB_USER}" --password-stdin
#------------------------------------------------

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
  --provenance=false \
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