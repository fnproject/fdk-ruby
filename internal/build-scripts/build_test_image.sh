#!/usr/bin/env bash
set -ex

if [ -z "$1" ]; then
  echo "Please supply function directory to build test function image" >>/dev/stderr
  exit 2
fi

if [ -z "$2" ]; then
  echo "Please supply ruby version as argument to build image." >>/dev/stderr
  exit 2
fi

fn_dir=$1
RUBY_version=$2
pkg_version=${BUILD_VERSION}

(
  # Build test function image for integration test.
  # Copy the gem file ie .gem fdk-ruby folder to the function test dir.
  cp -R fdk-${pkg_version}.gem ${fn_dir}
  pushd ${fn_dir}
  name="$(awk '/^name:/ { print $2 }' func.yaml)"

  version="$(awk '/^runtime:/ { print $2 }' func.yaml)"
  image_identifier="${version}-${BUILD_VERSION}"

  docker build -t fnproject/${name}:${image_identifier} -f Build_file --build-arg RUBY_VERSION=${RUBY_version} --build-arg PKG_VERSION=${pkg_version} --build-arg OCIR_REGION=${OCIR_REGION} --build-arg OCIR_LOC=${OCIR_LOC} --build-arg BUILD_VERSION=${BUILD_VERSION} .
  rm -rf fdk-${pkg_version}.gem
  popd

  # Push to OCIR
  ocir_image="${OCIR_LOC}/${name}:${image_identifier}"

  docker image tag "fnproject/${name}:${image_identifier}" "${OCIR_REGION}/${ocir_image}"
  docker image push "${OCIR_REGION}/${ocir_image}"

)
