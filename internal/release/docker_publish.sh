#!/usr/bin/env bash

set -eu

REGCTL_BIN=regctl
# Test regctl is on path
$REGCTL_BIN --help

TEMPDIR=$(mktemp -d)
cd "${TEMPDIR}"

function cleanup {
    rm -rf "${TEMPDIR}"
}
trap cleanup EXIT

{
$REGCTL_BIN image copy iad.ocir.io/oraclefunctionsdevelopm/fnproject/ruby:3.3-dev docker.io/fnproject/ruby:3.3-dev;
$REGCTL_BIN image copy iad.ocir.io/oraclefunctionsdevelopm/fnproject/ruby:3.3 docker.io/fnproject/ruby:3.3;
$REGCTL_BIN image copy iad.ocir.io/oraclefunctionsdevelopm/fnproject/ruby:3.1-dev docker.io/fnproject/ruby:3.1-dev;
$REGCTL_BIN image copy iad.ocir.io/oraclefunctionsdevelopm/fnproject/ruby:3.1 docker.io/fnproject/ruby:3.1;
}

