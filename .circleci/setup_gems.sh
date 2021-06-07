#!/usr/bin/env bash

set -euo pipefail

mkdir -p ~/.gem
echo -e "---\r\n:rubygems_api_key: $GEM_API_KEY_TEST" > ~/.gem/credentials
chmod 0600 ~/.gem/credentials