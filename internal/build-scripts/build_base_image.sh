#!/usr/bin/env bash
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


set -xeuo pipefail

if [[ -z ${1:-} ]];then
  echo "Please supply ruby version as argument to build image." >> /dev/stderr
  exit 2
fi

rubyversion=$1

echo $rubyversion

#Login to OCIR
echo ${OCIR_PASSWORD} | docker login --username "${OCIR_USERNAME}" --password-stdin ${OCIR_REGION}

pushd internal/images/build-stage/${rubyversion} && docker buildx build --push --platform linux/amd64,linux/arm64 -t ${OCIR_REGION}/${OCIR_LOC}/ruby:${rubyversion}-${BUILD_VERSION}-dev . && popd
pushd internal/images/runtime/${rubyversion} && docker buildx build --push --platform linux/amd64,linux/arm64 -t ${OCIR_REGION}/${OCIR_LOC}/ruby:${rubyversion}-${BUILD_VERSION} . && popd
