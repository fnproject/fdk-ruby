
# Build base fdk build and runtime images
echo "Ruby Version"
ruby --version

# Create a builder instance
(
  docker buildx rm builderInstance || true
  docker buildx create --name builderInstance --driver docker-container --platform linux/amd64,linux/arm64
  docker buildx use builderInstance
)

./internal/build-scripts/build_base_image.sh 2.7
./internal/build-scripts/build_base_image.sh 3.1
