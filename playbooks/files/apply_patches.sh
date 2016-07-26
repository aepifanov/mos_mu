#!/bin/bash

PATCHES_DIR=${1:-$PATCHES_DIR}
PATCHES_DIR=${PATCHES_DIR:?"PATCHES_DIR is undefined!"}

cd "${PATCHES_DIR}" &>/dev/null || exit 0

# Apply patches
PATCHES=$(find . -type f -name "*.patch" |sort)
for PATCH in ${PATCHES}; do
    patch -p1 -N -d / < "${PATCH}" ||
        { echo "[ERROR] ${PATCH} failed to apply";
         RET=1; }
    echo "[INFO] ${PATCH} Applied OK"
done

exit ${RET}

