#!/bin/bash
set -euo pipefail
start_time=$(date +%s)

IMAGE="${IMAGE:-project-name-placeholder}"
REGISTRY="${REGISTRY:-192.168.31.229:5444}"
VERSION="${VERSION:-$(git rev-parse --short=6 HEAD 2>/dev/null || echo "dev")}"
PLATFORMS="${PLATFORMS:-linux/amd64,linux/arm64}"

FULL_IMAGE="${REGISTRY}/${IMAGE}"

echo "-------------------------------------------"
echo "Platforms: ${PLATFORMS}"
echo "Registry: ${REGISTRY}"
echo "Image: ${FULL_IMAGE}"
echo "Version: ${VERSION}"
echo "-------------------------------------------"

# Create builder if needed
if ! docker buildx inspect multiarch-builder >/dev/null 2>&1; then
    echo "Creating multiarch builder..."
    docker buildx create --name multiarch-builder --driver docker-container --use >/dev/null 2>&1
fi

docker buildx use multiarch-builder >/dev/null 2>&1

docker buildx inspect --bootstrap >/dev/null 2>&1 || {
  echo "[ERROR] Failed to bootstrap builder" >&2
  exit 1
}

# Build + push multi-arch image
docker buildx build \
  --platform "${PLATFORMS}" \
  --build-arg VERSION="${VERSION}" \
  -t "${FULL_IMAGE}:${VERSION}" \
  -t "${FULL_IMAGE}:latest" \
  --push .

echo 
echo "[OK] Multi-arch image pushed successfully"
end_time=$(date +%s)
duration=$((end_time - start_time))

# getting the digest
digest=""
for i in 1 2; do
  digest=$(docker buildx imagetools inspect "${FULL_IMAGE}:${VERSION}" 2>/dev/null \
    | awk '/Digest:/ {print $2; exit}' || true)
  
  [[ -n "$digest" ]] && break
  sleep 1
done
digest=${digest:-unknown}

# cleaning remnants and leftovers
echo
echo "[INFO] Cleaning up dangling images..."
total=$(docker buildx prune --builder multiarch-builder -f 2>/dev/null | tail -n 1 || true)
if [[ -z "${total}" ]]; then
  total="Total: 0B"
fi
echo "$total"
#docker builder prune -f

echo
echo "[SUMMARY]"
echo "----------"
printf "%-18s %s\n" "Image Name:"     "$IMAGE"
printf "%-18s %s\n" "Registry:"       "$REGISTRY"
printf "%-18s %s\n" "Version Tag:"    "$VERSION"
printf "%-18s %s\n" "Latest Tag:"     "latest"
printf "%-18s %s\n" "Repository:"     "$FULL_IMAGE"
printf "%-18s %s\n" "Digest:"         "$digest"
printf "%-18s %s\n" "Build duration:" "${duration}s"