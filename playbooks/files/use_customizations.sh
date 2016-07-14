#!/bin/bash -x

CUSTOM_DIR=${1:-$CUSTOM_DIR}
CUSTOM_DIR=${CUSTOM_DIR:?"CUSTOM_DIR is undefined!"}
PATCHES_DIR=${2:-$PATCHES_DIR}
PATCHES_DIR=${PATCHES_DIR:?"PATCHES_DIR is undefined!"}

prepare_current_customizations_for_applying()
{
    cd ${CUSTOM_DIR} || return 0
    [ -d ${PATCHES_DIR} ] || mkdir -p ${PATCHES_DIR}
    for PACK in *; do
        cp -f ${PACK}/${PACK}_customization.patch ${PATCHES_DIR} || exit 1
    done
}

prepare_current_customizations_for_applying
