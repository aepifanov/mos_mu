#!/bin/bash -x

CUSTOM_DIR=${1:-$CUSTOM_DIR}
CUSTOM_DIR=${CUSTOM_DIR:?"CUSTOM_DIR is undefined!"}
PATCHES_DIR=${2:-$PATCHES_DIR}
PATCHES_DIR=${PATCHES_DIR:?"PATCHES_DIR is undefined!"}

cd "${CUSTOM_DIR}" || exit 0
[ -d "${PATCHES_DIR}" ] || mkdir -p "${PATCHES_DIR}"
rm -rf "${PATCHES_DIR}"/*

PATCHES=$(find . -type f -name "*.patch" |sort)
for PATCH in ${PATCHES}; do
    cp -f "${PATCH}" "${PATCHES_DIR}/" || exit 1
done
