#!/bin/bash

set -x

declare -A targets
i=0
targets+=([$i,TARGET_PROJECT]=operator \
        [$i,TARGET_IMAGE]=prometheus-operator-builder \
        [$i,TARGET_TAG]=v0.38.3)
((i++))
targets+=([$i,TARGET_PROJECT]=prometheus-config-reloader \
        [$i,TARGET_IMAGE]=prometheus-config-reloader-builder \
        [$i,TARGET_TAG]=v0.38.3)

max_i=$i

MULTIARCH_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ROOT_DIR="$( cd $MULTIARCH_DIR/.. >/dev/null 2>&1 && pwd )"

TARGET_REPO=${TARGET_REPO:-lisy09kubesphere}

mkdir -p $ROOT_DIR/bin

for (( i=0; i <= $max_i; i++ ))
do
    TARGET_PROJECT=${targets[$i,TARGET_PROJECT]} \
    TARGET_IMAGE=${targets[$i,TARGET_IMAGE]} \
    TARGET_TAG=${targets[$i,TARGET_TAG]}

    TARGET_PROJECT=$TARGET_PROJECT \
    TARGET_IMAGE=$TARGET_IMAGE \
    TARGET_TAG=$TARGET_TAG \
    $MULTIARCH_DIR/build_binary_image_template.sh

    BUILDER_IMAGE=$TARGET_REPO/$TARGET_IMAGE:$TARGET_TAG
    id=$(docker create $BUILDER_IMAGE)
    docker cp $id:/workspace/bin $ROOT_DIR/
    docker rm -v $id 
    docker rmi $BUILDER_IMAGE
done