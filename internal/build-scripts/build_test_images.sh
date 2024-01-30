#!/usr/bin/env bash

set -ex

echo "Ruby Version"
ruby --version

# Login to OCIR
echo ${OCIR_PASSWORD} | docker login --username "${OCIR_USERNAME}" --password-stdin ${OCIR_REGION}

# Build and push the test function images to OCIR for integration test framework.

# Ruby 3.1
(
  source internal/build-scripts/build_test_image.sh internal/tests-images/ruby3.1/hello-world-test 3.1
  source internal/build-scripts/build_test_image.sh internal/tests-images/ruby3.1/timeout-test 3.1
  source internal/build-scripts/build_test_image.sh internal/tests-images/ruby3.1/runtime-version-test 3.1
  source internal/build-scripts/build_test_image.sh internal/tests-images/ruby3.1/oci-sdk-test 3.1
)