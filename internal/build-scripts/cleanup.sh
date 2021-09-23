#!/usr/bin/env bash

set -ex

if [ "${LOCAL}" = "true" ] && [ "${RUN_TYPE}" != "release" ]; then
  # Remove gem file
  rm -rf fdk-${BUILD_VERSION}.gem
fi
