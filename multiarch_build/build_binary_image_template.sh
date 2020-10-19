#!/bin/bash

MULTIARCH_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ROOT_DIR="$( cd $MULTIARCH_DIR/.. >/dev/null 2>&1 && pwd )"

TARGET_REPO=${TARGET_REPO:-lisy09kubesphere}
docker build -t ${TARGET_REPO}/${TARGET_IMAGE}:${TARGET_TAG} \
    --build-arg TARGET_PROJECT=${TARGET_PROJECT} \
    -f $MULTIARCH_DIR/builder.Dockerfile \
    $ROOT_DIR