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
set -exuo pipefail
set -ex

mkdir -p ~/.gem
echo -e "---\r\n:rubygems_api_key: $GEM_API_KEY" > ~/.gem/credentials
chmod 0600 ~/.gem/credentials
# Release the fdk gem to rubygems.org
gem push fdk-${BUILD_VERSION}.gem
