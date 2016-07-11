#!/bin/bash

CUSTOM_DIR=${CUSTOM_DIR:-1}
CUSTOM_DIR=${CUSTOM_DIR:?"CUSTOM_DIR is undefined!"}
PATCHES_DIR=${PATCHES_DIR:-2}
PATCHES_DIR=${PATCHES_DIR:?"PATCHES_DIR is undefined!"}

SKIP_USE_CURRENT_CUSTOMIZATIONS=${SKIP_USE_CURRENT_CUSTOMIZATIONS:-1}

prepare_current_customizations_for_applying()
{
    cd ${CUSTOM_DIR} || return 0
    [ ! -d ${PATCHES_DIR} ] || mkdir -p ${PATCHES_DIR}
    for PACK in $(ls .)
    do
        cp ${PACK}/${PACK}_customization.patch ${PATCHES_DIR}
    done
}

[ ${SKIP_USE_CURRENT_CUSTOMIZATIONS} ] && prepare_current_customizations_for_applying

cd ${PATCHES_DIR} || exit 0

for PATCH in $(ls .)
do
    if patch -p0 -N --dry-run -d / < ${PATCH}
    then
        patch -p0 -d / < ${PATCH}
    fi
done
