#!/usr/bin/env bash
set -e
set -x
. /etc/profile

WORKDIR=$PWD

BRANCH=$(git rev-parse --symbolic-full-name --abbrev-ref HEAD || echo "")
( [ -z "$BRANCH" ] || [ "${BRANCH,,}" == "head" ] ) && BRANCH="${SOURCE_BRANCH}"

# Cleanup old binaries
rm -rfv ./bin

# Publish tmconnect
cd ./tmconnect
make publish

# Copy all binaries to bin directory
cd $WORKDIR
mkdir -p ./bin
cp -rfv ./tmconnect/bin/* ./bin
rm -rfv ./tmconnect/bin/*
