
# Build base fdk build and runtime images
echo "Ruby Version"
ruby --version

# Create a builder instance
(
  docker buildx rm builderInstance || true
  docker buildx create --name builderInstance --driver-opt=image=iad.ocir.io/oraclefunctionsdevelopm/moby/buildkit:buildx-stable-1 --platform linux/amd64,linux/arm64
  docker buildx use builderInstance
)

#Teamcity uses a very old version of buildx which creates a bad request body. Pushing the images to OCIR gives a 400 bad request error. Hence, use this 
#script to upgrade the buildx version.
./internal/build-scripts/update-buildx.sh

./internal/build-scripts/build_base_image.sh 2.7
./internal/build-scripts/build_base_image.sh 3.1
