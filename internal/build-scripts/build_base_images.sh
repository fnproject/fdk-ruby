
# Build base fdk build and runtime images
echo "Ruby Version"
ruby --version

./internal/build-scripts/build_base_image.sh 2.7
./internal/build-scripts/build_base_image.sh 3.1
