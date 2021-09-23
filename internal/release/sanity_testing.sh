#!/bin/bash
#
# Copyright (c) 2019, 2020 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# This script makes use of the sanity-testing/internal folder scripts created as part of internal/release/setup_sanity_testing_folder.sh script
# to execute unit tests and build fdk ruby dist package on the bitbucket github branch created from release tag branch.

set -ex

# Copy the contents of sanity-testing folder to .bitbucket/internal folder
cp -R sanity-testing/internal .bitbucket/internal

# .bitbucket folder contains the fdk node checked out code.
cd .bitbucket

ls -al

(
  # Build ruby containing src files toß generate a gem file
  docker build -t fdk_ruby_build_image -f ./internal/docker-files/Dockerfile_build .
  docker run --rm -v $PWD:/build -w /build --env BUILD_VERSION=${BUILD_VERSION} fdk_ruby_build_image ./internal/build-scripts/build_dist_pkg.sh

)

(
  # Execute unit tests
  docker build -t fdk_ruby_env_image -f ./internal/docker-files/Dockerfile_unit_test .
  docker run --rm fdk_ruby_env_image ./internal/build-scripts/execute_unit_tests.sh
)


# Remove the copied over internal folder for sanity testing
rm -rf internal/

# this step is to ensure we don't commit any files produced by unit test or build package to github branch
git status
if [[ -z $(git status -s) ]]
then
  echo "tree is clean"
else
  echo "tree is dirty, please commit changes before running this"
  exit 1
fi